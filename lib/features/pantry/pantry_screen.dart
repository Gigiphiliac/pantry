import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/utils/ingredient_dedup.dart';
import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/main.dart';
import 'package:pantry/features/shopping/prompt_utils.dart';

import 'pantry_providers.dart';
import 'ingredient_library_screen.dart';

// ── Main Pantry Screen (live stock view) ──────────────────────────────────────

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
    final categories = ref.watch(stockCategoriesProvider);
    final allStock = ref.watch(allStockProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search stock…',
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
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Ingredient Library',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const IngredientLibraryScreen(),
              ),
            ),
          ),
        ],
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (catList) {
          if (catList.isEmpty) {
            return const Center(
              child: Text('No storage categories configured.'),
            );
          }

          final allItems = allStock.valueOrNull ?? [];
          // Filter items by query, preserving category context.
          final filtered = _query.isEmpty
              ? allItems
              : allItems
                  .where((s) => s.ingredientName
                      .toLowerCase()
                      .contains(_query.toLowerCase()))
                  .toList();
          final filteredIds = filtered.map((s) => s.ingredientId).toSet();

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              for (final cat in catList) ...[
                PantryCategorySection(
                  category: cat,
                  query: _query,
                  filteredIds: filteredIds,
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStockItem,
        tooltip: 'Add to stock',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addStockItem() async {
    final db = ref.read(dbProvider);
    final ops = ref.read(pantryOpsProvider);
    var categories = await (db.select(db.pantryStockCategories)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    if (categories.isEmpty) {
      // Seed defaults so the + button works on a fresh database.
      await ops.createCategory('Fridge');
      await ops.createCategory('Freezer');
      await ops.createCategory('Pantry Cupboard');
      categories = await (db.select(db.pantryStockCategories)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();
      if (categories.isEmpty) return;
    }

    if (!mounted) return;

    // Pick a category first
    final category = await showDialog<PantryStockCategory>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Where does it go?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final cat in categories)
              ListTile(
                title: Text(cat.name),
                leading: const Icon(Icons.kitchen_outlined),
                onTap: () => Navigator.pop(ctx, cat),
              ),
          ],
        ),
      ),
    );

    if (category == null || !mounted) return;

    await showChainableDialog(
      context: context,
      title: 'Add to ${category.name}',
      builder: (fs) {
        fs.selectedCategoryId = category.id;
        return _AddStockForm(formState: fs);
      },
      onAdd: (fs) async {
        final name = fs.nameController.text.trim();
        if (name.isEmpty) return;
        final ingredientId = await getOrCreateIngredient(db, name);

        final qtyText = fs.qtyController.text.trim();
        final qty = qtyText.isNotEmpty ? double.tryParse(qtyText) : null;

        await ops.addStock(
          ingredientId,
          category.id,
          qty: qty,
          unit: fs.selectedUnit,
        );
      },
    );
  }
}

// ── Add Stock Form ─────────────────────────────────────────────────────────────

class _AddStockForm extends ConsumerStatefulWidget {
  final ChainableFormState formState;
  const _AddStockForm({required this.formState});

  @override
  ConsumerState<_AddStockForm> createState() => _AddStockFormState();
}

class _AddStockFormState extends ConsumerState<_AddStockForm> {

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ingredient name
          TextField(
            controller: widget.formState.nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ingredient name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Quantity + Unit row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: widget.formState.qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Qty',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(widget.formState.selectedUnit),
                  initialValue: widget.formState.selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    ...UnitRegistry.weightUnits,
                    ...UnitRegistry.volumeUnits,
                    ...UnitRegistry.countUnits,
                  ].map((u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(u.abbreviation),
                      )).toList(),
                  onChanged: (v) => setState(() =>
                    widget.formState.selectedUnit = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category Section Widget ────────────────────────────────────────────────────

class PantryCategorySection extends ConsumerStatefulWidget {
  final PantryStockCategory category;
  final String query;
  final Set<int> filteredIds;

  const PantryCategorySection({
    super.key,
    required this.category,
    required this.query,
    required this.filteredIds,
  });

  @override
  ConsumerState<PantryCategorySection> createState() =>
      _PantryCategorySectionState();
}

class _PantryCategorySectionState extends ConsumerState<PantryCategorySection> {
  bool _isDropTarget = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(stockByCategoryProvider(widget.category.id));
    final ops = ref.read(pantryOpsProvider);

    // Hide empty section during search.
    if (widget.query.isNotEmpty && items.isEmpty) return const SizedBox.shrink();

    return DragTarget<StockEntry>(
      onWillAcceptWithDetails: (details) {
        // Only accept if not already in this category.
        if (details.data.categoryId == widget.category.id) return false;
        setState(() => _isDropTarget = true);
        return true;
      },
      onLeave: (_) => setState(() => _isDropTarget = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDropTarget = false);
        ops.moveStockItem(details.data.stockId, widget.category.id);
      },
      builder: (context, candidates, rejected) {
        final displayItems = widget.query.isEmpty
            ? items
            : items.where((s) => widget.filteredIds.contains(s.ingredientId)).toList();

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
                // ── Category header row ──
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  padding: const EdgeInsets.fromLTRB(32, 6, 16, 6),
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.category.name,
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
                // ── Items list ──
                if (displayItems.isNotEmpty)
                  ...displayItems.map(
                    (item) => PantryStockTile(
                      entry: item,
                      categories: ref.watch(stockCategoriesProvider).valueOrNull ?? [],
                    ),
                  ),
                if (displayItems.isEmpty && widget.query.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No items in ${widget.category.name}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addItem(BuildContext context) async {
    final ops = ref.read(pantryOpsProvider);

    await showChainableDialog(
      context: context,
      title: 'Add to ${widget.category.name}',
      builder: (fs) {
        // Pre-set the category
        fs.selectedCategoryId = widget.category.id;
        return _AddStockForm(formState: fs);
      },
      onAdd: (fs) async {
        final name = fs.nameController.text.trim();
        if (name.isEmpty) return;
        final db = ref.read(dbProvider);
        final ingredientId = await getOrCreateIngredient(db, name);

        final qtyText = fs.qtyController.text.trim();
        final qty = qtyText.isNotEmpty ? double.tryParse(qtyText) : null;

        await ops.addStock(
          ingredientId,
          widget.category.id,
          qty: qty,
          unit: fs.selectedUnit,
        );
      },
    );
  }
}

// ── Stock Tile Widget ──────────────────────────────────────────────────────────

class PantryStockTile extends ConsumerStatefulWidget {
  final StockEntry entry;
  final List<PantryStockCategory> categories;

  const PantryStockTile({
    super.key,
    required this.entry,
    required this.categories,
  });

  @override
  ConsumerState<PantryStockTile> createState() => _PantryStockTileState();
}

class _PantryStockTileState extends ConsumerState<PantryStockTile> {
  @override
  Widget build(BuildContext context) {
    final ops = ref.read(pantryOpsProvider);

    final unit = UnitRegistry.parse(widget.entry.onHandUnit);
    final qtyText = widget.entry.onHandQty != null
        ? '${UnitRegistry.formatQty(widget.entry.onHandQty!)} ${unit?.abbreviation ?? widget.entry.onHandUnit ?? ""}'
            .trim()
        : 'Unmeasured';

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ops.deleteStockItem(widget.entry.stockId),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Remove',
          ),
        ],
      ),
      child: LongPressDraggable<StockEntry>(
        data: widget.entry,
        delay: const Duration(milliseconds: 400),
        feedback: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 64,
            child: ListTile(
              title: Text(widget.entry.ingredientName),
              subtitle: Text(qtyText),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _StockTileContent(entry: widget.entry, qtyText: qtyText),
        ),
        onDragEnd: (_) {
          // Move is handled by DragTarget.onAcceptWithDetails.
        },
        child: _StockTileContent(entry: widget.entry, qtyText: qtyText),
      ),
    );
  }
}

