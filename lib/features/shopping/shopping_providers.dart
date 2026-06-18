import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/main.dart';

// ── Shopping Lists ─────────────────────────────────────────────────────────

final shoppingListsProvider = StreamProvider<List<ShoppingList>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.shoppingLists)
        ..where((t) => t.archivedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
});

final archivedListsProvider = StreamProvider<List<ShoppingList>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.shoppingLists)
        ..where((t) => t.archivedAt.isNotNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
});

// ── Stores for a list ──────────────────────────────────────────────────────

final storesProvider =
    StreamProvider.family<List<ShoppingListStore>, int>((ref, listId) {
  final db = ref.watch(dbProvider);
  return (db.select(db.shoppingListStores)
        ..where((t) => t.listId.equals(listId))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();
});

// ── Sections for a store ───────────────────────────────────────────────────

final sectionsProvider =
    StreamProvider.family<List<ShoppingListSection>, int>((ref, storeId) {
  final db = ref.watch(dbProvider);
  return (db.select(db.shoppingListSections)
        ..where((t) => t.storeId.equals(storeId))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();
});

// ── Items for a section ────────────────────────────────────────────────────

final itemsProvider =
    StreamProvider.family<List<ShoppingListItem>, int>((ref, sectionId) {
  final db = ref.watch(dbProvider);
  return (db.select(db.shoppingListItems)
        ..where((t) => t.sectionId.equals(sectionId))
        ..orderBy([
          (t) => OrderingTerm.asc(t.checked),
          (t) => OrderingTerm.asc(t.id),
        ]))
      .watch();
});

// ── Operations ─────────────────────────────────────────────────────────────

class ShoppingListOps {
  final AppDatabase db;
  ShoppingListOps(this.db);

  Future<int> createList(String name) =>
      db.into(db.shoppingLists).insert(
            ShoppingListsCompanion.insert(name: name),
          );

  Future<void> renameList(int id, String name) =>
      (db.update(db.shoppingLists)..where((t) => t.id.equals(id)))
          .write(ShoppingListsCompanion(name: Value(name)));

  Future<void> archiveList(int id) =>
      (db.update(db.shoppingLists)..where((t) => t.id.equals(id))).write(
        ShoppingListsCompanion(archivedAt: Value(DateTime.now())),
      );

  Future<void> unarchiveList(int id) =>
      (db.update(db.shoppingLists)..where((t) => t.id.equals(id))).write(
        ShoppingListsCompanion(archivedAt: const Value(null)),
      );

  Future<void> deleteList(int id) async {
    final stores = await (db.select(db.shoppingListStores)
          ..where((t) => t.listId.equals(id)))
        .get();
    for (final store in stores) {
      await deleteStore(store.id);
    }
    await (db.delete(db.shoppingLists)..where((t) => t.id.equals(id))).go();
  }

  Future<int> addStore(int listId, String name) async {
    final count = await (db.select(db.shoppingListStores)
          ..where((t) => t.listId.equals(listId)))
        .get()
        .then((l) => l.length);
    final storeId = await db.into(db.shoppingListStores).insert(
          ShoppingListStoresCompanion.insert(
            listId: listId,
            storeName: name,
            sortOrder: Value(count),
          ),
        );
    await addSection(storeId, 'General');
    return storeId;
  }

  Future<void> renameStore(int storeId, String name) =>
      (db.update(db.shoppingListStores)
            ..where((t) => t.id.equals(storeId)))
          .write(ShoppingListStoresCompanion(storeName: Value(name)));

  Future<void> deleteStore(int storeId) async {
    final sections = await (db.select(db.shoppingListSections)
          ..where((t) => t.storeId.equals(storeId)))
        .get();
    for (final section in sections) {
      await deleteSection(section.id);
    }
    await (db.delete(db.shoppingListStores)
          ..where((t) => t.id.equals(storeId)))
        .go();
  }

  Future<int> addSection(int storeId, String name) async {
    final count = await (db.select(db.shoppingListSections)
          ..where((t) => t.storeId.equals(storeId)))
        .get()
        .then((l) => l.length);
    return db.into(db.shoppingListSections).insert(
          ShoppingListSectionsCompanion.insert(
            storeId: storeId,
            sectionName: name,
            sortOrder: Value(count),
          ),
        );
  }

  Future<void> renameSection(int sectionId, String name) =>
      (db.update(db.shoppingListSections)
            ..where((t) => t.id.equals(sectionId)))
          .write(ShoppingListSectionsCompanion(sectionName: Value(name)));

  Future<void> deleteSection(int sectionId) async {
    await (db.delete(db.shoppingListItems)
          ..where((t) => t.sectionId.equals(sectionId)))
        .go();
    await (db.delete(db.shoppingListSections)
          ..where((t) => t.id.equals(sectionId)))
        .go();
  }

  Future<void> addItem(
    int sectionId,
    String rawText, {
    double? qty,
    String? unit,
    int? ingredientId,
  }) async {
    final normalised = rawText.toLowerCase().trim();

    // Look for an existing unchecked match in this section
    final query = db.select(db.shoppingListItems)
      ..where((t) {
        final base = t.sectionId.equals(sectionId) & t.checked.equals(false);
        if (ingredientId != null) {
          return base &
              (t.ingredientId.equals(ingredientId) |
                  t.rawText.lower().equals(normalised));
        }
        return base & t.rawText.lower().equals(normalised);
      })
      ..limit(1);

    final existing = await query.getSingleOrNull();

    if (existing != null && existing.qty != null && qty != null) {
      final existingUnit = UnitRegistry.parse(existing.unit);
      final newUnit = UnitRegistry.parse(unit);

      // Case A: exact same unit ID — preserve unit, add qty directly
      final sameId = existingUnit != null &&
          newUnit != null &&
          existingUnit.id == newUnit.id;
      // Case B: cross-unit within weight or volume (never for count)
      final crossConvertible = existingUnit != null &&
          newUnit != null &&
          existingUnit.id != newUnit.id &&
          existingUnit.family == newUnit.family &&
          existingUnit.family != UnitFamily.count;
      // Case C: both truly unitless (null string, not just unrecognised)
      final bothUnitless = existing.unit == null && unit == null;

      if (sameId) {
        await (db.update(db.shoppingListItems)
              ..where((t) => t.id.equals(existing.id)))
            .write(ShoppingListItemsCompanion(
          qty: Value(existing.qty! + qty),
        ));
        return;
      } else if (crossConvertible) {
        final canonical = UnitRegistry.canonicalUnit(existingUnit.family);
        final stacked =
            UnitRegistry.convert(existing.qty!, existingUnit, canonical) +
                UnitRegistry.convert(qty, newUnit, canonical);
        await (db.update(db.shoppingListItems)
              ..where((t) => t.id.equals(existing.id)))
            .write(ShoppingListItemsCompanion(
          qty: Value(stacked),
          unit: Value(canonical.id),
        ));
        return;
      } else if (bothUnitless) {
        await (db.update(db.shoppingListItems)
              ..where((t) => t.id.equals(existing.id)))
            .write(ShoppingListItemsCompanion(
          qty: Value(existing.qty! + qty),
        ));
        return;
      }
    }

    await db.into(db.shoppingListItems).insert(
          ShoppingListItemsCompanion.insert(
            sectionId: sectionId,
            rawText: rawText,
            qty: Value(qty),
            unit: Value(unit),
            ingredientId: Value(ingredientId),
          ),
        );
  }

  Future<void> toggleItem(int itemId, bool checked) =>
      (db.update(db.shoppingListItems)..where((t) => t.id.equals(itemId)))
          .write(ShoppingListItemsCompanion(checked: Value(checked)));

  Future<void> deleteItem(int itemId) =>
      (db.delete(db.shoppingListItems)..where((t) => t.id.equals(itemId)))
          .go();

  Future<void> clearChecked(int sectionId) =>
      (db.delete(db.shoppingListItems)
            ..where((t) =>
                t.sectionId.equals(sectionId) & t.checked.equals(true)))
          .go();
}

final shoppingOpsProvider = Provider<ShoppingListOps>((ref) {
  return ShoppingListOps(ref.watch(dbProvider));
});
