#!/usr/bin/env python3
"""
generate_synthetic.py — Generate labelled training data from recipe websites.

Pipeline:
  1. Fetch sitemap(s) to discover recipe URLs
  2. Fetch each recipe page and extract schema.org JSON-LD
  3. Render each recipe as structured text with known line labels
  4. Compute all 20 features per line (text-derived from real content,
     spatial features simulated via linear layout with noise)
  5. Export labelled CSV for training

Usage:
  python generate_synthetic.py \
      --sitemap https://www.recipetineats.com/post-sitemap.xml \
      --max-recipes 500 \
      --output ./data/labelled_lines.csv

  # Or use a pre-downloaded JSONL file instead of scraping:
  python generate_synthetic.py \
      --recipes ./data/recipes.jsonl \
      --output ./data/labelled_lines.csv
"""

import argparse
import csv
import json
import math
import random
import sys
import time
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime
from typing import Any
from urllib.parse import urlparse

# ── Constants ────────────────────────────────────────────────────────────────

# Must match FeatureExtractor.featureNames in lib/core/ocr/feature_extractor.dart
FEATURE_NAMES = [
    "relative_top",
    "relative_left",
    "relative_width",
    "relative_height",
    "relative_font_size",
    "block_index",
    "lines_in_block",
    "line_index_in_block",
    "starts_with_digit",
    "starts_with_unicode_fraction",
    "ends_with_colon",
    "word_count",
    "char_count",
    "starts_with_imperative_verb",
    "contains_number",
    "ends_with_punctuation",
    "has_mixed_case",
    "confidence",
    "is_first_in_block",
    "is_last_in_block",
]

# Must match OnnxClassifier label enum order
LABEL_NAMES = [
    "title",
    "servings",
    "section_header",
    "ingredient",
    "method_step",
    "method_continuation",
    "nutrition",
    "notes",
    "ignore",
]

# Imperative verb set (mirrors RecipeTextParser.imperativeVerbs)
IMPERATIVE_VERBS = {
    "add", "bake", "beat", "blend", "boil", "broil", "brown", "chill",
    "chop", "combine", "cook", "cover", "cut", "defrost", "dice", "drain",
    "drizzle", "fold", "fry", "garnish", "grate", "grill", "heat", "knead",
    "layer", "marinate", "mash", "melt", "microwave", "mix", "place",
    "pour", "preheat", "prepare", "press", "refrigerate", "remove",
    "rinse", "roast", "rest", "roll", "sauté", "sear", "season", "serve",
    "simmer", "slice", "soak", "spread", "steam", "stir", "toast",
    "toss", "trim", "whisk",
}

# Simulated image dimensions (arbitrary, for normalised spatial features)
PAGE_W = 800.0
PAGE_H = 1200.0

# User-agent for requests
UA = "PantryTraining/1.0 (recipe classifier data collection)"

# ── Helpers ──────────────────────────────────────────────────────────────────


def fetch(url: str) -> str:
    """Fetch a URL with a polite User-Agent and timeout."""
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return resp.read().decode("utf-8")


def extract_recipe_urls_from_sitemap(sitemap_url: str) -> list[str]:
    """Parse a WordPress Yoast SEO sitemap and return recipe-like URLs."""
    raw = fetch(sitemap_url)
    urls = []
    for line in raw.splitlines():
        line = line.strip()
        if line.startswith("<loc>") and line.endswith("</loc>"):
            url = line[5:-6].strip()
            # Filter to recipe-like paths (not pages, categories, tags)
            path = urlparse(url).path
            # Skip non-recipe pages
            skip_patterns = [
                "/blog/", "/about/", "/contact/", "/privacy",
                "/category/", "/tag/", "/author/", "/page/",
            ]
            if any(p in path for p in skip_patterns):
                continue
            urls.append(url)
    return urls


