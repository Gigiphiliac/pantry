import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/main.dart';
import 'package:pantry/utils/ingredient_dedup.dart';

import 'models/recipe_draft.dart';
import 'recipe_providers.dart';

class RecipeFormScreen extends ConsumerStatefulWidget {
  final Recipe? recipe;
  final RecipeDraft? initialDraft;
  final String? sourceUrl;
  final String? sourceType;

  const RecipeFormScreen({
    super.key,
    this.recipe,
    this.initialDraft,
    this.sourceUrl,
    this.sourceType,
  });

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _nameCtrl = TextEditingController();
  final _servingsCtrl = TextEditingController();
  final _sourceUrlCtrl = TextEditingController();
  final List<TextEditingController> _stepControllers = [];

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
      _sourceUrlCtrl.text = r.sourceUrl ?? '';
      _loadExistingIngredients();
      _loadExistingSteps();
    } else if (d != null) {
      _nameCtrl.text = d.name ?? '';
      _servingsCtrl.text = d.servings?.toString() ?? '';
      _sourceUrlCtrl.text = widget.sourceUrl ?? '';
      for (final step in d.steps) {
        _stepControllers.add(TextEditingController(text: step));
      }
      if (_stepControllers.isEmpty) {
        _stepControllers.add(TextEditingController());
      }
      for (final ing in d.ingredients) {
        _ingredients.add(_IngredientEntry(
          nameCtrl: TextEditingController(text: ing.name),
          qtyCtrl: TextEditingController(
              text: ing.qty != null
                  ? (ing.qty! % 1 == 0
                      ? ing.qty!.toInt().toString()
                      : ing.qty.toString())
                  : ''),
          selectedUnit: UnitRegistry.parse(ing.unit),
          notes: ing.notes,
        ));
      }
    } else {
      _stepControllers.add(TextEditingController());
    }
  }

  Future<void> _loadExistingSteps() async {
    final ops = ref.read(recipeOpsProvider);
    final steps = await ops.getSteps(widget.recipe!.id);
    setState(() {
      for (final c in _stepControllers) {
        c.dispose();
      }
      _stepControllers.clear();
      for (final s in steps) {
        _stepControllers.add(TextEditingController(text: s));
      }
      if (_stepControllers.isEmpty) {
        _stepControllers.add(TextEditingController());
      }
    });
  }

  Future<void> _loadExistingIngredients() async {
    final ops = ref.read(recipeOpsProvider);
    final rows = await ops.getIngredients(widget.recipe!.id);
    setState(() {
      for (final row in rows) {
        _ingredients.add(_IngredientEntry(
          nameCtrl: TextEditingController(text: row.ingredientName),
          qtyCtrl: TextEditingController(text: row.qty?.toString() ?? ''),
          selectedUnit: UnitRegistry.parse(row.unit),
          resolvedIngredientId: row.ingredientId,
        ));
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingsCtrl.dispose();
    _sourceUrlCtrl.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
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
            onPressed: () => setState(
                () => _ingredients.add(_IngredientEntry(
                      nameCtrl: TextEditingController(),
                      qtyCtrl: TextEditingController(),
                    ))),
          ),
          const SizedBox(height: 24),

          // Method
          Text('Method', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._stepControllers.asMap().entries.map((e) {
            final i = e.key;
            final ctrl = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, right: 8),
                    child: SizedBox(
                      width: 24,
                      child: Text(
                        '${i + 1}.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      decoration: InputDecoration(
                        hintText: 'Step ${i + 1}',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  if (_stepControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _stepControllers[i].dispose();
                        _stepControllers.removeAt(i);
                      }),
                    ),
                ],
              ),
            );
          }),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add step'),
            onPressed: () => setState(
              () => _stepControllers.add(TextEditingController()),
            ),
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
                unit: e.selectedUnit?.id,
                notes: e.notes,
                resolvedIngredientId: e.resolvedIngredientId,
              ))
          .toList();

      final steps = _stepControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final id = await ops.saveRecipe(
        id: widget.recipe?.id,
        name: name,
        servings: servings,
        steps: steps,
        sourceUrl: _sourceUrlCtrl.text.trim().isEmpty
            ? null
            : _sourceUrlCtrl.text.trim(),
        sourceType: widget.sourceType ??
            (widget.initialDraft != null ? 'ocr' : 'manual'),
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
  Unit? selectedUnit;
  int? resolvedIngredientId;
  String? mergeCandidate;
  int? mergeCandidateId;
  String? notes;

  _IngredientEntry({
    required this.nameCtrl,
    required this.qtyCtrl,
    this.selectedUnit,
    this.resolvedIngredientId,
    this.notes,
  });

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
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

  Future<void> _pickUnit(BuildContext context) async {
    final result = await showModalBottomSheet<_PickResult>(
      context: context,
      builder: (_) => const _UnitPickerSheet(),
    );
    if (result != null) {
      setState(() => widget.entry.selectedUnit = result.unit);
    }
  }

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
              // Unit picker
              SizedBox(
                width: 72,
                child: InkWell(
                  onTap: () => _pickUnit(context),
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    child: Text(
                      widget.entry.selectedUnit?.abbreviation ?? 'Unit',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.entry.selectedUnit != null
                            ? null
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
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

// ── Unit picker sheet ─────────────────────────────────────────────────────────

/// Wraps the selected Unit so null ("None") can be distinguished from dismissal.
class _PickResult {
  final Unit? unit;
  const _PickResult(this.unit);
}

class _UnitPickerSheet extends StatelessWidget {
  const _UnitPickerSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              title: const Text('None'),
              onTap: () => Navigator.pop(context, const _PickResult(null)),
            ),
            const Divider(height: 1),
            _familySection(context, 'Weight', UnitFamily.weight),
            _familySection(context, 'Volume', UnitFamily.volume),
            _familySection(context, 'Count', UnitFamily.count),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _familySection(
      BuildContext context, String title, UnitFamily family) {
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
            title: Text(u.displayName),
            trailing: Text(
              u.abbreviation,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            onTap: () => Navigator.pop(context, _PickResult(u)),
          ),
        ),
      ],
    );
  }
}
