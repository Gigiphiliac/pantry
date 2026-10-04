import 'package:pantry/core/recipes/recipe_text_parser.dart';
import 'package:pantry/features/recipes/models/recipe_draft.dart';
import 'zone_assembler.dart';

/// Deterministic parser that converts raw OCR recipe text into a [RecipeDraft].
///
/// Uses a dual-pass approach:
///   1. Scan for zone marker words ("Ingredients", "Method", etc.) and split
///      the text into title, ingredients zone, and method zone.
///   2. Extract metadata lines (servings, times, nutrition) from the
///      ingredient zone and remove them before parsing.
///   3. Parse each zone with the appropriate shared utility from
///      [RecipeTextParser].
///
/// If no markers are found, falls back to a line-by-line heuristic.
class OcrRecipeParser {
  // ── Detection patterns ─────────────────────────────────────────────────────

  /// Servings: "Serves 4", "Makes 12", "Yield: 8 servings"
  static final RegExp _servingsPattern = RegExp(
    r'^(serv(es|ings?)|makes|yields?)\b',
    caseSensitive: false,
  );

  /// Prep / cook / total time markers (at line start, case-insensitive).
  static final RegExp _timePattern = RegExp(
    r'^(prep\s*time|cook\s*time|total\s*time)\b',
    caseSensitive: false,
  );

  /// Nutrition intro lines: "Calories: 250", "Nutrition per serve", etc.
  static final RegExp _nutritionIntroPattern = RegExp(
    r'^(calories|nutrition|protein|fat|carbs|sugar|sodium|fibre|fiber)\b',
    caseSensitive: false,
  );

  /// Noise substrings (same set as OnnxClassifier / LabelCorrector).
  static final Set<String> _noisePatterns = {
    'prep time',
    'cook time',
    'total time',
    'calories:',
    'nutrition facts',
    'author:',
    'recipe video',
    'jump to recipe',
    'skip to recipe',
    'rate this recipe',
    'print recipe',
    'share recipe',
    'www.',
    '©',
    'copyright',
    'published:',
    'dietary:',
    'allergen',
  };

  static final RegExp _pageNumberPattern = RegExp(
    r'^\s*(page\s*\d+|p\.?\s*\d+|(\d+)\s*/\s*(\d+))\s*$',
    caseSensitive: false,
  );

  static final RegExp _starPattern = RegExp(r'^[\u2605\u2726\u2b50\*]{2,}\s*$');

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Parse raw OCR text into a structured [RecipeDraft].
  ///
  /// Returns a best-effort structure even for noisy input. Sparse or missing
  /// fields (null title, empty steps, etc.) are expected and handled gracefully
  /// by the caller.
  static RecipeDraft parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return RecipeDraft(ingredients: [], sections: [], steps: []);
    }

    // Step 1: Dual-pass zone segmentation
    final zones = RecipeTextParser.splitZones(rawText);

    // Step 2: Extract metadata from ingredient lines and filter them out
    final meta = _Metadata();
    final cleanIngredientLines = _extractAndFilter(zones.ingredientLines, meta);
    final cleanMethodLines = _extractAndFilter(zones.methodLines, meta);

    // Step 3: Parse ingredient lines into sections + unsectioned ingredients
    final (sections, unsectioned) = RecipeTextParser.parseIngredientLines(
      cleanIngredientLines,
    );

    // Step 4: Parse method lines into steps
    final steps = RecipeTextParser.parseInstructions(cleanMethodLines);

    return RecipeDraft(
      name: zones.title,
      servings: meta.servings,
      ingredients: unsectioned,
      sections: sections,
      steps: steps,
      notes: meta.notes,
      nutrition: meta.nutrition.isNotEmpty ? meta.nutrition : null,
      prepTime: meta.prepTime,
      cookTime: meta.cookTime,
      totalTime: meta.totalTime,
    );
  }

  // ── Metadata extraction ────────────────────────────────────────────────────

  /// Scan [lines] for known metadata patterns, extract values into [meta],
  /// and return the lines that are NOT metadata (to be parsed as ingredients
  /// or steps).
  static List<String> _extractAndFilter(List<String> lines, _Metadata meta) {
    if (lines.isEmpty) return const [];

    final remaining = <String>[];
    final noteWords = <String>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();

      if (line.isEmpty) {
        remaining.add(line);
        continue;
      }

      // ── Noise ──────────────────────────────────────────────────────────
      if (_isNoise(line)) continue;

      // ── Servings ───────────────────────────────────────────────────────
      if (meta.servings == null && _servingsPattern.hasMatch(line)) {
        final match = RegExp(r'\d+').firstMatch(line);
        if (match != null) {
          meta.servings = int.tryParse(match.group(0)!);
        }
        continue;
      }

      // ── Times ──────────────────────────────────────────────────────────
      if (_timePattern.hasMatch(line)) {
        final timeType = line.toLowerCase().split(RegExp(r'\s+')).first;
        // Strip the label prefix and store the rest
        final value = line.replaceFirst(RegExp(r'^[^:]*:?\s*'), '').trim();
        if (value.isNotEmpty) {
          if (timeType.startsWith('prep')) {
            meta.prepTime ??= value;
          } else if (timeType.startsWith('cook')) {
            meta.cookTime ??= value;
          } else if (timeType.startsWith('total')) {
            meta.totalTime ??= value;
          }
        }
        continue;
      }

      // ── Nutrition intro line ───────────────────────────────────────────
      if (_nutritionIntroPattern.hasMatch(line)) {
        final nut = ZoneAssembler.parseNutritionLine(line);
        if (nut.label.isNotEmpty) {
          meta.nutrition.add(nut);
        }
        continue;
      }

      // ── Long narrative line → notes candidate ─────────────────────────
      final wordCount = line.split(RegExp(r'\s+')).length;
      if (wordCount > 10) {
        noteWords.add(line);
        continue;
      }

      // Default: keep in remaining list
      remaining.add(line);
    }

    // Collate notes
    if (noteWords.isNotEmpty) {
      meta.notes = noteWords.join(' ');
    }

    return remaining;
  }

  // ── Noise detection ────────────────────────────────────────────────────────

  /// Returns true if [text] matches any known noise pattern.
  static bool _isNoise(String text) {
    final normalised = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = normalised.toLowerCase();
    for (final pattern in _noisePatterns) {
      if (lower.contains(pattern)) return true;
    }
    if (_pageNumberPattern.hasMatch(normalised)) return true;
    if (_starPattern.hasMatch(normalised)) return true;
    return false;
  }
}

/// Mutable accumulator for metadata extracted from raw OCR text lines.
///
/// Passed to [OcrRecipeParser._extractAndFilter] which populates its fields
/// and returns a filtered line list. Top-level class because Dart does not
/// support inner classes with instance fields that can be mutated from a
/// static method of the outer class.
class _Metadata {
  int? servings;
  String? prepTime;
  String? cookTime;
  String? totalTime;
  String? notes;
  final List<NutritionDraft> nutrition = [];
}
