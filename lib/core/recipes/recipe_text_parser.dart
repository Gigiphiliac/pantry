import 'package:pantry/core/ingredients/ingredient_parser.dart';
import 'package:pantry/features/recipes/models/recipe_draft.dart';

/// Shared utilities for parsing raw recipe text into structured data.
///
/// Used by both the URL import pipeline (schema.org normalisation) and the
/// OCR pipeline (deterministic fallback from raw text).
class RecipeTextParser {
  // ── Section headers ───────────────────────────────────────────────────────

  /// Matches a line that looks like a section header within an ingredient list
  /// (e.g. "For the sauce:", "Dough:"). Lines ending with ":" that do NOT start
  /// with a quantity digit or Unicode fraction character.
  static final RegExp sectionHeaderPattern = RegExp(
    r'^[^0-9¼½¾⅓⅔⅛⅜⅝⅞].*:$',
  );

  // ── Zone-marker words for dual-pass segmentation ──────────────────────────

  /// Words that mark the start of the ingredients zone, matched case-insensitively
  /// at the start of a line, optionally followed by a colon.
  static const _ingredientsMarkers = {'ingredients', 'ingredient'};

  /// Words that mark the start of the method/directions zone.
  static const _methodMarkers = {
    'method',
    'directions',
    'instructions',
    'steps',
    'preparation',
    'procedure',
    'cooking',
  };

  // ── Zone segmentation ─────────────────────────────────────────────────────

  /// Splits raw OCR text into title, ingredient lines, and method lines.
  ///
  /// Uses a dual-pass approach:
  ///   1. Scan for zone marker words (Ingredients / Method etc.)
  ///   2. If found, split at those boundaries
  ///   3. If not found, fall back to heuristic (numbered lines = steps,
  ///      digit-starting lines = ingredients)
  static ({String? title, List<String> ingredientLines, List<String> methodLines})
  splitZones(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return (title: null, ingredientLines: const [], methodLines: const []);
    }

