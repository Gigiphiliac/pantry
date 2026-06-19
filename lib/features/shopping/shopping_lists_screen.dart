import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shopping_providers.dart';
import 'shopping_list_detail_screen.dart';
import 'prompt_utils.dart';

class ShoppingListsScreen extends ConsumerWidget {
  const ShoppingListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListsProvider);
    final ops = ref.watch(shoppingOpsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archived lists',
            onPressed: () => _showArchived(context, ref),
          ),
        ],
      ),
      body: lists.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? const Center(
                child: Text(
                  'No lists yet.\nTap + to create one.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final list = items[i];
                  return ListTile(
                    title: Text(list.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ShoppingListDetailScreen(listId: list.id, listName: list.name),
                      ),
                    ),
                    onLongPress: () => _showListMenu(context, ref, ops, list.id, list.name),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createList(context, ops),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createList(BuildContext context, ShoppingListOps ops) async {
    final name = await promptText(context, title: 'New list', hint: 'List name');
    if (name != null && name.isNotEmpty) await ops.createList(name);
  }

  void _showListMenu(
    BuildContext context,
    WidgetRef ref,
    ShoppingListOps ops,
    int id,
    String name,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(context);
                final newName = await promptText(context, title: 'Rename list', hint: 'List name', initial: name);
                if (newName != null && newName.isNotEmpty) await ops.renameList(id, newName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () async {
                Navigator.pop(context);
                await ops.archiveList(id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete list?'),
                    content: Text('Delete "$name" and all its items? This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) await ops.deleteList(id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showArchived(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _ArchivedListsScreen()),
    );
  }
}

class _ArchivedListsScreen extends ConsumerWidget {
  const _ArchivedListsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(archivedListsProvider);
    final ops = ref.watch(shoppingOpsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Archived Lists')),
      body: lists.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No archived lists'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final list = items[i];
                  return ListTile(
                    title: Text(list.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      tooltip: 'Restore',
                      onPressed: () => ops.unarchiveList(list.id),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
