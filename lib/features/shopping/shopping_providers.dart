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
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.id),
        ]))
      .watch();
});

// ── Operations ─────────────────────────────────────────────────────────────

class ShoppingListOps {
  final AppDatabase db;
  ShoppingListOps(this.db);

  Future<int> createList(String name) async {
    final listId = await db.into(db.shoppingLists).insert(
          ShoppingListsCompanion.insert(name: name),
        );
    // Every list starts with an Unsorted store so items can be added immediately
    await _createUnsortedStore(listId);
    return listId;
  }

  Future<int> _createUnsortedStore(int listId) async {
    final storeId = await db.into(db.shoppingListStores).insert(
          ShoppingListStoresCompanion.insert(
            listId: listId,
            storeName: 'Unsorted',
            sortOrder: const Value(-1),
          ),
        );
    await addSection(storeId, 'General');
    return storeId;
  }

  Future<int> getOrCreateUnsortedSection(int listId) async {
    final stores = await (db.select(db.shoppingListStores)
          ..where((t) =>
              t.listId.equals(listId) & t.storeName.equals('Unsorted')))
        .get();

    final int storeId;
    if (stores.isNotEmpty) {
      storeId = stores.first.id;
    } else {
      storeId = await _createUnsortedStore(listId);
    }

    final sections = await (db.select(db.shoppingListSections)
          ..where((t) => t.storeId.equals(storeId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    return sections.isNotEmpty
        ? sections.first.id
        : await addSection(storeId, 'General');
  }

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

  // ── Item stacking helpers ─────────────────────────────────────────────────

  Future<bool> _tryStack(
    ShoppingListItem existing,
    double? qty,
    String? unit,
  ) async {
    if (existing.qty == null || qty == null) return false;

    final existingUnit = UnitRegistry.parse(existing.unit);
    final newUnit = UnitRegistry.parse(unit);

    // Case A: same unit — add directly
    final sameId = existingUnit != null &&
        newUnit != null &&
        existingUnit.id == newUnit.id;

    // Case B: cross-unit within weight or volume (never for count)
    final crossConvertible = existingUnit != null &&
        newUnit != null &&
        existingUnit.id != newUnit.id &&
        existingUnit.family == newUnit.family &&
        existingUnit.family != UnitFamily.count;

    // Case C: both unitless
    final bothUnitless = existing.unit == null && unit == null;

    if (sameId || bothUnitless) {
      await (db.update(db.shoppingListItems)
            ..where((t) => t.id.equals(existing.id)))
          .write(ShoppingListItemsCompanion(
        qty: Value(existing.qty! + qty),
      ));
      return true;
    } else if (crossConvertible) {
      // Convert incoming qty to the existing item's unit — preserves display unit
      final stacked = existing.qty! + UnitRegistry.convert(qty, newUnit, existingUnit);
      await (db.update(db.shoppingListItems)
            ..where((t) => t.id.equals(existing.id)))
          .write(ShoppingListItemsCompanion(
        qty: Value(stacked),
      ));
      return true;
    }
    return false;
  }

  // ── addItem: section-scoped add/stack ─────────────────────────────────────

  Future<void> addItem(
    int sectionId,
    String rawText, {
    double? qty,
    String? unit,
    int? ingredientId,
  }) async {
    final normalised = rawText.toLowerCase().trim();

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

    if (existing != null && await _tryStack(existing, qty, unit)) return;

    final nextOrder = await (db.select(db.shoppingListItems)
          ..where((t) => t.sectionId.equals(sectionId)))
        .get()
        .then((l) => l.length);

    await db.into(db.shoppingListItems).insert(
          ShoppingListItemsCompanion.insert(
            sectionId: sectionId,
            rawText: rawText,
            qty: Value(qty),
            unit: Value(unit),
            ingredientId: Value(ingredientId),
            sortOrder: Value(nextOrder),
          ),
        );
  }

  // ── stackOrAddItem: list-scoped add/stack, falls back to Unsorted ─────────

  Future<void> stackOrAddItem(
    int listId,
    String rawText, {
    double? qty,
    String? unit,
    int? ingredientId,
  }) async {
    final normalised = rawText.toLowerCase().trim();

    // Gather all section IDs for this list
    final stores = await (db.select(db.shoppingListStores)
          ..where((t) => t.listId.equals(listId)))
        .get();
    final sectionIds = <int>[];
    for (final store in stores) {
      final sections = await (db.select(db.shoppingListSections)
            ..where((t) => t.storeId.equals(store.id)))
          .get();
      sectionIds.addAll(sections.map((s) => s.id));
    }

    // Search all unchecked items in the list for a match
    if (sectionIds.isNotEmpty) {
      final query = db.select(db.shoppingListItems)
        ..where((t) {
          final inSections = t.sectionId.isIn(sectionIds);
          final unchecked = t.checked.equals(false);
          if (ingredientId != null) {
            return inSections &
                unchecked &
                (t.ingredientId.equals(ingredientId) |
                    t.rawText.lower().equals(normalised));
          }
          return inSections & unchecked & t.rawText.lower().equals(normalised);
        })
        ..limit(1);

      final existing = await query.getSingleOrNull();
      if (existing != null && await _tryStack(existing, qty, unit)) return;
    }

    // No match found — add to Unsorted
    final sectionId = await getOrCreateUnsortedSection(listId);
    final nextOrder = await (db.select(db.shoppingListItems)
          ..where((t) => t.sectionId.equals(sectionId)))
        .get()
        .then((l) => l.length);

    await db.into(db.shoppingListItems).insert(
          ShoppingListItemsCompanion.insert(
            sectionId: sectionId,
            rawText: rawText,
            qty: Value(qty),
            unit: Value(unit),
            ingredientId: Value(ingredientId),
            sortOrder: Value(nextOrder),
          ),
        );
  }

  // ── moveItem: update section + sort position ──────────────────────────────

  Future<void> moveItem(
    int itemId,
    int targetSectionId,
    int targetSortOrder,
  ) async {
    // Shift items in the target section down to make room
    await db.customStatement(
      'UPDATE shopping_list_items SET sort_order = sort_order + 1 '
      'WHERE section_id = ? AND sort_order >= ?',
      [targetSectionId, targetSortOrder],
    );

    await (db.update(db.shoppingListItems)
          ..where((t) => t.id.equals(itemId)))
        .write(ShoppingListItemsCompanion(
      sectionId: Value(targetSectionId),
      sortOrder: Value(targetSortOrder),
    ));
  }

  Future<void> reorderItemInSection(
    int sectionId,
    int itemId,
    int newSortOrder,
  ) async {
    // Compact existing sort orders first
    final items = await (db.select(db.shoppingListItems)
          ..where((t) => t.sectionId.equals(sectionId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();

    final others = items.where((i) => i.id != itemId).toList();
    final clamped = newSortOrder.clamp(0, others.length);

    final reordered = [
      ...others.sublist(0, clamped),
      items.firstWhere((i) => i.id == itemId),
      ...others.sublist(clamped),
    ];

    for (var i = 0; i < reordered.length; i++) {
      await (db.update(db.shoppingListItems)
            ..where((t) => t.id.equals(reordered[i].id)))
          .write(ShoppingListItemsCompanion(sortOrder: Value(i)));
    }
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
