import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/features/recipes/models/recipe_draft.dart';

// Regex/unit parsing stage that runs before the LLM cleanup step.
// Produces a PrestructuredRecipe with whatever can be confidently extracted;
// sparse output is expected and handled gracefully by the LLM stage.
class OcrTextParser {
  static final _startsWithQuantity = RegExp(r'^[\d¼½¾⅓⅔⅛⅜⅝⅞]');
  static final _numberedStep = RegExp(r'^\d+[\.\)]\s');

  static final _leadingNumber = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(\d+)/(\d+)'
    r'|^(\d+)/(\d+)'
    r'|^(\d+(?:\.\d+)?)',
  );

  static const _unicodeFractions = {
    '¼': 0.25,
    '½': 0.5,
    '¾': 0.75,
    '⅓': 1 / 3,
    '⅔': 2 / 3,
    '⅛': 0.125,
    '⅜': 0.375,
    '⅝': 0.625,
    '⅞': 0.875,
  };

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
    double? qty;
    String remaining = line;

    // Handle unicode fraction prefix (e.g. "½ tsp salt")
    if (line.isNotEmpty && _unicodeFractions.containsKey(line[0])) {
      qty = _unicodeFractions[line[0]];
      remaining = line.substring(1).trim();
    } else {
      final m = _leadingNumber.firstMatch(line);
      if (m != null) {
        if (m.group(1) != null) {
          // mixed fraction: "1 1/2"
          qty = double.parse(m.group(1)!) +
              double.parse(m.group(2)!) / double.parse(m.group(3)!);
        } else if (m.group(4) != null) {
          // simple fraction: "1/2"
          qty =
              double.parse(m.group(4)!) / double.parse(m.group(5)!);
        } else {
          // decimal or integer
          qty = double.tryParse(m.group(6)!);
        }
        remaining = line.substring(m.end).trim();
      }
    }

    if (remaining.isEmpty) return null;

    // Strip inline unit conversion alternatives: "g/4oz" or "g / 4oz" → "g"
    // Right side must start with a digit/fraction; preserves word/word slashes.
    remaining = remaining
        .replaceAll(
          RegExp(
              r'\s*/\s*(?=[¼½¾⅓⅔⅛⅜⅝⅞\d])[\d¼½¾⅓⅔⅛⅜⅝⅞][^\s,()]*(?:\s+[a-zA-Z]+)?'),
          '',
        )
        .trim();

    if (remaining.isEmpty) return null;

    String? unitId;
    String name = remaining;
    final words = remaining.split(RegExp(r'\s+'));

    if (words.length >= 2) {
      final twoWord = UnitRegistry.parse('${words[0]} ${words[1]}');
      if (twoWord != null) {
        unitId = twoWord.id;
        name = words.sublist(2).join(' ');
      }
    }
    if (unitId == null && words.isNotEmpty) {
      final oneWord = UnitRegistry.parse(words[0]);
      if (oneWord != null) {
        unitId = oneWord.id;
        name = words.sublist(1).join(' ');
      }
    }

    if (name.isEmpty) name = remaining;
    return ParsedIngredientLine(qty: qty, unit: unitId, name: name);
  }
}
