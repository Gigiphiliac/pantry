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
}

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get sourceType => text().withDefault(const Constant('manual'))();
  IntColumn get servings => integer().nullable()();
  TextColumn get instructions => text().nullable()();
  TextColumn get nutritionJson => text().nullable()();
}

class RecipeIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().references(Recipes, #id)();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get qty => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get notes => text().nullable()();
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

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Ingredients,
  IngredientAliases,
  ShoppingLists,
  ShoppingListStores,
  ShoppingListSections,
  ShoppingListItems,
  Recipes,
  RecipeIngredients,
  MealPlans,
  MealPlanDays,
  MealSlots,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'pantry');
}
