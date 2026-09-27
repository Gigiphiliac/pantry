import 'dart:convert';
import 'dart:math' show exp;

import 'package:flutter/services.dart' show rootBundle;

/// Evaluates a LightGBM multiclass model in pure Dart.
///
/// Loads the JSON dump from `model.dump_model()` and walks the decision
/// trees directly. No native dependencies, no FFI, no ONNX Runtime.
///
/// The JSON model is typically 100–300 KB for a ~50-tree multiclass model.
class LightgbmModel {
  late final List<Map<String, dynamic>> _treeInfo;
  late final int _numClasses;
  late final int _numTreePerIteration;

  // ── State ───────────────────────────────────────────────────────────────

  bool _loaded = false;

  /// The label names from the model metadata.
  List<String>? labelNames;

  /// The feature names expected by the model.
  List<String>? featureNames;

  // ── Loading ─────────────────────────────────────────────────────────────

  /// Load model from a JSON asset path.
  Future<void> load({String assetPath = 'assets/ml/recipe_classifier.json'}) async {
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      _numClasses = (data['num_class'] as num).toInt();
      _numTreePerIteration = (data['num_tree_per_iteration'] as num).toInt();
      _treeInfo = (data['tree_info'] as List).cast<Map<String, dynamic>>();

      labelNames = (data['_label_names'] as List?)?.cast<String>();
      featureNames = (data['_feature_names'] as List?)?.cast<String>();

      _loaded = true;
    } catch (e) {
      _loaded = false;
      // Silently fail — caller checks [_loaded] and falls back to stub.
    }
  }

  /// Whether the model was loaded successfully.
  bool get isLoaded => _loaded;

  // ── Inference ───────────────────────────────────────────────────────────

  /// Predict class labels for one or more feature vectors.
  ///
  /// [features] — one inner list per line, each of length [FeatureExtractor.featureCount].
  /// Returns a list of (classIndex, confidence) pairs, one per line.
  List<(int, double)> predict(List<List<double>> features) {
    if (!_loaded) {
      throw StateError('Model not loaded');
    }

    return features.map((feat) => _predictOne(feat)).toList();
  }

  /// Predict class for a single feature vector.
  (int, double) _predictOne(List<double> features) {
    final numTrees = _treeInfo.length;
    // Sum raw scores per class
    final scores = List.filled(_numClasses, 0.0);

    for (var ti = 0; ti < numTrees; ti++) {
      final classIdx = ti % _numTreePerIteration;
      final tree = _treeInfo[ti];
      final leafValue = _walkTree(tree['tree_structure'] as Map<String, dynamic>, features);
      scores[classIdx] += leafValue;
    }

    // Softmax to get probabilities
    return _softmax(scores);
  }

  /// Walk a single decision tree and return the leaf value.
  double _walkTree(Map<String, dynamic> node, List<double> features) {
    // Leaf node
    if (node.containsKey('leaf_value')) {
      return (node['leaf_value'] as num).toDouble();
    }

    // Internal (split) node
    final splitFeature = (node['split_feature'] as num).toInt();
    final threshold = (node['threshold'] as num).toDouble();
    final decisionType = node['decision_type'] as String? ?? '<=';

    final featValue = features[splitFeature];
    final goLeft = decisionType == '<=' ? featValue <= threshold : featValue <= threshold;

    if (goLeft) {
      return _walkTree(node['left_child'] as Map<String, dynamic>, features);
    } else {
      return _walkTree(node['right_child'] as Map<String, dynamic>, features);
    }
  }

  /// Compute softmax over scores, return (predictedClass, confidence).
  (int, double) _softmax(List<double> scores) {
    // Find max for numeric stability
    double maxScore = scores[0];
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) maxScore = scores[i];
    }

    double sum = 0;
    final exps = List.filled(scores.length, 0.0);
    for (var i = 0; i < scores.length; i++) {
      exps[i] = (scores[i] - maxScore).clamp(-700, 700); // prevent overflow
      exps[i] = _fastExp(exps[i]);
      sum += exps[i];
    }

    int bestClass = 0;
    double bestProb = 0;
    for (var i = 0; i < scores.length; i++) {
      final prob = exps[i] / sum;
      if (prob > bestProb) {
        bestProb = prob;
        bestClass = i;
      }
    }

    return (bestClass, bestProb);
  }

  /// Fast exponential approximation (sufficient for softmax).
  static double _fastExp(double x) {
    return exp(x);
  }
}