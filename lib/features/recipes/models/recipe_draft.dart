class IngredientDraft {
  final double? qty;
  final String? unit;
  final String name;
  final String? notes;

  const IngredientDraft({
    this.qty,
    this.unit,
    required this.name,
    this.notes,
  });

  factory IngredientDraft.fromJson(Map<String, dynamic> json) {
    return IngredientDraft(
      qty: (json['qty'] as num?)?.toDouble(),
      unit: _nullIfEmpty(json['unit'] as String?),
      name: json['name'] as String? ?? '',
      notes: _nullIfEmpty(json['notes'] as String?),
    );
  }

  static String? _nullIfEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}

class RecipeDraft {
  final String? name;
  final int? servings;
  final List<IngredientDraft> ingredients;
  final String? instructions;

  const RecipeDraft({
    this.name,
    this.servings,
    this.ingredients = const [],
    this.instructions,
  });

  factory RecipeDraft.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'];
    final ingredients = rawIngredients is List
        ? rawIngredients
            .whereType<Map<String, dynamic>>()
            .map(IngredientDraft.fromJson)
            .toList()
        : <IngredientDraft>[];

    return RecipeDraft(
      name: _nullIfEmpty(json['name'] as String?),
      servings: (json['servings'] as num?)?.toInt(),
      ingredients: ingredients,
      instructions: _nullIfEmpty(json['instructions'] as String?),
    );
  }

  static String? _nullIfEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}
