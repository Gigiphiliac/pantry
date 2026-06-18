import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pantry/features/settings/settings_screen.dart';
import 'ocr_providers.dart';
import '../recipe_form_screen.dart';

class OcrScanScreen extends ConsumerStatefulWidget {
  final XFile image;

  const OcrScanScreen({super.key, required this.image});

  @override
  ConsumerState<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends ConsumerState<OcrScanScreen> {
  bool _scanning = false;
  String _phase = '';

  Future<void> _scan(LlmConfig config) async {
    setState(() {
      _scanning = true;
      _phase = 'Extracting text…';
    });

    try {
      final service = ref.read(recipeOcrServiceProvider);
      final rawText = await service.extractText(widget.image);

      if (!mounted) return;
      setState(() => _phase = 'Structuring recipe…');

      final draft = await service.structureRecipe(rawText, config);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeFormScreen(initialDraft: draft),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _phase = '';
      });
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Confirm Photo'),
      ),
      body: Stack(
        children: [
          // Full-screen image preview
          Positioned.fill(
            child: Image.file(
              File(widget.image.path),
              fit: BoxFit.contain,
            ),
          ),

          // LLM not configured banner
          llmAsync.when(
            data: (config) => !config.isConfigured
                ? Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.orange.shade900.withValues(alpha: 0.92),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'OCR structuring requires LLM — configure in Settings',
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
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Scanning overlay
          if (_scanning)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.72),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      _phase,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom action bar
          if (!_scanning)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                child: llmAsync.when(
                  data: (config) => Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Retake'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: config.isConfigured
                              ? () => _scan(config)
                              : null,
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Use Photo'),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
