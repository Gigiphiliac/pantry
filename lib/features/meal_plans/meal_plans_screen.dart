import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/features/meal_plans/meal_plan_providers.dart';
import 'package:pantry/features/meal_plans/meal_slot_cell.dart';
import 'package:pantry/features/meal_plans/slot_detail_screen.dart';
import 'package:pantry/features/meal_plans/week_header.dart';
import 'package:pantry/widgets/app_bar_logo.dart';

class MealPlansScreen extends ConsumerStatefulWidget {
  const MealPlansScreen({super.key});

  @override
  ConsumerState<MealPlansScreen> createState() => _MealPlansScreenState();
}

class _MealPlansScreenState extends ConsumerState<MealPlansScreen> {
  late DateTime _weekStart;
  bool _showDeleteZone = false;

  @override
  void initState() {
    super.initState();
    _weekStart = _computeWeekStart(DateTime.now());
  }

  DateTime _computeWeekStart(DateTime date) {
    final normalised = DateTime(date.year, date.month, date.day);
    final dow = normalised.weekday; // 1=Mon ... 7=Sun
    return normalised.subtract(Duration(days: dow - 1));
  }

  void _goPrevious() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _goNext() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  void _goToday() =>
      setState(() => _weekStart = _computeWeekStart(DateTime.now()));

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slotsAsync = ref.watch(mealSlotsForWeekProvider(_weekStart));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarLogo(),
        title: const Text('Meal Plans'),
        actions: [],
      ),
      body: Column(
        children: [
          // ── Week cycling header ──────────────────────────────────
          WeekHeader(
            weekStart: _weekStart,
            onPrevious: _goPrevious,
            onNext: _goNext,
            onToday: _goToday,
          ),

          // ── Week grid ────────────────────────────────────────────
          Expanded(
            child: slotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (slots) => _buildWeekGrid(theme, slots),
            ),
          ),
        ],
      ),

      // ── Floating delete zone ─────────────────────────────────────
      floatingActionButton: _showDeleteZone ? _buildDeleteFab(theme) : null,
    );
  }

  Widget _buildWeekGrid(ThemeData theme, Map<String, MealSlotData> slots) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: 7,
      itemBuilder: (context, index) {
        final date = _weekStart.add(Duration(days: index));
        final isToday = _isToday(date);
        final dateStr = _dateKey(date);

        return _DayRow(
          date: date,
          dayName: _dayName(date.weekday),
          isToday: isToday,
          mealTypeKeys: const ['breakfast', 'lunch', 'dinner'],
          slots: slots,
          dateStr: dateStr,
          onTapSlot: (mealType) => _openSlotDetail(date, mealType, slots),
          onDeleteSlot: (mealType) => _deleteSlot(dateStr, mealType, slots),
          onDragStarted: (_) => setState(() => _showDeleteZone = true),
          onDragEnded: () => setState(() => _showDeleteZone = false),
          onAcceptDrop: (data, mealType) =>
              _handleDrop(data, date, mealType, slots),
          isOtherDragging: _showDeleteZone,
        );
      },
    );
  }

  Widget _buildDeleteFab(ThemeData theme) {
    return DragTarget<MealSlotData>(
      onAcceptWithDetails: (details) async {
        setState(() => _showDeleteZone = false);
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

  // ── Actions ──────────────────────────────────────────────────────────────

  void _openSlotDetail(
    DateTime date,
    String mealType,
    Map<String, MealSlotData> slots,
  ) {
    final key = '${_dateKey(date)}_$mealType';
    final existing = slots[key];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SlotDetailScreen(
          date: date,
          mealType: mealType,
          existingSlot: existing,
        ),
      ),
    );
  }

  Future<void> _deleteSlot(
    String dateStr,
    String mealType,
    Map<String, MealSlotData> slots,
  ) async {
    final key = '${dateStr}_$mealType';
    final slot = slots[key];
    if (slot == null) return;
    final ops = ref.read(mealPlanOpsProvider);
    await ops.clearSlot(slot.id);
  }

  Future<void> _handleDrop(
    MealSlotData source,
    DateTime targetDate,
    String targetMealType,
    Map<String, MealSlotData> slots,
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
}

// ── Day Row Widget ──────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final DateTime date;
  final String dayName;
  final bool isToday;
  final List<String> mealTypeKeys;
  final Map<String, MealSlotData> slots;
  final String dateStr;
  final void Function(String mealType) onTapSlot;
  final void Function(String mealType) onDeleteSlot;
  final ValueChanged<MealSlotData>? onDragStarted;
  final VoidCallback? onDragEnded;
  final void Function(MealSlotData data, String targetMealType) onAcceptDrop;
  final bool isOtherDragging;

  const _DayRow({
    required this.date,
    required this.dayName,
    required this.isToday,
    required this.mealTypeKeys,
    required this.slots,
    required this.dateStr,
    required this.onTapSlot,
    required this.onDeleteSlot,
    this.onDragStarted,
    this.onDragEnded,
    required this.onAcceptDrop,
    required this.isOtherDragging,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Day label ─────────────────────────────────────────────
          SizedBox(
            width: 44,
            child: Column(
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
                            onDragStarted: onDragStarted,
                            onDragEnded: onDragEnded,
                            onAcceptDrop: (dropped) =>
                                onAcceptDrop(dropped, mealType),
                            onDelete: () => onDeleteSlot(mealType),
                          )
                        : MealSlotCell(
                            mealType: mealType,
                            isToday: isToday,
                            isDragActive: isOtherDragging,
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
