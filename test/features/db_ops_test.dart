import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:pantry/db/database.dart';
import 'package:pantry/features/recipes/recipe_providers.dart';
import 'package:pantry/features/meal_plans/meal_plan_providers.dart';
import 'package:pantry/features/shopping/shopping_providers.dart';
import 'package:pantry/features/pantry/pantry_ops.dart';

/// In-memory Drift database for testing.
AppDatabase createMemoryDb() => AppDatabase.connect(NativeDatabase.memory());

// ─────────────────────────────────────────────────────────────────────────────
// RecipeOps
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('RecipeOps', () {
    late AppDatabase db;
    late RecipeOps ops;

    setUp(() async {
      db = createMemoryDb();
      ops = RecipeOps(db);
      // Seed an ingredient that will be used across tests.
      await db
          .into(db.ingredients)
          .insert(IngredientsCompanion.insert(name: 'salt'));
      await db
          .into(db.ingredientAliases)
          .insert(
            IngredientAliasesCompanion.insert(alias: 'salt', ingredientId: 1),
          );
    });

    tearDown(() async {
      await db.close();
    });

    group('saveRecipe()', () {
      test('creates a new recipe with ingredients', () async {
        final id = await ops.saveRecipe(
          name: 'Test Recipe',
          steps: ['Step 1', 'Step 2'],
          ingredients: [
            RecipeIngredientDraft(
              rawText: 'salt',
              qty: 1,
              unit: 'tsp',
              notes: 'to taste',
            ),
          ],
        );

        expect(id, isNonNegative);

        // Verify recipe row exists
        final recipes = await db.select(db.recipes).get();
        expect(recipes.length, 1);
        expect(recipes.first.name, 'Test Recipe');

        // Verify ingredient is linked
        final ingredients = await ops.getIngredients(id);
        expect(ingredients.length, 1);
        expect(ingredients.first.ingredientName, 'salt');
        expect(ingredients.first.qty, 1.0);
        expect(ingredients.first.unit, 'tsp');

        // Verify steps
        final steps = await ops.getSteps(id);
        expect(steps, ['Step 1', 'Step 2']);
      });

      test('creates a new ingredient for unknown names', () async {
        final id = await ops.saveRecipe(
          name: 'Test Recipe',
          ingredients: [RecipeIngredientDraft(rawText: 'sugar')],
        );

        final ingredients = await ops.getIngredients(id);
        expect(ingredients.length, 1);
        expect(ingredients.first.ingredientName, 'sugar');

        // Verify both salt (seeded) and sugar (created) exist
        final all = await db.select(db.ingredients).get();
        expect(all.length, 2);
      });

      test('re-resolves ingredient when edited name differs from FK', () async {
        // Create a recipe with ingredient FK'd to "salt"
        final recipeId = await ops.saveRecipe(
          name: 'Test Recipe',
          ingredients: [
            RecipeIngredientDraft(
              rawText: 'salt',
              resolvedIngredientId: 1, // FK to the canonical "salt"
            ),
          ],
        );

        // Now edit: change name to "sugar" while keeping the old FK
        await ops.saveRecipe(
          id: recipeId,
          name: 'Test Recipe',
          ingredients: [
            RecipeIngredientDraft(
              rawText: 'sugar',
              resolvedIngredientId:
                  1, // stale FK — should trigger re-resolution
            ),
          ],
        );

        // The recipe ingredient should now link to the NEW "sugar" entry
        final ingredients = await ops.getIngredients(recipeId);
        expect(ingredients.length, 1);
        expect(ingredients.first.ingredientName, 'sugar');
        expect(ingredients.first.ingredientId, isNot(1));

        // The old "salt" must still exist untouched
        final all = await db.select(db.ingredients).get();
        expect(all.length, 2);
        expect(all.any((i) => i.name == 'salt'), isTrue);
      });

      test('keeps FK when edited name still matches canonical', () async {
        final recipeId = await ops.saveRecipe(
          name: 'Test Recipe',
          ingredients: [
            RecipeIngredientDraft(rawText: 'salt', resolvedIngredientId: 1),
          ],
        );

        // Edit but keep the same name — FK should be preserved
        await ops.saveRecipe(
          id: recipeId,
          name: 'Test Recipe (edited)',
          ingredients: [
            RecipeIngredientDraft(
              rawText: 'salt', // same as canonical
              qty: 2.0,
              resolvedIngredientId: 1,
            ),
          ],
        );

        final ingredients = await ops.getIngredients(recipeId);
        expect(ingredients.length, 1);
        expect(ingredients.first.ingredientName, 'salt');
        expect(ingredients.first.ingredientId, 1);
        expect(ingredients.first.qty, 2.0);

        // Only the original ingredient exists — no new one created
        final all = await db.select(db.ingredients).get();
        expect(all.length, 1);
      });

      test('handles case-insensitive name matching', () async {
        final recipeId = await ops.saveRecipe(
          name: 'Test',
          ingredients: [
            RecipeIngredientDraft(
              rawText: 'Salt', // capitalised
              resolvedIngredientId: 1, // canonical is lowercase "salt"
            ),
          ],
        );

        final ingredients = await ops.getIngredients(recipeId);
        expect(ingredients.length, 1);
        // FK kept because case-insensitive compare matches
        expect(ingredients.first.ingredientId, 1);

        // No new ingredient created
        final all = await db.select(db.ingredients).get();
        expect(all.length, 1);
      });

      test('deletes old ingredients and steps on re-save', () async {
        final recipeId = await ops.saveRecipe(
          name: 'Test Recipe',
          steps: ['Step A'],
          ingredients: [RecipeIngredientDraft(rawText: 'salt')],
        );

        // Re-save with different ingredients and steps
        await ops.saveRecipe(
          id: recipeId,
          name: 'Test Recipe',
          steps: ['Step B'],
          ingredients: [RecipeIngredientDraft(rawText: 'sugar')],
        );

        final ingredients = await ops.getIngredients(recipeId);
        expect(ingredients.length, 1);
        expect(ingredients.first.ingredientName, 'sugar');

        final steps = await ops.getSteps(recipeId);
        expect(steps, ['Step B']);
      });
    });

    group('deleteRecipe()', () {
      test('removes recipe and its ingredients', () async {
        final recipeId = await ops.saveRecipe(
          name: 'To Delete',
          ingredients: [RecipeIngredientDraft(rawText: 'salt')],
        );

        await ops.deleteRecipe(recipeId);

        final recipes = await db.select(db.recipes).get();
        expect(recipes, isEmpty);

        // Ingredient itself is preserved in the library
        final all = await db.select(db.ingredients).get();
        expect(all.length, 1);
      });
    });

    group('getIngredients() / getAlternatives()', () {
      test('returns alternatives for a recipe ingredient', () async {
        final recipeId = await ops.saveRecipe(
          name: 'Test',
          ingredients: [
            RecipeIngredientDraft(
              rawText: 'salt',
              alternatives: [
                RecipeIngredientDraft(
                  rawText: 'sea salt',
                  resolvedIngredientId: null,
                ),
              ],
            ),
          ],
        );

        final ingredients = await ops.getIngredients(recipeId);
        expect(ingredients.length, 1);

        final alts = await ops.getAlternatives(ingredients.first.id);
        expect(alts.length, 1);
        expect(alts.first.ingredientName, 'sea salt');
      });
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // MealPlanOps
  // ───────────────────────────────────────────────────────────────────────────

  group('MealPlanOps', () {
    late AppDatabase db;
    late MealPlanOps ops;

    setUp(() async {
      db = createMemoryDb();
      ops = MealPlanOps(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('upsertSlot()', () {
      test('creates a new slot', () async {
        final slot = await ops.upsertSlot(
          date: DateTime(2026, 3, 10),
          mealType: 'lunch',
          slotName: 'Tacos',
        );

        expect(slot.id, isNonNegative);
        expect(slot.mealType, 'lunch');
        expect(slot.slotName, 'Tacos');

        final all = await db.select(db.mealSlots).get();
        expect(all.length, 1);
      });

      test('updates an existing slot by (date, mealType)', () async {
        await ops.upsertSlot(
          date: DateTime(2026, 3, 10),
          mealType: 'lunch',
          slotName: 'Tacos',
        );

        final updated = await ops.upsertSlot(
          date: DateTime(2026, 3, 10),
          mealType: 'lunch',
          slotName: 'Burritos',
          notes: 'with guac',
        );

        expect(updated.slotName, 'Burritos');
        expect(updated.notes, 'with guac');

        final all = await db.select(db.mealSlots).get();
        expect(all.length, 1); // still one row
      });

      test('can link and unlink a recipe', () async {
        await db
            .into(db.ingredients)
            .insert(IngredientsCompanion.insert(name: 'filling'));
        await db
            .into(db.recipes)
            .insert(RecipesCompanion.insert(name: 'Taco Recipe'));

        final slot = await ops.upsertSlot(
          date: DateTime(2026, 3, 10),
          mealType: 'dinner',
          slotName: 'Tacos',
          recipeId: 1,
        );
        expect(slot.recipeId, 1);

        await ops.linkRecipe(slot.id, null);
        final reloaded = await ops.upsertSlot(
          date: DateTime(2026, 3, 10),
          mealType: 'dinner',
          slotName: 'Tacos',
        );
        expect(reloaded.recipeId, isNull);
      });
    });

    group('clearSlot()', () {
      test('deletes a slot by id', () async {
        final slot = await ops.upsertSlot(
          date: DateTime(2026, 3, 10),
          mealType: 'breakfast',
          slotName: 'Pancakes',
        );

        await ops.clearSlot(slot.id);

        final all = await db.select(db.mealSlots).get();
        expect(all, isEmpty);
      });
    });

    group('swapSlots()', () {
      test('exchanges content between two populated slots', () async {
        final a = await ops.upsertSlot(
          date: DateTime(2026, 3, 10),
          mealType: 'lunch',
          slotName: 'Tacos',
          notes: 'beef',
        );
        final b = await ops.upsertSlot(
          date: DateTime(2026, 3, 11),
          mealType: 'dinner',
          slotName: 'Pasta',
          notes: 'vegan',
        );

        await ops.swapSlots(
          sourceId: a.id,
          sourceDate: a.date,
          sourceMealType: a.mealType,
          targetDate: b.date,
          targetMealType: b.mealType,
        );

        final all = await db.select(db.mealSlots).get();
        expect(all.length, 2);

        // a's slot should now have Pasta content
        final reloadedA = await (db.select(
          db.mealSlots,
        )..where((t) => t.id.equals(a.id))).get();
        expect(reloadedA.first.slotName, 'Pasta');
        expect(reloadedA.first.notes, 'vegan');

        // b's slot should now have Tacos content
        final reloadedB = await (db.select(
          db.mealSlots,
        )..where((t) => t.id.equals(b.id))).get();
        expect(reloadedB.first.slotName, 'Tacos');
        expect(reloadedB.first.notes, 'beef');
      });

      test('moves source to empty target (no swap)', () async {
        final source = await ops.upsertSlot(
          date: DateTime(2026, 3, 10),
          mealType: 'lunch',
          slotName: 'Tacos',
        );

        // Swap with an empty slot (target doesn't exist)
        await ops.swapSlots(
          sourceId: source.id,
          sourceDate: source.date,
          sourceMealType: source.mealType,
          targetDate: DateTime(2026, 3, 12), // empty
          targetMealType: 'dinner',
        );

        final all = await db.select(db.mealSlots).get();
        expect(all.length, 1); // still one row, just moved
        expect(all.first.mealType, 'dinner');
        expect(all.first.slotName, 'Tacos');
      });
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // ShoppingListOps
  // ───────────────────────────────────────────────────────────────────────────

  group('ShoppingListOps', () {
    late AppDatabase db;
    late ShoppingListOps ops;

    setUp(() async {
      db = createMemoryDb();
      ops = ShoppingListOps(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('addItem()', () {
      test('creates item in a store/section', () async {
        final listId = await ops.createList('Weekly');
        final storeId = await ops.addStore(listId, 'Coles');
        final sectionId = await ops.addSection(storeId, 'Produce');

        await ops.addItem(
          storeId,
          sectionId: sectionId,
          rawText: 'apples',
          qty: 3,
          unit: 'piece',
        );

        final items = await (db.select(
          db.shoppingListItems,
        )..where((t) => t.sectionId.equals(sectionId))).get();
        expect(items.length, 1);
        expect(items.first.rawText, 'apples');
        expect(items.first.qty, 3.0);
      });
    });

    group('stacking', () {
      test('stacks matching unit', () async {
        final listId = await ops.createList('Weekly');
        final storeId = await ops.addStore(listId, 'Coles');

        await ops.addItem(storeId, rawText: 'flour', qty: 2, unit: 'cup');
        await ops.addItem(storeId, rawText: 'flour', qty: 1, unit: 'cup');

        final items = await db.select(db.shoppingListItems).get();
        expect(items.length, 1);
        expect(items.first.qty, 3.0);
      });

      test('stacks convertible units within same family', () async {
        final listId = await ops.createList('Weekly');
        final storeId = await ops.addStore(listId, 'Coles');

        // 1 litre + 500 ml → should stack as 1.5 litres
        await ops.addItem(storeId, rawText: 'milk', qty: 1, unit: 'l');
        await ops.addItem(storeId, rawText: 'milk', qty: 500, unit: 'ml');

        final items = await db.select(db.shoppingListItems).get();
        expect(items.length, 1);
        expect(items.first.qty, 1.5);
      });

      test('does not stack incompatible units (weight vs volume)', () async {
        final listId = await ops.createList('Weekly');
        final storeId = await ops.addStore(listId, 'Coles');

        await ops.addItem(storeId, rawText: 'butter', qty: 2, unit: 'cup');
        await ops.addItem(storeId, rawText: 'butter', qty: 250, unit: 'g');

        final items = await db.select(db.shoppingListItems).get();
        expect(items.length, 2);
      });

      test('does not stack checked items', () async {
        final listId = await ops.createList('Weekly');
        final storeId = await ops.addStore(listId, 'Coles');

        await ops.addItem(storeId, rawText: 'bread', qty: 1);
        // Manually check the first item
        final first = await (db.select(
          db.shoppingListItems,
        )..where((t) => t.rawText.equals('bread'))).get().then((r) => r.first);
        await ops.toggleItem(first.id, true);

        // Adding same item should create a new row (old one is checked)
        await ops.addItem(storeId, rawText: 'bread', qty: 1);

        final items = await db.select(db.shoppingListItems).get();
        expect(items.length, 2);
      });
    });

    group('stackOrAddItem()', () {
      test('creates a default store when list has none', () async {
        final listId = await ops.createList('Weekly');

        await ops.stackOrAddItem(listId, 'eggs', qty: 12);

        final items = await db.select(db.shoppingListItems).get();
        expect(items.length, 1);
        expect(items.first.rawText, 'eggs');
      });
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PantryOps
  // ───────────────────────────────────────────────────────────────────────────

  group('PantryOps', () {
    late AppDatabase db;
    late PantryOps ops;

    setUp(() async {
      db = createMemoryDb();
      ops = PantryOps(db);
      await db
          .into(db.ingredients)
          .insert(IngredientsCompanion.insert(name: 'salt'));
    });

    tearDown(() async {
      await db.close();
    });

    group('autoCreatePantryItem()', () {
      test('creates a pantry entry for an ingredient', () async {
        await ops.autoCreatePantryItem(1);

        final items = await db.select(db.pantryItems).get();
        expect(items.length, 1);
        expect(items.first.ingredientId, 1);
        expect(items.first.tier, 3); // default tier
      });

      test('is idempotent (insertOrIgnore)', () async {
        await ops.autoCreatePantryItem(1);
        await ops.autoCreatePantryItem(1);

        final items = await db.select(db.pantryItems).get();
        expect(items.length, 1);
      });
    });

    group('addStock()', () {
      test('creates stock entry and auto-creates pantry item', () async {
        final catId = await ops.createCategory('Spices');

        await ops.addStock(1, catId, qty: 100, unit: 'g');

        final stock = await db.select(db.pantryStock).get();
        expect(stock.length, 1);
        expect(stock.first.onHandQty, 100.0);

        // Should also create pantry library item
        final items = await db.select(db.pantryItems).get();
        expect(items.length, 1);
      });
    });

    group('deleteCategory()', () {
      test('prevents deleting a category that has stock', () async {
        final catId = await ops.createCategory('Spices');
        await ops.addStock(1, catId);

        expect(() => ops.deleteCategory(catId), throwsArgumentError);
      });

      test('deletes an empty category', () async {
        final catId = await ops.createCategory('Empty');

        await ops.deleteCategory(catId);

        final cats = await db.select(db.pantryStockCategories).get();
        // DB seeds 3 defaults (Fridge, Freezer, Pantry Cupboard)
        expect(cats.length, 3);
        expect(cats.any((c) => c.name == 'Empty'), isFalse);
      });
    });

    group('updateStockQty() / deleteStockItem()', () {
      test('updates and removes stock', () async {
        final catId = await ops.createCategory('Spices');
        await ops.addStock(1, catId, qty: 50, unit: 'g');

        final stock = await db.select(db.pantryStock).get();
        final stockId = stock.first.id;

        await ops.updateStockQty(stockId, 25);
        final reloaded = await db.select(db.pantryStock).get();
        expect(reloaded.first.onHandQty, 25.0);

        await ops.deleteStockItem(stockId);
        expect(await db.select(db.pantryStock).get(), isEmpty);

        // Ingredient still exists
        expect(await db.select(db.ingredients).get(), isNotEmpty);
      });
    });
  });
}
