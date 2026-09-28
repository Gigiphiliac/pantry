# OCR Line Classifier — Training Pipeline

Trains a LightGBM gradient-boosted tree to label each OCR text line with one
of 9 recipe-structure roles.

## Overview

```
synthetic recipe data → render as images → ML Kit OCR → labelled lines
                                                                   ↓
                                                            train_model.py
                                                                   ↓
                                                        recipe_classifier.onnx
                                                                   ↓
                                                    assets/ml/ in Flutter app
```

## Setup

```bash
cd training
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Files

| File | Purpose |
|---|---|
| `generate_synthetic.py` | Render structured recipes as images, run OCR, produce labelled lines |
| `train_model.py` | Train LightGBM on labelled line data, export to ONNX |
| `export_onnx.py` | ONNX → CoreML (iOS) + TFLite (Android) conversion |
| `visualise_features.py` | Feature importance plots for debugging |
| `feature_config.json` | Canonical feature list (must match `FeatureExtractor`) |
| `label_map.json` | Output index → label name mapping |

## Feature Order

Must exactly match `lib/core/ocr/feature_extractor.dart` → `featureNames`.

1. `relative_top`
2. `relative_left`
3. `relative_width`
4. `relative_height`
5. `relative_font_size`
6. `block_index`
7. `lines_in_block`
8. `line_index_in_block`
9. `starts_with_digit`
10. `starts_with_unicode_fraction`
11. `ends_with_colon`
12. `word_count`
13. `char_count`
14. `starts_with_imperative_verb`
15. `contains_number`
16. `ends_with_punctuation`
17. `has_mixed_case`
18. `confidence`
19. `is_first_in_block`
20. `is_last_in_block`

## Labels

| Index | Name | Description |
|---|---|---|
| 0 | title | Recipe name |
| 1 | servings | "Serves 4", "Makes 12" |
| 2 | section_header | "For the sauce:", "Dough:" |
| 3 | ingredient | Individual ingredient line |
| 4 | method_step | A numbered or free-text instruction step |
| 5 | method_continuation | Continuation of previous step |
| 6 | nutrition | Nutrition info block |
| 7 | notes | Recipe tips, variations |
| 8 | ignore | Copyright, URLs, decorative text |

## Exporting to the App

After training:

```bash
python train_model.py --data ./data/labelled_lines.csv --export ./output
cp output/recipe_classifier.onnx ../assets/ml/
cp output/label_map.json ../assets/ml/
cp output/feature_config.json ../assets/ml/
```

## Data Collection from User Corrections

When a user scans a recipe and corrects it in the form, the app can capture:

1. Original `RecipeOcrInput` (OCR output with spatial data)
2. Final structured `RecipeDraft` (after user edits)
3. Derive corrected line labels from the diff

Store as CSV rows and include in the next training cycle. See
`collect_training_data.dart` (TODO) for the app-side capture logic.

---

## Future: Replacing with a Neural Network

### When to consider

- Line-level accuracy plateaus below 90% on held-out real-world OCR samples
- Labelled dataset grows beyond 50K lines
- User feedback indicates zone-splitting errors are the top friction point

### Architecture options

| Architecture | Size | Data needed | Pros | Cons |
|---|---|---|---|---|
| **MobileBERT** | ~25 MB | 50K+ lines | Understands text semantics, not just heuristics | Heavy, needs tokeniser asset |
| **DistilBERT** | ~70 MB | 50K+ lines | Strong text understanding | Larger binary |
| **CNN + FastText** | ~5-15 MB | 10K+ lines | Fast, moderate size | Weaker on unusual phrasing |
| **CRF on top of tree** | ~1 MB | Same as tree | Models label transitions (ingredient → method_step boundary) | Adds complexity |

### Integration changes

1. **Tokenisation**: A transformer needs a WordPiece / BPE tokeniser. Add
   `assets/ml/tokeniser.json` (~1-5 MB). The Dart side needs a tokeniser
   implementation (or use `onnxruntime_extensions` if available).

2. **Batch inference**: Feed all lines as a single batch. The
   `OnnxClassifier.classify()` API already accepts `List<List<double>>` —
   change the input type to `List<Int64>` (token IDs) or keep the float vector
   approach if using a CNN.

3. **Runtime**: ONNX Runtime still works. CoreML on iOS may give better
   transformer performance via ANE. TFLite delegates on Android.

4. **Spatial features**: A transformer reads text directly, so text-derived
   features become less important. Spatial features (position, font size)
   still matter for layout detection — feed them as additional input
   embeddings or a separate head.

### Migration steps

1. Train the NN in PyTorch alongside the tree model for 2 release cycles
2. A/B test in-app: tree → NN on a cohort of users, compare correction rates
3. Once NN demonstrates higher accuracy with acceptable latency
   (target < 10 ms per image), replace `assets/ml/recipe_classifier.onnx`
4. Keep the tree model as secondary fallback for low-end devices

### Open questions for NN path

- Can a transformer handle the spatial features, or should we use a
  two-tower architecture (text encoder + spatial MLP)?
- Does iOS ANE acceleration work with ONNX Runtime or only CoreML?
- How does inference latency scale with number of lines on an iPhone SE?
- Can we distill the tree model's knowledge into a tiny NN to get the best
  of both worlds?