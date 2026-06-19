import 'dart:convert';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pantry/core/llm/llm_client.dart';
import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/features/settings/settings_screen.dart';
import '../models/recipe_draft.dart';
import 'ocr_text_parser.dart';

class OcrException implements Exception {
  final String message;
  const OcrException(this.message);
  @override
  String toString() => message;
}

class LlmParseException implements Exception {
  final String message;
  const LlmParseException(this.message);
  @override
  String toString() => message;
}

const _systemPrompt =
    '''You are a recipe extraction assistant. You will receive raw OCR text and a pre-parsed structure as hints. Clean up errors, fill in missing fields, and return ONLY valid JSON — no markdown fences, no explanation.

JSON format:
{
  "name": "string or null",
  "servings": integer or null,
  "steps": ["step one text", "step two text"],
  "ingredients": [
    { "qty": number or null, "unit": "string or null", "name": "string", "notes": "string or null" }
  ]
}

Rules:
- Use the raw text as the source of truth; treat pre-parsed hints as guidance only
- "name" is the recipe title
- "servings" is a whole number or null
- "steps" is an ordered list of instruction steps — each step is a separate string
- "ingredients" must always be an array, even if empty
- "notes" captures modifiers like "finely chopped", "at room temperature", "sifted"''';

class RecipeOcrService {
  Future<String> extractText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final recogniser = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognised = await recogniser.processImage(inputImage);
      final text = recognised.text.trim();
      if (text.isEmpty) {
        throw const OcrException(
            'No text could be extracted from the image. Try a clearer photo.');
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

  Future<RecipeDraft> structureRecipe(
      String rawText, LlmConfig config) async {
    final prestructured = _prestructure(rawText);
    return _cleanupWithLlm(prestructured, config);
  }

  PrestructuredRecipe _prestructure(String rawText) {
    return OcrTextParser.parse(rawText);
  }

  Future<RecipeDraft> _cleanupWithLlm(
      PrestructuredRecipe prestructured, LlmConfig config) async {
    final hintsJson = const JsonEncoder.withIndent('  ').convert(
      prestructured.toJson()..remove('rawText'),
    );

    final userMessage = 'RAW OCR TEXT:\n'
        '${prestructured.rawText}\n\n'
        'PRE-PARSED HINTS:\n'
        '$hintsJson';

    late String content;
    try {
      content = await LlmClient.complete(_systemPrompt, userMessage, config);
    } catch (e) {
      throw LlmParseException(e.toString());
    }

    try {
      final cleaned = content
          .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*', multiLine: true), '')
          .trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final draft = RecipeDraft.fromJson(json);
      return RecipeDraft(
        name: draft.name,
        servings: draft.servings,
        steps: draft.steps,
        ingredients: draft.ingredients.map((ing) {
          final parsed = UnitRegistry.parse(ing.unit);
          return IngredientDraft(
            qty: ing.qty,
            unit: parsed?.id ?? ing.unit,
            name: ing.name,
            notes: ing.notes,
          );
        }).toList(),
      );
    } catch (e) {
      throw LlmParseException('Failed to parse LLM response: $e');
    }
  }
}
