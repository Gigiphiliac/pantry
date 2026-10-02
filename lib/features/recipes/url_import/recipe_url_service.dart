import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'package:pantry/core/recipes/recipe_text_parser.dart';
import 'package:pantry/features/recipes/models/recipe_draft.dart';

class UrlImportException implements Exception {
  final String message;
  const UrlImportException(this.message);
  @override
  String toString() => message;
}

class RecipeUrlService {
  Future<RecipeDraft> fetchAndParse(String url) async {
    final html = await _fetchHtml(url);
    final schemaMap = _extractSchemaOrg(html);
    return _normaliseFields(schemaMap);
  }

  Future<String> _fetchHtml(String url) async {
    late http.Response response;
    try {
      response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; Pantry/1.0)',
              'Accept': 'text/html,application/xhtml+xml',
            },
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw UrlImportException('Could not fetch URL: $e');
    }
    if (response.statusCode != 200) {
      throw UrlImportException(
        'Site returned ${response.statusCode}, please check the URL',
      );
    }
    return response.body;
  }

  // Returns the raw schema.org Recipe map, or throws if none found.
  Map<String, dynamic> _extractSchemaOrg(String html) {
    final document = html_parser.parse(html);
    final scripts = document.querySelectorAll(
      'script[type="application/ld+json"]',
    );
    for (final script in scripts) {
      try {
        final raw = script.text.trim();
        if (raw.isEmpty) continue;
        final data = jsonDecode(raw);
        final recipe = _findRecipeNode(data);
        if (recipe != null) return recipe;
      } catch (_) {
        continue;
      }
    }
    throw const UrlImportException(
      "This site doesn't support structured recipe data. "
      'Try copying the recipe text and using the camera import instead.',
    );
  }

  // Converts a raw schema.org Recipe map into a RecipeDraft.
  // Missing or malformed fields produce null/empty values rather than exceptions.
  RecipeDraft _normaliseFields(Map<String, dynamic> r) {
    final ingredientStrings = r['recipeIngredient'];
    final (sections, unsectioned) = ingredientStrings is List
        ? RecipeTextParser.parseIngredientLines(
            ingredientStrings.whereType<String>().toList(),
          )
        : (const <RecipeSectionDraft>[], const <IngredientDraft>[]);

    return RecipeDraft(
      name: r['name'] as String?,
      servings: RecipeTextParser.parseServings(r['recipeYield']),
      sections: sections,
      ingredients: unsectioned,
      steps: _parseInstructions(r['recipeInstructions']),
      notes: _extractNotes(r),
      nutrition: _extractNutrition(r),
      prepTime: _isoDuration(r['prepTime'] as String?),
      cookTime: _isoDuration(r['cookTime'] as String?),
      totalTime: _isoDuration(r['totalTime'] as String?),
    );
  }

  /// Extract a notes‑like field from JSON-LD.
  /// Many sites embed notes in the description, or in an extension field.
  String? _extractNotes(Map<String, dynamic> r) {
    final desc = r['description'] as String?;
    if (desc != null && desc.trim().isNotEmpty) return desc.trim();
    return null;
  }

  /// Convert schema.org nutrition object into a list of key-value pairs.
  /// Schema.org NutritionInformation uses fields like:
  ///   calories, proteinContent, fatContent, carbohydrateContent, etc.
  List<NutritionDraft>? _extractNutrition(Map<String, dynamic> r) {
    final raw = r['nutrition'];
    if (raw is! Map) return null;
    final entries = <NutritionDraft>[];

    // Known schema.org nutrition field names
    const nutritionFields = [
      'calories', 'proteinContent', 'fatContent', 'carbohydrateContent',
      'fiberContent', 'sugarContent', 'sodiumContent', 'cholesterolContent',
      'saturatedFatContent', 'transFatContent', 'unsaturatedFatContent',
      'servingSize',
    ];

    for (final field in nutritionFields) {
      final value = raw[field];
      if (value is String && value.trim().isNotEmpty) {
        entries.add(NutritionDraft(label: field, value: value.trim()));
      } else if (value is num) {
        entries.add(NutritionDraft(label: field, value: value.toString()));
      }
    }

    // Also pick up any additional non-standard fields
    for (final entry in raw.entries) {
      final key = entry.key;
      if (nutritionFields.contains(key)) continue;
      final value = entry.value;
      if (value is String && value.trim().isNotEmpty) {
        entries.add(NutritionDraft(label: key, value: value.trim()));
      } else if (value is num) {
        entries.add(NutritionDraft(label: key, value: value.toString()));
      }
    }

    return entries.isNotEmpty ? entries : null;
  }

  /// Pass‑through for ISO 8601 duration strings (e.g. "PT15M").
  /// Returns the raw string; display logic parses it for human-readable form.
  String? _isoDuration(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic>? _findRecipeNode(dynamic data) {
    if (data is List) {
      for (final item in data) {
        final found = _findRecipeNode(item);
        if (found != null) return found;
      }
      return null;
    }
    if (data is! Map<String, dynamic>) return null;
    if (_isRecipeType(data['@type'])) return data;
    final graph = data['@graph'];
    if (graph != null) return _findRecipeNode(graph);
    return null;
  }

  bool _isRecipeType(dynamic type) {
    if (type is String) return type == 'Recipe' || type.endsWith('/Recipe');
    if (type is List) {
      return type.any(
        (t) => t is String && (t == 'Recipe' || t.endsWith('/Recipe')),
      );
    }
    return false;
  }

  // Returns each instruction as a separate string.
  // Schema.org HowToStep lists produce one element per step.
  List<String> _parseInstructions(dynamic raw) {
    if (raw == null) return const [];
    if (raw is String) {
      final t = raw.trim();
      return t.isEmpty
          ? const []
          : t
                .split('\n')
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .toList();
    }
    if (raw is List) {
      final steps = <String>[];
      for (final item in raw) {
        if (item is String) {
          final t = item.trim();
          if (t.isNotEmpty) steps.add(t);
        } else if (item is Map) {
          final text = item['text'] as String?;
          if (text != null && text.isNotEmpty) {
            steps.add(text.trim());
          } else {
            // HowToSection with nested itemListElement
            final sub = item['itemListElement'];
            if (sub is List) {
              for (final step in sub) {
                final t = step is Map ? step['text'] as String? : null;
                if (t != null && t.isNotEmpty) steps.add(t.trim());
              }
            }
          }
        }
      }
      return steps;
    }
    return const [];
  }
}
