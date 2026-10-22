import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:pantry/core/recipes/recipe_text_parser.dart';

part 'database.g.dart';

/// The three fixed meal types in a day.
enum MealType {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner');

  const MealType(this.value);
  final String value;

  static MealType fromString(String s) =>
      MealType.values.firstWhere((m) => m.value == s);
}

// ── Tables ────────────────────────────────────────────────────────────────────

class Ingredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get preferredUnit => text().nullable()();
  TextColumn get nutritionRef => text().nullable()();
}

class IngredientAliases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get alias => text().unique()();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
}

class ShoppingLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class ShoppingListStores extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get listId =>
      integer().references(ShoppingLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get storeName => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class ShoppingListSections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId => integer().references(
    ShoppingListStores,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get sectionName => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class ShoppingListItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId => integer().references(
    ShoppingListStores,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get sectionId => integer()
      .references(ShoppingListSections, #id, onDelete: KeyAction.setNull)
      .nullable()();
  IntColumn get ingredientId =>
      integer().references(Ingredients, #id).nullable()();
  TextColumn get rawText => text()();
  RealColumn get qty => real().nullable()();
  TextColumn get unit => text().nullable()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
}

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get sourceType => text().withDefault(const Constant('manual'))();
  IntColumn get servings => integer().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get nutritionJson => text().nullable()();
  TextColumn get notes => text().nullable()();
  // Timings stored as integer minutes.
  IntColumn get prepTime => integer().nullable()();
  IntColumn get cookTime => integer().nullable()();
  IntColumn get totalTime => integer().nullable()();
}

class RecipeSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().references(Recipes, #id)();
  IntColumn get stepNumber => integer()();
  TextColumn get content => text()();
}

class RecipeIngredientSections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().references(Recipes, #id)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class RecipeIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().references(Recipes, #id)();
  IntColumn get sectionId =>
      integer().references(RecipeIngredientSections, #id).nullable()();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get qty => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get notes => text().nullable()();
  // null = primary; 0 = first alternative; 1 = second; etc.
  IntColumn get activeAlternativeIndex => integer().nullable()();
}

class RecipeIngredientAlternatives extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeIngredientId =>
      integer().references(RecipeIngredients, #id)();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get qty => real().nullable()();
  TextColumn get unit => text().nullable()();
  IntColumn get sortOrder => integer()();
}

class MealSlots extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()();
  TextColumn get slotName => text()();
  IntColumn get recipeId => integer().references(Recipes, #id).nullable()();
  TextColumn get notes => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {date, mealType},
  ];
}

class PantryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  // 1 = always available, 2 = bulk staple, 3 = per-recipe
  IntColumn get tier => integer().withDefault(const Constant(3))();
  BoolColumn get userConfirmed =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {ingredientId},
  ];
}

class PantryStockCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class PantryStock extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  IntColumn get categoryId =>
      integer().references(PantryStockCategories, #id)();
  RealColumn get onHandQty => real().nullable()();
  TextColumn get onHandUnit => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {ingredientId},
  ];
}

/// Training data captured from OCR scans with user corrections.
///
/// Raw OCR input and the final structured recipe are stored as JSON so they
/// can be exported and fed back into the training pipeline.
class OcrTrainingData extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawJson => text()();
  TextColumn get correctedJson => text()();
  IntColumn get imageWidth => integer().nullable()();
  IntColumn get imageHeight => integer().nullable()();
  TextColumn get sourceType => text().withDefault(const Constant('ocr'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Ingredients,
    IngredientAliases,
    ShoppingLists,
    ShoppingListStores,
    ShoppingListSections,
    ShoppingListItems,
    Recipes,
    RecipeSteps,
    RecipeIngredientSections,
    RecipeIngredients,
    RecipeIngredientAlternatives,
    MealSlots,
    PantryItems,
    PantryStockCategories,
    PantryStock,
    OcrTrainingData,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Creates a database backed by an arbitrary [QueryExecutor].
  /// Used for testing with e.g. [NativeDatabase.memory()].
  AppDatabase.connect(super.e);

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Seed default stock categories
      await batch((b) {
        b.insertAll(pantryStockCategories, [
          PantryStockCategoriesCompanion.insert(
            name: 'Fridge',
            sortOrder: const Value(0),
          ),
          PantryStockCategoriesCompanion.insert(
            name: 'Freezer',
            sortOrder: const Value(1),
          ),
          PantryStockCategoriesCompanion.insert(
            name: 'Pantry Cupboard',
            sortOrder: const Value(2),
          ),
        ]);
      });
    },
    onUpgrade: (m, from, to) async {
      // Versioned, non-destructive migration chain. Each step upgrades from
      // ANY older version to the next, so existing user data is never wiped.
      // Add future steps as `if (from < N) await _upgradeToN(m);`.
      if (from < 14) {
        await _upgradeTo14(m);
      }
    },
  );

  /// Schema 14: timing fields become integer minutes.
  ///
  /// Non-destructive — handles any previous version:
  ///  - creates any tables that didn't exist in older schemas (no-op otherwise)
  ///  - adds missing `recipes` columns (`notes`, `description`, timings) as NULL
  ///  - converts legacy timing TEXT values to integer minutes and rebuilds the
  ///    `recipes` table so the timing columns have INTEGER type.
  Future<void> _upgradeTo14(Migrator m) async {
    // Safety net: create any tables that didn't exist in older schemas.
    await m.createAll();

    final columns = (await customSelect(
      'PRAGMA table_info(recipes)',
    ).get()).map((r) => r.read<String>('name')).toSet();
    final hasNotes = columns.contains('notes');
    final hasDescription = columns.contains('description');
    final hasTiming = columns.contains('prep_time');

    if (!hasNotes) {
      await m.addColumn(recipes, recipes.notes);
    }
    if (!hasDescription) {
      await m.addColumn(recipes, recipes.description);
    }

    if (!hasTiming) {
      // Schemas predating the timing fields: add them as NULL.
      await m.addColumn(recipes, recipes.prepTime);
      await m.addColumn(recipes, recipes.cookTime);
      await m.addColumn(recipes, recipes.totalTime);
      return;
    }

    // Timing columns exist as TEXT. Normalise legacy values to plain integer
    // strings first (so SQLite coerces them exactly on rebuild), then rebuild
    // the table so the columns become INTEGER.
    final rows = await customSelect(
      'SELECT id, prep_time, cook_time, total_time FROM recipes',
    ).get();
    for (final row in rows) {
      await customUpdate(
        'UPDATE recipes SET prep_time = ?, cook_time = ?, total_time = ? '
        'WHERE id = ?',
        variables: [
          Variable<int>(
            RecipeTextParser.parseDurationMinutes(
              row.read<String?>('prep_time'),
            ),
          ),
          Variable<int>(
            RecipeTextParser.parseDurationMinutes(
              row.read<String?>('cook_time'),
            ),
          ),
          Variable<int>(
            RecipeTextParser.parseDurationMinutes(
              row.read<String?>('total_time'),
            ),
          ),
          Variable<int>(row.read<int>('id')),
        ],
      );
    }
    // Drift's documented mechanism for column-type changes (runs SQLite's
    // 12-step procedure, preserving foreign keys, indexes and triggers).
    // ignore: experimental_member_use
    await m.alterTable(TableMigration(recipes));
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'pantry');
}
