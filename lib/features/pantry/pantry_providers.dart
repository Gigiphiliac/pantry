import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/main.dart';

import 'pantry_ops.dart';

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

final pantryOpsProvider = Provider<PantryOps>((ref) {
  return PantryOps(ref.watch(dbProvider));
});
