#!/usr/bin/env python3
"""
export_training_db.py — Export the app's SQLite training database into
labelled feature CSVs consumable by train_model.py.

The app stores raw OCR data + user corrections in ocr_training_data.
This script:
  1. Connects to the app's SQLite database
  2. For each entry with source_type='ocr': re-computes all 20 features
     from the stored spatial data and generates per-line ground-truth
     labels by text-matching against the corrected RecipeDraft
  3. For each entry with source_type='url': extracts text lines and
     uses the corrected structure as pseudo-ground-truth (no spatial
     features — useful for heuristic validation, not classifier training)
  4. Exports labelled feature CSV

Usage:
  python export_training_db.py \
      --db /path/to/pantry.sqlite \
      --output ./data/training_from_db.csv

Data directory:
  The app's SQLite database is typically at:
    ~/Library/Application Support/pantry/pantry.sqlite    (macOS)
    ~/.local/share/pantry/pantry.sqlite                   (Linux)
  Or wherever the app stores its data. Use `flutter sqllite` to find it.
"""

import argparse
import csv
import json
import math
import os
import re
import sqlite3
import sys
from collections import Counter

# ── Feature config (MUST match FeatureExtractor.dart) ─────────────────────────

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

LABEL_NAMES = [
    "title",
    "servings",
    "description",
    "section_header",
    "ingredient",
    "method_step",
    "method_continuation",
    "nutrition",
    "notes",
    "ignore",
]

IMPERATIVE_VERBS = {
    "add", "bake", "beat", "blend", "boil", "broil", "brown", "chill",
    "chop", "combine", "cook", "cover", "cut", "defrost", "dice", "drain",
    "drizzle", "fold", "fry", "garnish", "grate", "grill", "heat", "knead",
    "layer", "marinate", "mash", "melt", "microwave", "mix", "place", "pour",
    "preheat", "prepare", "press", "refrigerate", "remove", "rinse", "roast",
    "rest", "roll", "sauté", "sear", "season", "serve", "simmer", "slice",
    "soak", "spread", "steam", "stir", "toast", "toss", "trim", "whisk",
}

SERVINGS_PATTERN = re.compile(r"^(serv(es|ings?)|makes|yields?)\b", re.IGNORECASE)
SECTION_MARKERS = {"ingredients", "ingredient", "method", "directions",
                   "instructions", "preparation", "procedure", "cooking"}


def compute_features(line: dict, img_w: float, img_h: float,
                     avg_line_h: float, lines_in_block: int) -> list[float]:
    """Re-compute the 20-element feature vector for one OCR line.

    Mirrors FeatureExtractor._lineFeatures() in Dart.
    """
    text = line.get("text", "")
    left = line.get("x", 0)
    top = line.get("y", 0)
    w = line.get("w", 0)
    h = line.get("h", 0)
    block_idx = line.get("blockIndex", 0)
    line_idx = line.get("lineIndexInBlock", 0)
    conf = line.get("confidence", 1.0)

    trimmed = text.strip()

    # Spatial features
    relative_top = top / img_h if img_h > 0 else 0
    relative_left = left / img_w if img_w > 0 else 0
    relative_width = w / img_w if img_w > 0 else 0
    relative_height = h / img_h if img_h > 0 else 0
    relative_font_size = h / avg_line_h if avg_line_h > 0 else 1.0

    # Text heuristics
    starts_with_digit = 1.0 if trimmed and trimmed[0].isdigit() else 0.0
    starts_with_fraction = 1.0 if trimmed and trimmed[0] in "¼½¾⅓⅔⅛⅜⅝⅞" else 0.0
    ends_with_colon = 1.0 if trimmed.endswith(":") else 0.0

    words = trimmed.split()
    word_count = float(len(words))
    char_count = float(len(trimmed))

    starts_with_verb = 0.0
    if trimmed and words:
        first_word = words[0].lower().strip("(")
        if first_word in IMPERATIVE_VERBS:
            starts_with_verb = 1.0

    contains_number = 1.0 if any(c.isdigit() for c in trimmed) else 0.0
    ends_with_punctuation = 1.0 if trimmed and trimmed[-1] in ".!?" else 0.0
    has_mixed_case = 1.0 if (any(c.isupper() for c in trimmed)
                              and any(c.islower() for c in trimmed)) else 0.0

    is_first_in_block = 1.0 if line_idx == 0 else 0.0
    is_last_in_block = 1.0 if line_idx >= lines_in_block - 1 else 0.0

    return [
        relative_top, relative_left, relative_width, relative_height,
        relative_font_size, float(block_idx), float(lines_in_block),
        float(line_idx), starts_with_digit, starts_with_fraction,
        ends_with_colon, word_count, char_count, starts_with_verb,
        contains_number, ends_with_punctuation, has_mixed_case,
        float(conf), is_first_in_block, is_last_in_block,
    ]


