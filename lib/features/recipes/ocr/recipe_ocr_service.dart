import 'dart:convert';
import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:pantry/features/settings/settings_screen.dart';
import '../models/recipe_draft.dart';

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

const _systemPrompt = '''You are a recipe extraction assistant. Extract the recipe from the provided OCR text and return ONLY valid JSON — no markdown fences, no explanation.

JSON format:
{
  "name": "string or null",
  "servings": integer or null,
  "instructions": "string or null",
  "ingredients": [
    { "qty": number or null, "unit": "string or null", "name": "string", "notes": "string or null" }
  ]
}

Rules:
- "name" is the recipe title
- "servings" is a whole number or null
- "ingredients" must always be an array, even if empty
- "notes" captures modifiers like "finely chopped", "at room temperature", "sifted"
- "instructions" is the full method as a single string with newlines between steps''';

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
    final uri = Uri.parse('${config.endpoint}/chat/completions');

    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      if (config.apiKey.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer ${config.apiKey}',
    };

    final body = jsonEncode({
      'model': config.model.isNotEmpty ? config.model : 'llama3.2',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': rawText},
      ],
      'temperature': 0.1,
    });

    late http.Response response;
    try {
      response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 90));
    } catch (e) {
      throw LlmParseException('Could not reach LLM endpoint: $e');
    }

    if (response.statusCode != 200) {
      throw LlmParseException(
          'LLM returned status ${response.statusCode}: ${response.body}');
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          decoded['choices'][0]['message']['content'] as String;

      // Strip potential markdown code fences
      final cleaned = content
          .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*', multiLine: true), '')
          .trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return RecipeDraft.fromJson(json);
    } catch (e) {
      throw LlmParseException('Failed to parse LLM response: $e');
    }
  }
}
