import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/core/ocr/lightgbm_model.dart';

/// A minimal 2-tree, 2-class model for testing tree walking and softmax.
///
/// Tree 0 splits on feature[0] ≤ 0.5 → 0.5 (left) / -0.3 (right) — class 0.
/// Tree 1 is a leaf with value 0.2 — class 1.
const _syntheticModel = {
  'num_class': 2,
  'num_tree_per_iteration': 2,
  'tree_info': [
    {
      'tree_structure': {
        'split_feature': 0,
        'threshold': 0.5,
        'decision_type': '<=',
        'left_child': {'leaf_value': 0.5},
        'right_child': {'leaf_value': -0.3},
      },
    },
    {
      'tree_structure': {'leaf_value': 0.2},
    },
  ],
  '_label_names': ['class_a', 'class_b'],
  '_feature_names': ['f0'],
};

void main() {
  late LightgbmModel model;

  setUp(() {
    model = LightgbmModel();
    model.loadFromJson(jsonEncode(_syntheticModel));
  });

  group('loadFromJson()', () {
    test('loads model metadata', () {
      expect(model.isLoaded, isTrue);
      expect(model.featureNames, ['f0']);
      expect(model.labelNames, ['class_a', 'class_b']);
    });
  });

  group('predict()', () {
    test('feature ≤ threshold → walks left child', () {
      // feature[0] = 0.2 ≤ 0.5 → left → leaf_value 0.5
      // scores[0] = 0.5, scores[1] = 0.2
      final results = model.predict([
        [0.2],
      ]);
      expect(results.length, 1);

      final (classIdx, confidence) = results[0];
      // Softmax([0.5, 0.2]) → class 0 (scores not clamped, exp(0)=1, exp(-0.3)=0.741)
      expect(classIdx, 0);
      expect(confidence, closeTo(0.574, 0.01));
    });

    test('feature > threshold → walks right child', () {
      // feature[0] = 0.8 > 0.5 → right → leaf_value -0.3
      // scores[0] = -0.3, scores[1] = 0.2
      final results = model.predict([
        [0.8],
      ]);
      final (classIdx, confidence) = results[0];
      // Softmax([-0.3, 0.2]) → class 1
      expect(classIdx, 1);
      expect(confidence, closeTo(0.622, 0.01));
    });

    test('predicts multiple lines independently', () {
      final results = model.predict([
        [0.2], // class 0
        [0.8], // class 1
      ]);
      expect(results.length, 2);
      expect(results[0].$1, 0);
      expect(results[1].$1, 1);
    });
  });
}
