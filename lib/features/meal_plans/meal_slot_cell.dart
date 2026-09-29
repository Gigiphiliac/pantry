import 'package:flutter/material.dart';
import 'package:pantry/features/meal_plans/meal_plan_providers.dart';

/// A single cell in the week grid — either a placeholder
/// ("Breakfast", "Lunch", "Dinner") or an active meal slot.
///
/// When [isDragActive] is true, the cell renders as a [DragTarget] so other
/// slots can be dropped onto it. The hover highlight is controlled by the
/// DragTarget's builder (only shows when a drag hovers over this cell).
class MealSlotCell extends StatelessWidget {
  final String mealType;
  final MealSlotData? slot;
  final bool isToday;
  final bool isDragActive;
  final VoidCallback onTap;
  final void Function(MealSlotData data)? onAcceptDrop;

  const MealSlotCell({
    super.key,
    required this.mealType,
    this.slot,
    this.isToday = false,
    this.isDragActive = false,
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

    final cell = Container(
      decoration: BoxDecoration(
        color: _cellColor(theme, filled),
        border: Border.all(color: _borderColor(theme, filled), width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: filled ? _filledContent(theme) : _placeholderContent(theme),
    );

    // Wrap in DragTarget during active drag so drops can land here.
    if (isDragActive) {
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
            child: GestureDetector(onTap: onTap, child: cell),
          );
        },
      );
    }

    // No drag active → simple tappable cell.
    return GestureDetector(onTap: onTap, child: cell);
  }

  // ── Content builders ──────────────────────────────────────────────────

  Widget _placeholderContent(ThemeData theme) {
    return Text(
      _placeholder,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _filledContent(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            slot!.slotName,
            style: theme.textTheme.bodyMedium?.copyWith(
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

/// A draggable meal slot cell — wraps [MealSlotCell] in a
/// [LongPressDraggable] for drag-and-drop reordering.
///
/// A short tap calls [onTap]; a long press (400ms) starts a drag.
class DraggableMealSlotCell extends StatefulWidget {
  final String mealType;
  final MealSlotData slot;
  final bool isToday;
  final bool isDragActive;
  final ValueChanged<MealSlotData>? onDragStarted;
  final VoidCallback? onDragEnded;
  final void Function(MealSlotData data)? onAcceptDrop;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DraggableMealSlotCell({
    super.key,
    required this.mealType,
    required this.slot,
    this.isToday = false,
    this.isDragActive = false,
    this.onDragStarted,
    this.onDragEnded,
    this.onAcceptDrop,
    this.onTap,
    this.onDelete,
  });

  @override
  State<DraggableMealSlotCell> createState() => _DraggableMealSlotCellState();
}

class _DraggableMealSlotCellState extends State<DraggableMealSlotCell> {
  bool _selfDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LongPressDraggable<MealSlotData>(
      data: widget.slot,
      delay: const Duration(milliseconds: 400),
      onDragStarted: () {
        setState(() => _selfDragging = true);
        widget.onDragStarted?.call(widget.slot);
      },
      onDragEnd: (_) {
        setState(() => _selfDragging = false);
        widget.onDragEnded?.call();
      },
      onDraggableCanceled: (_, _) {
        setState(() => _selfDragging = false);
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
        // Show as DragTarget when THIS cell is being dragged OR another
        // cell is being dragged (isDragActive from parent).
        isDragActive: _selfDragging || widget.isDragActive,
        onAcceptDrop: widget.onAcceptDrop,
        onTap: widget.onTap ?? () {},
      ),
    );
  }
}
