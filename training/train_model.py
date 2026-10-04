#!/usr/bin/env python3
"""
train_model.py — Train LightGBM classifier on labelled OCR line data.

Pipeline:
  1. Load labelled CSV (from generate_synthetic.py)
  2. Train LightGBM with class-weighting
  3. Evaluate on held-out test set
  4. Export to JSON (LightGBM dump — evaluated in pure Dart)
     and ONNX (for future runtime use)

Usage:
  python train_model.py \
      --data ./data/labelled_lines.csv \
      --output ./output
"""

import argparse
import csv
import json
import os
import sys
from collections import Counter

import numpy as np

# ── Feature config (MUST match FeatureExtractor & generate_synthetic.py) ─────

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

NUM_CLASSES = len(LABEL_NAMES)


def load_data(path: str) -> tuple[np.ndarray, np.ndarray, list[str], list[int]]:
    """Load labelled CSV and return (X, y, texts, labels_seen)."""
    X_list = []
    y_list = []
    texts = []
    labels_seen = set()

    with open(path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            label = int(row["label"])
            labels_seen.add(label)
            features = [float(row[fn]) for fn in FEATURE_NAMES]
            X_list.append(features)
            y_list.append(label)
            texts.append(row.get("text", ""))

    X = np.array(X_list, dtype=np.float32)
    y = np.array(y_list, dtype=np.int32)
    return X, y, texts, sorted(labels_seen)


def train_lightgbm(X_train, y_train, X_val, y_val):
    """Train a LightGBM multiclass classifier with class weighting."""
    import lightgbm as lgb

    # Compute class weights inversely proportional to frequency
    counter = Counter(y_train)
    total = len(y_train)
    weights = {cls: total / (len(counter) * count) for cls, count in counter.items()}
    sample_weight = np.array([weights[y] for y in y_train], dtype=np.float32)

    print("\nClass weights:")
    for cls, w in sorted(weights.items()):
        name = LABEL_NAMES[cls] if cls < len(LABEL_NAMES) else f"class_{cls}"
        print(f"  {name:25s}: {w:.2f} (count: {counter[cls]})")

    params = {
        "objective": "multiclass",
        "num_class": NUM_CLASSES,
        "metric": ["multi_logloss", "multi_error"],
        "boosting_type": "gbdt",
        "num_leaves": 15,
        "max_depth": 6,
        "learning_rate": 0.08,
        "feature_fraction": 0.7,
        "bagging_fraction": 0.7,
        "bagging_freq": 5,
        "verbose": -1,
        "num_threads": 4,
        "min_data_in_leaf": 5,
        "lambda_l1": 0.1,
        "lambda_l2": 0.1,
        "min_gain_to_split": 0.0,
    }

    train_data = lgb.Dataset(
        X_train, y_train,
        weight=sample_weight,
    )
    val_data = lgb.Dataset(
        X_val, y_val,
        reference=train_data,
    )

    print("\nTraining LightGBM...")
    model = lgb.train(
        params,
        train_data,
        valid_sets=[train_data, val_data],
        num_boost_round=500,
        callbacks=[
            lgb.early_stopping(stopping_rounds=30, verbose=True),
            lgb.log_evaluation(50),
        ],
    )

    return model


def evaluate(model, X_val, y_val, texts_val):
    """Print classification metrics."""
    y_pred = model.predict(X_val)
    y_pred_class = np.argmax(y_pred, axis=1)

    correct = (y_pred_class == y_val).sum()
    total = len(y_val)
    accuracy = correct / total * 100
    print(f"\n── Validation Results ──────────────────────────────────────")
    print(f"Accuracy: {correct}/{total} = {accuracy:.1f}%")

    # Per-class metrics
    print(f"\nPer-class accuracy:")
    for cls in range(NUM_CLASSES):
        mask = y_val == cls
        if mask.sum() == 0:
            continue
        cls_correct = (y_pred_class[mask] == cls).sum()
        cls_total = mask.sum()
        name = LABEL_NAMES[cls]
        print(f"  {name:25s}: {cls_correct}/{cls_total} = {cls_correct/cls_total*100:.1f}%")

    # Sample some errors
    errors = np.where(y_pred_class != y_val)[0]
    if len(errors) > 0:
        print(f"\nSample errors (showing up to 10):")
        for idx in errors[:10]:
            true_label = LABEL_NAMES[y_val[idx]]
            pred_label = LABEL_NAMES[y_pred_class[idx]]
            conf = y_pred[idx][y_pred_class[idx]]
            text = texts_val[idx][:60]
            print(f"  True={true_label:20s} Pred={pred_label:20s} "
                  f"Conf={conf:.2f} Text='{text}'")

    # Feature importance (gain)
    if hasattr(model, "feature_importance"):
        importance = model.feature_importance(importance_type="gain")
        sorted_idx = np.argsort(importance)[::-1]
        print(f"\nTop-10 feature importance (gain):")
        for i in sorted_idx[:10]:
            print(f"  {FEATURE_NAMES[i]:30s}: {importance[i]:.0f}")


def train_and_evaluate(X_train, y_train, X_val, y_val, texts_val):
    """Full train + evaluate pipeline."""
    model = train_lightgbm(X_train, y_train, X_val, y_val)
    evaluate(model, X_val, y_val, texts_val)
    return model


def export_model(model, output_dir: str):
    """Export model to JSON (LightGBM dump) + ONNX + config files."""
    os.makedirs(output_dir, exist_ok=True)

    # ── JSON dump (lightweight, evaluated in pure Dart) ──────────────────
    print("\nExporting to JSON (Dart evaluator)...")
    try:
        model_json = model.dump_model()
        # Add metadata so the Dart side knows the feature names
        model_json["_feature_names"] = list(FEATURE_NAMES)
        model_json["_label_names"] = list(LABEL_NAMES)
        model_json["_num_classes"] = NUM_CLASSES

        json_path = os.path.join(output_dir, "recipe_classifier.json")
        with open(json_path, "w") as f:
            json.dump(model_json, f)
        model_size_kb = os.path.getsize(json_path) / 1024
        print(f"  JSON model: {json_path} ({model_size_kb:.0f} KB)")
    except Exception as e:
        print(f"  JSON export failed: {e}")

    # ── ONNX export (for future runtime use) ─────────────────────────────
    print("Exporting to ONNX...")
    try:
        import onnxmltools
        from onnxmltools.convert import convert_lightgbm
        from onnxmltools.convert.common.data_types import FloatTensorType

        initial_types = [("float_input", FloatTensorType([None, len(FEATURE_NAMES)]))]
        onnx_model = convert_lightgbm(
            model, initial_types=initial_types, target_opset=15
        )
        onnx_path = os.path.join(output_dir, "recipe_classifier.onnx")
        onnxmltools.utils.save_model(onnx_model, onnx_path)
        model_size_kb = os.path.getsize(onnx_path) / 1024
        print(f"  ONNX model: {onnx_path} ({model_size_kb:.0f} KB)")
    except Exception as e:
        print(f"  ONNX export failed: {e}")

    # ── Label map ───────────────────────────────────────────────────────
    label_map_path = os.path.join(output_dir, "label_map.json")
    with open(label_map_path, "w") as f:
        json.dump(list(LABEL_NAMES), f, indent=2)
    print(f"  Label map: {label_map_path}")

    # ── Feature config ───────────────────────────────────────────────────
    feature_config_path = os.path.join(output_dir, "feature_config.json")
    feature_config = {
        "feature_names": list(FEATURE_NAMES),
        "num_features": len(FEATURE_NAMES),
        "labels": list(LABEL_NAMES),
        "num_classes": NUM_CLASSES,
        "generated_by": "train_model.py",
        "generated_at": __import__("datetime").datetime.now().isoformat(),
    }
    with open(feature_config_path, "w") as f:
        json.dump(feature_config, f, indent=2)
    print(f"  Feature config: {feature_config_path}")

    print(f"\nTo deploy:")
    print(f"  cp {output_dir}/recipe_classifier.json ../assets/ml/")
    print(f"  cp {output_dir}/label_map.json ../assets/ml/")
    print(f"  cp {output_dir}/feature_config.json ../assets/ml/")


def dry_run(output_dir: str):
    """Create output config files without training."""
    os.makedirs(output_dir, exist_ok=True)

    label_map_path = os.path.join(output_dir, "label_map.json")
    with open(label_map_path, "w") as f:
        json.dump(LABEL_NAMES, f, indent=2)
    print(f"  Label map: {label_map_path}")

    feature_config_path = os.path.join(output_dir, "feature_config.json")
    feature_config = {
        "feature_names": FEATURE_NAMES,
        "num_features": len(FEATURE_NAMES),
        "labels": LABEL_NAMES,
        "num_classes": NUM_CLASSES,
        "generated_by": "train_model.py",
        "generated_at": __import__("datetime").datetime.now().isoformat(),
    }
    with open(feature_config_path, "w") as f:
        json.dump(feature_config, f, indent=2)
    print(f"  Feature config: {feature_config_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Train LightGBM classifier for OCR line labelling."
    )
    parser.add_argument(
        "--data",
        default="./data/labelled_lines.csv",
        help="Path to labelled feature CSV",
    )
    parser.add_argument(
        "--output",
        default="./output",
        help="Output directory for model + config files",
    )
    parser.add_argument(
        "--val-split",
        type=float,
        default=0.2,
        help="Validation split fraction",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Skip training, just export config files",
    )
    args = parser.parse_args()

    np.random.seed(args.seed)

    if args.dry_run:
        print("── Dry run — exporting config files only ──────────────────")
        dry_run(args.output)
        return

    # ── Load ────────────────────────────────────────────────────────────
    print(f"Loading data from {args.data}...")
    if not os.path.exists(args.data):
        print(f"ERROR: {args.data} not found. Run generate_synthetic.py first.")
        sys.exit(1)

    X, y, texts, labels_seen = load_data(args.data)
    print(f"Loaded {len(X)} samples, {len(labels_seen)}/{NUM_CLASSES} classes present")

    label_counts = Counter(y)
    for cls in sorted(label_counts):
        print(f"  {LABEL_NAMES[cls]:25s}: {label_counts[cls]}")

    # ── Train/validation split ──────────────────────────────────────────
    from sklearn.model_selection import train_test_split

    # Check if stratification is possible (every class needs >= 2 samples)
    can_stratify = all(c >= 2 for c in label_counts.values())

    split_kwargs = dict(
        test_size=args.val_split, random_state=args.seed,
    )
    if can_stratify:
        split_kwargs["stratify"] = y

    X_train, X_val, y_train, y_val, texts_train, texts_val = train_test_split(
        X, y, texts, **split_kwargs,
    )
    print(f"\nTrain: {len(X_train)}  Val: {len(X_val)}")

    # ── Train ───────────────────────────────────────────────────────────
    model = train_and_evaluate(X_train, y_train, X_val, y_val, texts_val)

    # ── Export ──────────────────────────────────────────────────────────
    export_model(model, args.output)

    print("\n── Done ───────────────────────────────────────────────────────")


if __name__ == "__main__":
    main()