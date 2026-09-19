import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/features/settings/settings_screen.dart';
import 'package:pantry/features/shopping/shopping_providers.dart';
import 'package:pantry/features/pantry/pantry_providers.dart';

class ShoppingItemTile extends ConsumerWidget {
  final ShoppingListItem item;
  final ShoppingListOps ops;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.ops,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref =
        ref.watch(unitPreferenceProvider).valueOrNull ?? UnitPreference.metric;
    final tierMap = ref.watch(pantryTierMapProvider).valueOrNull ?? {};
    final pantryTier =
    item.ingredientId != null ? tierMap[item.ingredientId] : null;

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
        ),
      ),
      child: _ItemContent(
        item: item,
        ops: ops,
        pref: pref,
        pantryTier: pantryTier,
      ),
    );
  }
}

class _ItemContent extends StatelessWidget {
  final ShoppingListItem item;
  final ShoppingListOps ops;
  final UnitPreference pref;
  final int? pantryTier;

  const _ItemContent({
    required this.item,
    required this.ops,
    required this.pref,
    this.pantryTier,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ops.deleteItem(item.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
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
        subtitle: pantryTier == 2 ? null : _buildQtySubtitle(item, pref),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 48, vertical: 0),
      ),
      ),
    );
  }

  Widget? _buildQtySubtitle(ShoppingListItem item, UnitPreference pref) {
    if (item.qty == null) return null;
    final unit = UnitRegistry.parse(item.unit);
    if (unit != null) {
      if (unit.family == UnitFamily.count) {
        return Text(
            '${UnitRegistry.formatQty(item.qty!)} ${unit.abbreviation}');
      }
      final display = UnitRegistry.preferredDisplayUnit(unit.family, pref);
      final qty = UnitRegistry.convert(item.qty!, unit, display);
      return Text('${UnitRegistry.formatQty(qty)} ${display.abbreviation}');
    }
    final raw = UnitRegistry.formatQty(item.qty!);
    return Text(item.unit != null ? '$raw ${item.unit}' : raw);
  }
}
