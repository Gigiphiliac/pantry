import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/main.dart';
import 'package:pantry/utils/ingredient_dedup.dart';
import 'package:pantry/features/shopping/shopping_providers.dart';
import 'package:pantry/features/pantry/pantry_ops.dart';

// ── Data classes ──────────────────────────────────────────────────────────────

class RecipeIngredientDraft {
  String rawText;
  double? qty;
  String? unit;
  String? notes;
  int? resolvedIngredientId;
  List<RecipeIngredientDraft> alternatives;
  // Index into the sections list passed to saveRecipe(); null = unsectioned.
  int? sectionIndex;

  RecipeIngredientDraft({
    required this.rawText,
    this.qty,
    this.unit,
    this.notes,
    this.resolvedIngredientId,
    this.alternatives = const [],
    this.sectionIndex,
  });
}

class RecipeIngredientRow {
  final int id;
  final String ingredientName;
  final double? qty;
  final String? unit;
  final String? notes;
  final int ingredientId;
  final int? activeAlternativeIndex;
  final int? sectionId;

  const RecipeIngredientRow({
    required this.id,
    required this.ingredientName,
    this.qty,
    this.unit,
    this.notes,
    required this.ingredientId,
    this.activeAlternativeIndex,
    this.sectionId,
  });
}

class RecipeIngredientAlternativeRow {
  final int id;
  final int recipeIngredientId;
  final String ingredientName;
  final double? qty;
  final String? unit;
  final int ingredientId;
  final int sortOrder;

  const RecipeIngredientAlternativeRow({
    required this.id,
    required this.recipeIngredientId,
    required this.ingredientName,
    this.qty,
    this.unit,
    required this.ingredientId,
    required this.sortOrder,
  });
}

/// The resolved ingredient to show/add for a given recipe_ingredient row.
/// Either the primary or the active alternative, depending on activeAlternativeIndex.
class EffectiveIngredient {
  final String name;
  final double? qty;
  final String? unit;
  final int ingredientId;

