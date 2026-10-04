import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pantry/core/ocr/feature_extractor.dart';
import 'package:pantry/core/ocr/label_corrector.dart';
import 'package:pantry/core/ocr/onnx_classifier.dart';
import 'package:pantry/core/ocr/recipe_ocr_input.dart';
import '../models/recipe_draft.dart';
import 'ocr_recipe_parser.dart';
import 'zone_assembler.dart';

class OcrException implements Exception {
  final String message;
  const OcrException(this.message);
  @override
  String toString() => message;
}

class RecipeOcrService {
  /// Run ML Kit OCR on [image] and return the raw recognised text.
  Future<String> extractText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final recogniser = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognised = await recogniser.processImage(inputImage);
      final text = recognised.text.trim();
      if (text.isEmpty) {
        throw const OcrException(
          'No text could be extracted from the image. Try a clearer photo.',
        );
      }
      return text;
    } on OcrException {
      rethrow;
    } catch (e) {
      throw OcrException('Text extraction failed: $e');
    } finally {
      recogniser.close();
    }
  }

  /// Run ML Kit OCR and return enriched input with per-line spatial data.
  Future<RecipeOcrInput> extractDetailed(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final recogniser = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognised = await recogniser.processImage(inputImage);
      final text = recognised.text.trim();
      if (text.isEmpty) {
        throw const OcrException(
          'No text could be extracted from the image. Try a clearer photo.',
        );
      }

      final lines = <RecipeOcrLine>[];
      for (var bi = 0; bi < recognised.blocks.length; bi++) {
        final block = recognised.blocks[bi];
        for (var li = 0; li < block.lines.length; li++) {
          final line = block.lines[li];
          lines.add(
            RecipeOcrLine(
              text: line.text,
              boundingBox: line.boundingBox,
              confidence: line.confidence,
              blockIndex: bi,
              linesInBlock: block.lines.length,
              lineIndexInBlock: li,
            ),
          );
        }
      }

      double maxW = 0, maxH = 0;
      for (final block in recognised.blocks) {
        final r = block.boundingBox;
        if (r.right > maxW) maxW = r.right;
        if (r.bottom > maxH) maxH = r.bottom;
      }

      return RecipeOcrInput(
        rawText: text,
        lines: lines,
        imageSize: Size(maxW, maxH),
      );
    } on OcrException {
      rethrow;
    } catch (e) {
      throw OcrException('Text extraction failed: $e');
    } finally {
      recogniser.close();
    }
  }

  /// Parse [input] using the classifier pipeline.
  Future<({RecipeDraft draft, bool usedStub})> parseWithClassifier(
    RecipeOcrInput input,
    OnnxClassifier classifier,
  ) async {
    final extractor = FeatureExtractor();
    final features = extractor.extract(input);
    final lineTexts = input.lines.map((l) => l.text).toList();

    final result = await classifier.classify(features, lineTexts);

    // Correct common misclassifications before assembling
    final corrected = LabelCorrector.correct(
      lineTexts: lineTexts,
      features: features,
      rawLabels: result.lineLabels,
    );

    final assembled = ZoneAssembler.assemble(corrected.texts, corrected.labels);
    final draft = ZoneAssembler.toRecipeDraft(assembled);

    return (draft: draft, usedStub: result.usedStub);
  }

  /// Deterministic fallback: parse raw text into a [RecipeDraft].
  RecipeDraft parseRaw(String rawText) {
    return OcrRecipeParser.parse(rawText);
  }
}
