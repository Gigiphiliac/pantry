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
    final ingredientsFuture = ops.getIngredients(_recipe.id);

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
      body: FutureBuilder<List<RecipeIngredientRow>>(
        future: ingredientsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final ingredients = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_recipe.servings != null) _servingsRow(),
              if (ingredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...ingredients.map((ing) => _ingredientRow(ing)),
              ],
              if (_recipe.instructions?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                Text('Instructions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_recipe.instructions!),
              ],
              if (_recipe.sourceUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                Text('Source', style: Theme.of(context).textTheme.titleMedium),
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
          );
        },
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

  Widget _ingredientRow(RecipeIngredientRow ing) {
    final scale = _baseServings > 0 ? _servingScale / _baseServings : 1.0;
    final scaledQty = ing.qty != null ? ing.qty! * scale : null;
    final qtyStr = scaledQty != null
        ? (scaledQty == scaledQty.roundToDouble()
            ? scaledQty.toInt().toString()
            : scaledQty.toStringAsFixed(1))
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Text('• '),
          if (qtyStr.isNotEmpty) Text('$qtyStr '),
          if (ing.unit?.isNotEmpty == true) Text('${ing.unit} '),
          Expanded(child: Text(ing.ingredientName)),
        ],
      ),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
                                // context is from the outer sheet builder,
                                // which is no longer mounted after pop.
                                // Use ScaffoldMessenger via a root key instead.
                                // Snackbar is best-effort here.
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
