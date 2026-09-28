import 'package:flutter/material.dart';
import 'package:pantry/features/meal_plans/meal_plan_providers.dart';

/// Bottom sheet for swapping the current slot with another day/meal.
class SwapSheet extends StatefulWidget {
  final DateTime weekStart;
  final MealSlotData currentSlot;
  final Map<String, MealSlotData> weekSlots;

  const SwapSheet({
    super.key,
    required this.weekStart,
    required this.currentSlot,
    required this.weekSlots,
  });

  @override
  State<SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends State<SwapSheet> {
  late int _selectedDayOffset; // 0=Mon .. 6=Sun
  late String _selectedMealType;

  static const _mealOptions = ['breakfast', 'lunch', 'dinner'];

  @override
  void initState() {
    super.initState();
    _selectedDayOffset = 0;
    _selectedMealType = 'breakfast';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title ─────────────────────────────────────────────
            Center(
              child: Text(
                'Swap with…',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Day picker ─────────────────────────────────────────
            Text('Day', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              initialValue: _selectedDayOffset,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              items: List.generate(7, (i) {
                final date = widget.weekStart.add(Duration(days: i));
                final dayName = _dayName(i);
                final dateStr = '${date.day}/${date.month}';
                return DropdownMenuItem(
                  value: i,
                  child: Text('$dayName ($dateStr)'),
                );
              }),
              onChanged: (v) => setState(() => _selectedDayOffset = v!),
            ),
            const SizedBox(height: 12),

            // ── Meal type picker ───────────────────────────────────
            Text('Meal', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedMealType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              items: _mealOptions.map((m) {
                return DropdownMenuItem(value: m, child: Text(_mealLabel(m)));
              }).toList(),
              onChanged: (v) => setState(() => _selectedMealType = v!),
            ),
            const SizedBox(height: 16),

            // ── Preview ───────────────────────────────────────────
            _buildPreview(context),
            const SizedBox(height: 16),

            // ── Swap button ────────────────────────────────────────
            FilledButton(
              onPressed: () {
                final targetKey =
                    '${dateKey(widget.weekStart.add(Duration(days: _selectedDayOffset)))}_$_selectedMealType';
                final targetSlot = widget.weekSlots[targetKey];
                Navigator.pop(context, (
                  dayOffset: _selectedDayOffset,
                  mealType: _selectedMealType,
                  targetSlot: targetSlot,
                ));
              },
              child: const Text('Swap'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final targetDate = widget.weekStart.add(Duration(days: _selectedDayOffset));
    final targetKey = '${dateKey(targetDate)}_$_selectedMealType';
    final target = widget.weekSlots[targetKey];

    final currentLabel =
        '${_dayName((widget.currentSlot.date.difference(widget.weekStart).inDays))} ${_mealLabel(widget.currentSlot.mealType)}';
    final targetLabel =
        '${_dayName(_selectedDayOffset)} ${_mealLabel(_selectedMealType)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              '$currentLabel ⇄ $targetLabel',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.currentSlot.slotName} ${target != null ? '⇄ ${target.slotName}' : '→ (empty)'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _dayName(int offset) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[offset];
  }

  String _mealLabel(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return mealType;
    }
  }

  String dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

/// Result from the swap sheet.
typedef SwapResult = ({
  int dayOffset,
  String mealType,
  MealSlotData? targetSlot,
});
