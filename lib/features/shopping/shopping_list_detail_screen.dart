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
        data: (storeList) => ListView.builder(
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
    final name =
        await promptText(context, title: 'New store', hint: 'Store name');
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

class _SectionTile extends ConsumerStatefulWidget {
  final ShoppingListSection section;
  final ShoppingListOps ops;

  const _SectionTile({required this.section, required this.ops});

  @override
  ConsumerState<_SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends ConsumerState<_SectionTile> {
  bool _isDropTarget = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsProvider(widget.section.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DragTarget<ShoppingListItem>(
          onWillAcceptWithDetails: (_) {
            setState(() => _isDropTarget = true);
            return true;
          },
          onLeave: (_) => setState(() => _isDropTarget = false),
          onAcceptWithDetails: (details) async {
            setState(() => _isDropTarget = false);
            final item = details.data;
            if (item.sectionId == widget.section.id) return;
            final currentItems =
                await ref.read(itemsProvider(widget.section.id).future);
            await widget.ops.moveItem(
              item.id,
              widget.section.id,
              currentItems.length,
            );
          },
          builder: (context, candidates, rejected) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _isDropTarget
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.4)
                    : null,
              ),
              child: Slidable(
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) async {
                        final newName = await promptText(
                          context,
                          title: 'Rename section',
                          hint: 'Section name',
                          initial: widget.section.sectionName,
                        );
                        if (newName != null && newName.isNotEmpty) {
                          await widget.ops
                              .renameSection(widget.section.id, newName);
                        }
                      },
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Rename',
                    ),
                    SlidableAction(
                      onPressed: (_) =>
                          widget.ops.deleteSection(widget.section.id),
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
                          widget.section.sectionName,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
            );
          },
        ),
        items.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('Error: $e'),
          data: (itemList) {
            if (itemList.isEmpty) return const SizedBox.shrink();
            return ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemList.length,
              itemBuilder: (context, index) {
                final item = itemList[index];
                return _buildReorderableItem(context, item, index);
              },
              onReorderItem: (oldIndex, newIndex) {
                widget.ops.reorderItemInSection(
                  widget.section.id,
                  itemList[oldIndex].id,
                  newIndex,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReorderableItem(
    BuildContext context,
    ShoppingListItem item,
    int index,
  ) {
    final pref = ref.watch(unitPreferenceProvider).valueOrNull ??
        UnitPreference.metric;

    return KeyedSubtree(
      key: ValueKey(item.id),
      child: Row(
        children: [
          Expanded(
            child: LongPressDraggable<ShoppingListItem>(
              data: item,
              delay: const Duration(milliseconds: 400),
              feedback: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 64,
                  child: _ItemContent(
                    item: item,
                    ops: widget.ops,
                    pref: pref,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _ItemContent(
                  item: item,
                  ops: widget.ops,
                  pref: pref,
                ),
              ),
              child: _ItemContent(
                item: item,
                ops: widget.ops,
                pref: pref,
              ),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(
                Icons.drag_handle,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(BuildContext context) async {
    final text =
        await promptText(context, title: 'Add item', hint: 'Item name');
    if (text != null && text.isNotEmpty) {
      await widget.ops.addItem(widget.section.id, text);
    }
  }
}

// ── Item content (used in both normal and dragging feedback) ─────────────────

class _ItemContent extends StatelessWidget {
  final ShoppingListItem item;
  final ShoppingListOps ops;
  final UnitPreference pref;

  const _ItemContent({
    required this.item,
    required this.ops,
    required this.pref,
  });

  @override
  Widget build(BuildContext context) {
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
        return Text(
            '${UnitRegistry.formatQty(item.qty!)} ${unit.abbreviation}');
      }
      final display = UnitRegistry.preferredDisplayUnit(unit.family, pref);
      final qty = UnitRegistry.convert(item.qty!, unit, display);
      return Text('${UnitRegistry.formatQty(qty)} ${display.abbreviation}');
    }
    final raw = UnitRegistry.formatQty(item.qty!);
    return Text(item.unit != null ? '$raw ${item.unit}' : raw);
  }
}
