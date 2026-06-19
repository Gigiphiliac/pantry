class ParsedIngredientLine {
  final double? qty;
  final String? unit;
  final String name;

  const ParsedIngredientLine({this.qty, this.unit, required this.name});

  Map<String, dynamic> toJson() => {'qty': qty, 'unit': unit, 'name': name};
}

class PrestructuredRecipe {
  final String rawText;
  final String? title;
  final List<ParsedIngredientLine> parsedIngredients;
  final List<String> instructionLines;

  const PrestructuredRecipe({
    required this.rawText,
    this.title,
    this.parsedIngredients = const [],
    this.instructionLines = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'parsedIngredients':
            parsedIngredients.map((i) => i.toJson()).toList(),
        'instructionLines': instructionLines,
      };
}

class IngredientDraft {
  final double? qty;
  final String? unit;
  final String name;
  final String? notes;
  final List<IngredientDraft> alternatives;

  const IngredientDraft({
    this.qty,
    this.unit,
    required this.name,
    this.notes,
    this.alternatives = const [],
  });

  factory IngredientDraft.fromJson(Map<String, dynamic> json) {
    final rawAlts = json['alternatives'];
    final alternatives = rawAlts is List
        ? rawAlts
            .whereType<Map<String, dynamic>>()
            .map(IngredientDraft.fromJson)
            .toList()
        : <IngredientDraft>[];

    return IngredientDraft(
      qty: (json['qty'] as num?)?.toDouble(),
      unit: _nullIfEmpty(json['unit'] as String?),
      name: json['name'] as String? ?? '',
      notes: _nullIfEmpty(json['notes'] as String?),
      alternatives: alternatives,
    );
  }

  static String? _nullIfEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}

class RecipeDraft {
  final String? name;
  final int? servings;
  final List<IngredientDraft> ingredients;
  final List<String> steps;

  const RecipeDraft({
    this.name,
    this.servings,
    this.ingredients = const [],
    this.steps = const [],
  });

  factory RecipeDraft.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'];
    final ingredients = rawIngredients is List
        ? rawIngredients
            .whereType<Map<String, dynamic>>()
            .map(IngredientDraft.fromJson)
            .toList()
        : <IngredientDraft>[];

    // Support both 'steps' (new) and 'instructions' (legacy LLM output)
    List<String> steps;
    final rawSteps = json['steps'];
    if (rawSteps is List) {
      steps = rawSteps
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      final blob = json['instructions'] as String?;
      steps = (blob == null || blob.trim().isEmpty)
          ? const []
          : blob
              .trim()
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
    }

    return RecipeDraft(
      name: _nullIfEmpty(json['name'] as String?),
      servings: (json['servings'] as num?)?.toInt(),
      ingredients: ingredients,
      steps: steps,
    );
  }

  static String? _nullIfEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}
