import 'package:flutter/material.dart';

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
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Like [promptText] but adds an "OK & create new" button that creates the
/// item (via [onAdd]), clears the field, and keeps the dialog open.
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
    builder: (ctx) => _ChainableDialog(
      title: title,
      hint: hint,
      controller: controller,
      onAdd: onAdd,
    ),
  );
}

class _ChainableDialog extends StatefulWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final Future<void> Function(String text) onAdd;

  const _ChainableDialog({
    required this.title,
    required this.hint,
    required this.controller,
    required this.onAdd,
  });

  @override
  State<_ChainableDialog> createState() => _ChainableDialogState();
}

class _ChainableDialogState extends State<_ChainableDialog> {
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
        TextButton(
          onPressed: _createAndDone,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
