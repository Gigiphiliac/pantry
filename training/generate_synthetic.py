#!/usr/bin/env python3
"""
generate_synthetic.py — Generate labelled training data from recipe websites.

Pipeline:
  1. Fetch sitemap(s) to discover recipe URLs
  2. Fetch each recipe page and extract schema.org JSON-LD
  3. Render each recipe as a clean card image via Pillow
  4. Run Tesseract OCR on the image to get real bounding boxes + blocks
  5. Match OCR lines back to ground-truth labels using Y-position overlap
  6. Compute all 20 features from the *real* OCR spatial data
  7. Export labelled CSV for training

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
import os
import random
import sys
import time
import urllib.request
import xml.etree.ElementTree as ET
from collections import Counter
from datetime import datetime
from typing import Any
from urllib.parse import urlparse

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    Image = None  # type: ignore

import pytesseract

# ── Constants ──────────────────────────────────────────────────────────────

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

# Render / OCR constants
PAGE_W = 800       # rendered page width (px)
MARGIN_X = 32      # left/right margin
MARGIN_Y = 24      # top margin
LINE_GAP = 6       # gap between lines (px)
TITLE_SIZE = 32    # title font size
BODY_SIZE = 18     # body text font size (ingredients, steps)
HEADING_SIZE = 22  # section heading font size

# User-agent for requests
UA = "PantryTraining/1.0 (recipe classifier data collection)"

# ── Font setup ─────────────────────────────────────────────────────────────

def _load_font(size: int):
    """Load a system TrueType font at the requested size."""
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    # Ultimate fallback — Pillow's built-in bitmap font
    return ImageFont.load_default()

_TITLE_FONT = _load_font(TITLE_SIZE)
_BODY_FONT = _load_font(BODY_SIZE)
_HEADING_FONT = _load_font(HEADING_SIZE)

# ── Noise line templates (labelled "ignore") ──────────────────────────────

# Recipe-blog noise that commonly appears in OCR output.  A random subset is
# injected per recipe so the model learns the `ignore` class.
NOISE_TEMPLATES: list[str] = [
    # Prep / cook / total time
    "Prep Time: 5 mins",
    "Prep Time 10 minutes",
    "Cook Time: 15 mins",
    "Cook Time 30 minutes",
    "Total Time: 20 mins",
    "Total Time: 45 minutes",
    # Ratings
    "4.90 from 219 votes",
    "5.0 from 100 ratings",
    "4.5 from 50 votes",
    "Rated 4.8 out of 5",
    # Author / source
    "Author: Nagi",
    "Recipe by John",
    "By Mary Smith",
    "Source: allrecipes.com",
    # Video / media
    "Recipe video above",
    "Watch the video",
    "Tap to view video",
    # Social / navigation
    "Print Recipe",
    "Share this recipe",
    "Pin Recipe",
    "Jump to Recipe",
    "Skip to Recipe",
    "Save Recipe",
    "Email Recipe",
    # Nutrition buzzers
    "Calories: 250 per serving",
    "Calories: 108cal",
    "Nutrition per serve",
    "Nutrition Facts",
    # Serving-size notes
    "Servings: 4",
    "Serves 4-6",
    "Makes 12 portions",
    # Miscellaneous noise
    "This recipe is reader favourite!",
    "Why this recipe works",
    "Frequently Asked Questions",
    "Pro tip: don't overmix",
    "Storage instructions",
]

# Up to this many noise lines are injected per recipe (random count)
MAX_NOISE_LINES = 6

# ── Helpers ────────────────────────────────────────────────────────────────


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
            path = urlparse(url).path
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


# ── Recipe rendering → image ───────────────────────────────────────────────


def render_label(
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
    if line_idx in known_labels:
        return known_labels[line_idx]
    return "ignore"


class RenderedRecipe:
    """One recipe rendered to an image with ground-truth metadata."""

    def __init__(self, image: Image.Image, lines: list[dict[str, Any]]):
        self.image = image
        # lines = [{"text": ..., "label": ..., "y_top": int, "y_bottom": int}, ...]
        self.lines = lines

    @property
    def width(self):
        return self.image.width

    @property
    def height(self):
        return self.image.height


def render_recipe_image(
    recipe: dict,
    *,
    inject_noise: bool = True,
    rng: random.Random | None = None,
) -> RenderedRecipe | None:
    """Render a recipe as a clean card image.

    Optionally injects non-recipe noise lines labelled "ignore" so the model
    learns to filter them out.

    Returns a RenderedRecipe with the image and per-line position metadata,
    or None if the recipe has no renderable content.
    """
    labelled = render_recipe(recipe)
    if not labelled:
        return None

    _rng = rng or random

    # ── Optionally inject noise lines ──────────────────────────────────
    if inject_noise and NOISE_TEMPLATES:
        num_noise = _rng.randint(1, MAX_NOISE_LINES)
        chosen = _rng.sample(NOISE_TEMPLATES, k=min(num_noise, len(NOISE_TEMPLATES)))
        for nl in chosen:
            # Pick a random insertion index: before first line, between any
            # two lines, or after last line.
            pos = _rng.randint(0, len(labelled))
            labelled.insert(pos, (nl, "ignore"))

    # Estimate total height — render twice: first to measure, second to draw
    y = MARGIN_Y
    measured: list[dict[str, Any]] = []
    for text, label in labelled:
        font = _TITLE_FONT if label == "title" else (
            _HEADING_FONT if label == "section_header" else _BODY_FONT
        )
        # Use getbbox for accurate bounding
        bbox = font.getbbox(text)
        line_h = bbox[3] - bbox[1] + LINE_GAP
        measured.append({"text": text, "label": label, "y_top": y, "font": font, "line_h": line_h})
        y += line_h

    page_h = y + MARGIN_Y

    # Create image
    img = Image.new("RGB", (PAGE_W, max(page_h, 100)), "white")
    draw = ImageDraw.Draw(img)

    lines_out: list[dict[str, Any]] = []
    for m in measured:
        draw.text((MARGIN_X, m["y_top"]), m["text"], fill="black", font=m["font"])
        bbox = m["font"].getbbox(m["text"])
        text_w = bbox[2] - bbox[0]
        lines_out.append({
            "text": m["text"],
            "label": m["label"],
            "y_top": m["y_top"],
            "y_bottom": m["y_top"] + m["line_h"],
            "x_left": MARGIN_X,
            "x_right": MARGIN_X + text_w,
        })

    return RenderedRecipe(image=img, lines=lines_out)


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

    # Instructions (method steps)
    instructions = recipe.get("recipeInstructions", [])
    steps = parse_instructions(instructions)
    if steps:
        lines.append(("Method:", "section_header"))
        for step in steps:
            text = step.get("text", "").strip()
            if text:
                lines.append((text, "method_step"))

    return lines


# ── OCR and feature extraction ──────────────────────────────────────────────


def ocr_recipe_image(rendered: RenderedRecipe) -> list[dict[str, Any]]:
    """Run Tesseract OCR on the rendered image and return per-line data.

    Returns list of dicts with:
      text, left, top, width, height, block_num, line_num, conf
    """
    data = pytesseract.image_to_data(
        rendered.image,
        output_type=pytesseract.Output.DICT,
    )

    # Group word-level data into lines by (block_num, par_num)
    # NOTE: Tesseract's line_num resets in each paragraph, so we key
    # on paragraph number instead.
    lines_map: dict[tuple[int, int], dict[str, Any]] = {}
    for i in range(len(data["text"])):
        text = (data["text"][i] or "").strip()
        if not text:
            continue
        key = (data["block_num"][i], data["par_num"][i])
        if key not in lines_map:
            lines_map[key] = {
                "texts": [],
                "left": data["left"][i],
                "top": data["top"][i],
                "right": data["left"][i] + data["width"][i],
                "bottom": data["top"][i] + data["height"][i],
                "block_num": data["block_num"][i],
                "line_num": data["line_num"][i],
                "confs": [],
            }
        entry = lines_map[key]
        entry["texts"].append(text)
        entry["left"] = min(entry["left"], data["left"][i])
        entry["top"] = min(entry["top"], data["top"][i])
        entry["right"] = max(entry["right"], data["left"][i] + data["width"][i])
        entry["bottom"] = max(entry["bottom"], data["top"][i] + data["height"][i])
        entry["confs"].append(data.get("conf", [0])[i] if "conf" in data else 0)

    # Sort lines: top-to-bottom, then left-to-right (for multiple columns)
    sorted_keys = sorted(lines_map.keys(), key=lambda k: (
        lines_map[k]["top"],
        lines_map[k]["left"],
    ))

    results = []
    for key in sorted_keys:
        entry = lines_map[key]
        avg_conf = sum(entry["confs"]) / max(len(entry["confs"]), 1) / 100.0
        results.append({
            "text": " ".join(entry["texts"]),
            "left": entry["left"],
            "top": entry["top"],
            "width": entry["right"] - entry["left"],
            "height": entry["bottom"] - entry["top"],
            "block_num": entry["block_num"],
            "conf": avg_conf,
        })

    return results


def match_ocr_to_ground_truth(
    ocr_lines: list[dict[str, Any]],
    rendered: RenderedRecipe,
) -> list[dict[str, Any]]:
    """Match OCR output lines to ground-truth labels by Y-position overlap.

    Each OCR line receives the label of the rendered line whose Y-range
    most overlaps with it.  Returns the same list as ocr_lines but with
    'label' and 'label_idx' added.
    """
    if not ocr_lines or not rendered.lines:
        return []

    labelled: list[dict[str, Any]] = []

    def overlap(a_start, a_end, b_start, b_end):
        return max(0, min(a_end, b_end) - max(a_start, b_start))

    for ocr_line in ocr_lines:
        ocr_cy = ocr_line["top"] + ocr_line["height"] / 2
        best_overlap = 0
        best_label = "ignore"
        best_label_idx = 8  # ignore index

        for gt_idx, gt in enumerate(rendered.lines):
            o = overlap(
                ocr_line["top"], ocr_line["top"] + ocr_line["height"],
                gt["y_top"], gt["y_bottom"],
            )
            if o > best_overlap and (
                # Also check that the Y-centre is within the GT line
                gt["y_top"] <= ocr_cy <= gt["y_bottom"]
            ):
                best_overlap = o
                best_label = gt["label"]
                best_label_idx = LABEL_NAMES.index(best_label) if best_label in LABEL_NAMES else 8

        labelled.append({**ocr_line, "label": best_label, "label_idx": best_label_idx})

    return labelled


def compute_features_from_ocr(
    ocr_line: dict[str, Any],
    image_size: tuple[int, int],
    all_lines: list[dict[str, Any]],
) -> list[float]:
    """Compute the 20 normalised features for a single OCR line.

    This replaces the old simulated compute_features() — all spatial values
    come from the real Tesseract bounding boxes.
    """
    img_w, img_h = image_size
    h_avg = sum(l["height"] for l in all_lines) / max(len(all_lines), 1)

    text = ocr_line["text"]
    trimmed = text.strip()
    words = trimmed.split() if trimmed else []

    # ── Spatial features (normalised to image) ────────────────────────
    relative_top = ocr_line["top"] / img_h
    relative_left = ocr_line["left"] / img_w
    relative_width = ocr_line["width"] / img_w
    relative_height = ocr_line["height"] / img_h
    relative_font_size = ocr_line["height"] / h_avg if h_avg > 0 else 1.0

    # Block membership from Tesseract
    block_idx = float(ocr_line.get("block_num", 1))
    lines_in_block = sum(
        1 for l in all_lines if l.get("block_num") == ocr_line.get("block_num")
    )
    same_block_lines = sorted(
        [l for l in all_lines if l.get("block_num") == ocr_line.get("block_num")],
        key=lambda l: l["top"],
    )
    try:
        line_index_in_block = float(
            next(i for i, l in enumerate(same_block_lines) if l is ocr_line)
        )
    except StopIteration:
        line_index_in_block = 0.0

    # ── Text-derived features ─────────────────────────────────────────
    starts_with_digit = 1.0 if trimmed and trimmed[0].isdigit() else 0.0
    starts_with_fraction = 1.0 if trimmed and trimmed[0] in "¼½¾⅓⅔⅛⅜⅝⅞" else 0.0
    ends_with_colon = 1.0 if trimmed.endswith(":") else 0.0
    word_count = float(len(words))
    char_count = float(len(trimmed))
    starts_with_verb = 1.0 if words and words[0].lower().strip("(") in IMPERATIVE_VERBS else 0.0
    contains_number = 1.0 if any(c.isdigit() for c in trimmed) else 0.0
    ends_with_punctuation = 1.0 if trimmed and trimmed[-1] in ".!?" else 0.0
    has_mixed_case = 1.0 if (any(c.isupper() for c in trimmed) and any(c.islower() for c in trimmed)) else 0.0
    confidence = ocr_line.get("conf", 0.95)

    is_first_in_block = 1.0 if line_index_in_block == 0 else 0.0
    is_last_in_block = 1.0 if line_index_in_block == max(lines_in_block - 1, 0) else 0.0

    return [
        round(relative_top, 6),
        round(relative_left, 6),
        round(relative_width, 6),
        round(relative_height, 6),
        round(relative_font_size, 6),
        block_idx,
        float(lines_in_block),
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
        round(confidence, 4),
        is_first_in_block,
        is_last_in_block,
    ]


# ── Data augmentation (optional) ──────────────────────────────────────────

def augment_image(image: Image.Image) -> Image.Image:
    """Apply mild augmentation to make the model robust to OCR noise.

    Randomly rotates, shifts contrast, or adds blur.  Each augmentation
    is applied independently with 30 % probability.
    """
    import random

    # Rotate slightly
    if random.random() < 0.3:
        angle = random.uniform(-1.0, 1.0)
        image = image.rotate(angle, expand=True, fillcolor="white")

    # Adjust contrast
    if random.random() < 0.3:
        from PIL import ImageEnhance
        factor = random.uniform(0.85, 1.15)
        enhancer = ImageEnhance.Contrast(image)
        image = enhancer.enhance(factor)

    # Gaussian blur (simulates slight camera blur)
    if random.random() < 0.15:
        from PIL import ImageFilter
        radius = random.uniform(0.3, 1.0)
        image = image.filter(ImageFilter.GaussianBlur(radius=radius))

    return image


# ── Main ─────────────────────────────────────────────────────────────────


def scrape_from_sitemap(sitemap_url: str, max_recipes: int) -> list[dict]:
    """Scrape recipes from a sitemap. Respectful delays."""
    print(f"Fetching sitemap: {sitemap_url}")
    recipe_urls = extract_recipe_urls_from_sitemap(sitemap_url)
    print(f"Found {len(recipe_urls)} URLs in sitemap")
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
            time.sleep(0.3)
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
        "--augment",
        action="store_true",
        default=True,
        help="Apply mild image augmentation (default: on)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for reproducibility (default: 42)",
    )
    args = parser.parse_args()

    random.seed(args.seed)

    if Image is None:
        print("ERROR: Pillow is required. Install with: pip install Pillow")
        sys.exit(1)

    # ── Load recipes ──────────────────────────────────────────────────
    if args.recipes:
        recipes = load_recipes_from_jsonl(args.recipes)
        print(f"Loaded {len(recipes)} recipes from {args.recipes}")
    elif args.sitemap:
        recipes = scrape_from_sitemap(args.sitemap, args.max_recipes)
    else:
        # Fall back to a small built-in test set for quick verification
        recipes = _builtin_test_recipes()
        print(f"Using {len(recipes)} built-in test recipes")

    if not recipes:
        print("No recipes found. Check your input.")
        sys.exit(1)

    # ── Render, OCR, extract features ─────────────────────────────────
    csv_rows = []
    total_lines = 0
    skipped = 0
    ocr_failures = 0

    for recipe_idx, recipe in enumerate(recipes):
        recipe_name = recipe.get("name", "?")
        print(f"\n[{recipe_idx + 1}/{len(recipes)}] {recipe_name}")

        # Render (uses the seeded `random` module for reproducible noise)
        rendered = render_recipe_image(recipe, inject_noise=args.augment, rng=random)
        if rendered is None:
            print("  → No renderable content")
            skipped += 1
            continue

        # Optional augmentation
        img = rendered.image
        if args.augment:
            img = augment_image(img)

        # OCR
        ocr_lines = ocr_recipe_image(RenderedRecipe(image=img, lines=rendered.lines))
        if not ocr_lines:
            print("  → OCR returned no lines")
            ocr_failures += 1
            continue

        # Match OCR lines to ground-truth labels
        # We need to re-create RenderedRecipe with the augmented image's lines
        # Actually, the image augmentation doesn't change the rendered positions
        labelled_ocr = match_ocr_to_ground_truth(
            ocr_lines,
            rendered,  # original rendered positions still apply
        )

        # Compute features for each labelled OCR line
        img_size = (img.width, img.height)
        for line_idx, ocr_line in enumerate(labelled_ocr):
            features = compute_features_from_ocr(
                ocr_line, img_size, labelled_ocr,
            )
            if len(features) != len(FEATURE_NAMES):
                print(f"  → Feature count mismatch for '{ocr_line['text'][:40]}'")
                continue

            row = {
                "label": ocr_line["label_idx"],
                "label_name": ocr_line["label"],
                "text": ocr_line["text"],
                "recipe_name": recipe_name,
                "recipe_url": recipe.get("_source_url", ""),
            }
            for fname, fval in zip(FEATURE_NAMES, features):
                row[fname] = fval

            csv_rows.append(row)
            total_lines += 1

    # ── Write CSV ──────────────────────────────────────────────────────
    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)

    fieldnames = ["label", "label_name", "text", "recipe_name", "recipe_url"] + FEATURE_NAMES
    with open(args.output, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(csv_rows)

    # ── Summary ────────────────────────────────────────────────────────
    label_counts: dict[str, int] = {}
    for row in csv_rows:
        lbl = row["label_name"]
        label_counts[lbl] = label_counts.get(lbl, 0) + 1

    print(f"\n{'=' * 60}")
    print(f"Generated {total_lines} labelled lines from {len(recipes)} recipes")
    print(f"Skipped: {skipped}   OCR failures: {ocr_failures}")
    print(f"Output: {args.output}")
    print(f"\nLabel distribution:")
    for name in LABEL_NAMES:
        count = label_counts.get(name, 0)
        pct = count / total_lines * 100 if total_lines else 0
        print(f"  {name:25s} {count:6d} ({pct:5.1f}%)")

    if total_lines == 0:
        print("\n⚠ No training data generated. Try running with --sitemap or --recipes.")


def _builtin_test_recipes() -> list[dict]:
    """Return a small set of built-in test recipes for quick verification."""
    return [
        {
            "name": "Simple Pancakes",
            "recipeYield": ["4 servings"],
            "recipeIngredient": [
                "1 cup plain flour",
                "2 tbsp sugar",
                "2 tsp baking powder",
                "Pinch of salt",
                "1 cup milk",
                "1 egg",
                "2 tbsp butter",
            ],
            "recipeInstructions": [
                {"@type": "HowToStep", "text": "Mix flour, sugar, baking powder and salt in a bowl."},
                {"@type": "HowToStep", "text": "Add milk and egg, whisk until smooth."},
                {"@type": "HowToStep", "text": "Heat a pan over medium heat and melt some butter."},
                {"@type": "HowToStep", "text": "Pour batter and cook until bubbles form on surface."},
                {"@type": "HowToStep", "text": "Flip and cook until golden. Serve with toppings."},
            ],
        },
        {
            "name": "Garlic Pasta",
            "recipeYield": ["2"],
            "recipeIngredient": [
                "200g spaghetti",
                "4 cloves garlic, minced",
                "2 tbsp olive oil",
                "1/4 cup parmesan",
                "Salt to taste",
            ],
            "recipeInstructions": [
                {"@type": "HowToStep", "text": "Boil pasta in salted water until al dente."},
                {"@type": "HowToStep", "text": "Sauté garlic in olive oil until fragrant."},
                {"@type": "HowToStep", "text": "Toss pasta with garlic oil and parmesan. Serve immediately."},
            ],
        },
        {
            "name": "Classic Margherita Pizza",
            "recipeYield": ["1 large pizza"],
            "recipeIngredient": [
                "2 1/2 cups bread flour",
                "1 tsp instant yeast",
                "1 tsp salt",
                "1 cup warm water",
                "1/2 cup tomato sauce",
                "200g fresh mozzarella",
                "Fresh basil leaves",
            ],
            "recipeInstructions": [
                {"@type": "HowToStep", "text": "Mix flour, yeast and salt. Add warm water and knead 10 minutes."},
                {"@type": "HowToStep", "text": "Let dough rise for 1 hour in a warm spot."},
                {"@type": "HowToStep", "text": "Preheat oven to 250°C with a pizza stone inside."},
                {"@type": "HowToStep", "text": "Shape dough into a 12-inch circle. Spread sauce, tear mozzarella on top."},
                {"@type": "HowToStep", "text": "Bake 8-10 minutes until crust is golden. Top with fresh basil."},
            ],
        },
    ]


if __name__ == "__main__":
    main()