def extract_recipe_jsonld(html: str, url: str) -> dict[str, Any] | None:
    """Find the Recipe node in schema.org JSON-LD embedded in HTML."""
    import re
    # Find all JSON-LD script blocks
    for match in re.finditer(
        r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>',
        html, re.DOTALL | re.IGNORECASE,
    ):
        raw = match.group(1).strip()
        if not raw:
            continue
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            continue

        # Walk @graph arrays looking for Recipe type
        def find_recipe(node):
            if isinstance(node, dict):
                if isinstance(node.get("@type"), str) and "Recipe" in node["@type"]:
                    return node
                if isinstance(node.get("@type"), list) and "Recipe" in node["@type"]:
                    return node
                for val in node.values():
                    result = find_recipe(val)
                    if result:
                        return result
            elif isinstance(node, list):
                for item in node:
                    result = find_recipe(item)
                    if result:
                        return result
            return None

        recipe = find_recipe(data)
        if recipe:
            return recipe
    return None


def parse_instructions(instructions: Any) -> list[dict[str, Any]]:
    """Normalise recipeInstructions into a list of {name?, text} steps."""
    steps = []
    if isinstance(instructions, str):
        steps.append({"text": instructions.strip()})
    elif isinstance(instructions, list):
        for item in instructions:
            if isinstance(item, str):
                steps.append({"text": item.strip()})
            elif isinstance(item, dict):
                typ = item.get("@type", "")
                if "HowToSection" in typ:
                    section_name = item.get("name", "")
                    elements = item.get("itemListElement", [])
                    for sub in elements:
                        text = ""
                        if isinstance(sub, str):
                            text = sub
                        elif isinstance(sub, dict):
                            text = sub.get("text", "")
                        if text:
                            steps.append({"name": section_name, "text": text.strip()})
                elif "HowToStep" in typ:
                    text = item.get("text", "")
                    if text:
                        steps.append({"text": text.strip()})
    return steps


def extract_label(
    line_text: str,
    known_labels: dict[int, str],
    line_idx: int,
    total_lines: int,
    is_title: bool,
    is_ingredient_section: bool,
    is_method_section: bool,
    is_servings_line: bool,
    is_section_header: bool,
) -> str:
    """Assign ground-truth label based on known recipe structure."""
    if is_title:
        return "title"
    if is_servings_line:
        return "servings"
    if is_section_header:
        return "section_header"
    if is_ingredient_section:
        return "ingredient"
    if is_method_section:
        return "method_step"

    # Lines known_labels override (future use)
    if line_idx in known_labels:
        return known_labels[line_idx]

    return "ignore"


# ── Feature computation ──────────────────────────────────────────────────────


def compute_features(text: str, line_idx: int, num_lines: int) -> list[float]:
    """Compute the 20 normalised features for a single line.

    Spatial features are simulated with a linear layout plus Gaussian noise
    so the model learns robust patterns, not exact positions.
    """
    # Simulated bounding box — linear Y with noise, fixed X-margin
    noise_y = random.gauss(0, 0.003)  # small jitter
    noise_h = random.gauss(0, 0.001)

    line_height = 0.04 + noise_h  # ~48 px on 1200px page
    top = (line_idx / max(num_lines, 1)) * 0.85 + 0.05 + noise_y
    left = 0.08
    width = 0.84

    # Title gets bigger font (wider, taller, top-aligned)
    if line_idx == 0:
        line_height = 0.06
        top = 0.03
        left = 0.10

    # Relative font size vs average
    avg_line_height = 0.04
    relative_font_size = line_height / avg_line_height

    # Block membership — simulate 3 blocks: header, ingredients, method
    # Rough heuristic: first 2-3 lines are block 0, ingredients block 1,
    # method block 2
    if line_idx <= 2 and num_lines > 3:
        block_idx = 0.0
    elif line_idx < num_lines // 2:
        block_idx = 1.0
    else:
        block_idx = 2.0
    lines_in_block = float(num_lines)
    line_index_in_block = float(line_idx)

    # Text-derived features
    trimmed = text.strip()
    words = trimmed.split() if trimmed else []
    word_count = float(len(words))
    char_count = float(len(trimmed))

    starts_with_digit = 1.0 if trimmed and trimmed[0].isdigit() else 0.0
    starts_with_fraction = 1.0 if trimmed and trimmed[0] in "¼½¾⅓⅔⅛⅜⅝⅞" else 0.0
    ends_with_colon = 1.0 if trimmed.endswith(":") else 0.0
    starts_with_verb = 1.0 if words and words[0].lower().strip("(") in IMPERATIVE_VERBS else 0.0
    contains_number = 1.0 if any(c.isdigit() for c in trimmed) else 0.0
    ends_with_punctuation = 1.0 if trimmed and trimmed[-1] in ".!?" else 0.0
    has_mixed_case = 1.0 if any(c.isupper() for c in trimmed) and any(c.islower() for c in trimmed) else 0.0
    confidence = 0.95  # Simulated: synthetic data is "clean"

    is_first_in_block = 1.0 if line_index_in_block == 0 else 0.0
    is_last_in_block = 1.0 if line_index_in_block == lines_in_block - 1 else 0.0

    # Augment: add variance for lines that look OCR-noisy (low confidence)
    # to teach the model that low-confidence lines may have errors
    if random.random() < 0.02:
        confidence = round(random.uniform(0.4, 0.7), 2)

    return [
        top,
        left,
        width,
        line_height,
        relative_font_size,
        block_idx,
        lines_in_block,
        line_index_in_block,
        starts_with_digit,
        starts_with_fraction,
        ends_with_colon,
        word_count,
        char_count,
        starts_with_verb,
        contains_number,
        ends_with_punctuation,
        has_mixed_case,
        confidence,
        is_first_in_block,
        is_last_in_block,
    ]


