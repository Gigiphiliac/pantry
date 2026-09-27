# OCR Line Classifier — Design Document

Date: 2025-09-25
Status: Decision record (pre-implementation)

## Summary

Replace the current heuristic-based `OcrRecipeParser.splitZones()` with an
on-device ML classifier that labels each OCR line as one of 9 roles using
spatial + text features. Fall back to the heuristic when the model is
unavailable. Goal: fully offline recipe parsing that matches or exceeds LLM
quality on the zone-splitting task.

---

## Decisions

### 1. Classification Level — Line-level

Each ML Kit `TextLine` gets exactly one label. Block-level (paragraph) grouping
is provided as a feature but not used as the classification unit.

Labels (9):
| Label | Meaning |
|---|---|
| `title` | Recipe name |
| `servings` | "Serves 4", "Makes 12" |
| `section_header` | "For the sauce:", "Dough:" (ingredient subsection) |
| `ingredient` | A single ingredient line (with or without quantity) |
| `method_step` | A numbered or free-text instruction step |
| `method_continuation` | A line continuing the previous step (no new verb) |
| `nutrition` | Nutrition info block |
| `notes` | Recipe notes, tips, variations |
| `ignore` | Copyright, URLs, decorative text |

### 2. Model Architecture — Gradient-boosted tree

- **Library**: LightGBM → ONNX export
- **Input**: ~15–20 derived / normalised features per line (no raw tokens)
- **Output**: 9-class softmax
- **Size**: ~50 KB – 500 KB in ONNX / CoreML
- **Inference**: <1 ms on CPU, no GPU required
- **Fallback**: `OcrRecipeParser` (existing heuristic) when model unavailable

### 3. Deployment — ONNX → platform format at build

- Train in LightGBM, export to ONNX
- Convert to CoreML (`.mlpackage`) for iOS and TFLite (`.tflite`) for Android
  as a build step (script in `training/export_onnx.py`)
- Bundle the ONNX file as a Flutter asset
- Run inference via `onnxruntime_flutter` on both platforms
- `assets/ml/recipe_classifier.onnx`
- `assets/ml/label_map.json`
- `assets/ml/feature_config.json` (feature names, normalisation params)

### 4. Features — Derived, not raw

**Spatial** (relative to image dimensions):
- `relative_top` — `line.boundingBox.top / image.height`
- `relative_left` — `line.boundingBox.left / image.width`
- `relative_width` — `line.boundingBox.width / image.width`
- `relative_height` — `line.boundingBox.height / image.height`
- `relative_font_size` — `line.boundingBox.height / avg_line_height` (titles are bigger)
- `block_index` — which TextBlock this line belongs to (0-based)
- `lines_in_block` — total lines in the parent block
- `line_index_in_block` — position within block (0-based)

**Text-derived** (boolean / numeric):
- `starts_with_digit` — `bool`
- `starts_with_unicode_fraction` — `bool`
- `ends_with_colon` — `bool`
- `word_count` — `int`
- `char_count` — `int`
- `starts_with_imperative_verb` — `bool` (from the verb set in `RecipeTextParser`)
- `contains_number` — `bool`
- `ends_with_punctuation` — `bool`
- `has_mixed_case` — `bool` (likely a title)

### 5. Training Data — Synthetic + Heuristic-bootstrap + User corrections

**Phase 1 — Synthetic seed:**
- Take ~500 structured recipes (RecipeNLG, schema.org scrapes)
- Render as recipe-card images with varied layouts
- Run through ML Kit OCR → get RecognizedText with boxes
- Auto-label each line from the known recipe structure
- Yields ~5000–10000 labelled lines

**Phase 2 — Heuristic bootstrap:**
- Run existing `OcrRecipeParser` on a corpus of real OCR outputs
- Where heuristic = synthetic model → high confidence, keep
- Where they disagree → manual label these edge cases

**Phase 3 — User corrections:**
- When user edits a scanned recipe in the form and saves, capture:
  original OCR output → final structure → derive corrected labels
- Add to training pool
- Retrain quarterly

### 6. Pipeline Integration

```
Camera → ML Kit .processImage()
             │
             ▼
     recipe_ocr_service.extractDetailed()
             │
             ▼
     RecipeOcrInput { rawText, lines[], imageSize }
             │
             ├──────────────────────────────┐
             ▼                              ▼
     FeatureExtractor              OcrRecipeParser
        (lines → vectors)           (heuristic fallback)
             │
             ▼
     OnnxClassifier.run()
        (vectors → labels)
             │
             ▼
     ZoneAssembler
        (labelled lines → zones)
             │
             ▼
     IngredientParser (per ingredient line)
             │
             ▼
     RecipeDraft
```

