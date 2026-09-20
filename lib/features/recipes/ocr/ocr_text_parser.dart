import 'package:pantry/core/ingredients/ingredient_parser.dart';
import 'package:pantry/features/recipes/models/recipe_draft.dart';

// Regex/unit parsing stage that runs before the LLM cleanup step.
// Produces a PrestructuredRecipe with whatever can be confidently extracted;
// sparse output is expected and handled gracefully by the LLM stage.
class OcrTextParser {
  static final _startsWithQuantity = RegExp(r'^[\d¼½¾⅓⅔⅛⅜⅝⅞]');
  static final _numberedStep = RegExp(r'^\d+[.)]\s');

  static PrestructuredRecipe parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? title;
    final parsedIngredients = <ParsedIngredientLine>[];
    final instructionLines = <String>[];
    var seenIngredients = false;

    for (final line in lines) {
      if (_isIngredientLine(line)) {
        seenIngredients = true;
        final parsed = _parseIngredientLine(line);
        if (parsed != null) parsedIngredients.add(parsed);
      } else if (title == null && !seenIngredients) {
        title = line;
      } else {
        instructionLines.add(line);
      }
    }

    return PrestructuredRecipe(
      rawText: rawText,
      title: title,
      parsedIngredients: parsedIngredients,
      instructionLines: instructionLines,
    );
  }

  static bool _isIngredientLine(String line) {
    if (!_startsWithQuantity.hasMatch(line)) return false;
    if (_numberedStep.hasMatch(line)) return false;
    return true;
  }

  static ParsedIngredientLine? _parseIngredientLine(String line) {
    final parsed = IngredientParser.parse(line);
    if (parsed.name.isEmpty) return null;

    final altLines = parsed.alternatives
        .map((a) => ParsedIngredientLine(name: a.name))
        .toList();

    return ParsedIngredientLine(
      qty: parsed.qty,
      unit: parsed.unit,
      name: parsed.name,
      alternatives: altLines,
    );
  }
}
