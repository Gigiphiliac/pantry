import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'ocr_providers.dart';
import 'ocr_review_screen.dart';

class OcrScanScreen extends ConsumerStatefulWidget {
  final XFile image;

  const OcrScanScreen({super.key, required this.image});

  @override
  ConsumerState<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends ConsumerState<OcrScanScreen> {
  bool _scanning = false;
  String _phase = '';
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.image.readAsBytes();
    if (mounted) setState(() => _imageBytes = bytes);
  }

  Future<void> _extractAndReview() async {
    setState(() {
      _scanning = true;
      _phase = 'Analysing recipe…';
    });

    try {
      final service = ref.read(recipeOcrServiceProvider);
      final classifier = ref.read(onnxClassifierProvider);

      // Step 1: Run ML Kit OCR with spatial data
      final ocrInput = await service.extractDetailed(widget.image);

      if (!mounted) return;

      // Step 2: Run classifier to label each line
      final result = await service.parseWithClassifier(
        ocrInput,
        classifier,
      );
      final draft = result.draft;
      final usedStub = result.usedStub;

      if (!mounted) return;

      // Step 3: Navigate to the parsed preview screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrReviewScreen(
            ocrInput: ocrInput,
            draft: draft,
            usedStub: usedStub,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 5),
        ),
      );
      setState(() {
        _scanning = false;
        _phase = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: _imageBytes != null
                ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
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
                        fontWeight: FontWeight.w500,
                      ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Hint banner ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '💡 For best results, use a clean recipe image. '
                        'On websites, the pre-print view works best.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // ── Buttons ─────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white54,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            child: const Text('Retake'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _extractAndReview,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            child: const Text('Use Photo'),
                          ),
                        ),
                      ],
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