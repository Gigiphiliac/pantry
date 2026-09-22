import 'package:flutter/material.dart';

// ── Generic chainable dialog ────────────────────────────────────────────────────

/// Form state exposed to the [builder] of [showChainableDialog].
class ChainableFormState {
  final TextEditingController nameController;
  final TextEditingController qtyController;
  String? selectedUnit;
  int? selectedCategoryId;

  /// Callback to reset all fields to defaults after chaining.
  final VoidCallback reset;

  ChainableFormState({
    required this.nameController,
    required this.qtyController,
    this.selectedUnit,
    this.selectedCategoryId,
    required this.reset,
  });
}

/// A generic chainable dialog with "Cancel", "OK & create new", and "OK" buttons.
///
/// [builder] receives a [ChainableFormState] and returns the form widget.
/// [onAdd] is called on both "OK & create new" and "OK" with the current form state.
/// The "OK & create new" button calls [onAdd], then calls [formState.reset] to clear
/// fields and keeps the dialog open.
///
/// Returns null on Cancel, or the final form state on OK.
Future<ChainableFormState?> showChainableDialog({
  required BuildContext context,
  required String title,
  required Widget Function(ChainableFormState formState) builder,
  required Future<void> Function(ChainableFormState formState) onAdd,
}) {
  return showDialog<ChainableFormState>(
    context: context,
    builder: (ctx) =>
        _ChainableDialog(title: title, builder: builder, onAdd: onAdd),
  );
}

class _ChainableDialog extends StatefulWidget {
  final String title;
  final Widget Function(ChainableFormState formState) builder;
  final Future<void> Function(ChainableFormState formState) onAdd;

  const _ChainableDialog({
    required this.title,
    required this.builder,
    required this.onAdd,
  });

  @override
  State<_ChainableDialog> createState() => _ChainableDialogState();
}

class _ChainableDialogState extends State<_ChainableDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late ChainableFormState _formState;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _qtyController = TextEditingController();
    _formState = ChainableFormState(
      nameController: _nameController,
      qtyController: _qtyController,
      selectedUnit: null,
      selectedCategoryId: null,
      reset: () {
        _nameController.clear();
        _qtyController.clear();
        setState(() {
          _formState.selectedUnit = null;
          _formState.selectedCategoryId = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _createAndContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await widget.onAdd(_formState);
    _formState.reset();
  }

  void _createAndDone() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await widget.onAdd(_formState);
    if (mounted) Navigator.pop(context, _formState);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: widget.builder(_formState),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _createAndContinue,
          child: const Text('OK & create new'),
        ),
        TextButton(onPressed: _createAndDone, child: const Text('OK')),
      ],
    );
  }
}

// ── Convenience wrappers ────────────────────────────────────────────────────────

Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String hint,
  String? initial,
}) async {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: hint),
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Convenience wrapper around [showChainableDialog] that uses a single text field.
/// Returns null on Cancel, or the final text on OK.
Future<String?> promptItemText(
  BuildContext context, {
  required String title,
  required String hint,
  required Future<void> Function(String text) onAdd,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => _SimpleChainableDialog(
      title: title,
      hint: hint,
      controller: controller,
      onAdd: onAdd,
    ),
  );
}

class _SimpleChainableDialog extends StatefulWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final Future<void> Function(String text) onAdd;

  const _SimpleChainableDialog({
    required this.title,
    required this.hint,
    required this.controller,
    required this.onAdd,
  });

  @override
  State<_SimpleChainableDialog> createState() => _SimpleChainableDialogState();
}

class _SimpleChainableDialogState extends State<_SimpleChainableDialog> {
  Future<void> _createAndContinue() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    await widget.onAdd(text);
    widget.controller.clear();
  }

  void _createAndDone() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    await widget.onAdd(text);
    if (mounted) Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: widget.controller,
        decoration: InputDecoration(hintText: widget.hint),
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _createAndDone(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _createAndContinue,
          child: const Text('OK & create new'),
        ),
        TextButton(onPressed: _createAndDone, child: const Text('OK')),
      ],
    );
  }
}
