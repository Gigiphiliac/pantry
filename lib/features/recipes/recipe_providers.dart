import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/main.dart';
import 'package:pantry/utils/ingredient_dedup.dart';
import 'package:pantry/features/shopping/shopping_providers.dart';

// ── Data classes ──────────────────────────────────────────────────────────────

class RecipeIngredientDraft {
  String rawText;
  double? qty;
  String? unit;
  String? notes;
  int? resolvedIngredientId;

  RecipeIngredientDraft({
    required this.rawText,
    this.qty,
    this.unit,
    this.notes,
    this.resolvedIngredientId,
  });
}

class RecipeIngredientRow {
  final int id;
  final String ingredientName;
  final double? qty;
  final String? unit;
  final String? notes;
  final int ingredientId;

  const RecipeIngredientRow({
    required this.id,
    required this.ingredientName,
    this.qty,
    this.unit,
    this.notes,
    required this.ingredientId,
  });
}

// ── Providers ─────────────────────────────────────────────────────────────────

final recipesProvider = StreamProvider<List<Recipe>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.recipes)
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();
});

final recipesSearchProvider =
    StreamProvider.family<List<Recipe>, String>((ref, query) {
  final db = ref.watch(dbProvider);
  if (query.isEmpty) {
    return (db.select(db.recipes)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }
  return (db.select(db.recipes)
        ..where((t) => t.name.like('%$query%'))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();
});

final recipeIngredientCountProvider =
    StreamProvider.family<int, int>((ref, recipeId) {
  final db = ref.watch(dbProvider);
  final query = db.selectOnly(db.recipeIngredients)
    ..addColumns([db.recipeIngredients.id.count()])
    ..where(db.recipeIngredients.recipeId.equals(recipeId));
  return query.map((row) => row.read(db.recipeIngredients.id.count()) ?? 0).watchSingle();
});

final recipeStepsProvider =
    StreamProvider.family<List<String>, int>((ref, recipeId) {
  final db = ref.watch(dbProvider);
  return (db.select(db.recipeSteps)
        ..where((t) => t.recipeId.equals(recipeId))
        ..orderBy([(t) => OrderingTerm.asc(t.stepNumber)]))
      .watch()
      .map((rows) => rows.map((r) => r.content).toList());
});

// ── RecipeOps ─────────────────────────────────────────────────────────────────

class RecipeOps {
  final AppDatabase db;
  RecipeOps(this.db);

  Future<int> saveRecipe({
    int? id,
    required String name,
    int? servings,
    List<String> steps = const [],
    String? sourceUrl,
    String sourceType = 'manual',
    required List<RecipeIngredientDraft> ingredients,
  }) async {
    return db.transaction(() async {
      final int recipeId;
      if (id == null) {
        recipeId = await db.into(db.recipes).insert(
              RecipesCompanion.insert(
                name: name,
                servings: Value(servings),
                sourceUrl: Value(sourceUrl),
                sourceType: Value(sourceType),
              ),
            );
      } else {
        recipeId = id;
        await (db.update(db.recipes)..where((t) => t.id.equals(id))).write(
          RecipesCompanion(
            name: Value(name),
            servings: Value(servings),
            sourceUrl: Value(sourceUrl),
          ),
        );
        await (db.delete(db.recipeIngredients)
              ..where((t) => t.recipeId.equals(id)))
            .go();
        await (db.delete(db.recipeSteps)
              ..where((t) => t.recipeId.equals(id)))
            .go();
      }

      // Insert steps
      for (var i = 0; i < steps.length; i++) {
        final content = steps[i].trim();
        if (content.isEmpty) continue;
        await db.into(db.recipeSteps).insert(
              RecipeStepsCompanion.insert(
                recipeId: recipeId,
                stepNumber: i + 1,
                content: content,
              ),
            );
      }

      for (final draft in ingredients) {
        if (draft.rawText.trim().isEmpty) continue;
        final ingredientId = draft.resolvedIngredientId ??
            await getOrCreateIngredient(db, draft.rawText);
        await db.into(db.recipeIngredients).insert(
              RecipeIngredientsCompanion.insert(
                recipeId: recipeId,
                ingredientId: ingredientId,
                qty: Value(draft.qty),
                unit: Value(draft.unit),
                notes: Value(draft.notes),
              ),
            );
      }

      return recipeId;
    });
  }

  Future<void> deleteRecipe(int id) async {
    await (db.delete(db.recipeSteps)..where((t) => t.recipeId.equals(id)))
        .go();
    await (db.delete(db.recipeIngredients)
          ..where((t) => t.recipeId.equals(id)))
        .go();
    await (db.delete(db.recipes)..where((t) => t.id.equals(id))).go();
  }

  Future<List<String>> getSteps(int recipeId) async {
    final rows = await (db.select(db.recipeSteps)
          ..where((t) => t.recipeId.equals(recipeId))
          ..orderBy([(t) => OrderingTerm.asc(t.stepNumber)]))
        .get();
    return rows.map((r) => r.content).toList();
  }

  Future<List<RecipeIngredientRow>> getIngredients(int recipeId) async {
    final query = db.select(db.recipeIngredients).join([
      innerJoin(
        db.ingredients,
        db.ingredients.id.equalsExp(db.recipeIngredients.ingredientId),
      ),
    ])
      ..where(db.recipeIngredients.recipeId.equals(recipeId));

    final rows = await query.get();
    return rows.map((row) {
      final ri = row.readTable(db.recipeIngredients);
      final ing = row.readTable(db.ingredients);
      return RecipeIngredientRow(
        id: ri.id,
        ingredientName: ing.name,
        qty: ri.qty,
        unit: ri.unit,
        notes: ri.notes,
        ingredientId: ing.id,
      );
    }).toList();
  }

  Future<void> addToShoppingList(
    int recipeId,
    int listId,
    String recipeName,
  ) async {
    final ingredients = await getIngredients(recipeId);
    if (ingredients.isEmpty) return;

    final shoppingOps = ShoppingListOps(db);

    // Find first store's General section, or create store named after recipe
    final stores = await (db.select(db.shoppingListStores)
          ..where((t) => t.listId.equals(listId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    final int sectionId;
    if (stores.isNotEmpty) {
      final sections = await (db.select(db.shoppingListSections)
            ..where((t) => t.storeId.equals(stores.first.id))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();
      sectionId = sections.isNotEmpty
          ? sections.first.id
          : await shoppingOps.addSection(stores.first.id, 'General');
    } else {
      final storeId = await db.into(db.shoppingListStores).insert(
            ShoppingListStoresCompanion.insert(
              listId: listId,
              storeName: recipeName,
              sortOrder: const Value(0),
            ),
          );
      sectionId = await shoppingOps.addSection(storeId, 'General');
    }

    for (final ing in ingredients) {
      final unit = UnitRegistry.parse(ing.unit);
      // Convert weight/volume to canonical (g, ml) for cross-unit stacking.
      // Count units preserve their own ID — cans stay cans, not pieces.
      final needsConversion =
          unit != null && unit.family != UnitFamily.count && ing.qty != null;
      final canonicalQty = needsConversion
          ? UnitRegistry.convertToCanonical(ing.qty!, unit)
          : ing.qty;
      final canonicalUnitId = needsConversion
          ? UnitRegistry.canonicalUnit(unit.family).id
          : ing.unit;
      await shoppingOps.addItem(
        sectionId,
        ing.ingredientName,
        qty: canonicalQty,
        unit: canonicalUnitId,
        ingredientId: ing.ingredientId,
      );
    }
  }
}

final recipeOpsProvider = Provider<RecipeOps>((ref) {
  return RecipeOps(ref.watch(dbProvider));
});
