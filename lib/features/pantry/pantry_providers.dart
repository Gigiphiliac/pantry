import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/main.dart';

import 'pantry_ops.dart';

// ── Library (current PantryEntry, unchanged) ─────────────────────────────────

class PantryEntry {
  final int pantryItemId;
  final int ingredientId;
  final String ingredientName;
  final String? preferredUnit;
  final int tier;
  final bool userConfirmed;

  const PantryEntry({
    required this.pantryItemId,
    required this.ingredientId,
    required this.ingredientName,
    this.preferredUnit,
    required this.tier,
    required this.userConfirmed,
  });
}

/// All pantry entries joined with ingredient names, ordered tier DESC then name ASC.
final pantryEntriesProvider = StreamProvider<List<PantryEntry>>((ref) {
  final db = ref.watch(dbProvider);
  final query = db.select(db.pantryItems).join([
    innerJoin(
      db.ingredients,
      db.ingredients.id.equalsExp(db.pantryItems.ingredientId),
    ),
  ])
    ..orderBy([
      OrderingTerm.desc(db.pantryItems.tier),
      OrderingTerm.asc(db.ingredients.name),
    ]);
  return query.watch().map((rows) => rows.map((row) {
        final p = row.readTable(db.pantryItems);
        final i = row.readTable(db.ingredients);
        return PantryEntry(
          pantryItemId: p.id,
          ingredientId: i.id,
          ingredientName: i.name,
          preferredUnit: i.preferredUnit,
          tier: p.tier,
          userConfirmed: p.userConfirmed,
        );
      }).toList());
});

/// Flat map of ingredientId → tier for quick lookups (e.g. shopping list display).
final pantryTierMapProvider = StreamProvider<Map<int, int>>((ref) {
  final db = ref.watch(dbProvider);
  return db.select(db.pantryItems).watch().map((rows) => {
        for (final row in rows) row.ingredientId: row.tier,
      });
});

// ── Stock (new) ────────────────────────────────────────────────────────────────

class StockEntry {
  final int stockId;
  final int ingredientId;
  final String ingredientName;
  final double? onHandQty;
  final String? onHandUnit;
  final int categoryId;
  final String categoryName;
  final String? notes;

  const StockEntry({
    required this.stockId,
    required this.ingredientId,
    required this.ingredientName,
    this.onHandQty,
    this.onHandUnit,
    required this.categoryId,
    required this.categoryName,
    this.notes,
  });
}

/// All stock categories ordered by sortOrder.
final stockCategoriesProvider = StreamProvider<List<PantryStockCategory>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.pantryStockCategories)
    ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();
});

/// All stock items joined with ingredient and category names, flat list.
final allStockProvider = StreamProvider<List<StockEntry>>((ref) {
  final db = ref.watch(dbProvider);
  final query = db.select(db.pantryStock).join([
    innerJoin(
      db.ingredients,
      db.ingredients.id.equalsExp(db.pantryStock.ingredientId),
    ),
    innerJoin(
      db.pantryStockCategories,
      db.pantryStockCategories.id.equalsExp(db.pantryStock.categoryId),
    ),
  ]);
  return query.watch().map((rows) => rows.map((row) {
        final s = row.readTable(db.pantryStock);
        final i = row.readTable(db.ingredients);
        final c = row.readTable(db.pantryStockCategories);
        return StockEntry(
          stockId: s.id,
          ingredientId: i.id,
          ingredientName: i.name,
          onHandQty: s.onHandQty,
          onHandUnit: s.onHandUnit,
          categoryId: c.id,
          categoryName: c.name,
          notes: s.notes,
        );
      }).toList());
});

/// Stock items filtered by category (derived from allStockProvider).
final stockByCategoryProvider =
    Provider.family<List<StockEntry>, int>((ref, categoryId) {
  final all = ref.watch(allStockProvider).valueOrNull ?? [];
  return all.where((s) => s.categoryId == categoryId).toList();
});

// ── Operations ─────────────────────────────────────────────────────────────────

final pantryOpsProvider = Provider<PantryOps>((ref) {
  return PantryOps(ref.watch(dbProvider));
});
