import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/main.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

List<ShoppingListItem> sortItemsAlphabetically(
    Iterable<ShoppingListItem> items,
    ) {
  return [...items]
    ..sort((a, b) {
      // Unchecked (false) before checked (true).
      if (a.checked != b.checked) return a.checked ? 1 : -1;
      return a.rawText.toLowerCase().compareTo(b.rawText.toLowerCase());
    });
}

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

// ── Items for a store ──────────────────────────────────────────────────────

final storeItemsProvider =
StreamProvider.family<List<ShoppingListItem>, int>((ref, storeId) {
  final db = ref.watch(dbProvider);
  return (db.select(db.shoppingListItems)
    ..where((t) => t.storeId.equals(storeId)))
      .watch()
      .map(sortItemsAlphabetically);
});

/// Items that belong to a section (derived from storeItemsProvider).
final sectionItemsProvider =
Provider.family<List<ShoppingListItem>, ({int storeId, int sectionId})>(
      (ref, param) {
    final items = ref.watch(storeItemsProvider(param.storeId)).valueOrNull ?? [];
    return items.where((i) => i.sectionId == param.sectionId).toList();
  },
);

/// Ungrouped items for a store (derived from storeItemsProvider).
final ungroupedItemsProvider = Provider.family<List<ShoppingListItem>, int>(
      (ref, storeId) {
    final items = ref.watch(storeItemsProvider(storeId)).valueOrNull ?? [];
    return items.where((i) => i.sectionId == null).toList();
  },
);

// ── Operations ─────────────────────────────────────────────────────────────

class ShoppingListOps {
  final AppDatabase db;
  ShoppingListOps(this.db);

  Future<int> createList(String name) async {
    final listId = await db.into(db.shoppingLists).insert(
      ShoppingListsCompanion.insert(name: name),
    );
    return listId;
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
    await (db.delete(db.shoppingLists)..where((t) => t.id.equals(id))).go();
  }

  Future<int> addStore(int listId, String name) async {
    final count = await (db.select(db.shoppingListStores)
      ..where((t) => t.listId.equals(listId)))
        .get()
        .then((l) => l.length);
    return db.into(db.shoppingListStores).insert(
      ShoppingListStoresCompanion.insert(
        listId: listId,
        storeName: name,
        sortOrder: Value(count),
      ),
    );
  }

  Future<void> renameStore(int storeId, String name) =>
      (db.update(db.shoppingListStores)
        ..where((t) => t.id.equals(storeId)))
          .write(ShoppingListStoresCompanion(storeName: Value(name)));

  Future<void> deleteStore(int storeId) async {
    // FK cascade handles items and sections.
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
    // FK SET NULL cascades items to ungrouped automatically.
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
      final stacked =
          existing.qty! + UnitRegistry.convert(qty, newUnit, existingUnit);
      await (db.update(db.shoppingListItems)
        ..where((t) => t.id.equals(existing.id)))
          .write(ShoppingListItemsCompanion(
        qty: Value(stacked),
      ));
      return true;
    }
    return false;
  }

  // ── addItem: store-scoped add/stack ───────────────────────────────────────

  Future<void> addItem(
      int storeId, {
        int? sectionId,
        required String rawText,
        double? qty,
        String? unit,
        int? ingredientId,
      }) async {
    final normalised = rawText.toLowerCase().trim();

    // Search for an existing unchecked match within the same store.
    final query = db.select(db.shoppingListItems)
      ..where((t) {
        final base = t.storeId.equals(storeId) & t.checked.equals(false);
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

    await db.into(db.shoppingListItems).insert(
      ShoppingListItemsCompanion.insert(
        storeId: storeId,
        sectionId: Value(sectionId),
        rawText: rawText,
        qty: Value(qty),
        unit: Value(unit),
        ingredientId: Value(ingredientId),
      ),
    );
  }

  // ── stackOrAddItem: list-scoped add/stack, falls back to first store ──────

  Future<void> stackOrAddItem(
      int listId,
      String rawText, {
        double? qty,
        String? unit,
        int? ingredientId,
      }) async {
    final normalised = rawText.toLowerCase().trim();

    // Gather all store IDs for this list.
    final stores = await (db.select(db.shoppingListStores)
      ..where((t) => t.listId.equals(listId)))
        .get();

    if (stores.isEmpty) {
      // No stores exist yet — create one with a default name.
      final storeId = await addStore(listId, 'Default');
      await addItem(
        storeId,
        rawText: rawText,
        qty: qty,
        unit: unit,
        ingredientId: ingredientId,
      );
      return;
    }

    // Search all unchecked items in the list for a match.
    final storeIds = stores.map((s) => s.id).toList();
    final query = db.select(db.shoppingListItems)
      ..where((t) {
        final inStore = t.storeId.isIn(storeIds);
        final unchecked = t.checked.equals(false);
        if (ingredientId != null) {
          return inStore &
          unchecked &
          (t.ingredientId.equals(ingredientId) |
          t.rawText.lower().equals(normalised));
        }
        return inStore & unchecked & t.rawText.lower().equals(normalised);
      })
      ..limit(1);

    final existing = await query.getSingleOrNull();

    if (existing != null && await _tryStack(existing, qty, unit)) return;

    // No match found — add to the first store as ungrouped.
    // TODO: This fallback to the first store is not final behaviour.
    //       See https://github.com/user/pantry/issues/NNN
    final firstStoreId = stores.first.id;
    await addItem(
      firstStoreId,
      rawText: rawText,
      qty: qty,
      unit: unit,
      ingredientId: ingredientId,
    );
  }

  // ── moveItem: change item's section (null = ungrouped) ────────────────────

  Future<void> moveItem(int itemId, int? destinationSectionId) async {
    // If destination is a section, verify it belongs to the same store as the item.
    if (destinationSectionId != null) {
      final item = await (db.select(db.shoppingListItems)
        ..where((t) => t.id.equals(itemId)))
          .getSingle();

      final section = await (db.select(db.shoppingListSections)
        ..where((t) => t.id.equals(destinationSectionId)))
          .getSingle();

      if (section.storeId != item.storeId) {
        throw ArgumentError(
          'Cannot move item to a section in a different store.',
        );
      }
    }

    await (db.update(db.shoppingListItems)
      ..where((t) => t.id.equals(itemId)))
        .write(ShoppingListItemsCompanion(
      sectionId: Value(destinationSectionId),
    ));
  }

  Future<void> toggleItem(int itemId, bool checked) =>
      (db.update(db.shoppingListItems)..where((t) => t.id.equals(itemId)))
          .write(ShoppingListItemsCompanion(checked: Value(checked)));

  Future<void> deleteItem(int itemId) =>
      (db.delete(db.shoppingListItems)..where((t) => t.id.equals(itemId)))
          .go();

  Future<void> clearChecked(int storeId) =>
      (db.delete(db.shoppingListItems)
        ..where((t) =>
        t.storeId.equals(storeId) & t.checked.equals(true)))
          .go();
}

final shoppingOpsProvider = Provider<ShoppingListOps>((ref) {
  return ShoppingListOps(ref.watch(dbProvider));
});
