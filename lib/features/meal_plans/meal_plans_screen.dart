import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/features/meal_plans/meal_plan_providers.dart';
import 'package:pantry/features/meal_plans/meal_slot_cell.dart';
import 'package:pantry/features/meal_plans/slot_detail_screen.dart';
import 'package:pantry/features/meal_plans/week_header.dart';
import 'package:pantry/features/recipes/recipe_providers.dart';
import 'package:pantry/features/shopping/shopping_list_detail_screen.dart';
import 'package:pantry/features/shopping/shopping_providers.dart';
import 'package:pantry/main.dart';
import 'package:pantry/widgets/app_bar_logo.dart';

class MealPlansScreen extends ConsumerStatefulWidget {
  const MealPlansScreen({super.key});

  @override
  ConsumerState<MealPlansScreen> createState() => _MealPlansScreenState();
}

class _MealPlansScreenState extends ConsumerState<MealPlansScreen> {
  late final PageController _pageCtrl;
  late DateTime _weekStart;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _weekStart = _computeWeekStart(DateTime.now());
    _pageCtrl = PageController(initialPage: 104);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  DateTime _computeWeekStart(DateTime date) {
    final normalised = DateTime(date.year, date.month, date.day);
    final dow = normalised.weekday;
    return normalised.subtract(Duration(days: dow - 1));
  }

