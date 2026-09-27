import 'package:pantry/core/ocr/lightgbm_model.dart';

/// Possible labels the classifier can assign to a line.
///
/// Order matches the training output in `assets/ml/label_map.json`.
enum OcrLineLabel {
  title,
  servings,
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
      return _runModel(features);
    }
    return _stubClassify(features, lineTexts);
  }

  /// Run the LightGBM model on [features].
  Future<OcrClassificationResult> _runModel(
    List<List<double>> features,
  ) async {
    final results = _model.predict(features);
    final labels = <OcrLineClassification>[];

    for (final (classIdx, confidence) in results) {
      final labelName = _model.labelNames != null &&
              classIdx < _model.labelNames!.length
          ? _model.labelNames![classIdx]
          : 'ignore';

      labels.add(OcrLineClassification(
        label: _labelFromName(labelName),
        confidence: confidence,
        labelName: labelName,
      ));
    }

    return OcrClassificationResult(lineLabels: labels, usedStub: false);
  }

  /// Stub classifier: assigns labels using heuristics from [OcrRecipeParser].
  /// Used when the model asset is not available.
  Future<OcrClassificationResult> _stubClassify(
    List<List<double>> features,
    List<String> lineTexts,
  ) async {
    final labels = <OcrLineClassification>[];
    bool seenMethod = false;

    for (var i = 0; i < lineTexts.length; i++) {
      final text = lineTexts[i];
      final feat = features[i];

      const idxDigit = 8;
      const idxFraction = 9;
      const idxColon = 10;
      const idxVerb = 13;

      final startsWithDigit = feat[idxDigit] > 0.5;
      final startsWithFraction = feat[idxFraction] > 0.5;
      final endsWithColon = feat[idxColon] > 0.5;
      final startsWithVerb = feat[idxVerb] > 0.5;
      final hasQuantity = startsWithDigit || startsWithFraction;

      OcrLineLabel label;

      if (endsWithColon) {
        label = OcrLineLabel.sectionHeader;
      } else if (hasQuantity && !seenMethod) {
        label = OcrLineLabel.ingredient;
      } else if (startsWithVerb || RegExp(r'^\d+[.)]\s').hasMatch(text)) {
        seenMethod = true;
        label = OcrLineLabel.methodStep;
      } else if (seenMethod) {
        label = OcrLineLabel.methodContinuation;
      } else if (hasQuantity) {
        label = OcrLineLabel.ingredient;
      } else {
        label = OcrLineLabel.ingredient;
      }

      labels.add(OcrLineClassification(
        label: label,
        confidence: 0.9,
        labelName: label.name,
      ));
    }

    return OcrClassificationResult(lineLabels: labels, usedStub: true);
  }

  OcrLineLabel _labelFromName(String name) {
    switch (name) {
      case 'title':
        return OcrLineLabel.title;
      case 'servings':
        return OcrLineLabel.servings;
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