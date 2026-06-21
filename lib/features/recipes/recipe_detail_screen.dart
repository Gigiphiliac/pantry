import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/features/shopping/shopping_providers.dart';

import 'recipe_providers.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  int _servingScale = 1;
  late Recipe _recipe;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _servingScale = _recipe.servings ?? 1;
  }

  int get _baseServings => _recipe.servings ?? 1;

  @override
  Widget build(BuildContext context) {
    final ops = ref.watch(recipeOpsProvider);
    final ingredientsAsync = ref.watch(recipeIngredientsProvider(_recipe.id));
    final sectionsAsync = ref.watch(recipeSectionsProvider(_recipe.id));
    final steps = ref.watch(recipeStepsProvider(_recipe.id));
    final sectionNames = {
      for (final s in sectionsAsync.valueOrNull ?? <RecipeIngredientSection>[])
        s.id: s.name,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.push<Recipe>(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeFormScreen(recipe: _recipe),
                ),
              );
              if (updated != null) setState(() => _recipe = updated);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ops),
          ),
        ],
      ),
      body: ingredientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ingredients) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_recipe.servings != null) _servingsRow(),
            if (ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Ingredients',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._buildIngredientWidgets(
                  context, ingredients, sectionNames),
            ],
            ...steps.when(
              loading: () => const [],
              error: (_, _) => const [],
              data: (stepList) => stepList.isEmpty
                  ? const []
                  : [
                      const SizedBox(height: 20),
                      Text('Method',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...stepList.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${e.key + 1}.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(e.value)),
                                ],
                              ),
                            ),
                          ),
                    ],
            ),
            if (_recipe.sourceUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 20),
              Text('Source',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                _recipe.sourceUrl!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Add to shopping list'),
            onPressed: () => _showAddToList(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildIngredientWidgets(
    BuildContext context,
    List<RecipeIngredientRow> ingredients,
    Map<int, String> sectionNames,
  ) {
    final widgets = <Widget>[];
    int? lastSectionId = -1; // sentinel — not a valid DB id
    for (final ing in ingredients) {
      if (ing.sectionId != lastSectionId) {
        lastSectionId = ing.sectionId;
        if (ing.sectionId != null) {
          final name = sectionNames[ing.sectionId] ?? '';
          if (name.isNotEmpty) {
            widgets.add(Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 2),
              child: Text(
                name,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ));
          }
        }
      }
      widgets.add(_IngredientTile(
        key: ValueKey(ing.id),
        ing: ing,
        baseServings: _baseServings,
        servingScale: _servingScale,
      ));
    }
    return widgets;
  }

  Widget _servingsRow() {
    return Row(
      children: [
        const Text('Servings:'),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: _servingScale > 1
              ? () => setState(() => _servingScale--)
              : null,
        ),
        Text('$_servingScale',
            style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => setState(() => _servingScale++),
        ),
      ],
    );
  }

  void _showAddToList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _AddToListSheet(recipe: _recipe),
    );
  }

  Future<void> _confirmDelete(BuildContext context, RecipeOps ops) async {
    final nav = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('Delete "${_recipe.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ops.deleteRecipe(_recipe.id);
      if (mounted) nav.pop();
    }
  }
}

// ── Ingredient tile with cycle button ─────────────────────────────────────────

class _IngredientTile extends ConsumerWidget {
  final RecipeIngredientRow ing;
  final int baseServings;
  final int servingScale;

  const _IngredientTile({
    super.key,
    required this.ing,
    required this.baseServings,
    required this.servingScale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final altsAsync =
        ref.watch(recipeIngredientAlternativesProvider(ing.id));
    final ops = ref.watch(recipeOpsProvider);

    return altsAsync.when(
      loading: () => _buildRow(context, ing.ingredientName, ing.qty,
          ing.unit, hasAlts: false, onCycle: null),
      error: (_, _) => _buildRow(context, ing.ingredientName, ing.qty,
          ing.unit, hasAlts: false, onCycle: null),
      data: (alts) {
        final hasAlts = alts.isNotEmpty;

        // Resolve effective name/qty/unit from activeAlternativeIndex
        final idx = ing.activeAlternativeIndex;
        final String displayName;
        final double? displayQty;
        final String? displayUnit;

        if (idx == null || idx >= alts.length) {
          displayName = ing.ingredientName;
          displayQty = ing.qty;
          displayUnit = ing.unit;
        } else {
          final alt = alts[idx];
          displayName = alt.ingredientName;
          displayQty = alt.qty ?? ing.qty;
          displayUnit = alt.unit ?? ing.unit;
        }

        return _buildRow(
          context,
          displayName,
          displayQty,
          displayUnit,
          hasAlts: hasAlts,
          activeIdx: idx,
          totalOptions: alts.length + 1,
          onCycle: hasAlts
              ? () => ops.cycleAlternative(ing.id)
              : null,
        );
      },
    );
  }

  Widget _buildRow(
    BuildContext context,
    String name,
    double? qty,
    String? unit, {
    required bool hasAlts,
    required VoidCallback? onCycle,
    int? activeIdx,
    int totalOptions = 1,
  }) {
    final scale = baseServings > 0 ? servingScale / baseServings : 1.0;
    final scaledQty = qty != null ? qty * scale : null;
    final qtyStr = scaledQty != null
        ? (scaledQty == scaledQty.roundToDouble()
            ? scaledQty.toInt().toString()
            : scaledQty.toStringAsFixed(1))
        : '';

    // Dot indicator: which option is active (e.g. "2/3")
    final indicatorLabel = hasAlts
        ? '${(activeIdx ?? -1) + 2}/$totalOptions'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Text('• '),
          if (qtyStr.isNotEmpty) Text('$qtyStr '),
          if (unit?.isNotEmpty == true) Text('$unit '),
          Expanded(child: Text(name)),
          if (hasAlts) ...[
            if (indicatorLabel != null)
              Text(
                indicatorLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: 2),
            GestureDetector(
              onTap: onCycle,
              child: Tooltip(
                message: 'Cycle alternative',
                child: Icon(
                  Icons.swap_horiz,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Add to list sheet ─────────────────────────────────────────────────────────

class _AddToListSheet extends ConsumerWidget {
  final Recipe recipe;
  const _AddToListSheet({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListsProvider);
    final ops = ref.watch(recipeOpsProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Add to which list?',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          lists.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No shopping lists yet.'),
                  )
                : Column(
                    children: items
                        .map((list) => ListTile(
                              title: Text(list.name),
                              onTap: () async {
                                Navigator.pop(context);
                                await ops.addToShoppingList(
                                    recipe.id, list.id, recipe.name);
                              },
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
