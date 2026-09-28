import 'package:flutter/material.dart';
import 'package:pantry/features/meal_plans/meal_plan_providers.dart';

/// Describes a single cell in the week grid — either a placeholder
/// ("Breakfast", "Lunch", "Dinner") or an active meal slot.
class MealSlotCell extends StatelessWidget {
  final String mealType;
  final MealSlotData? slot;
  final bool isToday;
  final bool isDragActive;
  final bool isDropCandidate;
  final VoidCallback onTap;
  final void Function(MealSlotData data)? onAcceptDrop;

  const MealSlotCell({
    super.key,
    required this.mealType,
    this.slot,
    this.isToday = false,
    this.isDragActive = false,
    this.isDropCandidate = false,
    required this.onTap,
    this.onAcceptDrop,
  });

  String get _placeholder {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = slot != null;

    // ── Base cell decoration ───────────────────────────────────────────
    final cell = Container(
      decoration: BoxDecoration(
        color: _cellColor(theme, filled),
        border: Border.all(
          color: _borderColor(theme, filled),
          width: isDropCandidate ? 1.5 : 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: filled ? _filledContent(theme) : _placeholderContent(theme),
    );

    // ── Wrap in DragTarget only when drag is active ────────────────────
    if (isDragActive && filled) {
      // When there IS content, we want to show childWhenDragging from the
      // LongPressDraggable. DragTarget just wraps for accepting drops.
      return DragTarget<MealSlotData>(
        onAcceptWithDetails: (details) {
          onAcceptDrop?.call(details.data);
        },
        builder: (context, candidates, rejected) {
          final isHovered = candidates.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isHovered
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
            child: cell,
          );
        },
      );
    }

    // ── No drag active → simple tappable cell ─────────────────────────
    return GestureDetector(onTap: onTap, child: cell);
  }

  // ── Empty placeholder content ──────────────────────────────────────────
  Widget _placeholderContent(ThemeData theme) {
    return Text(
      _placeholder,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── Filled slot content ────────────────────────────────────────────────
  Widget _filledContent(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            slot!.slotName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (slot!.recipeId != null)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(
              Icons.link,
              size: 12,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Color _cellColor(ThemeData theme, bool filled) {
    if (isToday && !filled) {
      return theme.colorScheme.primaryContainer.withValues(alpha: 0.15);
    }
    if (isToday) {
      return theme.colorScheme.primaryContainer.withValues(alpha: 0.25);
    }
    if (filled) {
      return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    }
    return Colors.transparent;
  }

  Color _borderColor(ThemeData theme, bool filled) {
    if (isToday) {
      return theme.colorScheme.primary.withValues(alpha: 0.4);
    }
    if (filled) {
      return theme.colorScheme.outlineVariant;
    }
    return theme.colorScheme.outlineVariant.withValues(alpha: 0.3);
  }
}

/// The draggable wrapper — used only for filled slots in the week view.
/// Needs to be a StatefulWidget so we can manage drag state (show delete zone).
class DraggableMealSlotCell extends StatefulWidget {
  final String mealType;
  final MealSlotData slot;
  final bool isToday;
  final ValueChanged<MealSlotData>? onDragStarted;
  final VoidCallback? onDragEnded;
  final void Function(MealSlotData data)? onAcceptDrop;

  /// Called when the user drops this slot onto the delete target.
  final VoidCallback? onDelete;

  const DraggableMealSlotCell({
    super.key,
    required this.mealType,
    required this.slot,
    this.isToday = false,
    this.onDragStarted,
    this.onDragEnded,
    this.onAcceptDrop,
    this.onDelete,
  });

  @override
  State<DraggableMealSlotCell> createState() => _DraggableMealSlotCellState();
}

class _DraggableMealSlotCellState extends State<DraggableMealSlotCell> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LongPressDraggable<MealSlotData>(
      data: widget.slot,
      delay: const Duration(milliseconds: 400),
      onDragStarted: () {
        setState(() => _isDragging = true);
        widget.onDragStarted?.call(widget.slot);
      },
      onDragEnd: (_) {
        setState(() => _isDragging = false);
        widget.onDragEnded?.call();
      },
      onDraggableCanceled: (_, __) {
        setState(() => _isDragging = false);
        widget.onDragEnded?.call();
      },
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 120,
          constraints: const BoxConstraints(maxWidth: 160),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.primary),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.slot.slotName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.slot.recipeId != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.link,
                    size: 12,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: MealSlotCell(
          mealType: widget.mealType,
          slot: widget.slot,
          isToday: widget.isToday,
          onTap: () {},
        ),
      ),
      child: MealSlotCell(
        mealType: widget.mealType,
        slot: widget.slot,
        isToday: widget.isToday,
        isDragActive: _isDragging,
        onAcceptDrop: widget.onAcceptDrop,
        onTap: () {
          // Tap while dragging is handled by LongPressDraggable.
        },
      ),
    );
  }
}
