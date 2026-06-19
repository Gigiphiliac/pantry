import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pantry/db/database.dart';
import 'recipe_providers.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';
import 'models/recipe_draft.dart';
import 'ocr/ocr_scan_screen.dart';
import 'url_import/recipe_url_providers.dart';
import 'url_import/recipe_url_service.dart';

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
              onTap: () async {
                Navigator.pop(ctx);
                await _importFromUrl();
              },
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

  Future<void> _importFromUrl() async {
    // Pre-fill from clipboard if it looks like a URL
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final initial = _looksLikeUrl(clip?.text) ? clip!.text!.trim() : '';

    if (!mounted) return;
    final url = await _promptUrl(context, initial: initial);
    if (url == null || url.isEmpty || !mounted) return;

    final service = ref.read(recipeUrlServiceProvider);

    RecipeDraft? draft;
    Object? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UrlImportDialog(
        url: url,
        service: service,
        onDone: (d) {
          draft = d;
          Navigator.pop(ctx);
        },
        onError: (e) {
          error = e;
          Navigator.pop(ctx);
        },
      ),
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      return;
    }

    if (draft != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeFormScreen(
            initialDraft: draft,
            sourceUrl: url,
            sourceType: 'url',
          ),
        ),
      );
    }
  }

  bool _looksLikeUrl(String? s) =>
      s != null &&
      (s.startsWith('http://') || s.startsWith('https://'));

  Future<String?> _promptUrl(BuildContext context,
      {String initial = ''}) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import from URL'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'https://…'),
          keyboardType: TextInputType.url,
          autocorrect: false,
          onSubmitted: (_) => Navigator.pop(ctx, ctrl.text.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

class _UrlImportDialog extends StatefulWidget {
  final String url;
  final RecipeUrlService service;
  final void Function(RecipeDraft) onDone;
  final void Function(Object) onError;

  const _UrlImportDialog({
    required this.url,
    required this.service,
    required this.onDone,
    required this.onError,
  });

  @override
  State<_UrlImportDialog> createState() => _UrlImportDialogState();
}

class _UrlImportDialogState extends State<_UrlImportDialog> {
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final draft = await widget.service.fetchAndParse(widget.url);
      if (!_cancelled && mounted) widget.onDone(draft);
    } catch (e) {
      if (!_cancelled && mounted) widget.onError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 30),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text('Fetching recipe…'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _cancelled = true;
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ],
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
