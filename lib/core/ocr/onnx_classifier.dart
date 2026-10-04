import 'package:pantry/core/ocr/lightgbm_model.dart';

/// Possible labels the classifier can assign to a line.
///
/// Order matches the training output in `assets/ml/label_map.json`.
enum OcrLineLabel {
  title,
  servings,
  description,
  sectionHeader,
  ingredient,
  methodStep,
  methodContinuation,
  nutrition,
  notes,
  ignore,
}

/// Classifier result for a single line.
class OcrLineClassification {
  final OcrLineLabel label;
  final double confidence;
  final String labelName;

  const OcrLineClassification({
    required this.label,
    required this.confidence,
    required this.labelName,
  });
}

/// Result of classifying all lines in an OCR input.
class OcrClassificationResult {
  /// One label per input line, in the same order.
  final List<OcrLineClassification> lineLabels;

  /// Whether the result came from a real model or the stub.
  final bool usedStub;

  const OcrClassificationResult({
    required this.lineLabels,
    required this.usedStub,
  });

  /// Convenience: list of label names in line order.
  List<String> get labelNames => lineLabels.map((l) => l.labelName).toList();
}

/// On-device classifier that labels each OCR line.
///
/// Loads a LightGBM model (exported as JSON from `model.dump_model()`) and
/// evaluates it in pure Dart — no native dependencies required.
///
/// When the model asset is unavailable, falls back to a heuristic stub so
/// the pipeline is always functional.
class OnnxClassifier {
  static const _defaultJsonPath = 'assets/ml/recipe_classifier.json';

  final LightgbmModel _model = LightgbmModel();
  bool _loaded = false;
  bool _loadAttempted = false;

  /// Initialise the classifier. Call once at app start or first use.
  ///
  /// If the model asset doesn't exist, silently marks as stub-only.
  Future<void> init({String? assetPath}) async {
    if (_loadAttempted) return;
    _loadAttempted = true;

    await _model.load(assetPath: assetPath ?? _defaultJsonPath);

    if (_model.isLoaded) {
      _loaded = true;
    }
  }

  /// Returns true if the model is loaded and ready.
  bool get isReady => _loaded;

  /// Classify [features] (one vector per line) into labels.
  ///
  /// Uses the trained LightGBM model when loaded; falls back to a heuristic
  /// stub otherwise.
  Future<OcrClassificationResult> classify(
    List<List<double>> features,
    List<String> lineTexts,
  ) async {
    if (_loaded) {
      return _runModel(features, lineTexts);
    }
    return _stubClassify(features, lineTexts);
  }

  /// Run the LightGBM model on [features], then post-filter any noise lines
  /// the model would otherwise miss (since the training data has no `ignore`
  /// examples).
  Future<OcrClassificationResult> _runModel(
    List<List<double>> features,
    List<String> lineTexts,
  ) async {
    final results = _model.predict(features);
    final labels = <OcrLineClassification>[];

    for (var i = 0; i < results.length; i++) {
      final (classIdx, confidence) = results[i];

      // Post-filter: override model prediction if the line looks like noise
      if (_isNoise(lineTexts[i])) {
        labels.add(
          OcrLineClassification(
            label: OcrLineLabel.ignore,
            confidence: 0.98,
            labelName: 'ignore',
          ),
        );
        continue;
      }

      final labelName =
          _model.labelNames != null && classIdx < _model.labelNames!.length
          ? _model.labelNames![classIdx]
          : 'ignore';

      labels.add(
        OcrLineClassification(
          label: _labelFromName(labelName),
          confidence: confidence,
          labelName: labelName,
        ),
      );
    }

    return OcrClassificationResult(lineLabels: labels, usedStub: false);
  }