def guess_label_for_line(text: str, corrected: dict,
                         filled_ingredients: set) -> str:
    """Best-effort label for a raw OCR line by matching against corrected data.

    Returns one of LABEL_NAMES.
    """
    t = text.strip()
    lower = t.lower()

    # Noise
    if not t or t.lower() in {"", " "}:
        return "ignore"

    # Section headers (exact markers)
    clean = lower.rstrip(":. ").strip()
    if clean in SECTION_MARKERS:
        return "section_header"

    # Title
    title = (corrected.get("name") or "").strip()
    if title and (t == title or t.startswith(title) or title.startswith(t)):
        return "title"

    # Description
    desc = (corrected.get("description") or "").strip()
    if desc and len(desc) > 10 and desc in text:
        return "description"

    # Servings
    if SERVINGS_PATTERN.match(t):
        return "servings"

    # Ingredients (check both sectioned and unsectioned)
    for ing in corrected.get("ingredients", []):
        ing_name = (ing.get("name") or "").strip().lower()
        if ing_name and ing_name in lower:
            filled_ingredients.add(ing_name)
            return "ingredient"

    for section in corrected.get("sections", []):
        for ing in section.get("ingredients", []):
            ing_name = (ing.get("name") or "").strip().lower()
            if ing_name and ing_name in lower:
                filled_ingredients.add(ing_name)
                return "ingredient"

    # Steps (method)
    for step in corrected.get("steps", []):
        if isinstance(step, str):
            step_text = step.strip().lower()
            if step_text and len(step_text) > 5 and step_text in lower:
                return "method_step"

    # Nutrition
    for nut in corrected.get("nutrition", []):
        label = (nut.get("label") or "").strip().lower()
        if label and label in lower:
            return "nutrition"

    # Numbered step (even if not matched above)
    if re.match(r"^\d+[.)]\s", t):
        return "method_step"

    # Imperative verb start
    first_word = lower.split()[0] if lower.split() else ""
    if first_word in IMPERATIVE_VERBS:
        return "method_step"

    # Long narrative that didn't match anything → likely noise or notes
    if len(words := t.split()) > 10:
        return "ignore"

    # Default
    return "ingredient"


def extract_features_from_ocr_entry(row: dict) -> list[dict]:
    """Process one ocr_training_data row and return labelled feature rows."""
    try:
        raw = json.loads(row["rawJson"])
        corrected = json.loads(row["correctedJson"])
    except (json.JSONDecodeError, KeyError) as e:
        print(f"  [skip] row {row['id']}: JSON parse error: {e}", file=sys.stderr)
        return []

    lines_data = raw.get("lines", [])
    if not lines_data:
        return []

    img_size = raw.get("imageSize", {})
    img_w = float(img_size.get("width", 1))
    img_h = float(img_size.get("height", 1))
    if img_w <= 0 or img_h <= 0:
        img_w, img_h = 1, 1

    # Average line height for relative font size
    heights = [l.get("h", 0) for l in lines_data]
    avg_line_h = sum(heights) / max(len(heights), 1)

    # Group lines by block to compute lines_in_block
    block_counts: dict[int, int] = {}
    for l in lines_data:
        bid = l.get("blockIndex", 0)
        block_counts[bid] = block_counts.get(bid, 0) + 1

    # Set line_index_in_block if missing (common in older entries)
    block_line_idx: dict[int, int] = {}
    for l in lines_data:
        bid = l.get("blockIndex", 0)
        lidx = block_line_idx.get(bid, 0)
        if "lineIndexInBlock" not in l or l["lineIndexInBlock"] is None:
            l["lineIndexInBlock"] = lidx
        block_line_idx[bid] = lidx + 1

    # Pre-collect ingredient names for matching
    filled_ingredients: set[str] = set()

    features_rows = []
    for line in lines_data:
        text = line.get("text", "").strip()
        if not text:
            continue

        bid = line.get("blockIndex", 0)
        lib = block_counts.get(bid, 1)
        feat = compute_features(line, img_w, img_h, avg_line_h, lib)
        label = guess_label_for_line(text, corrected, filled_ingredients)
        label_idx = LABEL_NAMES.index(label) if label in LABEL_NAMES else 9

        row_data = {
            "text": text,
            "label": label_idx,
        }
        for fn, fv in zip(FEATURE_NAMES, feat):
            row_data[fn] = fv

        features_rows.append(row_data)

    return features_rows


