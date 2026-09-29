import 'package:flutter/material.dart';

/// Header bar for cycling through weeks, showing the date range
/// and a "Today" jump button.
class WeekHeader extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const WeekHeader({
    super.key,
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  String get _dateRangeText {
    final end = weekStart.add(const Duration(days: 6));
    final startStr = _formatDate(weekStart);
    final endStr = _formatDate(end);
    final showYear =
        weekStart.year != end.year || weekStart.year != DateTime.now().year;
    if (showYear) {
      return '$startStr – $endStr, ${weekStart.year}';
    }
    // Check if month changes across the week
    if (weekStart.month != end.month) {
      return '$startStr – $endStr';
    }
    // Same month: "Mar 10 – 16"
    final month = _monthAbbr(weekStart);
    return '$month ${weekStart.day} – ${end.day}';
  }

  String _formatDate(DateTime dt) {
    final month = _monthAbbr(dt);
    return '$month ${dt.day}';
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
    final isCurrentWeek = _isCurrentWeek(weekStart);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // ── Previous week ──────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
            tooltip: 'Previous week',
          ),

          // ── Date range ─────────────────────────────────────────────
          Expanded(
            child: Text(
              _dateRangeText,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ── Next week ─────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            tooltip: 'Next week',
          ),

          // ── Today jump ────────────────────────────────────────────
          TextButton(
            onPressed: isCurrentWeek ? null : onToday,
            style: TextButton.styleFrom(
              foregroundColor: isCurrentWeek
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Today'),
          ),
        ],
      ),
    );
  }

  bool _isCurrentWeek(DateTime weekStart) {
    final now = DateTime.now();
    final todayWeekStart = now.subtract(Duration(days: now.weekday - 1));
    return weekStart.year == todayWeekStart.year &&
        weekStart.month == todayWeekStart.month &&
        weekStart.day == todayWeekStart.day;
  }
}
