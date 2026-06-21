import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

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
  IntColumn get listId => integer().references(ShoppingLists, #id)();
  TextColumn get storeName => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class ShoppingListSections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId => integer().references(ShoppingListStores, #id)();
  TextColumn get sectionName => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class ShoppingListItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sectionId => integer().references(ShoppingListSections, #id)();
  IntColumn get ingredientId => integer().references(Ingredients, #id).nullable()();
  TextColumn get rawText => text()();
  RealColumn get qty => real().nullable()();
  TextColumn get unit => text().nullable()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get sourceType => text().withDefault(const Constant('manual'))();
  IntColumn get servings => integer().nullable()();
  TextColumn get nutritionJson => text().nullable()();
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

class MealPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
}

class MealPlanDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().references(MealPlans, #id)();
  DateTimeColumn get date => dateTime()();
}

class MealSlots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayId => integer().references(MealPlanDays, #id)();
  TextColumn get slotName => text()();
  IntColumn get recipeId => integer().references(Recipes, #id).nullable()();
  TextColumn get notes => text().nullable()();
}

class PantryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  // 1 = always available, 2 = bulk staple, 3 = per-recipe
  IntColumn get tier => integer().withDefault(const Constant(3))();
  BoolColumn get userConfirmed => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {ingredientId}
      ];
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
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
  MealPlans,
  MealPlanDays,
  MealSlots,
  PantryItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Destructive reset — wipe all tables and recreate from scratch.
          // Safe for dev: no production data exists.
          final tables = (await customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name != 'sqlite_sequence'",
          ).get())
              .map((r) => r.read<String>('name'))
              .toList();
          await customStatement('PRAGMA foreign_keys = OFF');
          for (final t in tables) {
            await customStatement('DROP TABLE IF EXISTS "$t"');
          }
          await customStatement('PRAGMA foreign_keys = ON');
          await m.createAll();
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'pantry');
}
