import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/features/meal_plans/meal_plan_providers.dart';

/// Searchable bottom sheet to pick a recipe to link to a meal slot.
///
/// The sheet expands when the keyboard opens so the search field and
/// recipe list remain fully visible.
class RecipePickerSheet extends ConsumerStatefulWidget {
  const RecipePickerSheet({super.key});

  @override
  ConsumerState<RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends ConsumerState<RecipePickerSheet> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipesAsync = ref.watch(allRecipesForPickerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Title ─────────────────────────────────────────
                Text(
                  'Link Recipe',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Search field ───────────────────────────────────
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search recipes…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 12),

                // ── Recipe list ────────────────────────────────────
                recipesAsync.when(
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SizedBox(
                    height: 200,
                    child: Center(child: Text('Error: $e')),
                  ),
                  data: (recipes) {
                    final filtered = _query.isEmpty
                        ? recipes
                        : recipes
                              .where(
                                (r) => r.name.toLowerCase().contains(_query),
                              )
                              .toList();

                    if (filtered.isEmpty) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: Text('No recipes found')),
                      );
                    }

                    return SizedBox(
                      height: 300,
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final recipe = filtered[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.menu_book_outlined,
                              size: 20,
                            ),
                            title: Text(
                              recipe.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => Navigator.pop(context, recipe),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
