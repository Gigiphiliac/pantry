import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/utils/ingredient_dedup.dart';
import 'package:pantry/main.dart';

import 'pantry_providers.dart';

const _tierLabels = {
  3: 'Per-Recipe',
  2: 'Bulk Staples',
  1: 'Always Available',
};

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(pantryEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search ingredients…',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              )
            : const Text('Pantry'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _searchController.clear();
                _query = '';
              }
            }),
          ),
        ],
      ),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allEntries) {
          final filtered = _query.isEmpty
              ? allEntries
              : allEntries
                  .where((e) => e.ingredientName
                      .toLowerCase()
                      .contains(_query.toLowerCase()))
                  .toList();

          final tier3 = filtered.where((e) => e.tier == 3).toList();
          final tier2 = filtered.where((e) => e.tier == 2).toList();
          final tier1 = filtered.where((e) => e.tier == 1).toList();

          return Column(
            children: [
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? 'No ingredients yet.\nTap + to create one.'
                              : 'No results for "$_query".',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView(
                        children: [
                          if (tier3.isNotEmpty) ...[
                            _TierHeader(label: _tierLabels[3]!),
                            ...tier3.map((e) => _PantryRow(entry: e)),
                          ],
                          if (tier2.isNotEmpty) ...[
                            _TierHeader(label: _tierLabels[2]!),
                            ...tier2.map((e) => _PantryRow(entry: e)),
                          ],
                          if (tier1.isNotEmpty) ...[
                            _TierHeader(label: _tierLabels[1]!),
                            ...tier1.map((e) => _PantryRow(entry: e)),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addIngredient(context),
        tooltip: 'Add to pantry',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addIngredient(BuildContext context) async {
    final nameController = TextEditingController();
    int selectedTier = 3;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add to Pantry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ingredient name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 3, icon: Icon(Icons.menu_book_outlined)),
                  ButtonSegment(value: 2, icon: Icon(Icons.inventory_2_outlined)),
                  ButtonSegment(value: 1, icon: Icon(Icons.kitchen_outlined)),
                ],
                selected: {selectedTier},
                onSelectionChanged: (s) =>
                    setDialogState(() => selectedTier = s.first),
              ),
              const SizedBox(height: 6),
              Text(
                const {3: 'Per-Recipe', 2: 'Bulk Staple', 1: 'Always Available'}[selectedTier]!,
                style: Theme.of(ctx).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final db = ref.read(dbProvider);
    final ops = ref.read(pantryOpsProvider);
    final ingredientId = await getOrCreateIngredient(db, name);
    await ops.addFromStocktake(ingredientId, selectedTier);
  }
}

class _TierHeader extends StatelessWidget {
  final String label;
  const _TierHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _PantryRow extends ConsumerWidget {
  final PantryEntry entry;
  const _PantryRow({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: SizedBox(
        width: 12,
        height: 12,
        child: entry.userConfirmed
            ? null
            : Container(
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
      ),
      title: Text(entry.ingredientName),
      subtitle: entry.preferredUnit != null
          ? Text(entry.preferredUnit!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => _showEditSheet(context, ref),
    );
  }

  Future<void> _showEditSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EditPantryItemSheet(entry: entry),
    );
  }
}

class _EditPantryItemSheet extends ConsumerStatefulWidget {
  final PantryEntry entry;
  const _EditPantryItemSheet({required this.entry});

  @override
  ConsumerState<_EditPantryItemSheet> createState() =>
      _EditPantryItemSheetState();
}

class _EditPantryItemSheetState extends ConsumerState<_EditPantryItemSheet> {
  late int _selectedTier;
  late TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.entry.tier;
    _unitController =
        TextEditingController(text: widget.entry.preferredUnit ?? '');
  }

  @override
  void dispose() {
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = ref.read(pantryOpsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.entry.ingredientName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (!widget.entry.userConfirmed)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Category',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 3, icon: Icon(Icons.menu_book_outlined)),
              ButtonSegment(value: 2, icon: Icon(Icons.inventory_2_outlined)),
              ButtonSegment(value: 1, icon: Icon(Icons.kitchen_outlined)),
            ],
            selected: {_selectedTier},
            onSelectionChanged: (s) =>
                setState(() => _selectedTier = s.first),
          ),
          const SizedBox(height: 6),
          Text(
            const {3: 'Per-Recipe', 2: 'Bulk Staple', 1: 'Always Available'}[_selectedTier]!,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text('Preferred unit (optional)',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _unitController,
            decoration: const InputDecoration(
              hintText: 'e.g. kg, ml, bunch',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await ops.setTier(widget.entry.pantryItemId, _selectedTier);
              final unit = _unitController.text.trim();
              if (unit != (widget.entry.preferredUnit ?? '')) {
                await ops.setPreferredUnit(
                    widget.entry.ingredientId, unit.isEmpty ? null : unit);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
