import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/features/meal_plans/meal_plan_providers.dart';
import 'package:pantry/features/meal_plans/recipe_picker_sheet.dart';
import 'package:pantry/features/meal_plans/swap_sheet.dart';
import 'package:pantry/features/recipes/recipe_detail_screen.dart';
import 'package:pantry/main.dart';

/// Pushed page for viewing and editing a single meal slot.
///
/// Works for both new (empty) and existing slots.
/// Auto-saves changes when the user pops the page.
class SlotDetailScreen extends ConsumerStatefulWidget {
  final DateTime date;
  final String mealType; // 'breakfast' | 'lunch' | 'dinner'

  const SlotDetailScreen({
    super.key,
    required this.date,
    required this.mealType,
  });

  @override
  ConsumerState<SlotDetailScreen> createState() => _SlotDetailScreenState();
}

class _SlotDetailScreenState extends ConsumerState<SlotDetailScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  MealSlotData? _slot;
  bool _dirty = false;
  bool _hasSaved = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _nameCtrl.addListener(_markDirty);
    _notesCtrl.addListener(_markDirty);
    _loadExistingSlot();
  }

  Future<void> _loadExistingSlot() async {
    final db = ref.read(dbProvider);
    final normalised = normaliseDate(widget.date);
    final rows =
        await (db.select(db.mealSlots)..where(
              (t) =>
                  t.date.equals(normalised) &
                  t.mealType.equals(widget.mealType),
            ))
            .get();
    if (!mounted) return;
    if (rows.isNotEmpty) {
      final slot = rows.first;
      setState(() {
        _slot = MealSlotData.fromMealSlot(slot);
        _nameCtrl.text = slot.slotName;
        _notesCtrl.text = slot.notes ?? '';
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _saveIfNeeded();
    _nameCtrl.removeListener(_markDirty);
    _notesCtrl.removeListener(_markDirty);
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  String get _mealLabel {
    switch (widget.mealType) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return widget.mealType;
    }
  }

  String get _subtitleText {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = dayNames[widget.date.weekday - 1];
    final dateStr = '${dayName} ${widget.date.day} ${_monthAbbr(widget.date)}';
    return '$dateStr · $_mealLabel';
  }

  String _monthAbbr(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[dt.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_mealLabel),
              Text(
                _subtitleText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _saveIfNeeded();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_slot?.slotName ?? _mealLabel),
              Text(
                _subtitleText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          actions: [
            if (_slot != null) ...[
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: 'Swap with…',
                onPressed: () => _openSwapSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear slot',
                onPressed: () => _clearSlot(context),
              ),
            ],
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Slot name ─────────────────────────────────────────
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Meal name',
                hintText: 'e.g. Spaghetti Bolognese',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // ── Recipe link ───────────────────────────────────────
            _buildRecipeSection(context, theme),
            const SizedBox(height: 16),

            // ── Notes ──────────────────────────────────────────────
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Any notes for this meal…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeSection(BuildContext context, ThemeData theme) {
    if (_slot?.recipeId == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.menu_book_outlined, size: 18),
        label: const Text('Link Recipe'),
        onPressed: () => _pickRecipe(context),
      );
    }

    // There IS a linked recipe — show it.
    return Card(
      child: ListTile(
        leading: const Icon(Icons.menu_book),
        title: Text(
          _slot!.slotName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: const Text('Tap to view recipe'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Replace name with recipe name action
            if (_slot!.recipeId != null && _nameCtrl.text != _slot!.slotName)
              IconButton(
                icon: const Icon(Icons.sync, size: 18),
                tooltip: 'Replace name with recipe name',
                onPressed: () {
                  _nameCtrl.text = _slot!.slotName;
                  _markDirty();
                },
              ),
            IconButton(
              icon: const Icon(Icons.link_off, size: 18),
              tooltip: 'Unlink recipe',
              onPressed: () => _unlinkRecipe(),
            ),
          ],
        ),
        onTap: () => _openRecipe(context),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _pickRecipe(BuildContext context) async {
    final recipe = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const RecipePickerSheet(),
    );
    if (recipe == null || !mounted) return;

    final ops = ref.read(mealPlanOpsProvider);

    if (_slot == null) {
      // New slot — create with recipe name auto-filled
      final newSlot = await ops.upsertSlot(
        date: widget.date,
        mealType: widget.mealType,
        slotName: recipe.name,
        recipeId: recipe.id,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      );
      setState(() {
        _slot = newSlot;
        _nameCtrl.text = recipe.name;
        _hasSaved = true;
      });
    } else {
      // Existing slot — link recipe
      await ops.linkRecipe(_slot!.id, recipe.id);
      // If name was empty or unchanged from placeholder, auto-fill
      if (_nameCtrl.text.isEmpty || _nameCtrl.text == _mealLabel) {
        _nameCtrl.text = recipe.name;
        await ops.updateSlotName(_slot!.id, recipe.name);
      }
      setState(() {
        _slot = MealSlotData(
          id: _slot!.id,
          date: _slot!.date,
          mealType: _slot!.mealType,
          slotName: _slot!.slotName,
          recipeId: recipe.id,
          notes: _slot!.notes,
        );
        _hasSaved = true;
      });
    }
  }

  Future<void> _unlinkRecipe() async {
    if (_slot == null) return;
    final ops = ref.read(mealPlanOpsProvider);
    await ops.linkRecipe(_slot!.id, null);
    setState(() {
      _slot = MealSlotData(
        id: _slot!.id,
        date: _slot!.date,
        mealType: _slot!.mealType,
        slotName: _slot!.slotName,
        recipeId: null,
        notes: _slot!.notes,
      );
    });
  }

  Future<void> _openRecipe(BuildContext context) async {
    if (_slot?.recipeId == null) return;
    // Fetch the full recipe to navigate to it
    final db = ref.read(dbProvider);
    final recipes = await (db.select(
      db.recipes,
    )..where((t) => t.id.equals(_slot!.recipeId!))).get();
    if (recipes.isEmpty) {
      // Recipe was deleted — show a message and clear the stale link
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This recipe has been deleted.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      final ops = ref.read(mealPlanOpsProvider);
      await ops.linkRecipe(_slot!.id, null);
      if (!mounted) return;
      setState(() {
        _slot = _slot!.copyWith(recipeId: null);
        _dirty = false;
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: recipes.first),
      ),
    );
  }

  Future<void> _openSwapSheet(BuildContext context) async {
    if (_slot == null) return;
    final weekStart = weekStartFor(widget.date);
    final slots = await ref.read(mealSlotsForWeekProvider(weekStart).future);

    final result = await showModalBottomSheet<SwapResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SwapSheet(
        weekStart: weekStart,
        currentSlot: _slot!,
        weekSlots: slots,
      ),
    );

    if (result == null || !mounted) return;

    final ops = ref.read(mealPlanOpsProvider);
    final targetDate = weekStart.add(Duration(days: result.dayOffset));

    await ops.swapSlots(
      sourceId: _slot!.id,
      sourceDate: _slot!.date,
      sourceMealType: _slot!.mealType,
      targetDate: targetDate,
      targetMealType: result.mealType,
    );
    // Invalidate the local stale slot so _saveIfNeeded doesn't
    // upsert at the old (date, mealType) and re-create it.
    _hasSaved = true;

    // If the swap moved us away, pop back to week view
    if (result.targetSlot != null &&
        (result.dayOffset != widget.date.difference(weekStart).inDays ||
            result.mealType != widget.mealType)) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _clearSlot(BuildContext context) async {
    if (_slot == null) return;
    _hasSaved = true; // Prevent auto-save from re-creating
    final ops = ref.read(mealPlanOpsProvider);
    await ops.clearSlot(_slot!.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveIfNeeded() async {
    if (_loading) return;
    if (_hasSaved) return; // Already saved via a direct action
    if (!_dirty) return;

    final ops = ref.read(mealPlanOpsProvider);
    final newSlot = await ops.upsertSlot(
      date: widget.date,
      mealType: widget.mealType,
      slotName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : _mealLabel,
      recipeId: _slot?.recipeId,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
    );
    _slot = newSlot;
    _hasSaved = true;
  }
}

/// Helper to compute Monday of the week containing [date].
DateTime weekStartFor(DateTime date) {
  final normalised = DateTime(date.year, date.month, date.day);
  final dow = normalised.weekday; // 1=Mon ... 7=Sun
  return normalised.subtract(Duration(days: dow - 1));
}
