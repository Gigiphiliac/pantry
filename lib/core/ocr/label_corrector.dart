import 'package:pantry/core/ocr/onnx_classifier.dart';
import 'package:pantry/core/recipes/recipe_text_parser.dart';

/// Post-processing pass that corrects common OCR line misclassifications.
///
/// Runs between [OnnxClassifier.classify] and [ZoneAssembler.assemble].
/// Each rule is ordered so that earlier corrections inform later ones.
///
/// ## Correction pipeline
///
///   1. Whitespace normalisation — collapse multiple spaces across all texts
///   2. Noise re-check — re-label lines matching expanded noise patterns
///   3. Servings detection — re-label lines like "Serves 4" → `servings`
///   4. Description detection — re-label long narrative lines → `notes`
///   5. Section-header re-labelling — re-label "Ingredients:" etc. → `sectionHeader`
///   6. Method-continuation merging — concatenate continuation into parent step
///
/// The output list may be shorter than the input (step 6 drops continuation
/// lines). All downstream consumers ([ZoneAssembler], [RecipeTextParser])
/// handle variable-length input.
class LabelCorrector {
  // ── Feature indices (must match FeatureExtractor.featureNames) ─────────────
  static const int _idxBlockIndex = 5;
  static const int _idxWordCount = 11;

  // ── Noise patterns (expanded from OnnxClassifier._ignorePatterns) ──────────

  /// Matches rating lines like "4.90 from 219 votes".
  static final RegExp _ratingPattern = RegExp(
    r'^[\d.]+ from \d+ votes\b',
    caseSensitive: false,
  );

  /// Matches standalone "Print" or "Share" button labels.
  static final RegExp _standaloneNoise = RegExp(
    r'^(print|share|pin|tweet|email|save)\b',
    caseSensitive: false,
  );

  /// Substring patterns that indicate non-recipe noise.
  ///
  /// Matched against the lower-cased, whitespace-normalised line text.
  /// This is the combined set: original `_ignorePatterns` from
  /// [OnnxClassifier] plus new patterns for common recipe-page debris.
  static final Set<String> _noisePatterns = {
    // Times
    'prep time',
    'cook time',
    'total time',
    // Nutrition banners
    'calories:',
    'nutrition facts',
    // Author / source
    'author:',
    // Video / social
    'recipe video',
    'jump to recipe',
    'skip to recipe',
    'rate this recipe',
    'print recipe',
    'share recipe',
    // URLs and branding
    'www.',
    // Copyright
    '©',
    'copyright',
    // Publication metadata
    'published:',
    // Dietary / allergen
    'dietary:',
    'allergen',
  };

  /// Page-number pattern: "Page 1", "Page 2", "1 / 2", etc.
  static final RegExp _pageNumberPattern = RegExp(
    r'^\s*(page\s*\d+|p\.?\s*\d+|(\d+)\s*/\s*(\d+))\s*$',
    caseSensitive: false,
  );

  /// Star-rating pattern: runs of ★ or ✦ characters, or "★★★★★" as text.
  static final RegExp _starPattern = RegExp(r'^[\u2605\u2726\u2b50\*]{2,}\s*$');

  // ── Servings markers ───────────────────────────────────────────────────────

  static final RegExp _servingsPattern = RegExp(
    r'^(serv(es|ings?)|makes|yields?)\b',
    caseSensitive: false,
  );

  // ── Section-header markers ─────────────────────────────────────────────────

