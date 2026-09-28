import 'package:pantry/core/ocr/recipe_ocr_input.dart';
import 'package:pantry/core/recipes/recipe_text_parser.dart';

/// Extracts a fixed-length, normalised feature vector for each OCR line.
///
/// Features are derived from spatial geometry and text heuristics so the
/// classifier can learn layout patterns (titles are bigger and centred,
/// ingredients are short and indented, etc.) without needing raw pixel or
/// coordinate data.
///
/// The feature order must match the order used during model training. See
/// `training/feature_config.json` for the canonical feature list.
class FeatureExtractor {
  FeatureExtractor();

  /// Number of features produced per line.
  static const int featureCount = 20;

  /// Feature names in the order they appear in the output vector.
  /// Must match `training/feature_config.json`.
  static const List<String> featureNames = [
    'relative_top',
    'relative_left',
    'relative_width',
    'relative_height',
    'relative_font_size',
    'block_index',
    'lines_in_block',
    'line_index_in_block',
    'starts_with_digit',
    'starts_with_unicode_fraction',
    'ends_with_colon',
    'word_count',
    'char_count',
    'starts_with_imperative_verb',
    'contains_number',
    'ends_with_punctuation',
    'has_mixed_case',
    'confidence',
    'is_first_in_block',
    'is_last_in_block',
  ];

  /// Compute a normalised feature vector for every line in [input].
  ///
  /// Returns a list parallel to [input.lines]. Each inner list contains
  /// exactly [featureCount] doubles.
  List<List<double>> extract(RecipeOcrInput input) {
    final result = <List<double>>[];

    // Pre-compute image dimensions once
    final imgW = input.imageSize.width;
    final imgH = input.imageSize.height;

    // Average line height for relative font-size computation
    double avgLineHeight = 0;
    for (final line in input.lines) {
      avgLineHeight += line.boundingBox.height;
    }
    if (input.lines.isNotEmpty) {
      avgLineHeight /= input.lines.length;
    }

    for (final line in input.lines) {
      result.add(_lineFeatures(line, imgW, imgH, avgLineHeight));
    }

    return result;
  }

  List<double> _lineFeatures(
    RecipeOcrLine line,
    double imgW,
    double imgH,
    double avgLineHeight,
  ) {
    final box = line.boundingBox;
    final text = line.text;

    // ── Spatial features (normalised to image dimensions) ──────────────
    final relativeTop = box.top / imgH;
    final relativeLeft = box.left / imgW;
    final relativeWidth = box.width / imgW;
    final relativeHeight = box.height / imgH;
    final relativeFontSize = avgLineHeight > 0
        ? box.height / avgLineHeight
        : 1.0;

    // ── Block membership ───────────────────────────────────────────────
    final blockIdx = line.blockIndex.toDouble();
    final linesInBlock = line.linesInBlock.toDouble();
    final lineIdxInBlock = line.lineIndexInBlock.toDouble();

    // ── Text heuristics ────────────────────────────────────────────────
    final trimmed = text.trim();

    bool startsWithDigit =
        trimmed.isNotEmpty && RegExp(r'^[\d]').hasMatch(trimmed);

    bool startsWithFraction =
        trimmed.isNotEmpty && RegExp(r'^[¼½¾⅓⅔⅛⅜⅝⅞]').hasMatch(trimmed);

    bool endsWithColon = trimmed.endsWith(':');

    final words = trimmed.split(RegExp(r'\s+'));
    final wordCount = words.length.toDouble();
    final charCount = trimmed.length.toDouble();

    bool startsWithVerb =
        trimmed.isNotEmpty &&
        RecipeTextParser.imperativeVerbs.contains(words.first.toLowerCase());

    bool containsNumber = RegExp(r'\d').hasMatch(trimmed);

    bool endsWithPunctuation =
        trimmed.isNotEmpty && RegExp(r'[.!?]$').hasMatch(trimmed);

    // Mixed case: has both upper and lower chars (likely a title)
    bool hasMixedCase = _hasMixedCase(trimmed);

    // Confidence (Android only; default 1.0 on iOS)
    final confidence = line.confidence ?? 1.0;

    // Position within block
    final isFirstInBlock = line.lineIndexInBlock == 0 ? 1.0 : 0.0;
    final isLastInBlock = line.lineIndexInBlock == line.linesInBlock - 1
        ? 1.0
        : 0.0;

    return [
      relativeTop,
      relativeLeft,
      relativeWidth,
      relativeHeight,
      relativeFontSize,
      blockIdx,
      linesInBlock,
      lineIdxInBlock,
      startsWithDigit ? 1.0 : 0.0,
      startsWithFraction ? 1.0 : 0.0,
      endsWithColon ? 1.0 : 0.0,
      wordCount,
      charCount,
      startsWithVerb ? 1.0 : 0.0,
      containsNumber ? 1.0 : 0.0,
      endsWithPunctuation ? 1.0 : 0.0,
      hasMixedCase ? 1.0 : 0.0,
      confidence,
      isFirstInBlock,
      isLastInBlock,
    ];
  }

  /// Returns true if [s] contains at least one uppercase and one lowercase
  /// letter — a signal this might be a title rather than a lowercase
  /// ingredient or instruction line.
  bool _hasMixedCase(String s) {
    bool hasUpper = false;
    bool hasLower = false;
    for (final ch in s.runes) {
      final c = String.fromCharCode(ch);
      if (c.toUpperCase() == c && c.toLowerCase() != c) hasUpper = true;
      if (c.toLowerCase() == c && c.toUpperCase() != c) hasLower = true;
      if (hasUpper && hasLower) return true;
    }
    return false;
  }
}
