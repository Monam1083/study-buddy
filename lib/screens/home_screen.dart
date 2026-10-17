import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/study_result.dart';
import '../services/gemma_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  final _service = GemmaService();

  bool _loading = false;
  bool _deepExplain = false; // uses thinking level "high"

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1024, // resize to speed up upload and response
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _loading = true);
    try {
      final result = await _service.analyzeImage(
        image,
        thinkingLevel: _deepExplain ? 'high' : 'minimal',
      );

      // Milestone 1 check: raw output in the debug console.
      debugPrint(
        'Topic: ${result.topic}, steps: ${result.steps.length}, '
        'quiz: ${result.quiz.length}, cards: ${result.flashcards.length}',
      );

      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ResultScreen(result: result)));
    } on StudyException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Study Buddy')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Gemma is reading your page...'),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 80,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Snap a page. Learn it.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Photograph a textbook page, handwritten notes, or a diagram '
                    'and get step-by-step explanations, a quiz, and flashcards.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => _pickAndAnalyze(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Take a photo'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _pickAndAnalyze(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from gallery'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _deepExplain,
                    onChanged: (v) => setState(() => _deepExplain = v),
                    title: const Text('Deep explain'),
                    subtitle: const Text('Slower, better for math and logic'),
                  ),
                ],
              ),
      ),
    );
  }
}
