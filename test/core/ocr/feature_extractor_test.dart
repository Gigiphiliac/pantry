import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/core/ocr/feature_extractor.dart';
import 'package:pantry/core/ocr/recipe_ocr_input.dart';

/// Shorthand: build a [RecipeOcrLine] with only the fields this test cares about.
RecipeOcrLine _line({
  required String text,
  required int blockIndex,
  required int linesInBlock,
  required int lineIndexInBlock,
  Rect boundingBox = const Rect.fromLTWH(0, 0, 100, 20),
  double? confidence,
}) => RecipeOcrLine(
  text: text,
  boundingBox: boundingBox,
  confidence: confidence,
  blockIndex: blockIndex,
  linesInBlock: linesInBlock,
  lineIndexInBlock: lineIndexInBlock,
);

void main() {
  late FeatureExtractor extractor;

  setUp(() {
    extractor = FeatureExtractor();
  });

  group('extract()', () {
    test('returns empty for no lines', () {
      final input = RecipeOcrInput(
        rawText: '',
        lines: const [],
        imageSize: const Size(800, 600),
      );
      expect(extractor.extract(input), isEmpty);
    });

    test('returns one feature vector per line', () {
      final input = RecipeOcrInput(
        rawText: 'Hello\nWorld',
        lines: [
          _line(
            text: 'Hello',
            blockIndex: 0,
            linesInBlock: 2,
            lineIndexInBlock: 0,
          ),
          _line(
            text: 'World',
            blockIndex: 0,
            linesInBlock: 2,
            lineIndexInBlock: 1,
          ),
        ],
        imageSize: const Size(800, 600),
      );
      final result = extractor.extract(input);
      expect(result.length, 2);
      expect(result[0].length, 20);
      expect(result[1].length, 20);
    });

    group('spatial features', () {
      test('relative_top and relative_left are normalised by image size', () {
        final input = RecipeOcrInput(
          rawText: 'Title',
          lines: [
            _line(
              text: 'Title',
              boundingBox: const Rect.fromLTWH(100, 60, 200, 40),
              blockIndex: 0,
              linesInBlock: 1,
              lineIndexInBlock: 0,
            ),
          ],
          imageSize: const Size(800, 600),
        );
        final f = extractor.extract(input).single;
        // 60 / 600
        expect(f[0], closeTo(0.1, 0.001));
        // 100 / 800
        expect(f[1], closeTo(0.125, 0.001));
        // 200 / 800
        expect(f[2], closeTo(0.25, 0.001));
        // 40 / 600
        expect(f[3], closeTo(0.0667, 0.001));
      });

      test('relative_font_size compares box height to average line height', () {
        // Two lines with different heights: avg = 30
        final input = RecipeOcrInput(
          rawText: 'Big\nSmall',
          lines: [
            _line(
              text: 'Big',
              boundingBox: const Rect.fromLTWH(0, 0, 100, 40),
              blockIndex: 0,
              linesInBlock: 2,
              lineIndexInBlock: 0,
            ),
            _line(
              text: 'Small',
              boundingBox: const Rect.fromLTWH(0, 40, 80, 20),
              blockIndex: 0,
              linesInBlock: 2,
              lineIndexInBlock: 1,
            ),
          ],
          imageSize: const Size(400, 200),
        );
        final fs = extractor.extract(input);
        // First line: 40 / 30 ≈ 1.333
        expect(fs[0][4], closeTo(1.333, 0.001));
        // Second line: 20 / 30 ≈ 0.667
        expect(fs[1][4], closeTo(0.667, 0.001));
      });
    });

    group('block membership', () {
      test('block_index, lines_in_block and line_index are passed through', () {
        final f = extractor
            .extract(
              RecipeOcrInput(
                rawText: 'A\nB\nC',
                lines: [
                  _line(
                    text: 'A',
                    blockIndex: 2,
                    linesInBlock: 3,
                    lineIndexInBlock: 1,
                  ),
                ],
                imageSize: const Size(100, 100),
              ),
            )
            .single;
        expect(f[5], 2.0); // block_index
        expect(f[6], 3.0); // lines_in_block
        expect(f[7], 1.0); // line_index_in_block
      });
    });

    group('text heuristic features', () {
      test('starts_with_digit', () {
        final input = RecipeOcrInput(
          rawText: '2 eggs',
          lines: [
            _line(
              text: '2 eggs',
              blockIndex: 0,
              linesInBlock: 1,
              lineIndexInBlock: 0,
            ),
          ],
          imageSize: const Size(100, 100),
        );
        expect(extractor.extract(input).single[8], 1.0);
      });

      test('starts_with_unicode_fraction', () {
        final input = RecipeOcrInput(
          rawText: '½ cup flour',
          lines: [
            _line(
              text: '½ cup flour',
              blockIndex: 0,
              linesInBlock: 1,
              lineIndexInBlock: 0,
            ),
          ],
          imageSize: const Size(100, 100),
        );
        expect(extractor.extract(input).single[9], 1.0);
      });

      test('ends_with_colon', () {
        final input = RecipeOcrInput(
          rawText: 'Ingredients:',
          lines: [
            _line(
              text: 'Ingredients:',
              blockIndex: 0,
              linesInBlock: 1,
              lineIndexInBlock: 0,
            ),
          ],
          imageSize: const Size(100, 100),
        );
        expect(extractor.extract(input).single[10], 1.0);
      });

      test('word_count and char_count', () {
        final input = RecipeOcrInput(
          rawText: 'Boil pasta in salted water',
          lines: [
            _line(
              text: 'Boil pasta in salted water',
              blockIndex: 0,
              linesInBlock: 1,
              lineIndexInBlock: 0,
            ),
          ],
          imageSize: const Size(100, 100),
        );
        final f = extractor.extract(input).single;
        expect(f[11], 5.0); // word count
        expect(f[12], 26.0); // char count
      });

      test('starts_with_imperative_verb', () {
        final f = extractor
            .extract(
              RecipeOcrInput(
                rawText: 'Mix well',
                lines: [
                  _line(
                    text: 'Mix well',
                    blockIndex: 0,
                    linesInBlock: 1,
                    lineIndexInBlock: 0,
                  ),
                ],
                imageSize: const Size(100, 100),
              ),
            )
            .single;
        expect(f[13], 1.0);
      });

      test('contains_number', () {
        final f = extractor
            .extract(
              RecipeOcrInput(
                rawText: 'Bake at 180°C for 30 min',
                lines: [
                  _line(
                    text: 'Bake at 180°C for 30 min',
                    blockIndex: 0,
                    linesInBlock: 1,
                    lineIndexInBlock: 0,
                  ),
                ],
                imageSize: const Size(100, 100),
              ),
            )
            .single;
        expect(f[14], 1.0);
      });

      test('ends_with_punctuation', () {
        final f = extractor
            .extract(
              RecipeOcrInput(
                rawText: 'A quick recipe.',
                lines: [
                  _line(
                    text: 'A quick recipe.',
                    blockIndex: 0,
                    linesInBlock: 1,
                    lineIndexInBlock: 0,
                  ),
                ],
                imageSize: const Size(100, 100),
              ),
            )
            .single;
        expect(f[15], 1.0);
      });

      test('has_mixed_case for title-like lines', () {
        final f = extractor
            .extract(
              RecipeOcrInput(
                rawText: 'Fluffy Pancakes',
                lines: [
                  _line(
                    text: 'Fluffy Pancakes',
                    blockIndex: 0,
                    linesInBlock: 1,
                    lineIndexInBlock: 0,
                  ),
                ],
                imageSize: const Size(100, 100),
              ),
            )
            .single;
        expect(f[16], 1.0);
      });

      test('no mixed case for lowercase line', () {
        final f = extractor
            .extract(
              RecipeOcrInput(
                rawText: 'flour',
                lines: [
                  _line(
                    text: 'flour',
                    blockIndex: 0,
                    linesInBlock: 1,
                    lineIndexInBlock: 0,
                  ),
                ],
                imageSize: const Size(100, 100),
              ),
            )
            .single;
        expect(f[16], 0.0);
      });
    });

    test('confidence passthrough (Android)', () {
      final f = extractor
          .extract(
            RecipeOcrInput(
              rawText: 'Test',
              lines: [
                _line(
                  text: 'Test',
                  confidence: 0.85,
                  blockIndex: 0,
                  linesInBlock: 1,
                  lineIndexInBlock: 0,
                ),
              ],
              imageSize: const Size(100, 100),
            ),
          )
          .single;
      expect(f[17], 0.85);
    });

    test('confidence defaults to 1.0 on iOS (null confidence)', () {
      final f = extractor
          .extract(
            RecipeOcrInput(
              rawText: 'Test',
              lines: [
                _line(
                  text: 'Test',
                  confidence: null,
                  blockIndex: 0,
                  linesInBlock: 1,
                  lineIndexInBlock: 0,
                ),
              ],
              imageSize: const Size(100, 100),
            ),
          )
          .single;
      expect(f[17], 1.0);
    });

    group('block position features', () {
      test('is_first_in_block', () {
        final f = extractor
            .extract(
              RecipeOcrInput(
                rawText: 'A',
                lines: [
                  _line(
                    text: 'A',
                    blockIndex: 0,
                    linesInBlock: 2,
                    lineIndexInBlock: 0,
                  ),
                ],
                imageSize: const Size(100, 100),
              ),
            )
            .single;
        expect(f[18], 1.0); // first
        expect(f[19], 0.0); // not last
      });

      test('is_last_in_block', () {
        final f = extractor
            .extract(
              RecipeOcrInput(
                rawText: 'C',
                lines: [
                  _line(
                    text: 'C',
                    blockIndex: 0,
                    linesInBlock: 3,
                    lineIndexInBlock: 2,
                  ),
                ],
                imageSize: const Size(100, 100),
              ),
            )
            .single;
        expect(f[18], 0.0); // not first
        expect(f[19], 1.0); // last
      });
    });
  });
}
