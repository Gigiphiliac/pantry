import 'package:flutter/material.dart';
import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/features/shopping/item_qty_dialog.dart';
import 'package:pantry/features/shopping/prompt_utils.dart';
import 'package:pantry/features/shopping/shopping_providers.dart';

/// Add-item dialog: a clean name field plus an expandable quantity section.
///
/// Items are resolved against the ingredient dictionary so they become
/// pantry-linked (tier-gated display and qty stacking). The quantity lives in
/// its own fields — never baked into the item name — so the pantry item stays
/// clean ("eggs", not "2 eggs").
Future<void> showAddItemDialog(
  BuildContext context,
  ShoppingListOps ops, {
  required int storeId,
  int? sectionId,
}) async {
  await showChainableDialog(
    context: context,
    title: 'Add item',
    builder: (formState) => _AddItemForm(formState: formState),
    onAdd: (formState) async {
      final name = formState.nameController.text.trim();
      if (name.isEmpty) return;
      final qty = double.tryParse(formState.qtyController.text.trim());
      await ops.addResolvedItem(
        storeId,
        sectionId: sectionId,
        rawText: name,
        qty: qty,
        unit: formState.selectedUnit,
      );
    },
  );
}

class _AddItemForm extends StatefulWidget {
  final ChainableFormState formState;

  const _AddItemForm({required this.formState});

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  Future<void> _pickUnit() async {
    final picked = await showUnitPickerSheet(
      context,
      widget.formState.selectedUnit,
    );
    if (picked != null && mounted) {
      setState(() => widget.formState.selectedUnit = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = widget.formState;
    final parsed = UnitRegistry.parse(formState.selectedUnit);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: formState.nameController,
            decoration: const InputDecoration(
              labelText: 'Item name',
              hintText: 'e.g. eggs',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          ExpansionTile(
            title: const Text('Quantity (optional)'),
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: formState.qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        hintText: 'e.g. 2',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        parsed != null
                            ? parsed.displayName
                            : formState.selectedUnit ?? 'No unit',
                      ),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: _pickUnit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