def extract_from_url_entry(row: dict) -> list[dict]:
    """Process a URL-sourced entry (no spatial data → can't compute features).

    Returns a minimal row with raw text for heuristic evaluation only.
    These entries can't be used for classifier training (no spatial features)
    but are useful for testing the heuristic parser.
    """
    try:
        raw = json.loads(row["rawJson"])
        corrected = json.loads(row["correctedJson"])
    except (json.JSONDecodeError, KeyError):
        return []

    text_lines = raw.get("lines", [])
    if isinstance(text_lines, list):
        texts = [l if isinstance(l, str) else l.get("text", "") for l in text_lines]
    else:
        return []

    filled_ingredients: set[str] = set()
    rows = []
    for text in texts:
        t = text.strip()
        if not t:
            continue
        feat = [0.0] * len(FEATURE_NAMES)
        label = guess_label_for_line(t, corrected, filled_ingredients)
        label_idx = LABEL_NAMES.index(label) if label in LABEL_NAMES else 9
        row_data = {"text": t, "label": label_idx}
        for fn, fv in zip(FEATURE_NAMES, feat):
            row_data[fn] = fv
        rows.append(row_data)

    return rows


def export(db_path: str, output_path: str, exclude_url: bool = False):
    """Read training DB and write labelled feature CSV."""
    print(f"Connecting to: {db_path}")
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row

    # Check the table exists
    tables = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table'"
    ).fetchall()
    table_names = {t["name"] for t in tables}

    if "ocr_training_data" not in table_names:
        print("ERROR: 'ocr_training_data' table not found in this database.")
        print("Available tables:", sorted(table_names))
        conn.close()
        sys.exit(1)

    # Get column names (source_type may not exist in older DBs)
    cols = {c["name"] for c in conn.execute(
        "PRAGMA table_info(ocr_training_data)"
    ).fetchall()}
    has_source_type = "source_type" in cols

    # Count entries
    count = conn.execute("SELECT COUNT(*) FROM ocr_training_data").fetchone()[0]
    print(f"Found {count} training entries")

    # Fetch all rows
    rows = conn.execute("SELECT * FROM ocr_training_data").fetchall()
    conn.close()

    all_feature_rows = []
    url_count = 0
    ocr_count = 0
    skipped = 0

    for r in rows:
        rid = r["id"]
        source_type = r["source_type"] if has_source_type else "ocr"

        if source_type == "url":
            if exclude_url:
                skipped += 1
                continue
            url_count += 1
            extracted = extract_from_url_entry(r)
            if extracted:
                for er in extracted:
                    er["source"] = "url"
                all_feature_rows.extend(extracted)
        else:
            ocr_count += 1
            extracted = extract_features_from_ocr_entry(r)
            if extracted:
                for er in extracted:
                    er["source"] = "ocr"
                all_feature_rows.extend(extracted)

    print(f"\nProcessed: {ocr_count} OCR + {url_count} URL = {ocr_count + url_count} entries")
    if skipped:
        print(f"  (skipped {skipped} URL entries due to --exclude-url)")
    print(f"Total labelled lines: {len(all_feature_rows)}")

    if not all_feature_rows:
        print("ERROR: no feature rows generated. Nothing to export.")
        sys.exit(1)

    # Summarise label distribution
    label_counts = Counter(r["label"] for r in all_feature_rows)
    print(f"\nLabel distribution:")
    for lidx in sorted(label_counts):
        name = LABEL_NAMES[lidx]
        print(f"  {name:25s}: {label_counts[lidx]}")

    # Write CSV
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    fieldnames = ["source", "text", "label"] + list(FEATURE_NAMES)
    with open(output_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_feature_rows)

    print(f"\nExported to: {output_path}")
    print(f"File size: {os.path.getsize(output_path) / 1024:.0f} KB")


def main():
    parser = argparse.ArgumentParser(
        description="Export training DB to labelled feature CSV."
    )
    parser.add_argument(
        "--db",
        default=os.path.expanduser(
            "~/Library/Application Support/pantry/pantry.sqlite"
        ),
        help="Path to app SQLite database (default: macOS path)",
    )
    parser.add_argument(
        "--output", default="./data/training_from_db.csv",
        help="Output CSV path",
    )
    parser.add_argument(
        "--exclude-url", action="store_true",
        help="Skip URL-sourced entries (no spatial features)",
    )
    args = parser.parse_args()

    export(args.db, args.output, exclude_url=args.exclude_url)


if __name__ == "__main__":
    main()