import 'dart:ui';

/// A single line from OCR output with its spatial metadata.
class RecipeOcrLine {
  /// The recognised text of this line.
  final String text;

  /// Bounding box of this line relative to the image.
  final Rect boundingBox;

  /// Confidence score (0–1). Only available on Android; null on iOS.
  final double? confidence;

  /// Which TextBlock (paragraph group) this line belongs to.
  final int blockIndex;

  /// How many lines are in the parent block.
  final int linesInBlock;

  /// This line's position within its block (0-based).
  final int lineIndexInBlock;

  const RecipeOcrLine({
    required this.text,
    required this.boundingBox,
    this.confidence,
    required this.blockIndex,
    required this.linesInBlock,
    required this.lineIndexInBlock,
  });
}

/// Enriched OCR output: flat text plus per-line spatial details.
///
/// [rawText] preserves the full flat string for the heuristic fallback path.
/// [lines] provides structured line-level data for the classifier path.
class RecipeOcrInput {
  /// Full flat text (same as [RecognizedText.text]).
  final String rawText;

  /// Per-line data with bounding boxes and block membership.
  final List<RecipeOcrLine> lines;

  /// Dimensions of the source image in pixels.
  final Size imageSize;

  const RecipeOcrInput({
    required this.rawText,
    required this.lines,
    required this.imageSize,
  });
}