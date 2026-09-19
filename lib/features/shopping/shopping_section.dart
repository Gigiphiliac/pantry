import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/features/shopping/shopping_providers.dart';
import 'package:pantry/features/shopping/shopping_item_tile.dart';
import 'package:pantry/features/shopping/prompt_utils.dart';

class ShoppingSection extends ConsumerStatefulWidget {
  final ShoppingListSection section;
  final ShoppingListOps ops;
  final int storeId;

  const ShoppingSection({
    super.key,
    required this.section,
    required this.ops,
    required this.storeId,
  });

  @override
  ConsumerState<ShoppingSection> createState() => _ShoppingSectionState();
}

class _ShoppingSectionState extends ConsumerState<ShoppingSection> {
  bool _isDropTarget = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(
      sectionItemsProvider((
      storeId: widget.storeId,
      sectionId: widget.section.id,
      )),
    );

    return DragTarget<ShoppingListItem>(
      onWillAcceptWithDetails: (details) {
        // Only accept items from the same store.
        if (details.data.storeId != widget.storeId) return false;
        // No-op if already in this section.
        if (details.data.sectionId == widget.section.id) return false;
        setState(() => _isDropTarget = true);
        return true;
      },
      onLeave: (_) => setState(() => _isDropTarget = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDropTarget = false);
        ref
            .read(shoppingOpsProvider)
            .moveItem(details.data.id, widget.section.id);
      },
      builder: (context, candidates, rejected) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDropTarget
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: _isDropTarget ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _isDropTarget
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.2)
                : Colors.transparent,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
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
              if (items.isNotEmpty)
                ...items.map((item) => ShoppingItemTile(
                  item: item,
                  ops: widget.ops,
                )),
            ],
          ),
        ),
      );
      },
    );
  }

  Future<void> _addItem(BuildContext context) async {
    final text =
    await promptText(context, title: 'Add item', hint: 'Item name');
    if (text != null && text.isNotEmpty) {
      await widget.ops.addItem(
        widget.storeId,
        sectionId: widget.section.id,
        rawText: text,
      );
    }
  }
}