# ── Recipe rendering ─────────────────────────────────────────────────────────


def render_recipe(recipe: dict) -> list[tuple[str, str]]:
    """Render a structured recipe into (text, label) pairs.

    Returns a list of (line_text, label) tuples preserving order.
    """
    lines: list[tuple[str, str]] = []
    name = recipe.get("name", "").strip()
    if name:
        lines.append((name, "title"))

    # Servings
    raw_yield = recipe.get("recipeYield", [])
    servings_text = ""
    if isinstance(raw_yield, list) and raw_yield:
        servings_text = str(raw_yield[0])
    elif isinstance(raw_yield, (str, int)):
        servings_text = str(raw_yield)
    if servings_text:
        lines.append((f"Serves {servings_text}", "servings"))

    # Ingredients
    ingredients = recipe.get("recipeIngredient", [])
    if isinstance(ingredients, list) and ingredients:
        lines.append(("Ingredients:", "section_header"))
        for ing in ingredients:
            if isinstance(ing, str) and ing.strip():
                lines.append((ing.strip(), "ingredient"))

    # Handle sections inside ingredients (from HowToSection)
    instructions = recipe.get("recipeInstructions", [])
    section_names_found = set()
    for step in parse_instructions(instructions):
        if step.get("name"):
            section_names_found.add(step["name"])

    # Instructions (method steps)
    steps = parse_instructions(instructions)
    if steps:
        lines.append(("Method:", "section_header"))
        for i, step in enumerate(steps):
            text = step.get("text", "").strip()
            if text:
                # Check if this step has a section name (HowToSection group)
                step_name = step.get("name", "")
                if step_name:
                    lines.append((step_name, "section_header"))
                lines.append((text, "method_step"))

    return lines


# ── Main ─────────────────────────────────────────────────────────────────────


def scrape_from_sitemap(sitemap_url: str, max_recipes: int) -> list[dict]:
    """Scrape recipes from a sitemap. Respectful delays."""
    print(f"Fetching sitemap: {sitemap_url}")
    recipe_urls = extract_recipe_urls_from_sitemap(sitemap_url)
    print(f"Found {len(recipe_urls)} URLs in sitemap")
    # Check for additional sitemaps (numbered ones: post-sitemap2.xml, etc.)
    base_sitemap = sitemap_url.replace(".xml", "")
    for i in range(2, 10):
        alt_url = f"{base_sitemap}{i}.xml"
        try:
            more = extract_recipe_urls_from_sitemap(alt_url)
            if more:
                print(f"Found {len(more)} URLs in sitemap {i}")
                recipe_urls.extend(more)
        except Exception:
            break

    random.shuffle(recipe_urls)
    recipe_urls = recipe_urls[:max_recipes]

    recipes = []
    errors = 0
    for idx, url in enumerate(recipe_urls):
        try:
            print(f"  [{idx + 1}/{len(recipe_urls)}] Fetching: {url}")
            html = fetch(url)
            recipe = extract_recipe_jsonld(html, url)
            if recipe:
                recipe["_source_url"] = url
                recipes.append(recipe)
                print(f"    → {recipe.get('name', '?')}")
            else:
                print(f"    → No Recipe JSON-LD found")
                errors += 1
            time.sleep(0.3)  # Polite delay
        except Exception as e:
            print(f"    → Error: {e}")
            errors += 1
            time.sleep(0.5)

    print(f"\nScraped {len(recipes)} recipes ({errors} errors)")
    return recipes