  /// Lines whose lower-cased text contains any of these substrings are
  /// extremely unlikely to be recipe content and should be ignored.
  ///
  /// Matched against whitespace-normalised text (multiple spaces collapsed to
  /// one) to handle OCR spacing artefacts.
  static final Set<String> _ignorePatterns = {
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

  /// Matches page-number lines: "Page 1", "P. 2", "1 / 2", etc.
  static final RegExp _pageNumberPattern = RegExp(
    r'^\s*(page\s*\d+|p\.?\s*\d+|(\d+)\s*/\s*(\d+))\s*$',
    caseSensitive: false,
  );

  /// Matches star-rating characters: ★, ✦, ⭐, or runs of "*".
  static final RegExp _starPattern = RegExp(r'^[\u2605\u2726\u2b50\*]{2,}\s*$');

  /// Stub classifier: assigns labels using heuristics from [OcrRecipeParser].
  /// Used when the model asset is not available.
  Future<OcrClassificationResult> _stubClassify(
    List<List<double>> features,
    List<String> lineTexts,
  ) async {
    final labels = <OcrLineClassification>[];
    bool seenIngredient = false;
    bool seenMethod = false;

    for (var i = 0; i < lineTexts.length; i++) {
      final text = lineTexts[i];
      final feat = features[i];

      // ---- Check for ignore patterns first ----
      if (_isNoise(text)) {
        labels.add(
          OcrLineClassification(
            label: OcrLineLabel.ignore,
            confidence: 0.95,
            labelName: 'ignore',
          ),
        );
        continue;
      }

      const idxDigit = 8;
      const idxFraction = 9;
      const idxColon = 10;
      const idxVerb = 13;
      const idxWordCount = 11;

      final startsWithDigit = feat[idxDigit] > 0.5;
      final startsWithFraction = feat[idxFraction] > 0.5;
      final endsWithColon = feat[idxColon] > 0.5;
      final startsWithVerb = feat[idxVerb] > 0.5;
      final hasQuantity = startsWithDigit || startsWithFraction;
      final wordCount = feat[idxWordCount];

      OcrLineLabel label;

      if (endsWithColon) {
        label = OcrLineLabel.sectionHeader;
      } else if (hasQuantity || startsWithDigit) {
        if (!seenMethod) {
          seenIngredient = true;
          label = OcrLineLabel.ingredient;
        } else {
          label = OcrLineLabel.ingredient;
        }
      } else if (startsWithVerb || RegExp(r'^\d+[.)]\s').hasMatch(text)) {
        seenMethod = true;
        label = OcrLineLabel.methodStep;
      } else if (seenMethod) {
        label = OcrLineLabel.methodContinuation;
      } else if (wordCount > 10 && !seenIngredient) {
        // Long narrative line before any ingredient → description
        label = OcrLineLabel.description;
      } else {
        label = OcrLineLabel.ingredient;
      }

      labels.add(
        OcrLineClassification(
          label: label,
          confidence: 0.9,
          labelName: label.name,
        ),
      );
    }

    return OcrClassificationResult(lineLabels: labels, usedStub: true);
  }

  /// Returns true if [text] looks like non-recipe noise (ratings, timers,
  /// social buttons, etc.).
  ///
  /// Whitespace is normalised before matching to handle OCR spacing
  /// artefacts ("Prep  Time" → "Prep Time").
  bool _isNoise(String text) {
    final normalised = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final lower = normalised.toLowerCase();
    for (final pattern in _ignorePatterns) {
      if (lower.contains(pattern)) return true;
    }
    if (_ratingPattern.hasMatch(normalised)) return true;
    if (_standaloneNoise.hasMatch(normalised)) return true;
    if (_pageNumberPattern.hasMatch(normalised)) return true;
    if (_starPattern.hasMatch(normalised)) return true;
    return false;
  }

  OcrLineLabel _labelFromName(String name) {
    switch (name) {
      case 'title':
        return OcrLineLabel.title;
      case 'servings':
        return OcrLineLabel.servings;
      case 'description':
        return OcrLineLabel.description;
      case 'section_header':
        return OcrLineLabel.sectionHeader;
      case 'ingredient':
        return OcrLineLabel.ingredient;
      case 'method_step':
        return OcrLineLabel.methodStep;
      case 'method_continuation':
        return OcrLineLabel.methodContinuation;
      case 'nutrition':
        return OcrLineLabel.nutrition;
      case 'notes':
        return OcrLineLabel.notes;
      default:
        return OcrLineLabel.ignore;
    }
  }
}
