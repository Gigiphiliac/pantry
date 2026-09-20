import 'package:drift/drift.dart';
import 'package:pantry/db/database.dart';

class PantryOps {
  final AppDatabase db;
  PantryOps(this.db);

  // ── Library (existing) ──────────────────────────────────────────────────

  /// Auto-create from recipe import — no-op if pantry entry already exists.
  Future<void> autoCreatePantryItem(int ingredientId) async {
    await db
        .into(db.pantryItems)
        .insert(
          PantryItemsCompanion.insert(ingredientId: ingredientId),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Manual stock-take add — creates or overwrites with the user's chosen tier.
  Future<void> addFromStocktake(int ingredientId, int tier) async {
    await db
        .into(db.pantryItems)
        .insertOnConflictUpdate(
          PantryItemsCompanion.insert(
            ingredientId: ingredientId,
            tier: Value(tier),
            userConfirmed: const Value(true),
          ),
        );
  }

  /// Sets tier and marks item as confirmed.
  Future<void> setTier(int pantryItemId, int tier) async {
    await (db.update(
      db.pantryItems,
    )..where((t) => t.id.equals(pantryItemId))).write(
      PantryItemsCompanion(tier: Value(tier), userConfirmed: const Value(true)),
    );
  }

  /// Marks item as confirmed without changing tier.
  Future<void> confirmItem(int pantryItemId) async {
    await (db.update(db.pantryItems)..where((t) => t.id.equals(pantryItemId)))
        .write(const PantryItemsCompanion(userConfirmed: Value(true)));
  }

  /// Removes a pantry entry. The underlying ingredient record is preserved.
  Future<void> deletePantryItem(int pantryItemId) async {
    await (db.delete(
      db.pantryItems,
    )..where((t) => t.id.equals(pantryItemId))).go();
  }

  /// Updates the ingredient's preferred unit.
  Future<void> setPreferredUnit(int ingredientId, String? unit) async {
    await (db.update(db.ingredients)..where((t) => t.id.equals(ingredientId)))
        .write(IngredientsCompanion(preferredUnit: Value(unit)));
  }

  // ── Stock (new) ─────────────────────────────────────────────────────────

  /// Add an ingredient to stock, auto-creating library entry if needed.
  Future<void> addStock(
    int ingredientId,
    int categoryId, {
    double? qty,
    String? unit,
    String? notes,
  }) async {
    await db
        .into(db.pantryStock)
        .insertOnConflictUpdate(
          PantryStockCompanion.insert(
            ingredientId: ingredientId,
            categoryId: categoryId,
            onHandQty: Value(qty),
            onHandUnit: Value(unit),
            notes: Value(notes),
          ),
        );
    // Also appear in the ingredient library (tier defaults to 3: Per-Recipe).
    await autoCreatePantryItem(ingredientId);
  }

  /// Update quantity for a stock item.
  Future<void> updateStockQty(int stockId, double? qty) async {
    await (db.update(db.pantryStock)..where((t) => t.id.equals(stockId))).write(
      PantryStockCompanion(onHandQty: Value(qty)),
    );
  }

  /// Update unit for a stock item.
  Future<void> updateStockUnit(int stockId, String? unit) async {
    await (db.update(db.pantryStock)..where((t) => t.id.equals(stockId))).write(
      PantryStockCompanion(onHandUnit: Value(unit)),
    );
  }

  /// Update notes for a stock item.
  Future<void> updateStockNotes(int stockId, String? notes) async {
    await (db.update(db.pantryStock)..where((t) => t.id.equals(stockId))).write(
      PantryStockCompanion(notes: Value(notes)),
    );
  }

  /// Move a stock item to a different category.
  Future<void> moveStockItem(int stockId, int newCategoryId) async {
    await (db.update(db.pantryStock)..where((t) => t.id.equals(stockId))).write(
      PantryStockCompanion(categoryId: Value(newCategoryId)),
    );
  }

  /// Remove a stock entry entirely. The ingredient and library entries are preserved.
  Future<void> deleteStockItem(int stockId) async {
    await (db.delete(db.pantryStock)..where((t) => t.id.equals(stockId))).go();
  }

  /// Clear all stock entries.
  Future<void> clearStock() async {
    await db.delete(db.pantryStock).go();
  }

  // ── Stock categories ────────────────────────────────────────────────────

  /// Create a new storage category.
  Future<int> createCategory(String name) async {
    final count = await (db.select(db.pantryStockCategories).get()).then(
      (l) => l.length,
    );
    return db
        .into(db.pantryStockCategories)
        .insert(
          PantryStockCategoriesCompanion.insert(
            name: name,
            sortOrder: Value(count),
          ),
        );
  }

  /// Rename a storage category.
  Future<void> renameCategory(int categoryId, String name) async {
    await (db.update(db.pantryStockCategories)
          ..where((t) => t.id.equals(categoryId)))
        .write(PantryStockCategoriesCompanion(name: Value(name)));
  }

  /// Reorder a storage category.
  Future<void> setCategorySortOrder(int categoryId, int sortOrder) async {
    await (db.update(db.pantryStockCategories)
          ..where((t) => t.id.equals(categoryId)))
        .write(PantryStockCategoriesCompanion(sortOrder: Value(sortOrder)));
  }

  /// Delete an empty storage category. Throws if it contains stock items.
  Future<void> deleteCategory(int categoryId) async {
    final stockCount =
        await (db.select(db.pantryStock)
              ..where((t) => t.categoryId.equals(categoryId)))
            .get()
            .then((l) => l.length);
    if (stockCount > 0) {
      throw ArgumentError(
        'Cannot delete category "$categoryId": $stockCount stock item(s) still in it. '
        'Move them first.',
      );
    }
    await (db.delete(
      db.pantryStockCategories,
    )..where((t) => t.id.equals(categoryId))).go();
  }

  /// Move all stock items from one category to another, then delete the source.
  Future<void> moveCategoryItems(int fromCategoryId, int toCategoryId) async {
    await (db.update(db.pantryStock)
          ..where((t) => t.categoryId.equals(fromCategoryId)))
        .write(PantryStockCompanion(categoryId: Value(toCategoryId)));
    await (db.delete(
      db.pantryStockCategories,
    )..where((t) => t.id.equals(fromCategoryId))).go();
  }
}
