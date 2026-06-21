import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'package:pantry/core/ingredients/ingredient_name_parser.dart';
import 'package:pantry/core/units/unit_system.dart';
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

  IngredientDraft _parseIngredientString(String s) {
    s = s.trim();

    double? qty;
    String remaining = s;

    // Match leading number: mixed "1 1/2", fraction "1/2", or decimal/int "2.5"
    final numPattern = RegExp(
        r'^(\d+(?:\.\d+)?)\s+(\d+)/(\d+)|'
        r'^(\d+)/(\d+)|'
        r'^(\d+(?:\.\d+)?)');
    final numMatch = numPattern.firstMatch(s);
    if (numMatch != null) {
      if (numMatch.group(1) != null) {
        final whole = double.parse(numMatch.group(1)!);
        final n = double.parse(numMatch.group(2)!);
        final d = double.parse(numMatch.group(3)!);
        qty = whole + n / d;
      } else if (numMatch.group(4) != null) {
        qty = double.parse(numMatch.group(4)!) /
            double.parse(numMatch.group(5)!);
      } else {
        qty = double.tryParse(numMatch.group(6)!);
      }
      remaining = s.substring(numMatch.end).trim();

      // Strip range upper bound: "1 - 1.5" → take lower bound, drop "- 1.5"
      remaining = remaining
          .replaceFirst(
              RegExp(r'^[-–—]\s*\d+(?:\.\d+)?(?:\s+\d+/\d+)?\s*'), '')
          .trim();
    }

    // Strip inline unit conversion alternatives: "120g / 4oz" or "120g/4oz" → "120g"
    // Right side must start with a digit/fraction; preserves word/word slashes.
    remaining = remaining
        .replaceAll(
          RegExp(
              r'\s*/\s*(?=[¼½¾⅓⅔⅛⅜⅝⅞\d])[\d¼½¾⅓⅔⅛⅜⅝⅞][^\s,()]*(?:\s+[a-zA-Z]+)?'),
          '',
        )
        .trim();

    Unit? unit;
    String name = remaining;

    if (remaining.isNotEmpty) {
      final words = remaining.split(RegExp(r'\s+'));
      if (words.length >= 2) {
        final parsed = UnitRegistry.parse('${words[0]} ${words[1]}');
        if (parsed != null) {
          unit = parsed;
          name = words.sublist(2).join(' ');
        }
      }
      if (unit == null) {
        final parsed = UnitRegistry.parse(words[0]);
        if (parsed != null) {
          unit = parsed;
          name = words.sublist(1).join(' ');
        }
      }
    }

    // Extract all parenthetical notes: "chicken (skinless) (500g)" →
    // name="chicken", notes="skinless, 500g"
    final notesParts = <String>[];
    var iterName = name;
    while (true) {
      final m =
          RegExp(r'^(.*?)\s*\(([^)]+)\)\s*(.*)$').firstMatch(iterName);
      if (m == null) break;
      notesParts.add(m.group(2)!.trim());
      iterName = [m.group(1)!.trim(), m.group(3)!.trim()]
          .where((p) => p.isNotEmpty)
          .join(' ');
    }
    name = iterName;
    String? notes = notesParts.isNotEmpty ? notesParts.join(', ') : null;

    // Split prep notes from ingredient name (heuristic: comma or known prep words).
    // Only applies when notes aren't already populated from parentheticals.
    if (notes == null) {
      final split = IngredientNameParser.splitHeuristic(name);
      if (split.notes != null) {
        name = split.name;
        notes = split.notes;
      }
    }

    // Detect "or" alternatives: "beer or beef stock" → primary + alternatives.
    // Also handles word/word slash: "beer/wine" (right side has no leading digit).
    final alternatives = <IngredientDraft>[];
    if (name.contains(' or ')) {
      final parts = name.split(' or ');
      name = parts.first.trim();
      for (final alt in parts.skip(1)) {
        if (alt.trim().isNotEmpty) {
          alternatives.add(_parseAlternative(alt.trim(), qty, unit?.id));
        }
      }
    } else {
      final slashIdx = name.indexOf('/');
      if (slashIdx > 0) {
        final left = name.substring(0, slashIdx).trim();
        final right = name.substring(slashIdx + 1).trim();
        // Word/word slash = alternative (digit-starting right side was already stripped above).
        if (right.isNotEmpty &&
            left.isNotEmpty &&
            !RegExp(r'^[\d¼½¾⅓⅔⅛⅜⅝⅞]').hasMatch(right)) {
          name = left;
          alternatives.add(_parseAlternative(right, qty, unit?.id));
        }
      }
    }

    return IngredientDraft(
      qty: qty,
      unit: unit?.id,
      name: name.isEmpty ? s : name,
      notes: notes,
      alternatives: alternatives,
    );
  }

  /// Parses an alternative ingredient string, inheriting qty/unit from the
  /// primary when the alternative has none of its own.
  IngredientDraft _parseAlternative(String raw, double? primaryQty, String? primaryUnit) {
    final numPattern = RegExp(
        r'^(\d+(?:\.\d+)?)\s+(\d+)/(\d+)|'
        r'^(\d+)/(\d+)|'
        r'^(\d+(?:\.\d+)?)');
    final numMatch = numPattern.firstMatch(raw);
    double? altQty;
    String remaining = raw;

    if (numMatch != null) {
      if (numMatch.group(1) != null) {
        altQty = double.parse(numMatch.group(1)!) +
            double.parse(numMatch.group(2)!) / double.parse(numMatch.group(3)!);
      } else if (numMatch.group(4) != null) {
        altQty = double.parse(numMatch.group(4)!) / double.parse(numMatch.group(5)!);
      } else {
        altQty = double.tryParse(numMatch.group(6)!);
      }
      remaining = raw.substring(numMatch.end).trim();
    }

    Unit? altUnit;
    String altName = remaining;
    if (remaining.isNotEmpty) {
      final words = remaining.split(RegExp(r'\s+'));
      if (words.length >= 2) {
        final parsed = UnitRegistry.parse('${words[0]} ${words[1]}');
        if (parsed != null) {
          altUnit = parsed;
          altName = words.sublist(2).join(' ');
        }
      }
      if (altUnit == null) {
        final parsed = UnitRegistry.parse(words[0]);
        if (parsed != null) {
          altUnit = parsed;
          altName = words.sublist(1).join(' ');
        }
      }
    }

    final split = IngredientNameParser.splitHeuristic(altName);

    return IngredientDraft(
      qty: altQty ?? primaryQty,
      unit: altUnit?.id ?? primaryUnit,
      name: split.name.isEmpty ? raw : split.name,
      notes: split.notes,
    );
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
