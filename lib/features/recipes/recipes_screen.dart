import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pantry/db/database.dart';

import 'recipe_providers.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';
import 'ocr/ocr_scan_screen.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(recipesSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search recipes…',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              )
            : const Text('Recipes'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _searchCtrl.clear();
                _query = '';
              }
            }),
          ),
        ],
      ),
      body: recipes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? Center(
                child: Text(
                  _query.isNotEmpty
                      ? 'No recipes matching "$_query"'
                      : 'No recipes yet.\nTap + to add one.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final recipe = list[i];
                  return _RecipeTile(recipe: recipe);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Manual entry'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RecipeFormScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Scan from camera'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAndScan(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Scan from photo library'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAndScan(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Import from URL'),
              subtitle: const Text('Coming soon'),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final file =
        await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (file == null || !mounted) return;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OcrScanScreen(image: file)),
    );
  }
}

class _RecipeTile extends ConsumerWidget {
  final Recipe recipe;
  const _RecipeTile({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(recipeIngredientCountProvider(recipe.id));

    return ListTile(
      title: Text(recipe.name),
      subtitle: Text(_subtitle(recipe, count.valueOrNull ?? 0)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: recipe),
        ),
      ),
    );
  }

  String _subtitle(Recipe recipe, int ingredientCount) {
    final parts = <String>[];
    if (recipe.servings != null) parts.add('${recipe.servings} servings');
    if (ingredientCount > 0) parts.add('$ingredientCount ingredients');
    return parts.join(' · ');
  }
}
