import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/features/shopping/shopping_providers.dart';
import 'package:pantry/features/shopping/shopping_store_page.dart';
import 'package:pantry/features/shopping/prompt_utils.dart';

class ShoppingListDetailScreen extends ConsumerStatefulWidget {
  final int listId;
  final String listName;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  ConsumerState<ShoppingListDetailScreen> createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState
    extends ConsumerState<ShoppingListDetailScreen> {
  bool _isFabExpanded = false;

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storesProvider(widget.listId));
    final ops = ref.watch(shoppingOpsProvider);

    return stores.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(widget.listName)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(widget.listName)),
        body: Center(child: Text('Error: $e')),
      ),
      data: (storeList) => _buildWithStores(context, ops, storeList),
    );
  }

  Widget _buildWithStores(
    BuildContext context,
    ShoppingListOps ops,
    List<ShoppingListStore> storeList,
  ) {
    if (storeList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.listName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No stores yet.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.store),
                label: const Text('Add store'),
                onPressed: () => _addStore(context, ops),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: storeList.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.listName),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: storeList
                .map((store) => Tab(text: store.storeName))
                .toList(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add store',
              onPressed: () => _addStore(context, ops),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'manage_stores') {
                  _showStoreManager(context, ops, storeList);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'manage_stores',
                  child: ListTile(
                    leading: Icon(Icons.store),
                    title: Text('Manage stores'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Listener(
          onPointerDown: (_) {
            if (_isFabExpanded) {
              setState(() => _isFabExpanded = false);
            }
          },
          child: TabBarView(
            children: storeList.map((store) {
              return ShoppingStorePage(
                store: store,
                ops: ops,
              );
            }).toList(),
          ),
        ),
        floatingActionButton: Builder(
          builder: (fabContext) => _buildFab(storeList, ops, fabContext),
        ),
      ),
    );
  }

  Widget _buildFab(
    List<ShoppingListStore> storeList,
    ShoppingListOps ops,
    BuildContext fabContext,
  ) {
    final tabController = DefaultTabController.maybeOf(fabContext);
    final currentIndex = tabController?.index ?? 0;
    final currentStore = storeList[currentIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _MiniFab(
          visible: _isFabExpanded,
          icon: Icons.add_box,
          label: 'Add group',
          onPressed: () {
            setState(() => _isFabExpanded = false);
            _addGroup(context, ops, currentStore.id);
          },
        ),
        const SizedBox(height: 8),
        _MiniFab(
          visible: _isFabExpanded,
          icon: Icons.playlist_add,
          label: 'Add item',
          onPressed: () {
            setState(() => _isFabExpanded = false);
            _addUngroupedItem(context, ops, currentStore.id);
          },
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          onPressed: () =>
              setState(() => _isFabExpanded = !_isFabExpanded),
          child: AnimatedRotation(
            turns: _isFabExpanded ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Future<void> _addStore(BuildContext context, ShoppingListOps ops) async {
    final name =
        await promptText(context, title: 'New store', hint: 'Store name');
    if (name != null && name.isNotEmpty) {
      await ops.addStore(widget.listId, name);
    }
  }

  Future<void> _addUngroupedItem(
      BuildContext context, ShoppingListOps ops, int storeId) async {
    await promptItemText(
      context,
      title: 'Add item',
      hint: 'Item name',
      onAdd: (text) => ops.addItem(storeId, rawText: text),
    );
  }

  Future<void> _addGroup(
      BuildContext context, ShoppingListOps ops, int storeId) async {
    final name = await promptText(
      context,
      title: 'New group',
      hint: 'Group name (e.g. Produce)',
    );
    if (name != null && name.isNotEmpty) {
      await ops.addSection(storeId, name);
    }
  }

  void _showStoreManager(
    BuildContext context,
    ShoppingListOps ops,
    List<ShoppingListStore> storeList,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Manage Stores',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            ...storeList.map((store) => ListTile(
              leading: const Icon(Icons.store_outlined),
              title: Text(store.storeName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () async {
                      Navigator.pop(ctx);
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
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete store?'),
                          content: Text(
                              'Delete "${store.storeName}" and all its items?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ops.deleteStore(store.id);
                      }
                    },
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Mini-FAB for speed-dial ────────────────────────────────────────────────

class _MiniFab extends StatefulWidget {
  final bool visible;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MiniFab({
    required this.visible,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_MiniFab> createState() => _MiniFabState();
}

class _MiniFabState extends State<_MiniFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    if (widget.visible) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_MiniFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _controller.forward();
    } else if (!widget.visible && oldWidget.visible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width - 64;
    return ScaleTransition(
      scale: _scale,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: FloatingActionButton.extended(
          heroTag: widget.label,
          icon: Icon(widget.icon),
          label: Text(widget.label),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}
