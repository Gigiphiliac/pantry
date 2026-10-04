import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/core/ocr/recipe_ocr_input.dart';
import 'package:pantry/features/recipes/models/recipe_draft.dart';

import 'ocr_providers.dart';
import '../recipe_form_screen.dart';

class OcrReviewScreen extends ConsumerStatefulWidget {
  final RecipeOcrInput ocrInput;
  final RecipeDraft draft;
  final bool usedStub;

  const OcrReviewScreen({
    super.key,
    required this.ocrInput,
    required this.draft,
    required this.usedStub,
  });

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  late final TextEditingController _rawTextCtrl;
  late RecipeDraft _draft;
  bool _showRawText = false;
  bool _reparsed = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _rawTextCtrl = TextEditingController(text: widget.ocrInput.rawText);
  }

  @override
  void dispose() {
    _rawTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _reparse() async {
    final text = _rawTextCtrl.text.trim();
    if (text.isEmpty) return;

    final service = ref.read(recipeOcrServiceProvider);
    final newDraft = service.parseRaw(text);
    setState(() {
      _draft = newDraft;
      _reparsed = true;
    });
  }

  Future<void> _createRecipe() async {
    setState(() => _processing = true);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeFormScreen(
          initialDraft: _draft,
          ocrInput: widget.ocrInput,
          sourceType: 'ocr',
        ),
      ),
    );
  }

  Widget _ingredientTile(IngredientDraft ing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
          ),
          if (ing.qty != null)
            Text(
              '${_formatQty(ing.qty!)} ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          if (ing.unit != null)
            Text(
              '${ing.unit} ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          Expanded(
            child: Text(
              ing.name + (ing.notes != null ? ', ${ing.notes}' : ''),
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatQty(double qty) {
    if (qty == qty.round()) {
      return qty.round().toString();
    }
    return qty.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Review Scanned Text')),
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Stub indicator ────────────────────────────────────────────
                if (widget.usedStub || _reparsed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          size: 18,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _reparsed
                                ? 'Re-parsed (heuristic) — quality may differ'
                                : 'Model unavailable — showing best-effort parse',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Name ──────────────────────────────────────────────────────
                if (_draft.name != null && _draft.name!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _draft.name!,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // ── Servings ──────────────────────────────────────────────────
                if (_draft.servings != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Serves ${_draft.servings}',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),

                // ── Ingredients ───────────────────────────────────────────────
                Text('Ingredients', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                if (_draft.sections.isNotEmpty)
                  ..._draft.sections.map((sec) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 2),
                          child: Text(
                            sec.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ...sec.ingredients.map((ing) => _ingredientTile(ing)),
                      ],
                    );
                  }),
                ..._draft.ingredients.map((ing) => _ingredientTile(ing)),
                if (_draft.ingredients.isEmpty && _draft.sections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '(no ingredients detected)',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Method ────────────────────────────────────────────────────
                Text('Method', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                if (_draft.steps.isNotEmpty)
                  ..._draft.steps.asMap().entries.map((e) {
                    final i = e.key;
                    final step = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 36,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                '${i + 1}.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(step, style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '(no steps detected)',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Expand/collapse raw text ──────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tappable label (InkWell bounds are confined to its child)
                    InkWell(
                      onTap: () => setState(() => _showRawText = !_showRawText),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.description, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _showRawText
                                    ? 'Hide OCR text'
                                    : 'View / Edit OCR Text',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            Icon(
                              _showRawText
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Raw text editor (rendered below the label — outside the InkWell's
                    // bounds, so it can receive taps without collapsing the panel)
                    if (_showRawText)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _rawTextCtrl,
                            maxLines: 15,
                            expands: false,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Edit the raw OCR text…',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: _reparse,
                                  child: const Text('Re-parse'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Create Recipe button ──────────────────────────────────────
                SafeArea(
                  top: false,
                  child: FilledButton(
                    onPressed: _processing ? null : _createRecipe,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Create Recipe'),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Processing overlay
          if (_processing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    const Text(
                      'Creating recipe…',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
