import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pantry/features/settings/settings_screen.dart';
import 'ocr_providers.dart';
import '../recipe_form_screen.dart';

class OcrReviewScreen extends ConsumerStatefulWidget {
  final String rawText;

  const OcrReviewScreen({super.key, required this.rawText});

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  late final TextEditingController _textCtrl;
  bool _processing = false;
  String _overlayText = 'Structuring recipe…';

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.rawText);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRecipe() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text to process — retake the photo.')),
      );
      return;
    }

    final llmAsync = ref.read(llmConfigProvider);
    final providerConfig = llmAsync.valueOrNull;
    final config = providerConfig?.activeLlmConfig;
    final llmConfigured = providerConfig?.isConfigured == true;

    if (!llmConfigured) {
      // Offline fallback: deterministic parser
      final service = ref.read(recipeOcrServiceProvider);
      final draft = service.parseRaw(text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeFormScreen(initialDraft: draft, sourceType: 'ocr'),
        ),
      );
      return;
    }

    // LLM path
    setState(() {
      _processing = true;
      _overlayText = 'Structuring recipe…';
    });

    final service = ref.read(recipeOcrServiceProvider);
    try {
      final draft = await service.structureRecipe(text, config!);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeFormScreen(initialDraft: draft, sourceType: 'ocr'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // LLM failed — offer fallback to deterministic parser
      final useFallback = await _showFallbackDialog(e.toString());
      if (useFallback != true || !mounted) {
        setState(() => _processing = false);
        return;
      }

      setState(() => _overlayText = 'LLM failed — using basic parser');
      final draft = service.parseRaw(text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeFormScreen(initialDraft: draft, sourceType: 'ocr'),
        ),
      );
    }
  }

  /// Show a dialog asking the user whether to fall back to the basic parser.
  /// Returns true if the user opted for fallback, false if cancelled.
  Future<bool?> _showFallbackDialog(String error) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('LLM Parsing Failed'),
        content: Text(
          'The AI could not structure this recipe.\n\n$error\n\n'
          'Use the basic parser instead? Results may be less accurate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Use basic parser'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final llmAsync = ref.watch(llmConfigProvider);
    final providerConfig = llmAsync.valueOrNull;
    final llmConfigured = providerConfig?.isConfigured == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Scanned Text')),
      body: Stack(
        children: [
          // Main content
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subtle info banner when no LLM
                if (providerConfig != null && !llmConfigured)
                  Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No LLM configured — basic parsing only',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                          child: const Text('Settings', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                // Editable OCR text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _textCtrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Scanned text appears here…',
                      ),
                    ),
                  ),
                ),

                // Create Recipe button — always enabled
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: FilledButton(
                      onPressed:
                          _processing ? null : _createRecipe,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        llmConfigured ? 'Create Recipe' : 'Create Recipe',
                      ),
                    ),
                  ),
                ),
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
                    Text(
                      _overlayText,
                      style: const TextStyle(
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