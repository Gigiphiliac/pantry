import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/core/ocr/onnx_classifier.dart';

/// Build a 20-element feature vector with the given overrides.
///
/// Defaults: all zeros except confidence (17) = 0.9.
List<double> features({
  double startsWithDigit = 0,
  double startsWithFraction = 0,
  double endsWithColon = 0,
  double wordCount = 1,
  double startsWithVerb = 0,
  double isNoise = 0,
}) => [
  0, // 0: relative_top
  0, // 1: relative_left
  0, // 2: relative_width
  0, // 3: relative_height
  0, // 4: relative_font_size
  0, // 5: block_index
  0, // 6: lines_in_block
  0, // 7: line_index_in_block
  startsWithDigit, // 8
  startsWithFraction, // 9
  endsWithColon, // 10
  wordCount, // 11: word_count
  0, // 12: char_count
  startsWithVerb, // 13
  0, // 14: contains_number
  0, // 15: ends_with_punctuation
  0, // 16: has_mixed_case
  0.9, // 17: confidence
  0, // 18: is_first_in_block
  0, // 19: is_last_in_block
];

void main() {
  late OnnxClassifier classifier;

  setUp(() {
    // Creating with default constructor — no init → model NOT loaded,
    // so classify() falls through to the stub path.
    classifier = OnnxClassifier();
  });

  group('stub classifier (model not loaded)', () {
    test('empty input returns empty result', () async {
      final result = await classifier.classify([], []);
      expect(result.lineLabels, isEmpty);
      expect(result.usedStub, isTrue);
    });

    group('noise detection', () {
      test('prep time noise → ignore', () async {
        final result = await classifier.classify(
          [features(isNoise: 1)],
          ['Prep Time: 10 mins'],
        );
        expect(result.lineLabels.single.label, OcrLineLabel.ignore);
      });

      test('rating line → ignore', () async {
        final result = await classifier.classify(
          [features(isNoise: 1)],
          ['4.90 from 219 votes'],
        );
        expect(result.lineLabels.single.label, OcrLineLabel.ignore);
      });

      test('standalone print/share → ignore', () async {
        final result = await classifier.classify(
          [features(isNoise: 1)],
          ['Print'],
        );
        expect(result.lineLabels.single.label, OcrLineLabel.ignore);
      });

      test('author line → ignore', () async {
        final result = await classifier.classify(
          [features(isNoise: 1)],
          ['Author: Jane Smith'],
        );
        expect(result.lineLabels.single.label, OcrLineLabel.ignore);
      });

      test('non-noise text is NOT marked as ignore', () async {
        final result = await classifier.classify(
          [features(startsWithDigit: 1)],
          ['2 cups flour'],
        );
        expect(result.lineLabels.single.label, isNot(OcrLineLabel.ignore));
      });
    });

    group('heuristic labelling', () {
      test('colon at end → section header', () async {
        final result = await classifier.classify(
          [features(endsWithColon: 1, wordCount: 1)],
          ['Ingredients:'],
        );
        expect(result.lineLabels.single.label, OcrLineLabel.sectionHeader);
      });

      test('starts with digit → ingredient', () async {
        final result = await classifier.classify(
          [features(startsWithDigit: 1, wordCount: 3)],
          ['400g spaghetti'],
        );
        expect(result.lineLabels.single.label, OcrLineLabel.ingredient);
      });

      test('starts with unicode fraction → ingredient', () async {
        final result = await classifier.classify(
          [features(startsWithFraction: 1, wordCount: 3)],
          ['½ cup flour'],
        );
        expect(result.lineLabels.single.label, OcrLineLabel.ingredient);
      });

      test('starts with imperative verb → method step', () async {
        final result = await classifier.classify(
          [features(startsWithVerb: 1, wordCount: 4)],
          ['Boil pasta in salted water'],
        );
        expect(result.lineLabels.single.label, OcrLineLabel.methodStep);
      });

      test('numbered step → method step', () async {
        final result = await classifier.classify(
          [features(wordCount: 2)],
          ['1. Mix ingredients.'],
        );
        expect(result.lineLabels.single.label, OcrLineLabel.methodStep);
      });

      test('long narrative before any ingredient → description', () async {
        final result = await classifier.classify(
          [features(wordCount: 12)],
          [
            'These fluffy pancakes are light and airy and perfect for breakfast',
          ],
        );
        expect(result.lineLabels.single.label, OcrLineLabel.description);
      });

      test(
        'short non-quantity line after method start → method continuation',
        () async {
          final result = await classifier.classify(
            [
              features(startsWithVerb: 1, wordCount: 3), // method step
              features(wordCount: 2), // continuation
            ],
            ['Mix ingredients.', 'until smooth'],
          );
          expect(result.lineLabels[0].label, OcrLineLabel.methodStep);
          expect(result.lineLabels[1].label, OcrLineLabel.methodContinuation);
        },
      );

      test('short line before any ingredient/verb → ingredient', () async {
        final result = await classifier.classify(
          [features(wordCount: 1)],
          ['salt'],
        );
        expect(result.lineLabels.single.label, OcrLineLabel.ingredient);
      });
    });
  });
}
