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

  Map<String, dynamic> toJson() => {
    'qty': qty,
    'unit': unit,
    'name': name,
    'notes': notes,
    if (alternatives.isNotEmpty)
      'alternatives': alternatives.map((a) => a.toJson()).toList(),
  };
}

class RecipeSectionDraft {
  final String name;
  final List<IngredientDraft> ingredients;

  const RecipeSectionDraft({required this.name, required this.ingredients});

  factory RecipeSectionDraft.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'];
    final ingredients = rawIngredients is List
        ? rawIngredients
              .whereType<Map<String, dynamic>>()
              .map(IngredientDraft.fromJson)
              .toList()
        : <IngredientDraft>[];
    return RecipeSectionDraft(
      name: json['name'] as String? ?? '',
      ingredients: ingredients,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
  };
}

/// A single nutrition fact: e.g. label="Calories", value="108cal".
///
/// Stored as key-value pairs so the form can render editable rows without
/// requiring the user to write raw JSON.
class NutritionDraft {
  final String label;
  final String value;

  const NutritionDraft({required this.label, required this.value});

  factory NutritionDraft.fromJson(Map<String, dynamic> json) => NutritionDraft(
    label: (json['label'] as String?) ?? '',
    value: (json['value'] as String?) ?? '',
  );

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}

class RecipeDraft {
  final String? name;
  final int? servings;
  final String? description;
  final List<IngredientDraft> ingredients;
  final List<RecipeSectionDraft> sections;
  final List<String> steps;
  final String? notes;
  final List<NutritionDraft>? nutrition; // nullable — no nutrition parsed
  final String? prepTime;
  final String? cookTime;
  final String? totalTime;

  const RecipeDraft({
    this.name,
    this.servings,
    this.description,
    this.ingredients = const [],
    this.sections = const [],
    this.steps = const [],
    this.notes,
    this.nutrition,
    this.prepTime,
    this.cookTime,
    this.totalTime,
  });

  factory RecipeDraft.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    final sections = rawSections is List
        ? rawSections
              .whereType<Map<String, dynamic>>()
              .map(RecipeSectionDraft.fromJson)
              .where((s) => s.name.isNotEmpty)
              .toList()
        : <RecipeSectionDraft>[];

    final rawIngredients = json['ingredients'];
    final ingredients = rawIngredients is List
        ? rawIngredients
              .whereType<Map<String, dynamic>>()
              .map(IngredientDraft.fromJson)
              .toList()
        : <IngredientDraft>[];

    // Support both 'steps' (new) and 'instructions'
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

    // Parse nutrition entries
    final nutrition = _parseNutrition(json['nutrition']);

    return RecipeDraft(
      name: _nullIfEmpty(json['name'] as String?),
      servings: (json['servings'] as num?)?.toInt(),
      description: _nullIfEmpty(json['description'] as String?),
      ingredients: ingredients,
      sections: sections,
      steps: steps,
      notes: _nullIfEmpty(json['notes'] as String?),
      nutrition: nutrition,
      prepTime: _nullIfEmpty(json['prepTime'] as String?),
      cookTime: _nullIfEmpty(json['cookTime'] as String?),
      totalTime: _nullIfEmpty(json['totalTime'] as String?),
    );
  }

  static List<NutritionDraft>? _parseNutrition(dynamic raw) {
    if (raw is! List) return null;
    final entries = raw
        .whereType<Map<String, dynamic>>()
        .map(NutritionDraft.fromJson)
        .where((n) => n.label.isNotEmpty)
        .toList();
    return entries.isEmpty ? null : entries;
  }

  static String? _nullIfEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'name': name,
      'servings': servings,
      'description': description,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'sections': sections.map((s) => s.toJson()).toList(),
      'steps': steps,
    };
    if (notes != null) result['notes'] = notes;
    final nut = nutrition;
    if (nut != null) {
      result['nutrition'] = nut.map((n) => n.toJson()).toList();
    }
    if (prepTime != null) result['prepTime'] = prepTime;
    if (cookTime != null) result['cookTime'] = cookTime;
    if (totalTime != null) result['totalTime'] = totalTime;
    return result;
  }
}
