import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/db/database.dart';

/// Verifies the versioned migration chain upgrades old databases WITHOUT
/// destroying user data (the old onUpgrade wiped every table — see v13 fix).
///
/// Each fixture writes a real SQLite file in the shape of an older schema
/// (raw SQL via a plain connection, since the app code generates the current
/// schema), sets `PRAGMA user_version` to the old version, then opens the real
/// [AppDatabase] on a fresh connection so the actual migration strategy runs.
class _RawConnection implements QueryExecutorUser {
  _RawConnection(this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

const _v13RecipesTable = '''
  CREATE TABLE "recipes" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "source_url" TEXT NULL,
    "source_type" TEXT NOT NULL DEFAULT 'manual',
    "servings" INTEGER NULL,
    "description" TEXT NULL,
    "nutrition_json" TEXT NULL,
    "notes" TEXT NULL,
    "prep_time" TEXT NULL,
    "cook_time" TEXT NULL,
    "total_time" TEXT NULL
  )
''';

/// Creates the file, writes the fixture, and returns the database path.
Future<String> _writeFixture({
  required int version,
  required List<String> statements,
}) async {
  final dir = await Directory.systemTemp.createTemp('pantry_migration');
  final file = '${dir.path}/fixture.db';

  final raw = NativeDatabase(File(file));
  await raw.ensureOpen(_RawConnection(version));
  for (final sql in statements) {
    await raw.runCustom(sql);
  }
  await raw.runCustom('PRAGMA user_version = $version');
  await raw.close();

  return file;
}

void main() {
  group('v13 → v14 migration', () {
    test(
      'preserves all data and converts legacy timing strings to minutes',
      () async {
        // ── v13 fixture: recipes has TEXT timing columns; every other table
        // has the shape it always had. Seeded with data across many features.
        final file = await _writeFixture(
          version: 13,
          statements: [
            _v13RecipesTable,
            '''
            CREATE TABLE "ingredients" (
              "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              "name" TEXT NOT NULL,
              "preferred_unit" TEXT NULL,
              "nutrition_ref" TEXT NULL
            )
          ''',
            '''
            CREATE TABLE "recipe_steps" (
              "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              "recipe_id" INTEGER NOT NULL,
              "step_number" INTEGER NOT NULL,
              "content" TEXT NOT NULL
            )
          ''',
            '''
            CREATE TABLE "recipe_ingredients" (
              "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              "recipe_id" INTEGER NOT NULL,
              "section_id" INTEGER NULL,
              "ingredient_id" INTEGER NOT NULL,
              "qty" REAL NULL,
              "unit" TEXT NULL,
              "notes" TEXT NULL,
              "active_alternative_index" INTEGER NULL
            )
          ''',
            '''
            CREATE TABLE "shopping_lists" (
              "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              "name" TEXT NOT NULL,
              "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
              "archived_at" INTEGER NULL
            )
          ''',
            '''
            CREATE TABLE "meal_slots" (
              "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              "date" INTEGER NOT NULL,
              "meal_type" TEXT NOT NULL,
              "slot_name" TEXT NOT NULL,
              "recipe_id" INTEGER NULL,
              "notes" TEXT NULL,
              UNIQUE ("date", "meal_type")
            )
          ''',
            // Recipes exercising every legacy timing shape:
            //  1. ISO strings ("PT15M") — what URL imports stored on v13
            //  2. human text ("15 min", "1 hr 30 min") — the brief parser era
            //  3. empty string and NULL — never set
            '''
            INSERT INTO "recipes"
              (id, name, source_url, source_type, servings, description,
               nutrition_json, notes, prep_time, cook_time, total_time)
            VALUES
              (1, 'ISO Recipe', 'https://example.com/1', 'url', 4, 'A recipe',
               '{}', 'note1', 'PT15M', 'PT30M', 'PT45M'),
              (2, 'Human Recipe', NULL, 'manual', NULL, 'Two', NULL, NULL,
               '15 min', '1 hr 30 min', ''),
              (3, 'Null Recipe', NULL, 'ocr', 2, NULL, NULL, NULL, NULL, NULL, NULL)
          ''',
            '''
            INSERT INTO "ingredients" (id, name, preferred_unit)
            VALUES (1, 'salt', 'tsp')
          ''',
            '''
            INSERT INTO "recipe_steps" (id, recipe_id, step_number, content)
            VALUES (1, 1, 1, 'Mix well')
          ''',
            '''
            INSERT INTO "recipe_ingredients" (id, recipe_id, ingredient_id, qty, unit)
            VALUES (1, 1, 1, 1.0, 'tsp')
          ''',
            '''
            INSERT INTO "shopping_lists" (id, name, created_at)
            VALUES (1, 'Weekly shop', 1750000000)
          ''',
            '''
            INSERT INTO "meal_slots" (id, date, meal_type, slot_name, recipe_id)
            VALUES (1, 1750000000, 'dinner', 'Dinner', 1)
          ''',
          ],
        );

        // ── Open: the real AppDatabase migration strategy runs 13 → 14.
        // Drift opens lazily on the first query, so the fixture file must
        // stay in place until the test is finished.
        final db = AppDatabase.connect(NativeDatabase(File(file)));
        addTearDown(() async {
          await db.close();
          File(file).parent.deleteSync(recursive: true);
        });

        // Sanity: the upgrade actually ran and advanced the version.
        final version =
            (await db.customSelect('PRAGMA user_version').getSingle())
                .read<int>('user_version');
        expect(version, 14);

        // recipes: id/name/etc preserved, timing converted to integer minutes.
        final recipes = await db.select(db.recipes).get();
        expect(recipes, hasLength(3));

        final iso = recipes.singleWhere((r) => r.id == 1);
        expect(iso.name, 'ISO Recipe');
        expect(iso.sourceUrl, 'https://example.com/1');
        expect(iso.sourceType, 'url');
        expect(iso.servings, 4);
        expect(iso.description, 'A recipe');
        expect(iso.nutritionJson, '{}');
        expect(iso.notes, 'note1');
        expect(iso.prepTime, 15);
        expect(iso.cookTime, 30);
        expect(iso.totalTime, 45);

        final human = recipes.singleWhere((r) => r.id == 2);
        expect(human.prepTime, 15);
        expect(human.cookTime, 90);
        expect(human.totalTime, isNull); // '' is not a duration

        final noTiming = recipes.singleWhere((r) => r.id == 3);
        expect(noTiming.prepTime, isNull);
        expect(noTiming.cookTime, isNull);
        expect(noTiming.totalTime, isNull);

        // Timing columns now have INTEGER type.
        final cols = (await db.customSelect('PRAGMA table_info(recipes)').get())
            .map(
              (r) =>
                  (name: r.read<String>('name'), type: r.read<String>('type')),
            )
            .toList();
        for (final col in ['prep_time', 'cook_time', 'total_time']) {
          final info = cols.singleWhere((c) => c.name == col);
          expect(
            info.type,
            'INTEGER',
            reason: '$col should be INTEGER after v14',
          );
        }

        // Every other feature's data is untouched: steps, ingredients, shopping
        // lists and meal slots all survive with their foreign keys intact.
        final steps = await db.select(db.recipeSteps).get();
        expect(steps, hasLength(1));
        expect(steps.single.recipeId, 1);
        expect(steps.single.content, 'Mix well');

        final ingredients = await db.select(db.recipeIngredients).get();
        expect(ingredients, hasLength(1));
        expect(ingredients.single.recipeId, 1);
        expect(ingredients.single.ingredientId, 1);
        expect(ingredients.single.qty, 1.0);

        final lists = await db.select(db.shoppingLists).get();
        expect(lists, hasLength(1));
        expect(lists.single.name, 'Weekly shop');

        final slots = await db.select(db.mealSlots).get();
        expect(slots, hasLength(1));
        expect(slots.single.recipeId, 1);
        expect(slots.single.mealType, 'dinner');
      },
    );
  });

  group('ancient schema → v14 migration', () {
    test(
      'adds missing recipes columns as NULL and keeps existing data',
      () async {
        // ── v11-style fixture: recipes predates notes/description/timing.
        final file = await _writeFixture(
          version: 11,
          statements: [
            '''
            CREATE TABLE "recipes" (
              "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              "name" TEXT NOT NULL,
              "source_url" TEXT NULL,
              "source_type" TEXT NOT NULL DEFAULT 'manual',
              "servings" INTEGER NULL
            )
          ''',
            '''
            INSERT INTO "recipes" (id, name, source_url, source_type, servings)
            VALUES (1, 'Old Recipe', 'https://example.com/old', 'manual', 2)
          ''',
          ],
        );

        final db = AppDatabase.connect(NativeDatabase(File(file)));
        addTearDown(() async {
          await db.close();
          File(file).parent.deleteSync(recursive: true);
        });

        final recipe = (await db.select(db.recipes).get()).single;
        expect(recipe.id, 1);
        expect(recipe.name, 'Old Recipe');
        expect(recipe.sourceUrl, 'https://example.com/old');
        expect(recipe.servings, 2);

        // New columns added, all NULL — nothing fabricated.
        expect(recipe.notes, isNull);
        expect(recipe.description, isNull);
        expect(recipe.prepTime, isNull);
        expect(recipe.cookTime, isNull);
        expect(recipe.totalTime, isNull);
      },
    );
  });
}