class _StockTileContent extends StatelessWidget {
  final StockEntry entry;
  final String qtyText;

  const _StockTileContent({
    required this.entry,
    required this.qtyText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        title: Text(entry.ingredientName),
        subtitle: Text(qtyText, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => _showEditSheet(context),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EditStockSheet(entry: entry),
    );
  }
}

// ── Stock Edit Bottom Sheet ────────────────────────────────────────────────────

class _EditStockSheet extends ConsumerStatefulWidget {
  final StockEntry entry;
  const _EditStockSheet({required this.entry});

  @override
  ConsumerState<_EditStockSheet> createState() => _EditStockSheetState();
}

class _EditStockSheetState extends ConsumerState<_EditStockSheet> {
  late TextEditingController _qtyController;
  String? _selectedUnit;
  int? _selectedCategoryId;
  late TextEditingController _notesController;
  List<PantryStockCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.entry.onHandQty != null
          ? UnitRegistry.formatQty(widget.entry.onHandQty!)
          : '',
    );
    _selectedUnit = widget.entry.onHandUnit;
    _selectedCategoryId = widget.entry.categoryId;
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    _loadCategories();
  }

  void _loadCategories() async {
    final db = ref.read(dbProvider);
    final cats = await (db.select(db.pantryStockCategories)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    if (mounted) setState(() => _categories = cats);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = ref.read(pantryOpsProvider);
    final categories = _categories;

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
          // Header
          Text(
            widget.entry.ingredientName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),

          // Quantity row with stepper
          Text('Quantity', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  final current = double.tryParse(_qtyController.text) ?? 0;
                  if (current > 0) {
                    _qtyController.text = (current - 1).toString();
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final current = double.tryParse(_qtyController.text) ?? 0;
                  _qtyController.text = (current + 1).toString();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Unit dropdown
          Text('Unit', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedUnit,
            decoration: const InputDecoration(
              hintText: 'Select unit',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              ...UnitRegistry.weightUnits,
              ...UnitRegistry.volumeUnits,
              ...UnitRegistry.countUnits,
            ].map((u) => DropdownMenuItem(
                  value: u.id,
                  child: Text(u.displayName),
                )).toList(),
            onChanged: (v) => setState(() => _selectedUnit = v),
          ),
          const SizedBox(height: 12),

          // Category dropdown
          Text('Storage location',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _selectedCategoryId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: categories
                .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v),
          ),
          const SizedBox(height: 12),

          // Notes
          Text('Notes (optional)',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'e.g. in the back of the fridge',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await ops.deleteStockItem(widget.entry.stockId);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Remove from stock'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final qtyText = _qtyController.text.trim();
                    final qty = qtyText.isNotEmpty ? double.tryParse(qtyText) : null;
                    await ops.updateStockQty(widget.entry.stockId, qty);
                    await ops.updateStockUnit(widget.entry.stockId, _selectedUnit);
                    if (_selectedCategoryId != null &&
                        _selectedCategoryId != widget.entry.categoryId) {
                      await ops.moveStockItem(
                          widget.entry.stockId, _selectedCategoryId!);
                    }
                    final notes = _notesController.text.trim();
                    await ops.updateStockNotes(
                        widget.entry.stockId, notes.isEmpty ? null : notes);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
