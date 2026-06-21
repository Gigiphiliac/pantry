import 'package:drift/drift.dart';
import 'package:pantry/db/database.dart';

class PantryOps {
  final AppDatabase db;
  PantryOps(this.db);

  /// Auto-create from recipe import — no-op if pantry entry already exists.
  Future<void> autoCreatePantryItem(int ingredientId) async {
    await db.into(db.pantryItems).insert(
          PantryItemsCompanion.insert(
            ingredientId: ingredientId,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Manual stock-take add — creates or overwrites with the user's chosen tier.
  Future<void> addFromStocktake(int ingredientId, int tier) async {
    await db.into(db.pantryItems).insertOnConflictUpdate(
          PantryItemsCompanion.insert(
            ingredientId: ingredientId,
            tier: Value(tier),
            userConfirmed: const Value(true),
          ),
        );
  }

  /// Sets tier and marks item as confirmed.
  Future<void> setTier(int pantryItemId, int tier) async {
    await (db.update(db.pantryItems)
          ..where((t) => t.id.equals(pantryItemId)))
        .write(PantryItemsCompanion(
      tier: Value(tier),
      userConfirmed: const Value(true),
    ));
  }

  /// Marks item as confirmed without changing tier.
  Future<void> confirmItem(int pantryItemId) async {
    await (db.update(db.pantryItems)
          ..where((t) => t.id.equals(pantryItemId)))
        .write(const PantryItemsCompanion(
      userConfirmed: Value(true),
    ));
  }

  /// Removes a pantry entry. The underlying ingredient record is preserved.
  Future<void> deletePantryItem(int pantryItemId) async {
    await (db.delete(db.pantryItems)
          ..where((t) => t.id.equals(pantryItemId)))
        .go();
  }

  /// Updates the ingredient's preferred unit.
  Future<void> setPreferredUnit(int ingredientId, String? unit) async {
    await (db.update(db.ingredients)
          ..where((t) => t.id.equals(ingredientId)))
        .write(IngredientsCompanion(preferredUnit: Value(unit)));
  }
}
