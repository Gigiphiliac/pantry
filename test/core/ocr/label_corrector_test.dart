import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/core/ocr/label_corrector.dart';
import 'package:pantry/core/ocr/onnx_classifier.dart';

void main() {
  group('LabelCorrector.correct()', () {
    // ── Helpers ──────────────────────────────────────────────────────────────

    /// Build a minimal 20-feature vector. Most features default to 0; only
    /// the ones relevant to the correction rules are set explicitly.
    List<double> features({
      double relativeTop = 0.0,
      double blockIndex = 0.0,
      double wordCount = 0.0,
    }) => [
      relativeTop, // 0: relative_top
      0.0, // 1: relative_left
      0.0, // 2: relative_width
      0.0, // 3: relative_height
      0.0, // 4: relative_font_size
      blockIndex, // 5: block_index
      0.0, // 6: lines_in_block
      0.0, // 7: line_index_in_block
      0.0, // 8: starts_with_digit
      0.0, // 9: starts_with_unicode_fraction
      0.0, // 10: ends_with_colon
      wordCount, // 11: word_count
      0.0, // 12: char_count
      0.0, // 13: starts_with_imperative_verb
      0.0, // 14: contains_number
      0.0, // 15: ends_with_punctuation
      0.0, // 16: has_mixed_case
      0.0, // 17: confidence
      0.0, // 18: is_first_in_block
      0.0, // 19: is_last_in_block
    ];

    OcrLineClassification label(OcrLineLabel l) =>
        OcrLineClassification(label: l, confidence: 0.9, labelName: l.name);

    // ── Tests ────────────────────────────────────────────────────────────────

    test('empty input returns empty output', () {
      final result = LabelCorrector.correct(
        lineTexts: const [],
        features: const [],
        rawLabels: const [],
      );
      expect(result.texts, isEmpty);
      expect(result.labels, isEmpty);
    });

    test('noise pattern re-labels to ignore', () {
      final result = LabelCorrector.correct(
        lineTexts: ['Prep Time: 10 mins'],
        features: [features()],
        rawLabels: [label(OcrLineLabel.ingredient)],
      );
      expect(result.labels.length, 1);
      expect(result.labels[0].label, OcrLineLabel.ignore);
    });

    test('whitespace normalisation catches spaced-out noise', () {
      final result = LabelCorrector.correct(
        lineTexts: ['Prep  Time:  10  mins'],
        features: [features()],
        rawLabels: [label(OcrLineLabel.ingredient)],
      );
      expect(result.labels.length, 1);
      expect(result.labels[0].label, OcrLineLabel.ignore);
    });

    test(
      'servings line between title and ingredient blocks is re-labelled',
      () {
        // Line 0: title (block 0)
        // Line 1: "Serves 4" (block 1) — should become servings
        // Line 2: first ingredient (block 2)
        final result = LabelCorrector.correct(
          lineTexts: ['Fluffy Pancakes', 'Serves 4', '1 cup flour'],
          features: [
            features(blockIndex: 0), // title
            features(blockIndex: 1, wordCount: 2), // "Serves 4"
            features(blockIndex: 2, wordCount: 3), // ingredient
          ],
          rawLabels: [
            label(OcrLineLabel.title),
            label(OcrLineLabel.ingredient), // mislabelled by model
            label(OcrLineLabel.ingredient),
          ],
        );
        expect(result.labels.length, 3);
        expect(result.labels[1].label, OcrLineLabel.servings);
        // Title and ingredient unchanged
        expect(result.labels[0].label, OcrLineLabel.title);
        expect(result.labels[2].label, OcrLineLabel.ingredient);
      },
    );

    test('servings line outside spatial bounds is NOT re-labelled', () {
      // "Serves 4" is in the method block (block 5) — should stay as-is
      final result = LabelCorrector.correct(
        lineTexts: ['Fluffy Pancakes', '1 cup flour', 'Serves 4'],
        features: [
          features(blockIndex: 0),
          features(blockIndex: 2, wordCount: 3),
          features(blockIndex: 5, wordCount: 2), // in method zone
        ],
        rawLabels: [
          label(OcrLineLabel.title),
          label(OcrLineLabel.ingredient),
          label(OcrLineLabel.methodStep), // model's original label
        ],
      );
      expect(result.labels[2].label, OcrLineLabel.methodStep); // unchanged
    });

    test('long narrative line between title and ingredients → notes', () {
      // A 15-word description between title and ingredient blocks
      final description =
          'These fluffy pancakes are light airy and perfect for a lazy weekend breakfast treat';
      final result = LabelCorrector.correct(
        lineTexts: ['Fluffy Pancakes', description, '1 cup flour'],
        features: [
          features(blockIndex: 0),
          features(blockIndex: 1, wordCount: 15.0), // long line
          features(blockIndex: 2, wordCount: 3),
        ],
        rawLabels: [
          label(OcrLineLabel.title),
          label(OcrLineLabel.methodStep), // mislabelled as method
          label(OcrLineLabel.ingredient),
        ],
      );
      expect(result.labels.length, 3);
      expect(result.labels[1].label, OcrLineLabel.notes);
    });

    test('section header re-labelled from ingredient', () {
      final result = LabelCorrector.correct(
        lineTexts: ['Ingredients:', '1 cup flour', 'Method:', 'Mix well'],
        features: [
          features(blockIndex: 1, wordCount: 1),
          features(blockIndex: 1, wordCount: 3),
          features(blockIndex: 2, wordCount: 1),
          features(blockIndex: 2, wordCount: 2),
        ],
        rawLabels: [
          label(OcrLineLabel.ingredient), // mislabelled
          label(OcrLineLabel.ingredient),
          label(OcrLineLabel.ingredient), // mislabelled
          label(OcrLineLabel.methodStep),
        ],
      );
      expect(result.labels[0].label, OcrLineLabel.sectionHeader);
      expect(result.labels[2].label, OcrLineLabel.sectionHeader);
    });

    test('method continuation merged into parent step', () {
      final result = LabelCorrector.correct(
        lineTexts: [
          'Boil pasta in salted water',
          'until al dente',
          'Add sauce',
        ],
        features: [
          features(blockIndex: 3, wordCount: 5),
          features(blockIndex: 3, wordCount: 3),
          features(blockIndex: 4, wordCount: 2),
        ],
        rawLabels: [
          label(OcrLineLabel.methodStep),
          label(OcrLineLabel.methodContinuation),
          label(OcrLineLabel.methodStep),
        ],
      );
      expect(result.texts.length, 2); // one fewer line
      expect(result.labels.length, 2);
      expect(result.texts[0], 'Boil pasta in salted water until al dente');
      expect(result.labels[0].label, OcrLineLabel.methodStep);
      expect(result.texts[1], 'Add sauce');
    });

    test('orphan continuation promoted to standalone step', () {
      final result = LabelCorrector.correct(
        lineTexts: ['until al dente'],
        features: [features(wordCount: 3)],
        rawLabels: [
          label(OcrLineLabel.methodContinuation), // no parent!
        ],
      );
      expect(result.labels.length, 1);
      expect(result.labels[0].label, OcrLineLabel.methodStep);
      expect(result.texts[0], 'until al dente');
    });

    test('multiple continuations merge into one step', () {
      final result = LabelCorrector.correct(
        lineTexts: ['Preheat oven to', '180°C and', 'line with baking paper'],
        features: [
          features(blockIndex: 3, wordCount: 3),
          features(blockIndex: 3, wordCount: 1),
          features(blockIndex: 3, wordCount: 4),
        ],
        rawLabels: [
          label(OcrLineLabel.methodStep),
          label(OcrLineLabel.methodContinuation),
          label(OcrLineLabel.methodContinuation),
        ],
      );
      expect(result.texts.length, 1);
      expect(
        result.texts[0],
        'Preheat oven to 180°C and line with baking paper',
      );
    });

    test('no change when all labels are already correct', () {
      final result = LabelCorrector.correct(
        lineTexts: ['Pancakes', '1 cup flour', 'Mix and cook'],
        features: [
          features(blockIndex: 0, wordCount: 1),
          features(blockIndex: 2, wordCount: 3),
          features(blockIndex: 4, wordCount: 3),
        ],
        rawLabels: [
          label(OcrLineLabel.title),
          label(OcrLineLabel.ingredient),
          label(OcrLineLabel.methodStep),
        ],
      );
      expect(result.labels.length, 3);
      expect(result.labels[0].label, OcrLineLabel.title);
      expect(result.labels[1].label, OcrLineLabel.ingredient);
      expect(result.labels[2].label, OcrLineLabel.methodStep);
      expect(result.texts[2], 'Mix and cook');
    });
  });
}
