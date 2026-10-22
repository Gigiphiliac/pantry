import 'package:flutter/material.dart';
import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/db/database.dart';

/// Result of the quantity editor: the numeric qty and the selected unit id
/// (null = no unit).
typedef ItemQtyResult = ({double qty, String? unit});

/// Dialog for setting/editing the quantity and unit of a shopping list item.
/// Returns null when cancelled.
Future<ItemQtyResult?> showItemQtyDialog(
  BuildContext context,
  ShoppingListItem item,
) async {
  final qtyCtrl = TextEditingController(
    text: item.qty != null ? UnitRegistry.formatQty(item.qty!) : '',
  );
  String? selectedUnit = item.unit;

  final result = await showDialog<ItemQtyResult>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final parsed = UnitRegistry.parse(selectedUnit);
        return AlertDialog(
          title: const Text('Set quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'e.g. 2',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  parsed != null
                      ? parsed.displayName
                      : selectedUnit ?? 'No unit',
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final picked = await showUnitPickerSheet(ctx, selectedUnit);
                  if (picked != null) {
                    setState(() => selectedUnit = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final qty = double.tryParse(qtyCtrl.text.trim());
                if (qty == null) return;
                Navigator.pop(ctx, (qty: qty, unit: selectedUnit));
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    ),
  );

  qtyCtrl.dispose();
  return result;
}

/// Bottom sheet listing units grouped by family (weight / volume / count).
/// Returns the chosen unit id, or null when "None" is picked or cancelled.
Future<String?> showUnitPickerSheet(
  BuildContext context,
  String? current,
) async {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('None'),
            trailing: current == null
                ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                : null,
            onTap: () => Navigator.pop(ctx, null),
          ),
          const Divider(height: 1),
          _unitFamilySection(ctx, 'Weight', UnitFamily.weight, current),
          _unitFamilySection(ctx, 'Volume', UnitFamily.volume, current),
          _unitFamilySection(ctx, 'Count', UnitFamily.count, current),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _unitFamilySection(
  BuildContext context,
  String title,
  UnitFamily family,
  String? current,
) {
  final units = UnitRegistry.unitsForFamily(family);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
      ),
      ...units.map(
        (u) => ListTile(
          dense: true,
          title: Text(u.displayName),
          trailing: Text(
            u.abbreviation,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () => Navigator.pop(context, u.id),
        ),
      ),
    ],
  );
}