  const EffectiveIngredient({
    required this.name,
    this.qty,
    this.unit,
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
  return query
      .map((row) => row.read(db.recipeIngredients.id.count()) ?? 0)
      .watchSingle();
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

final recipeSectionsProvider =
    StreamProvider.family<List<RecipeIngredientSection>, int>((ref, recipeId) {
  final db = ref.watch(dbProvider);
  return (db.select(db.recipeIngredientSections)
        ..where((t) => t.recipeId.equals(recipeId))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();
});

final recipeIngredientsProvider =
    StreamProvider.family<List<RecipeIngredientRow>, int>((ref, recipeId) {
  final db = ref.watch(dbProvider);
  return (db.select(db.recipeIngredients).join([
    innerJoin(
      db.ingredients,
      db.ingredients.id.equalsExp(db.recipeIngredients.ingredientId),
    ),
    leftOuterJoin(
      db.recipeIngredientSections,
      db.recipeIngredientSections.id
          .equalsExp(db.recipeIngredients.sectionId),
    ),
  ])
        ..where(db.recipeIngredients.recipeId.equals(recipeId))
        ..orderBy([
          OrderingTerm.asc(db.recipeIngredientSections.sortOrder),
          OrderingTerm.asc(db.recipeIngredients.id),
        ]))
      .watch()
      .map((rows) => rows
          .map((row) {
            final ri = row.readTable(db.recipeIngredients);
            final ing = row.readTable(db.ingredients);
            return RecipeIngredientRow(
              id: ri.id,
              ingredientName: ing.name,
              qty: ri.qty,
              unit: ri.unit,
              notes: ri.notes,
              ingredientId: ing.id,
              activeAlternativeIndex: ri.activeAlternativeIndex,
              sectionId: ri.sectionId,
            );
          })
          .toList());
});

final recipeIngredientAlternativesProvider =
    StreamProvider.family<List<RecipeIngredientAlternativeRow>, int>(
        (ref, recipeIngredientId) {
  final db = ref.watch(dbProvider);
  final query = db.select(db.recipeIngredientAlternatives).join([
    innerJoin(
      db.ingredients,
      db.ingredients.id
          .equalsExp(db.recipeIngredientAlternatives.ingredientId),
    ),
  ])
    ..where(db.recipeIngredientAlternatives.recipeIngredientId
        .equals(recipeIngredientId))
    ..orderBy([
      OrderingTerm.asc(db.recipeIngredientAlternatives.sortOrder),
    ]);
  return query.watch().map((rows) => rows.map((row) {
        final alt = row.readTable(db.recipeIngredientAlternatives);
        final ing = row.readTable(db.ingredients);
        return RecipeIngredientAlternativeRow(
          id: alt.id,
          recipeIngredientId: alt.recipeIngredientId,
          ingredientName: ing.name,
          qty: alt.qty,
          unit: alt.unit,
          ingredientId: ing.id,
          sortOrder: alt.sortOrder,
        );
      }).toList());
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
    List<String> sections = const [],
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
        // Delete alternatives → ingredients → sections (FK order)
        final existingIds = await (db.selectOnly(db.recipeIngredients)
              ..addColumns([db.recipeIngredients.id])
              ..where(db.recipeIngredients.recipeId.equals(id)))
            .map((row) => row.read(db.recipeIngredients.id)!)
            .get();
        for (final riId in existingIds) {
          await (db.delete(db.recipeIngredientAlternatives)
                ..where((t) => t.recipeIngredientId.equals(riId)))
              .go();
        }
        await (db.delete(db.recipeIngredients)
              ..where((t) => t.recipeId.equals(id)))
            .go();
        await (db.delete(db.recipeIngredientSections)
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

      // Insert sections; build index→id map for ingredient FK resolution.
      final sectionIdMap = <int, int>{};
      for (var i = 0; i < sections.length; i++) {
        final sectionName = sections[i].trim();
        if (sectionName.isEmpty) continue;
        final sectionId = await db.into(db.recipeIngredientSections).insert(
              RecipeIngredientSectionsCompanion.insert(
                recipeId: recipeId,
                name: sectionName,
                sortOrder: Value(i),
              ),
            );
        sectionIdMap[i] = sectionId;
      }

      final pantryOps = PantryOps(db);

      for (final draft in ingredients) {
        if (draft.rawText.trim().isEmpty) continue;
        final ingredientId = draft.resolvedIngredientId ??
            await getOrCreateIngredient(db, draft.rawText);
        await pantryOps.autoCreatePantryItem(ingredientId);
        final sectionId = draft.sectionIndex != null
            ? sectionIdMap[draft.sectionIndex]
            : null;
        final riId = await db.into(db.recipeIngredients).insert(
              RecipeIngredientsCompanion.insert(
                recipeId: recipeId,
                ingredientId: ingredientId,
                sectionId: Value(sectionId),
                qty: Value(draft.qty),
                unit: Value(draft.unit),
                notes: Value(draft.notes),
              ),
            );

        for (var i = 0; i < draft.alternatives.length; i++) {
          final alt = draft.alternatives[i];
          if (alt.rawText.trim().isEmpty) continue;
          final altIngredientId = alt.resolvedIngredientId ??
              await getOrCreateIngredient(db, alt.rawText);
          await pantryOps.autoCreatePantryItem(altIngredientId);
          await db.into(db.recipeIngredientAlternatives).insert(
                RecipeIngredientAlternativesCompanion.insert(
                  recipeIngredientId: riId,
                  ingredientId: altIngredientId,
                  qty: Value(alt.qty),
                  unit: Value(alt.unit),
                  sortOrder: i,
                ),
              );
        }
      }

      return recipeId;
    });
  }

  Future<void> deleteRecipe(int id) async {
    // Delete in FK order: alternatives → ingredients → sections → steps → recipe
    final existingIds = await (db.selectOnly(db.recipeIngredients)
          ..addColumns([db.recipeIngredients.id])
          ..where(db.recipeIngredients.recipeId.equals(id)))
        .map((row) => row.read(db.recipeIngredients.id)!)
        .get();
    for (final riId in existingIds) {
      await (db.delete(db.recipeIngredientAlternatives)
            ..where((t) => t.recipeIngredientId.equals(riId)))
          .go();
    }
    await (db.delete(db.recipeIngredients)
          ..where((t) => t.recipeId.equals(id)))
        .go();
    await (db.delete(db.recipeIngredientSections)
          ..where((t) => t.recipeId.equals(id)))
        .go();
    await (db.delete(db.recipeSteps)..where((t) => t.recipeId.equals(id)))
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
      leftOuterJoin(
        db.recipeIngredientSections,
        db.recipeIngredientSections.id
            .equalsExp(db.recipeIngredients.sectionId),
      ),
    ])
      ..where(db.recipeIngredients.recipeId.equals(recipeId))
      ..orderBy([
        OrderingTerm.asc(db.recipeIngredientSections.sortOrder),
        OrderingTerm.asc(db.recipeIngredients.id),
      ]);

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
        activeAlternativeIndex: ri.activeAlternativeIndex,
        sectionId: ri.sectionId,
      );
    }).toList();
  }

  Future<List<RecipeIngredientAlternativeRow>> getAlternatives(
      int recipeIngredientId) async {
    final query = db.select(db.recipeIngredientAlternatives).join([
      innerJoin(
        db.ingredients,
        db.ingredients.id
            .equalsExp(db.recipeIngredientAlternatives.ingredientId),
      ),
    ])
      ..where(db.recipeIngredientAlternatives.recipeIngredientId
          .equals(recipeIngredientId))
      ..orderBy([
        OrderingTerm.asc(db.recipeIngredientAlternatives.sortOrder),
      ]);
    final rows = await query.get();
    return rows.map((row) {
      final alt = row.readTable(db.recipeIngredientAlternatives);
      final ing = row.readTable(db.ingredients);
      return RecipeIngredientAlternativeRow(
        id: alt.id,
        recipeIngredientId: alt.recipeIngredientId,
        ingredientName: ing.name,
        qty: alt.qty,
        unit: alt.unit,
        ingredientId: ing.id,
        sortOrder: alt.sortOrder,
      );
    }).toList();
  }

  /// Cycles the active alternative for a recipe ingredient row.
  /// null (primary) → 0 (first alt) → 1 → ... → null
  Future<void> cycleAlternative(int recipeIngredientId) async {
    final row = await (db.select(db.recipeIngredients)
          ..where((t) => t.id.equals(recipeIngredientId)))
        .getSingle();

    final altCount = await (db.selectOnly(db.recipeIngredientAlternatives)
          ..addColumns([db.recipeIngredientAlternatives.id.count()])
          ..where(db.recipeIngredientAlternatives.recipeIngredientId
              .equals(recipeIngredientId)))
        .map((r) => r.read(db.recipeIngredientAlternatives.id.count()) ?? 0)
        .getSingle();

    if (altCount == 0) return;

    final current = row.activeAlternativeIndex;
    final next = (current == null)
        ? 0
        : (current + 1 >= altCount ? null : current + 1);

    await (db.update(db.recipeIngredients)
          ..where((t) => t.id.equals(recipeIngredientId)))
        .write(RecipeIngredientsCompanion(
      activeAlternativeIndex: Value(next),
    ));
  }

  /// Returns the effective ingredient (primary or active alternative) for display
  /// and shopping list purposes.
  Future<EffectiveIngredient> getEffectiveIngredient(
      RecipeIngredientRow row) async {
    final idx = row.activeAlternativeIndex;
    if (idx == null) {
      return EffectiveIngredient(
        name: row.ingredientName,
        qty: row.qty,
        unit: row.unit,
        ingredientId: row.ingredientId,
      );
    }

    final alts = await getAlternatives(row.id);
    if (idx < alts.length) {
      final alt = alts[idx];
      return EffectiveIngredient(
        name: alt.ingredientName,
        qty: alt.qty ?? row.qty,
        unit: alt.unit ?? row.unit,
        ingredientId: alt.ingredientId,
      );
    }

    // Index out of range (e.g. alternative was deleted) — fall back to primary.
    return EffectiveIngredient(
      name: row.ingredientName,
      qty: row.qty,
      unit: row.unit,
      ingredientId: row.ingredientId,
    );
  }

  Future<void> addToShoppingList(
    int recipeId,
    int listId,
    String recipeName,
  ) async {
    final ingredients = await getIngredients(recipeId);
    if (ingredients.isEmpty) return;

    final shoppingOps = ShoppingListOps(db);

    for (final ing in ingredients) {
      final effective = await getEffectiveIngredient(ing);

      final pantryItem = await (db.select(db.pantryItems)
            ..where((t) => t.ingredientId.equals(effective.ingredientId)))
          .getSingleOrNull();
      final tier = pantryItem?.tier ?? 3;

      if (tier == 1) continue; // always available — never needs buying

      await shoppingOps.stackOrAddItem(
        listId,
        effective.name,
        qty: tier == 2 ? null : effective.qty,
        unit: tier == 2 ? null : effective.unit,
        ingredientId: effective.ingredientId,
      );
    }
  }
}

final recipeOpsProvider = Provider<RecipeOps>((ref) {
  return RecipeOps(ref.watch(dbProvider));
});