  void _goPrevious() {
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goNext() {
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToday() {
    final target = _computeWeekStart(DateTime.now());
    final offset = target.difference(_weekStart).inDays ~/ 7;
    final current = _pageCtrl.page?.round() ?? 0;
    _pageCtrl.animateToPage(
      current + offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarLogo(),
        title: const Text('Meal Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Add all recipes to shopping list',
            onPressed: () => _addAllToShoppingList(context),
          ),
        ],
      ),
      body: Column(
        children: [
          WeekHeader(
            weekStart: _weekStart,
            onPrevious: _goPrevious,
            onNext: _goNext,
            onToday: _goToday,
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (page) {
                setState(() {
                  _weekStart = _computeWeekStart(
                    DateTime.now(),
                  ).add(Duration(days: 7 * (page - 104)));
                });
              },
              children: List.generate(
                // 208 pages = ~4 years of weeks centred on current week.
                208,
                (i) => _WeekPage(
                  weekStart: _computeWeekStart(
                    DateTime.now(),
                  ).add(Duration(days: 7 * (i - 104))),
                  isDragging: _isDragging,
                  onDragChanged: (v) => setState(() => _isDragging = v),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isDragging ? _buildDeleteFab(theme) : null,
    );
  }

  Widget _buildDeleteFab(ThemeData theme) {
    return DragTarget<MealSlotData>(
      onAcceptWithDetails: (details) async {
        setState(() => _isDragging = false);
        final ops = ref.read(mealPlanOpsProvider);
        await ops.clearSlot(details.data.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${details.data.slotName} removed'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, candidates, rejected) {
        final isHovered = candidates.isNotEmpty;
        return FloatingActionButton(
          onPressed: null,
          backgroundColor: isHovered
              ? Colors.red
              : Colors.red.withValues(alpha: 0.7),
          child: Icon(
            Icons.delete,
            color: isHovered
                ? Colors.white
                : Colors.white.withValues(alpha: 0.8),
          ),
        );
      },
    );
  }

  Future<void> _addAllToShoppingList(BuildContext context) async {
    final db = ref.read(dbProvider);

    // Query all meal slots and filter for the current week in Dart.
    // (Drift's extension methods for date comparisons aren't resolved by the
    //  Dart analyzer from external files, so we avoid them here.)
    final start = normaliseDate(_weekStart);
    final end = start.add(const Duration(days: 6));
    final allSlots = await db.select(db.mealSlots).get();
    if (!context.mounted) return;
    final slots = allSlots
        .where((s) => !s.date.isBefore(start) && !s.date.isAfter(end))
        .toList();

    // Collect unique linked recipe ids
    final recipeIds = slots
        .map((s) => s.recipeId)
        .where((id) => id != null)
        .cast<int>()
        .toSet()
        .toList();

    if (recipeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No linked recipes this week'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Build week label and week key
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
    final weekLabel =
        'Week of ${start.day} ${months[start.month - 1]} ${start.year}';
    final weekKey = dateKey(start);

    // Check for an existing week-keyed list
    final listOps = ShoppingListOps(db);
    final existingList = await listOps.findListByWeekKey(weekKey);

    final isNewList = existingList == null;
    final listName = isNewList ? weekLabel : existingList.name;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context, // ignore: use_build_context_synchronously
      builder: (_) => AlertDialog(
        title: Text(
          isNewList ? 'Create shopping list?' : 'Sync shopping list?',
        ),
        content: Text(
          'Add ingredients from ${recipeIds.length} linked '
          'recipe${recipeIds.length == 1 ? '' : 's'} to '
          '${isNewList ? 'a new list named "$weekLabel"' : '"$listName"'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isNewList ? 'Create' : 'Sync'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final recipeOps = ref.read(recipeOpsProvider);

    // Create the list or use the existing one
    final shoppingOps = ShoppingListOps(db);
    final listId = isNewList
        ? await shoppingOps.createListWithStore(weekLabel, weekKey: weekKey)
        : existingList.id;

    // Add ingredients from each linked recipe (stackOrAddItem merges by
    // ingredientId — checked items are preserved, qty stacks).
    for (final recipeId in recipeIds) {
      await recipeOps.addToShoppingList(recipeId, listId, weekLabel);
    }

    // Navigate to the list (new or existing)
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ShoppingListDetailScreen(listId: listId, listName: weekLabel),
        ),
      );
    }
  }
}

// ── Week page ────────────────────────────────────────────────────────────────

class _WeekPage extends ConsumerWidget {
  final DateTime weekStart;
  final bool isDragging;
  final ValueChanged<bool> onDragChanged;

  const _WeekPage({
    required this.weekStart,
    required this.isDragging,
    required this.onDragChanged,
  });

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _openSlotDetail(BuildContext context, DateTime date, String mealType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SlotDetailScreen(date: date, mealType: mealType),
      ),
    );
  }

  Future<void> _handleDrop(
    WidgetRef ref,
    MealSlotData source,
    DateTime targetDate,
    String targetMealType,
  ) async {
    final ops = ref.read(mealPlanOpsProvider);
    await ops.swapSlots(
      sourceId: source.id,
      sourceDate: source.date,
      sourceMealType: source.mealType,
      targetDate: targetDate,
      targetMealType: targetMealType,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots =
        ref.watch(mealSlotsForWeekProvider(weekStart)).valueOrNull ?? {};

    return Column(
      children: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));

        return Expanded(
          child: _DayRow(
            date: date,
            dayName: _dayName(date.weekday),
            dateStr: _dateKey(date),
            isToday: _isToday(date),
            mealTypeKeys: const ['breakfast', 'lunch', 'dinner'],
            slots: slots,
            isDragging: isDragging,
            onDragStarted: () => onDragChanged(true),
            onDragEnded: () => onDragChanged(false),
            onTapSlot: (mealType) => _openSlotDetail(context, date, mealType),
            onAcceptDrop: (data, mealType) =>
                _handleDrop(ref, data, date, mealType),
          ),
        );
      }),
    );
  }
}

// ── Day Row ──────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final DateTime date;
  final String dayName;
  final String dateStr;
  final bool isToday;
  final List<String> mealTypeKeys;
  final Map<String, MealSlotData> slots;
  final bool isDragging;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final void Function(String mealType) onTapSlot;
  final void Function(MealSlotData data, String targetMealType) onAcceptDrop;

  const _DayRow({
    required this.date,
    required this.dayName,
    required this.dateStr,
    required this.isToday,
    required this.mealTypeKeys,
    required this.slots,
    required this.isDragging,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onTapSlot,
    required this.onAcceptDrop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Day label ─────────────────────────────────────────────
          SizedBox(
            width: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // ── Meal slots ────────────────────────────────────────────
          Expanded(
            child: Row(
              children: mealTypeKeys.map((mealType) {
                final key = '${dateStr}_$mealType';
                final slot = slots[key];

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: slot != null
                        ? DraggableMealSlotCell(
                            mealType: mealType,
                            slot: slot,
                            isToday: isToday,
                            isDragActive: isDragging,
                            onDragStarted: (_) => onDragStarted(),
                            onDragEnded: onDragEnded,
                            onAcceptDrop: (dropped) =>
                                onAcceptDrop(dropped, mealType),
                            onTap: () => onTapSlot(mealType),
                          )
                        : MealSlotCell(
                            mealType: mealType,
                            isToday: isToday,
                            isDragActive: isDragging,
                            onAcceptDrop: (dropped) =>
                                onAcceptDrop(dropped, mealType),
                            onTap: () => onTapSlot(mealType),
                          ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