    // Find zone boundaries
    int? ingredientsStart;
    int? methodStart;

    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (_isZoneMarker(trimmed, _ingredientsMarkers)) {
        ingredientsStart ??= i;
      }
      if (_isZoneMarker(trimmed, _methodMarkers)) {
        methodStart ??= i;
      }
    }

    // If both markers found, split cleanly
    if (ingredientsStart != null || methodStart != null) {
      return _splitByMarkers(lines, ingredientsStart, methodStart);
    }

    // No markers found — fall back to line-by-line heuristic
    return _splitHeuristic(lines);
  }

  static bool _isZoneMarker(String line, Set<String> markers) {
    final lower = line.toLowerCase().replaceAll(RegExp(r'[:.]$'), '').trim();
    return markers.contains(lower);
  }

  static ({String? title, List<String> ingredientLines, List<String> methodLines})
  _splitByMarkers(
    List<String> lines,
    int? ingredientsStart,
    int? methodStart,
  ) {
    // Use the LAST ingredients marker and the FIRST method marker
    final ingredientsEnd = methodStart ?? lines.length;

    // Find the last "ingredients" marker before methodStart
    int? actualIngredientsStart;
    for (var i = ingredientsEnd - 1; i >= 0; i--) {
      final trimmed = lines[i].trim();
      if (_isZoneMarker(trimmed, _ingredientsMarkers)) {
        actualIngredientsStart = i;
        break;
      }
    }

    // Strip marker lines from the ingredient lines
    final ingredientLines = <String>[];
    final methodLines = <String>[];

    // Everything between the first line and ingredients marker is pre-content
    // (could be title)
    final preLines = <String>[];
    if (actualIngredientsStart != null) {
      preLines.addAll(lines.sublist(0, actualIngredientsStart));
    }

    // Ingredients zone
    final ingredientZoneStart =
        actualIngredientsStart != null ? actualIngredientsStart + 1 : 0;
    final ingredientZoneEnd = methodStart ?? lines.length;
    for (var i = ingredientZoneStart; i < ingredientZoneEnd; i++) {
      final line = lines[i].trim();
      if (!_isZoneMarker(line, _ingredientsMarkers) &&
          !_isZoneMarker(line, _methodMarkers)) {
        ingredientLines.add(line);
      }
    }

    // Method zone
    if (methodStart != null) {
      for (var i = methodStart + 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (!_isZoneMarker(line, _ingredientsMarkers) &&
            !_isZoneMarker(line, _methodMarkers)) {
          methodLines.add(line);
        }
      }
    }

    // Extract title from pre-lines: first non-ingredient-like line
    String? title;
    for (final line in preLines) {
      if (!_startsWithQuantity(line) && !_isZoneMarker(line, _ingredientsMarkers)) {
        title = line;
        break;
      }
    }

    return (
      title: title,
      ingredientLines: ingredientLines,
      methodLines: methodLines,
    );
  }

  static bool _startsWithQuantity(String line) =>
      RegExp(r'^[\d¼½¾⅓⅔⅛⅜⅝⅞]').hasMatch(line);

  /// Cooking-instruction imperative verbs. A line starting with one of these
  /// (base/imperative form) is almost certainly an instruction, not an
  /// ingredient.
  static const _imperativeVerbs = {
    'add', 'bake', 'beat', 'blend', 'boil', 'broil', 'brown', 'chill',
    'chop', 'combine', 'cook', 'cover', 'cut', 'defrost', 'dice', 'drain',
    'drizzle', 'fold', 'fry', 'garnish', 'grate', 'grill', 'heat', 'knead',
    'layer', 'marinate', 'mash', 'melt', 'microwave', 'mix', 'place',
    'pour', 'preheat', 'prepare', 'press', 'refrigerate', 'remove',
    'rinse', 'roast', 'rest', 'roll', 'sauté', 'sear', 'season', 'serve',
    'simmer', 'slice', 'soak', 'spread', 'steam', 'stir', 'toast',
    'toss', 'trim', 'whisk',
  };

  /// Heuristic fallback when no zone markers are found.
  ///
  /// Most recipe texts follow this pattern:
  ///   Title (first 1-2 lines)
  ///   Ingredients (several short lines, many starting with a quantity)
  ///   Instructions (numbered or beginning with action verbs)
  ///
  /// Finds the ingredient/instruction boundary by scanning for the first
  /// numbered step or the first line starting with an imperative cooking verb.
  static ({String? title, List<String> ingredientLines, List<String> methodLines})
  _splitHeuristic(List<String> lines) {
    if (lines.isEmpty) {
      return (title: null, ingredientLines: const [], methodLines: const []);
    }

    // Step 1: extract title — first line that doesn't start with a quantity
    String? title;
    int startIdx = 0;
    if (_startsWithQuantity(lines.first)) {
      startIdx = 0;
    } else {
      title = lines.first;
      startIdx = 1;
    }

    final ingredientLines = <String>[];
    final methodLines = <String>[];

    // Step 2: find the first line that signals the start of instructions
    // (numbered step or imperative verb)
    int? splitIdx;
    for (var i = startIdx; i < lines.length; i++) {
      final line = lines[i];
      if (_isNumberedStep(line)) {
        splitIdx = i;
        break;
      }
      final firstWord = line.split(RegExp(r'\s+')).first.toLowerCase();
      if (_imperativeVerbs.contains(firstWord)) {
        splitIdx = i;
        break;
      }
    }

    // Step 3: split at the boundary
    if (splitIdx != null) {
      for (var i = startIdx; i < splitIdx; i++) {
        ingredientLines.add(lines[i]);
      }
      for (var i = splitIdx; i < lines.length; i++) {
        methodLines.add(lines[i]);
      }
    } else {
      // No instruction signals detected — assume all remaining lines are
      // ingredients (no method section).
      for (var i = startIdx; i < lines.length; i++) {
        ingredientLines.add(lines[i]);
      }
    }

    return (
      title: title,
      ingredientLines: ingredientLines,
      methodLines: methodLines,
    );
  }

  static bool _isNumberedStep(String line) =>
      RegExp(r'^\d+[.)]\s').hasMatch(line);

  // ── Ingredient line parsing ───────────────────────────────────────────────

  /// Parse a list of ingredient strings into named sections and unsectioned
  /// ingredients.
  ///
  /// Lines ending with ":" that have no leading quantity are treated as section
  /// headers (e.g. "For the sauce:"). Subsequent lines belong to that section.
  /// Lines before any section header are unsectioned.
  static (List<RecipeSectionDraft> sections, List<IngredientDraft> unsectioned)
  parseIngredientLines(List<String> lines) {
    if (lines.isEmpty) return (const [], const []);

    final sections = <RecipeSectionDraft>[];
    final unsectioned = <IngredientDraft>[];
    String? currentSectionName;
    final currentItems = <IngredientDraft>[];

    void flushSection() {
      if (currentSectionName != null && currentItems.isNotEmpty) {
        sections.add(
          RecipeSectionDraft(
            name: currentSectionName.replaceFirst(RegExp(r':$'), '').trim(),
            ingredients: List.of(currentItems),
          ),
        );
      } else if (currentSectionName == null && currentItems.isNotEmpty) {
        unsectioned.addAll(currentItems);
      }
      currentItems.clear();
    }

    for (final line in lines) {
      if (line.isEmpty) continue;
      if (sectionHeaderPattern.hasMatch(line)) {
        flushSection();
        currentSectionName = line;
      } else {
        currentItems.add(parseIngredientString(line));
      }
    }

    flushSection();

    return (sections, unsectioned);
  }

  /// Parse a single ingredient string into an [IngredientDraft].
  static IngredientDraft parseIngredientString(String s) =>
      IngredientParser.parse(s);

  // ── Instruction parsing ────────────────────────────────────────────────────

  /// Parse raw instruction text into individual steps.
  ///
  /// If lines are numbered (e.g. "1. Boil pasta"), respects the numbering.
  /// Otherwise splits by sentence boundaries.
  static List<String> parseInstructions(List<String> lines) {
    if (lines.isEmpty) return const [];

    // Check if most lines are numbered
    final numberedCount =
        lines.where((l) => RegExp(r'^\d+[.)]\s').hasMatch(l.trim())).length;
    final usesNumbering = numberedCount > lines.length * 0.3;

    if (usesNumbering) {
      return lines
          .map((l) => l.trim().replaceFirst(RegExp(r'^\d+[.)]\s*'), '').trim())
          .where((l) => l.isNotEmpty)
          .toList();
    }

    // Fallback: split by sentence boundaries, merging short fragments
    final buffer = StringBuffer();
    for (final line in lines) {
      buffer.write('$line ');
    }
    final fullText = buffer.toString().trim();
    if (fullText.isEmpty) return const [];

    return _splitSentences(fullText);
  }

  /// Split text into sentences on `. `, `! `, `? ` boundaries.
  /// Filters out empty or very short fragments.
  static List<String> _splitSentences(String text) {
    // Split on sentence-ending punctuation followed by space or end-of-string
    final parts = text.split(RegExp(r'(?<=[.!?])\s+'));
    return parts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && p.length > 3)
        .toList();
  }

  // ── Servings parsing ───────────────────────────────────────────────────────

  /// Parse a servings value from various formats (int, num, list, string).
  static int? parseServings(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is List && value.isNotEmpty) return parseServings(value.first);
    final match = RegExp(r'\d+').firstMatch(value.toString());
    return match != null ? int.tryParse(match.group(0)!) : null;
  }
}