def load_recipes_from_jsonl(path: str) -> list[dict]:
    """Load pre-downloaded recipes from a JSONL file."""
    recipes = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                recipes.append(json.loads(line))
    return recipes


def main():
    parser = argparse.ArgumentParser(
        description="Generate labelled training data for OCR line classifier."
    )
    parser.add_argument(
        "--sitemap",
        default=None,
        help="WordPress sitemap URL (e.g., https://site.com/post-sitemap.xml)",
    )
    parser.add_argument(
        "--max-recipes",
        type=int,
        default=500,
        help="Maximum recipes to scrape (default: 500)",
    )
    parser.add_argument(
        "--recipes",
        default=None,
        help="Path to pre-downloaded recipes JSONL file (alternative to --sitemap)",
    )
    parser.add_argument(
        "--output",
        default="./data/labelled_lines.csv",
        help="Output CSV path (default: ./data/labelled_lines.csv)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for reproducible layout simulation (default: 42)",
    )
    args = parser.parse_args()

    random.seed(args.seed)

    # ── Load recipes ────────────────────────────────────────────────────
    if args.recipes:
        recipes = load_recipes_from_jsonl(args.recipes)
        print(f"Loaded {len(recipes)} recipes from {args.recipes}")
    elif args.sitemap:
        recipes = scrape_from_sitemap(args.sitemap, args.max_recipes)
    else:
        print("ERROR: Provide either --sitemap or --recipes")
        sys.exit(1)

    if not recipes:
        print("No recipes found. Check your input.")
        sys.exit(1)

    # ── Render and extract features ──────────────────────────────────────
    csv_rows = []
    total_lines = 0

    for recipe in recipes:
        labelled_lines = render_recipe(recipe)
        num_lines = len(labelled_lines)

        for line_idx, (text, label) in enumerate(labelled_lines):
            features = compute_features(text, line_idx, num_lines)
            if len(features) != len(FEATURE_NAMES):
                print(f"ERROR: Feature count mismatch for '{text[:40]}'")
                continue

            row = {
                "label": LABEL_NAMES.index(label) if label in LABEL_NAMES else -1,
                "label_name": label,
                "text": text,
                "recipe_name": recipe.get("name", "?"),
                "recipe_url": recipe.get("_source_url", ""),
            }
            for fname, fval in zip(FEATURE_NAMES, features):
                row[fname] = round(fval, 6)

            csv_rows.append(row)
            total_lines += 1

    # ── Write CSV ────────────────────────────────────────────────────────
    import os
    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)

    fieldnames = ["label", "label_name", "text", "recipe_name", "recipe_url"] + FEATURE_NAMES
    with open(args.output, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(csv_rows)

    # ── Summary ──────────────────────────────────────────────────────────
    label_counts = {}
    for row in csv_rows:
        lbl = row["label_name"]
        label_counts[lbl] = label_counts.get(lbl, 0) + 1

    print(f"\nGenerated {total_lines} labelled lines from {len(recipes)} recipes")
    print(f"Output: {args.output}")
    print("\nLabel distribution:")
    for name in LABEL_NAMES:
        count = label_counts.get(name, 0)
        pct = count / total_lines * 100 if total_lines else 0
        print(f"  {name:25s} {count:6d} ({pct:5.1f}%)")


if __name__ == "__main__":
    main()