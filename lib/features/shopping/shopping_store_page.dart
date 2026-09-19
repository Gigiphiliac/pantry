import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/features/shopping/shopping_providers.dart';
import 'package:pantry/features/shopping/shopping_section.dart';
import 'package:pantry/features/shopping/shopping_item_tile.dart';

class ShoppingStorePage extends ConsumerStatefulWidget {
  final ShoppingListStore store;
  final ShoppingListOps ops;

  const ShoppingStorePage({
    super.key,
    required this.store,
    required this.ops,
  });

  @override
  ConsumerState<ShoppingStorePage> createState() => _ShoppingStorePageState();
}

class _ShoppingStorePageState extends ConsumerState<ShoppingStorePage> {
  bool _isUngroupedDropTarget = false;

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(sectionsProvider(widget.store.id));

    return sections.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (sectionList) => _buildPage(context, sectionList),
    );
  }

  Widget _buildPage(BuildContext context, List<ShoppingListSection> sectionList) {
    final ungrouped = ref.watch(ungroupedItemsProvider(widget.store.id));
    final allItems = ref.watch(storeItemsProvider(widget.store.id));
    final hasNoItems = allItems.valueOrNull?.isEmpty ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ungrouped items area ──────────────────────────────────────
          DragTarget<ShoppingListItem>(
            onWillAcceptWithDetails: (details) {
              if (details.data.storeId != widget.store.id) return false;
              if (details.data.sectionId == null) return false;
              setState(() => _isUngroupedDropTarget = true);
              return true;
            },
            onLeave: (_) => setState(() => _isUngroupedDropTarget = false),
            onAcceptWithDetails: (details) {
              setState(() => _isUngroupedDropTarget = false);
              ref
                  .read(shoppingOpsProvider)
                  .moveItem(details.data.id, null);
            },
            builder: (context, candidates, rejected) {
              final isEmpty = ungrouped.isEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isUngroupedDropTarget
                        ? Theme.of(context).colorScheme.primary
                        : isEmpty
                            ? Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.6)
                            : Colors.transparent,
                    width: _isUngroupedDropTarget ? 1.5 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _isUngroupedDropTarget
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                margin:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                padding: isEmpty
                    ? const EdgeInsets.symmetric(vertical: 6, horizontal: 12)
                    : EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ungrouped.isNotEmpty)
                      ...ungrouped.map((item) => ShoppingItemTile(
                        item: item,
                        ops: widget.ops,
                      )),
                    if (isEmpty)
                      SizedBox(
                        height: 32,
                        child: Center(
                          child: Text(
                            _isUngroupedDropTarget
                                ? 'Drop here to ungroup'
                                : hasNoItems
                                    ? 'Create a new item'
                                    : 'Drop to ungroup',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                              color: _isUngroupedDropTarget
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // ── Sections ──────────────────────────────────────────────────
          ...sectionList.map((section) => ShoppingSection(
            section: section,
            ops: widget.ops,
            storeId: widget.store.id,
          )),

          // ── Bottom padding ────────────────────────────────────────────
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