  static final Set<String> _sectionHeaderMarkers = {
    'ingredients',
    'ingredient',
    'method',
    'directions',
    'instructions',
    'preparation',
    'procedure',
    'cooking',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Correct labels in-place and return a (possibly shorter) list.
  ///
  /// [features] must be parallel to [rawLabels] and [lineTexts] (same length,
  /// same order). The returned lists may be shorter due to step 6 merging.
  static ({List<String> texts, List<OcrLineClassification> labels}) correct({
    required List<String> lineTexts,
    required List<List<double>> features,
    required List<OcrLineClassification> rawLabels,
  }) {
    if (lineTexts.isEmpty) {
      return (texts: const [], labels: const []);
    }

    // Mutable working copies
    final texts = lineTexts.toList();
    final labels = rawLabels.toList();

    // ── Step 1: Whitespace normalisation ────────────────────────────────
    for (var i = 0; i < texts.length; i++) {
      texts[i] = _normalise(texts[i]);
    }

    // ── Step 2: Noise re-check ──────────────────────────────────────────
    for (var i = 0; i < texts.length; i++) {
      if (_isNoise(texts[i])) {
        labels[i] = OcrLineClassification(
          label: OcrLineLabel.ignore,
          confidence: 0.98,
          labelName: 'ignore',
        );
      }
    }

    // ── Step 3: Servings detection ──────────────────────────────────────
    _correctServings(texts, features, labels);

    // ── Step 4: Description detection ───────────────────────────────────
    _correctDescription(texts, features, labels);

    // ── Step 5: Section-header re-labelling ─────────────────────────────
    _correctSectionHeaders(texts, labels);

    // ── Step 6: Method-continuation merging ─────────────────────────────
    return _mergeContinuations(texts, labels);
  }

  // ── Step 2: Noise ─────────────────────────────────────────────────────────

  /// Returns true if [text] looks like non-recipe noise.
  static bool _isNoise(String text) {
    final lower = text.trim().toLowerCase();
    for (final pattern in _noisePatterns) {
      if (lower.contains(pattern)) return true;
    }
    if (_ratingPattern.hasMatch(text)) return true;
    if (_standaloneNoise.hasMatch(text.trim())) return true;
    if (_pageNumberPattern.hasMatch(text)) return true;
    if (_starPattern.hasMatch(text)) return true;
    return false;
  }

  // ── Step 3: Servings ──────────────────────────────────────────────────────

  /// Re-label lines matching a servings pattern as [OcrLineLabel.servings].
  ///
  /// Only applies when the line sits between the title block and the first
  /// ingredient block — this prevents misclassifying recipe narrative that
  /// happens to contain the word "serves".
  static void _correctServings(
    List<String> texts,
    List<List<double>> features,
    List<OcrLineClassification> labels,
  ) {
    if (texts.isEmpty) return;

    // Find the block index of the title (earliest) and the first ingredient
    double? titleBlock;
    double? firstIngredientBlock;

    for (var i = 0; i < labels.length; i++) {
      if (titleBlock == null &&
          labels[i].label == OcrLineLabel.title &&
          i < features.length) {
        titleBlock = features[i][_idxBlockIndex];
      }
      // Skip lines that look like servings — the model often mislabels
      // "Serves 4" as ingredient, which would make us use the servings
      // line's own block as the ingredient boundary and prevent correction.
      if (firstIngredientBlock == null &&
          labels[i].label == OcrLineLabel.ingredient &&
          i < texts.length &&
          !_servingsPattern.hasMatch(texts[i]) &&
          i < features.length) {
        firstIngredientBlock = features[i][_idxBlockIndex];
      }
      if (titleBlock != null && firstIngredientBlock != null) break;
    }

    // If no ingredient block found, use methodStep block as upper bound
    if (firstIngredientBlock == null) {
      for (var i = 0; i < labels.length; i++) {
        if (labels[i].label == OcrLineLabel.methodStep && i < features.length) {
          firstIngredientBlock = features[i][_idxBlockIndex];
          break;
        }
      }
    }

    // Need at least a title block to anchor
    if (titleBlock == null) return;

    for (var i = 0; i < texts.length; i++) {
      if (labels[i].label == OcrLineLabel.ignore) continue;

      if (_servingsPattern.hasMatch(texts[i])) {
        final blockIdx = i < features.length
            ? features[i][_idxBlockIndex]
            : titleBlock;

        // Line must be in or after the title block and before ingredients
        if (blockIdx >= titleBlock &&
            (firstIngredientBlock == null || blockIdx < firstIngredientBlock)) {
          labels[i] = OcrLineClassification(
            label: OcrLineLabel.servings,
            confidence: 0.95,
            labelName: 'servings',
          );
        }
      }
    }
  }

  // ── Step 4: Description ───────────────────────────────────────────────────

  /// Re-label long narrative lines between title and ingredients as description.
  ///
  /// Recipe descriptions are typically full sentences with more than 10 words,
  /// positioned between the title block and the first ingredient block. The
  /// model often misclassifies these as [OcrLineLabel.methodStep].
  static void _correctDescription(
    List<String> texts,
    List<List<double>> features,
    List<OcrLineClassification> labels,
  ) {
    if (texts.isEmpty) return;

    // Determine the zone boundaries from labels
    double? titleBlock;
    double? ingredientStartBlock;

    for (var i = 0; i < labels.length; i++) {
      if (titleBlock == null &&
          labels[i].label == OcrLineLabel.title &&
          i < features.length) {
        titleBlock = features[i][_idxBlockIndex];
      }
      if (ingredientStartBlock == null &&
          (labels[i].label == OcrLineLabel.ingredient ||
              labels[i].label == OcrLineLabel.sectionHeader) &&
          i < features.length) {
        ingredientStartBlock = features[i][_idxBlockIndex];
      }
      if (titleBlock != null && ingredientStartBlock != null) break;
    }

    if (titleBlock == null) return;

    for (var i = 0; i < texts.length; i++) {
      // Only re-label lines the model currently thinks are method or ingredient
      if (labels[i].label != OcrLineLabel.methodStep &&
          labels[i].label != OcrLineLabel.ingredient &&
          labels[i].label != OcrLineLabel.methodContinuation) {
        continue;
      }

      final wordCount = i < features.length ? features[i][_idxWordCount] : 0.0;
      if (wordCount <= 10) continue;

      // Don't re-label lines that look like numbered steps (actual method content)
      if (RegExp(r'^\d+[.)]\s').hasMatch(texts[i])) continue;

      final blockIdx = i < features.length
          ? features[i][_idxBlockIndex]
          : titleBlock;

      // Must be between title and ingredient zone
      if (blockIdx >= titleBlock &&
          (ingredientStartBlock == null || blockIdx < ingredientStartBlock)) {
        labels[i] = OcrLineClassification(
          label: OcrLineLabel.description,
          confidence: 0.90,
          labelName: 'description',
        );
      }
    }
  }

  // ── Step 5: Section headers ───────────────────────────────────────────────

  /// Re-label lines that are explicit zone markers back to [OcrLineLabel.sectionHeader].
  ///
  /// The model sometimes classifies "Ingredients:" or "Method:" as
  /// [OcrLineLabel.ingredient] or [OcrLineLabel.methodStep]. This rule catches
  /// lines whose normalised text is just a known section marker (optionally
  /// followed by a colon).
  static void _correctSectionHeaders(
    List<String> texts,
    List<OcrLineClassification> labels,
  ) {
    for (var i = 0; i < texts.length; i++) {
      if (labels[i].label == OcrLineLabel.ignore) continue;

      final lower = texts[i]
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[:.]$'), '')
          .trim();

      if (_sectionHeaderMarkers.contains(lower)) {
        labels[i] = OcrLineClassification(
          label: OcrLineLabel.sectionHeader,
          confidence: 0.97,
          labelName: 'sectionHeader',
        );
      }
    }
  }

  // ── Step 6: Merge continuations ───────────────────────────────────────────

  /// Merge [OcrLineLabel.methodContinuation] lines into their parent
  /// [OcrLineLabel.methodStep] and return the reduced list.
  ///
  /// Continuation lines that cannot be merged (no preceding step) are kept
  /// as standalone steps.
  static ({List<String> texts, List<OcrLineClassification> labels})
  _mergeContinuations(List<String> texts, List<OcrLineClassification> labels) {
    final outTexts = <String>[];
    final outLabels = <OcrLineClassification>[];

    for (var i = 0; i < texts.length; i++) {
      if (labels[i].label == OcrLineLabel.methodContinuation) {
        if (outTexts.isNotEmpty) {
          // Append continuation text to the last output step
          outTexts[outTexts.length - 1] = '${outTexts.last} ${texts[i]}';
        } else {
          // Orphan continuation — promote to standalone step
          outTexts.add(texts[i]);
          outLabels.add(
            OcrLineClassification(
              label: OcrLineLabel.methodStep,
              confidence: labels[i].confidence,
              labelName: 'methodStep',
            ),
          );
        }
      } else {
        outTexts.add(texts[i]);
        outLabels.add(labels[i]);
      }
    }

    return (texts: outTexts, labels: outLabels);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Collapse all whitespace runs to single spaces and trim.
  static String _normalise(String s) =>
      s.replaceAll(RegExp(r'\s+'), ' ').trim();
}
