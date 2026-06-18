import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/main.dart';
import 'package:pantry/utils/ingredient_dedup.dart';

import 'models/recipe_draft.dart';
import 'recipe_providers.dart';

class RecipeFormScreen extends ConsumerStatefulWidget {
  final Recipe? recipe;
  final RecipeDraft? initialDraft;

  const RecipeFormScreen({super.key, this.recipe, this.initialDraft});

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _nameCtrl = TextEditingController();
  final _servingsCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _sourceUrlCtrl = TextEditingController();

  final List<_IngredientEntry> _ingredients = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    final d = widget.initialDraft;
    if (r != null) {
      _nameCtrl.text = r.name;
      _servingsCtrl.text = r.servings?.toString() ?? '';
      _instructionsCtrl.text = r.instructions ?? '';
      _sourceUrlCtrl.text = r.sourceUrl ?? '';
      _loadExistingIngredients();
    } else if (d != null) {
      _nameCtrl.text = d.name ?? '';
      _servingsCtrl.text = d.servings?.toString() ?? '';
      _instructionsCtrl.text = d.instructions ?? '';
      for (final ing in d.ingredients) {
        _ingredients.add(_IngredientEntry(
          nameCtrl: TextEditingController(text: ing.name),
          qtyCtrl: TextEditingController(
              text: ing.qty != null
                  ? (ing.qty! % 1 == 0
                      ? ing.qty!.toInt().toString()
                      : ing.qty.toString())
                  : ''),
          unitCtrl: TextEditingController(text: ing.unit ?? ''),
          notes: ing.notes,
        ));
      }
    }
  }

  Future<void> _loadExistingIngredients() async {
    final ops = ref.read(recipeOpsProvider);
    final rows = await ops.getIngredients(widget.recipe!.id);
    setState(() {
      for (final row in rows) {
        _ingredients.add(_IngredientEntry(
          nameCtrl: TextEditingController(text: row.ingredientName),
          qtyCtrl: TextEditingController(
              text: row.qty?.toString() ?? ''),
          unitCtrl: TextEditingController(text: row.unit ?? ''),
          resolvedIngredientId: row.ingredientId,
        ));
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingsCtrl.dispose();
    _instructionsCtrl.dispose();
    _sourceUrlCtrl.dispose();
    for (final e in _ingredients) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.recipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Recipe' : 'New Recipe'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name
          TextField(
            controller: _nameCtrl,
            autofocus: widget.recipe == null,
            decoration: const InputDecoration(
              labelText: 'Recipe name *',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // Servings
          TextField(
            controller: _servingsCtrl,
            decoration: const InputDecoration(
              labelText: 'Servings',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          // Ingredients
          Text('Ingredients',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._ingredients.asMap().entries.map((e) =>
              _IngredientRow(
                entry: e.value,
                index: e.key,
                onRemove: () => setState(() => _ingredients.removeAt(e.key)),
                onResolved: (id) => setState(
                    () => _ingredients[e.key].resolvedIngredientId = id),
              )),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add ingredient'),
            onPressed: () => setState(() => _ingredients.add(_IngredientEntry(
                  nameCtrl: TextEditingController(),
                  qtyCtrl: TextEditingController(),
                  unitCtrl: TextEditingController(),
                ))),
          ),
          const SizedBox(height: 24),

          // Instructions
          Text('Instructions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _instructionsCtrl,
            decoration: const InputDecoration(
              hintText: 'Steps, notes, method…',
              border: OutlineInputBorder(),
            ),
            maxLines: null,
            minLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          // Source URL
          TextField(
            controller: _sourceUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'Source URL',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe name is required')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final ops = ref.read(recipeOpsProvider);
      final servings = int.tryParse(_servingsCtrl.text.trim());

      final drafts = _ingredients
          .where((e) => e.nameCtrl.text.trim().isNotEmpty)
          .map((e) => RecipeIngredientDraft(
                rawText: e.nameCtrl.text.trim(),
                qty: double.tryParse(e.qtyCtrl.text.trim()),
                unit: e.unitCtrl.text.trim().isEmpty
                    ? null
                    : e.unitCtrl.text.trim(),
                notes: e.notes,
                resolvedIngredientId: e.resolvedIngredientId,
              ))
          .toList();

      final id = await ops.saveRecipe(
        id: widget.recipe?.id,
        name: name,
        servings: servings,
        instructions: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        sourceUrl: _sourceUrlCtrl.text.trim().isEmpty
            ? null
            : _sourceUrlCtrl.text.trim(),
        sourceType: widget.initialDraft != null ? 'ocr' : 'manual',
        ingredients: drafts,
      );

      if (mounted) {
        final db = ref.read(dbProvider);
        final updated =
            await (db.select(db.recipes)..where((t) => t.id.equals(id)))
                .getSingleOrNull();
        if (mounted) Navigator.pop(context, updated);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Ingredient row state ───────────────────────────────────────────────────────

class _IngredientEntry {
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  int? resolvedIngredientId;
  String? mergeCandidate;
  int? mergeCandidateId;
  String? notes;

  _IngredientEntry({
    required this.nameCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
    this.resolvedIngredientId,
    this.notes,
  });

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
  }
}

// ── Ingredient row widget ─────────────────────────────────────────────────────

class _IngredientRow extends ConsumerStatefulWidget {
  final _IngredientEntry entry;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<int?> onResolved;

  const _IngredientRow({
    required this.entry,
    required this.index,
    required this.onRemove,
    required this.onResolved,
  });

  @override
  ConsumerState<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends ConsumerState<_IngredientRow> {
  String? _mergeCandidate;
  int? _mergeCandidateId;

  Future<void> _runDedup() async {
    final text = widget.entry.nameCtrl.text.trim();
    if (text.isEmpty) return;

    final db = ref.read(dbProvider);
    final result = await resolveIngredient(db, text);

    if (result.autoLinked) {
      widget.onResolved(result.ingredientId);
      setState(() {
        _mergeCandidate = null;
        _mergeCandidateId = null;
      });
    } else if (result.needsMergePrompt) {
      setState(() {
        _mergeCandidate = result.mergeCandidate;
        _mergeCandidateId = result.mergeCandidateId;
      });
    } else {
      widget.onResolved(null);
      setState(() {
        _mergeCandidate = null;
        _mergeCandidateId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              // Qty
              SizedBox(
                width: 60,
                child: TextField(
                  controller: widget.entry.qtyCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Qty',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 6),
              // Unit
              SizedBox(
                width: 72,
                child: TextField(
                  controller: widget.entry.unitCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Unit',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  textCapitalization: TextCapitalization.none,
                ),
              ),
              const SizedBox(width: 6),
              // Name
              Expanded(
                child: TextField(
                  controller: widget.entry.nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ingredient',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                    suffixIcon: widget.entry.resolvedIngredientId != null
                        ? const Icon(Icons.link, size: 16, color: Colors.green)
                        : null,
                  ),
                  textCapitalization: TextCapitalization.none,
                  onEditingComplete: _runDedup,
                  onTapOutside: (_) => _runDedup(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: widget.onRemove,
              ),
            ],
          ),
        ),
        // Merge prompt
        if (_mergeCandidate != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.merge_type, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Same as "$_mergeCandidate"?',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () {
                    widget.onResolved(_mergeCandidateId);
                    setState(() {
                      _mergeCandidate = null;
                      _mergeCandidateId = null;
                    });
                  },
                  child: const Text('Merge', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () {
                    widget.onResolved(null);
                    setState(() {
                      _mergeCandidate = null;
                      _mergeCandidateId = null;
                    });
                  },
                  child: const Text('Keep separate',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
