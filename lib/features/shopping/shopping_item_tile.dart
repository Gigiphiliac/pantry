import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/features/pantry/pantry_providers.dart';
import 'package:pantry/features/settings/settings_screen.dart';
import 'package:pantry/features/shopping/item_qty_dialog.dart';
import 'package:pantry/features/shopping/prompt_utils.dart';
import 'package:pantry/features/shopping/shopping_providers.dart';

/// What tapping an item's qty subtitle should do.
enum SubtitleTapAction { none, toggleToBulk, toggleToPerRecipe, editQty }

/// Pure decision rule for the subtitle tap, based on the ingredient's pantry
/// tier and whether a qty is stored on the item:
///  - unlinked items (raw text) and tier 1 (always available) are inert —
///    tier 1 is managed only from the pantry library
///  - no stored qty → open the quantity editor (then show it as per-recipe)
///  - stored qty → toggle display between bulk (2) and per-recipe (3)
@visibleForTesting
SubtitleTapAction resolveSubtitleTap({
  required int? pantryTier,
  required bool hasStoredQty,
}) {
  if (pantryTier == null || pantryTier == 1) return SubtitleTapAction.none;
  if (!hasStoredQty) return SubtitleTapAction.editQty;
  return pantryTier == 2
      ? SubtitleTapAction.toggleToPerRecipe
      : SubtitleTapAction.toggleToBulk;
}

class ShoppingItemTile extends ConsumerWidget {
  final ShoppingListItem item;
  final ShoppingListOps ops;

  const ShoppingItemTile({super.key, required this.item, required this.ops});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref =
        ref.watch(unitPreferenceProvider).valueOrNull ?? UnitPreference.metric;
    final tierMap = ref.watch(pantryTierMapProvider).valueOrNull ?? {};
    final pantryTier = item.ingredientId != null
        ? tierMap[item.ingredientId]
        : null;

    final subtitle = _buildSubtitle(context, item, pref, pantryTier);
    final onSubtitleTap = pantryTier == null
        ? null
        : () => _handleSubtitleTap(context, ref, item, pantryTier);

    return LongPressDraggable<ShoppingListItem>(
      data: item,
      delay: const Duration(milliseconds: 400),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 64,
          child: _ItemContent(
            item: item,
            ops: ops,
            pref: pref,
            pantryTier: pantryTier,
            subtitle: subtitle,
            onSubtitleTap: onSubtitleTap,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _ItemContent(
          item: item,
          ops: ops,
          pref: pref,
          pantryTier: pantryTier,
          subtitle: subtitle,
          onSubtitleTap: onSubtitleTap,
        ),
      ),
      child: _ItemContent(
        item: item,
        ops: ops,
        pref: pref,
        pantryTier: pantryTier,
        subtitle: subtitle,
        onSubtitleTap: onSubtitleTap,
      ),
    );
  }

  /// The subtitle slot, rendered for every pantry-linked item so the qty
  /// toggle is always discoverable:
  ///  - per-recipe (tier 3): the quantity itself
  ///  - bulk (tier 2) with a stored qty: hint that it can be shown
  ///  - no stored qty at all: hint that a qty can be set
  Widget? _buildSubtitle(
    BuildContext context,
    ShoppingListItem item,
    UnitPreference pref,
    int? pantryTier,
  ) {
    final linked = item.ingredientId != null;
    final qtySubtitle = _buildQtySubtitle(item, pref);

    if (linked && pantryTier == 2) {
      return _hintText(
        context,
        item.qty == null ? 'No qty — tap to set' : 'Tap to show qty',
      );
    }
    if (qtySubtitle != null) return qtySubtitle;
    if (linked) {
      return _hintText(context, 'No qty — tap to set');
    }
    return null;
  }

  Widget _hintText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: 12,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  /// Tap behaviour for the subtitle slot — see [resolveSubtitleTap].
  Future<void> _handleSubtitleTap(
    BuildContext context,
    WidgetRef ref,
    ShoppingListItem item,
    int pantryTier,
  ) async {
    final action = resolveSubtitleTap(
      pantryTier: pantryTier,
      hasStoredQty: item.qty != null,
    );
    final pantryOps = ref.read(pantryOpsProvider);

    switch (action) {
      case SubtitleTapAction.none:
        return;
      case SubtitleTapAction.editQty:
        final result = await showItemQtyDialog(context, item);
        if (result == null) return;
        await ops.setItemQty(item.id, result.qty, result.unit);
        await pantryOps.setTierByIngredientId(item.ingredientId!, 3);
      case SubtitleTapAction.toggleToBulk:
        await pantryOps.setTierByIngredientId(item.ingredientId!, 2);
      case SubtitleTapAction.toggleToPerRecipe:
        await pantryOps.setTierByIngredientId(item.ingredientId!, 3);
    }
  }

  Widget? _buildQtySubtitle(ShoppingListItem item, UnitPreference pref) {
    if (item.qty == null) return null;
    final unit = UnitRegistry.parse(item.unit);
    if (unit != null) {
      if (unit.family == UnitFamily.count) {
        return Text(
          '${UnitRegistry.formatQty(item.qty!)} ${unit.abbreviation}',
        );
      }
      final display = UnitRegistry.preferredDisplayUnit(unit.family, pref);
      final qty = UnitRegistry.convert(item.qty!, unit, display);
      return Text('${UnitRegistry.formatQty(qty)} ${display.abbreviation}');
    }
    final raw = UnitRegistry.formatQty(item.qty!);
    return Text(item.unit != null ? '$raw ${item.unit}' : raw);
  }
}

class _ItemContent extends StatelessWidget {
  final ShoppingListItem item;
  final ShoppingListOps ops;
  final UnitPreference pref;
  final int? pantryTier;
  final Widget? subtitle;
  final VoidCallback? onSubtitleTap;

  const _ItemContent({
    required this.item,
    required this.ops,
    required this.pref,
    this.pantryTier,
    this.subtitle,
    this.onSubtitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) async {
              final newName = await promptText(
                context,
                title: 'Rename item',
                hint: 'Item name',
                initial: item.rawText,
              );
              if (newName != null && newName.isNotEmpty) {
                ops.renameItem(item.id, newName);
              }
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
          ),
          SlidableAction(
            onPressed: (_) => ops.deleteItem(item.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: CheckboxListTile(
          value: item.checked,
          onChanged: (v) => ops.toggleItem(item.id, v ?? false),
          title: Text(
            item.rawText,
            style: item.checked
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Theme.of(context).disabledColor,
                  )
                : null,
          ),
          subtitle: subtitle == null
              ? null
              : onSubtitleTap == null
              ? subtitle
              : InkWell(
                  onTap: onSubtitleTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: subtitle,
                  ),
                ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 48,
            vertical: 0,
          ),
        ),
      ),
    );
  }
}
