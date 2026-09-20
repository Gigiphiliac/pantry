import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'package:pantry/core/ingredients/ingredient_parser.dart';
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
      response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; Pantry/1.0)',
        'Accept': 'text/html,application/xhtml+xml',
      }).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw UrlImportException('Could not fetch URL: $e');
    }
    if (response.statusCode != 200) {
      throw UrlImportException(
          'Site returned ${response.statusCode} — check the URL');
    }
    return response.body;
  }

  // Returns the raw schema.org Recipe map, or throws if none found.
  Map<String, dynamic> _extractSchemaOrg(String html) {
    final document = html_parser.parse(html);
    final scripts =
        document.querySelectorAll('script[type="application/ld+json"]');
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
        'Try copying the recipe text and using the camera import instead.');
  }

  // Converts a raw schema.org Recipe map into a RecipeDraft.
  // Missing or malformed fields produce null/empty values rather than exceptions.
  RecipeDraft _normaliseFields(Map<String, dynamic> r) {
    final (sections, unsectioned) =
        _parseIngredientListWithSections(r['recipeIngredient']);
    return RecipeDraft(
      name: r['name'] as String?,
      servings: _parseServings(r['recipeYield']),
      sections: sections,
      ingredients: unsectioned,
      steps: _parseInstructions(r['recipeInstructions']),
    );
  }

  // Scans the schema.org recipeIngredient array for section header strings
  // (lines ending with ":" that have no leading quantity) and groups following
  // ingredient strings under that section.
  (List<RecipeSectionDraft>, List<IngredientDraft>) _parseIngredientListWithSections(
      dynamic raw) {
    if (raw is! List) return (const [], const []);

    final sections = <RecipeSectionDraft>[];
    final unsectioned = <IngredientDraft>[];
    String? currentSectionName;
    final currentItems = <IngredientDraft>[];
    final headerPattern = RegExp(r'^[^0-9¼½¾⅓⅔⅛⅜⅝⅞].*:$');

    for (final item in raw.whereType<String>()) {
      final s = item.trim();
      if (s.isEmpty) continue;
      if (headerPattern.hasMatch(s)) {
        // Flush previous group
        if (currentSectionName != null && currentItems.isNotEmpty) {
          sections.add(RecipeSectionDraft(
            name: currentSectionName.replaceFirst(RegExp(r':$'), '').trim(),
            ingredients: List.of(currentItems),
          ));
        } else if (currentSectionName == null && currentItems.isNotEmpty) {
          unsectioned.addAll(currentItems);
        }
        currentItems.clear();
        currentSectionName = s;
      } else {
        currentItems.add(_parseIngredientString(s));
      }
    }

    // Flush final group
    if (currentSectionName != null && currentItems.isNotEmpty) {
      sections.add(RecipeSectionDraft(
        name: currentSectionName.replaceFirst(RegExp(r':$'), '').trim(),
        ingredients: List.of(currentItems),
      ));
    } else {
      unsectioned.addAll(currentItems);
    }

    return (sections, unsectioned);
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
      return type
          .any((t) => t is String && (t == 'Recipe' || t.endsWith('/Recipe')));
    }
    return false;
  }

  int? _parseServings(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is List && value.isNotEmpty) return _parseServings(value.first);
    final match = RegExp(r'\d+').firstMatch(value.toString());
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  /// Delegate to the deterministic [IngredientParser].
  IngredientDraft _parseIngredientString(String s) =>
      IngredientParser.parse(s);

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
