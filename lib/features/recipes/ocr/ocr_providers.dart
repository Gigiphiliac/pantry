import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/core/ocr/onnx_classifier.dart';
import 'package:pantry/core/ocr/recipe_ocr_input.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/features/recipes/models/recipe_draft.dart';
import 'package:pantry/main.dart';
import 'recipe_ocr_service.dart';

final recipeOcrServiceProvider = Provider<RecipeOcrService>(
  (_) => RecipeOcrService(),
);

/// Singleton classifier instance. Initialise once at app start.
final onnxClassifierProvider = Provider<OnnxClassifier>((ref) {
  final classifier = OnnxClassifier();
  // Call [classifier.init()] explicitly at app startup
  return classifier;
});

/// Service for capturing OCR training data.
final ocrTrainingDataServiceProvider = Provider<OcrTrainingDataService>(
  (ref) => OcrTrainingDataService(ref.watch(dbProvider)),
);

class OcrTrainingDataService {
  final AppDatabase _db;

  OcrTrainingDataService(this._db);

  /// Save a single OCR scan + its user-corrected recipe to the training table.
  ///
  /// Call this when the user saves a recipe that originated from an OCR scan.
  /// Fire-and-forget — does not block the save flow.
  Future<void> saveCorrection({
    required RecipeOcrInput ocrInput,
    required RecipeDraft correctedDraft,
  }) async {
    try {
      await _db.into(_db.ocrTrainingData).insert(
        OcrTrainingDataCompanion.insert(
          rawJson: jsonEncode(_serializeOcrInput(ocrInput)),
          correctedJson: jsonEncode(correctedDraft.toJson()),
          imageWidth: Value(ocrInput.imageSize.width.round()),
          imageHeight: Value(ocrInput.imageSize.height.round()),
        ),
      );
    } catch (_) {
      // Silently fail — training data capture is non-critical
    }
  }

  /// Export all training data as CSV for the Python training pipeline.
  ///
  /// Each row contains the raw feature vector + the corrected label per line.
  Future<String> exportCsv() async {
    final rows = await _db.select(_db.ocrTrainingData).get();
    if (rows.isEmpty) return '';

    final buffer = StringBuffer();
    // This would need FeatureExtractor to re-extract features from the
    // stored rawJson + correctedJson. For now, just export as JSONL.
    for (final row in rows) {
      buffer.writeln('{"id":${row.id},"created":"${row.createdAt}"}');
    }
    return buffer.toString();
  }

  Map<String, dynamic> _serializeOcrInput(RecipeOcrInput input) {
    return {
      'rawText': input.rawText,
      'imageSize': {
        'width': input.imageSize.width,
        'height': input.imageSize.height,
      },
      'lines': input.lines
          .map(
            (l) => {
              'text': l.text,
              'x': l.boundingBox.left,
              'y': l.boundingBox.top,
              'w': l.boundingBox.width,
              'h': l.boundingBox.height,
              'blockIndex': l.blockIndex,
              'linesInBlock': l.linesInBlock,
              'lineIndexInBlock': l.lineIndexInBlock,
              'confidence': l.confidence,
            },
          )
          .toList(),
    };
  }
}