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
  bool _analysing = false;

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

  Future<void> _analyse(LlmConfig config) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text to analyse — retake the photo.')),
      );
      return;
    }

    setState(() => _analysing = true);

    try {
      final service = ref.read(recipeOcrServiceProvider);
      final draft = await service.structureRecipe(text, config);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeFormScreen(initialDraft: draft),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _analysing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final llmAsync = ref.watch(llmConfigProvider);
    final providerConfig = llmAsync.valueOrNull;
    final config = providerConfig?.activeLlmConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Scanned Text'),
      ),
      body: Stack(
        children: [
          // Main content
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LLM not configured banner
                if (providerConfig != null && !providerConfig.isConfigured)
                  Container(
                    color: Colors.orange.shade900,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'LLM not configured — cannot structure recipe',
                            style: TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          ),
                          child: const Text('Settings',
                              style: TextStyle(color: Colors.white)),
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

                // Analyse button
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: FilledButton(
                      onPressed: providerConfig?.isConfigured == true
                          ? () => _analyse(config!)
                          : null,
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Analyse Recipe'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // LLM loading overlay
          if (_analysing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Structuring recipe…',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
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
