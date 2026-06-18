import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/features/settings/settings_screen.dart';

import 'shopping_providers.dart';
import 'prompt_utils.dart';

class ShoppingListDetailScreen extends ConsumerWidget {
  final int listId;
  final String listName;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(storesProvider(listId));
    final ops = ref.watch(shoppingOpsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(listName)),
      body: stores.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (storeList) => storeList.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No stores yet.'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add store'),
                      onPressed: () => _addStore(context, ops),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: storeList.length,
                itemBuilder: (context, i) =>
                    _StoreSection(store: storeList[i], ops: ops),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.store),
        label: const Text('Add store'),
        onPressed: () => _addStore(context, ops),
      ),
    );
  }

  Future<void> _addStore(BuildContext context, ShoppingListOps ops) async {
    final name = await promptText(context, title: 'New store', hint: 'Store name');
    if (name != null && name.isNotEmpty) await ops.addStore(listId, name);
  }
}

class _StoreSection extends ConsumerWidget {
  final ShoppingListStore store;
  final ShoppingListOps ops;

  const _StoreSection({required this.store, required this.ops});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(sectionsProvider(store.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slidable(
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) async {
                  final newName = await promptText(
                    context,
                    title: 'Rename store',
                    hint: 'Store name',
                    initial: store.storeName,
                  );
                  if (newName != null && newName.isNotEmpty) {
                    await ops.renameStore(store.id, newName);
                  }
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Rename',
              ),
              SlidableAction(
                onPressed: (_) => ops.deleteStore(store.id),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            width: double.infinity,
            child: Row(
              children: [
                const Icon(Icons.store_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store.storeName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Section'),
                  onPressed: () => _addSection(context),
                ),
              ],
            ),
          ),
        ),
        sections.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('Error: $e'),
          data: (sectionList) => Column(
            children: sectionList
                .map((s) => _SectionTile(section: s, ops: ops))
                .toList(),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _addSection(BuildContext context) async {
    final name = await promptText(
      context,
      title: 'New section',
      hint: 'Section name (e.g. Produce)',
    );
    if (name != null && name.isNotEmpty) await ops.addSection(store.id, name);
  }
}

class _SectionTile extends ConsumerWidget {
  final ShoppingListSection section;
  final ShoppingListOps ops;

  const _SectionTile({required this.section, required this.ops});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider(section.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slidable(
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) async {
                  final newName = await promptText(
                    context,
                    title: 'Rename section',
                    hint: 'Section name',
                    initial: section.sectionName,
                  );
                  if (newName != null && newName.isNotEmpty) {
                    await ops.renameSection(section.id, newName);
                  }
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Rename',
              ),
              SlidableAction(
                onPressed: (_) => ops.deleteSection(section.id),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.fromLTRB(32, 6, 16, 6),
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.sectionName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Item'),
                  onPressed: () => _addItem(context),
                ),
              ],
            ),
          ),
        ),
        items.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('Error: $e'),
          data: (itemList) => Column(
            children: itemList
                .map((item) => _ItemTile(item: item, ops: ops))
                .toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _addItem(BuildContext context) async {
    final text =
        await promptText(context, title: 'Add item', hint: 'Item name');
    if (text != null && text.isNotEmpty) await ops.addItem(section.id, text);
  }
}

class _ItemTile extends ConsumerWidget {
  final ShoppingListItem item;
  final ShoppingListOps ops;

  const _ItemTile({required this.item, required this.ops});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(unitPreferenceProvider).valueOrNull ??
        UnitPreference.metric;

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ops.deleteItem(item.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: CheckboxListTile(
        value: item.checked,
        onChanged: (v) => ops.toggleItem(item.id, v ?? false),
        title: Text(
          item.rawText,
          style: item.checked
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Theme.of(context).disabledColor,
                )
              : null,
        ),
        subtitle: _buildQtySubtitle(item, pref),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 48, vertical: 0),
      ),
    );
  }

  Widget? _buildQtySubtitle(ShoppingListItem item, UnitPreference pref) {
    if (item.qty == null) return null;
    final unit = UnitRegistry.parse(item.unit);
    if (unit != null) {
      if (unit.family == UnitFamily.count) {
        // Count units never convert — show their own abbreviation
        return Text('${UnitRegistry.formatQty(item.qty!)} ${unit.abbreviation}');
      }
      final display = UnitRegistry.preferredDisplayUnit(unit.family, pref);
      final qty = UnitRegistry.convert(item.qty!, unit, display);
      return Text('${UnitRegistry.formatQty(qty)} ${display.abbreviation}');
    }
    // Unrecognised unit — show as stored
    final raw = UnitRegistry.formatQty(item.qty!);
    return Text(item.unit != null ? '$raw ${item.unit}' : raw);
  }
}