The classifier path is primary. If the ONNX model fails to load (missing asset,
platform not supported), fall back to `OcrRecipeParser`.

### 7. Project Structure

```
pantry/
├── training/
│   ├── requirements.txt           # lightgbm, sklearn, onnx, coremltools
│   ├── generate_synthetic.py      # render recipes → images → OCR → labels
│   ├── train_model.py             # train LightGBM, export ONNX
│   ├── export_onnx.py             # ONNX → CoreML + TFLite conversion
│   ├── visualise_features.py      # feature importance plots
│   ├── label_studio_config.json   # config for manual labelling tool
│   └── README.md                  # full workflow + NN upgrade guide
├── assets/
│   └── ml/
│       ├── recipe_classifier.onnx
│       ├── label_map.json
│       └── feature_config.json
└── lib/
    ├── core/
    │   └── ocr/
    │       ├── recipe_ocr_input.dart       # RecipeOcrInput, RecipeOcrLine
    │       ├── feature_extractor.dart      # lines → normalised float vectors
    │       └── onnx_classifier.dart        # model load + inference wrapper
    └── features/
        └── recipes/
            └── ocr/
                ├── zone_assembler.dart     # labels → structured zones
                ├── ocr_recipe_parser.dart  # existing heuristic (unchanged)
                ├── recipe_ocr_service.dart # now has extractDetailed()
                ├── ocr_scan_screen.dart    # unchanged
                └── ocr_review_screen.dart  # unchanged
```

### 8. Implementation Order (Dart-first)

1. **Create `lib/core/ocr/recipe_ocr_input.dart`** — data classes
2. **Create `lib/core/ocr/feature_extractor.dart`** — feature computation
3. **Create `lib/features/recipes/ocr/zone_assembler.dart`** — labels → zones
4. **Create `lib/core/ocr/onnx_classifier.dart`** — model runner (stub initially)
5. **Update `recipe_ocr_service.dart`** — add `extractDetailed()`, wire classifier
6. **Scaffold `training/` directory** — README, requirements.txt, stubs
7. **Build the synthetic data generator** (`training/generate_synthetic.py`)
8. **Train initial model** (`training/train_model.py`)
9. **Export to ONNX, test on-device** (`training/export_onnx.py`)

---

## Future: Replacing with a Neural Network

### When to switch

- Accuracy plateaus below 90% on held-out real-world OCR samples
- Labelled dataset grows beyond 50K lines
- User feedback indicates zone-splitting errors are the top friction point

### Architecture options

- **Small transformer** (MobileBERT, DistilBERT): 15–70 MB. Tokenises the line
  text directly. Understands "Salt to taste" without hardcoded patterns.
  Requires ~10× more labelled data than a tree model.
- **CNN + text hybrid**: CNN over the spatial feature image + a small text
  encoder (FastText embeddings). 5–15 MB. Less data-hungry than transformer.
- **Sequence model**: If context across adjacent lines matters (e.g. detecting
  where `ingredient` → `method_step` transitions), a CRF or small transformer
  layer on top of per-line features. Can model transition probabilities.

### Integration changes

- **Tokenisation**: A NN needs a tokeniser (vocab file + bpe/wordpiece). Bundle
  as an asset. Adds ~1–5 MB.
- **Batch inference**: NNs prefer batch inputs. The `OnnxClassifier` wrapper
  should already accept `List<List<Float>>` (all lines at once) — keep this API
  shape.
- **Runtime**: ONNX Runtime still works. CoreML on iOS may give better perf for
  transformers (ANE acceleration). TFLite delegates on Android.
- **Feature vector may shrink**: A transformer reads the text directly, so
  text-derived features become less important. Spatial features still matter
  for layout detection.

### Migration path

1. Train the NN in PyTorch (or TF) alongside the tree model for 2 release
   cycles
2. A/B test: tree → NN on a cohort of users, compare correction rates
3. Once NN demonstrates higher accuracy with acceptable latency (target < 10ms
   per image), replace the ONNX model asset
4. Keep the tree model as a secondary fallback for low-end devices

---

## Open Questions (deferred)

- How does `method_continuation` get labelled in training data? Needs a rule:
  "a non-numbered line following a `method_step` that doesn't start with an
  imperative verb and is within the same TextBlock".
- Should `servings` always be a single line, or can it span multiple lines
  ("Serves 4–6 / as a main")?
- How to handle multi-column recipe layouts (ingredients left, method right)?
  The `relative_left` and `block_index` features should capture this, but it
  may need explicit column-detection preprocessing.