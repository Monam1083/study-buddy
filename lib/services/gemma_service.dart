import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/study_result.dart';

class GemmaService {
  // Run with: flutter run --dart-define=GEMINI_KEY=your_key
  static const String _apiKey = String.fromEnvironment('GEMINI_KEY');

  // Fallback if this is slow or rate limited: 'gemma-4-26b-a4b-it'
  static const String _model = 'gemma-4-31b-it';

  static const String _systemPrompt = '''
You are a study tutor for university students.
Use ONLY what is visible in the image. Do not invent content.
If the image is blurry, empty, or unreadable, return exactly:
{"error": "Image unclear. Please retake the photo."}

Otherwise return ONLY valid JSON (no markdown, no commentary) in this shape:
{
  "topic": "short title",
  "steps": [{"title": "...", "explanation": "..."}],
  "quiz": [{"question": "...", "options": ["...", "...", "...", "..."],
            "answer_index": 0, "why": "..."}],
  "flashcards": [{"front": "...", "back": "..."}]
}
Rules: 4-6 steps, exactly 5 quiz questions with 4 options each,
6-8 flashcards. Write in simple, clear English.
''';

  /// [thinkingLevel]: 'minimal' (fast) or 'high' (better reasoning, slower).
  /// If the API rejects the thinking setting, pass null to omit it.
  Future<StudyResult> analyzeImage(
    XFile image, {
    String? thinkingLevel = 'minimal',
  }) async {
    if (_apiKey.isEmpty) {
      throw StudyException(
        'Missing API key. Run with --dart-define=GEMINI_KEY=your_key',
      );
    }

    final bytes = await image.readAsBytes();
    final mime = _mimeFor(image.path);

    for (var attempt = 1; attempt <= 2; attempt++) {
      final text = await _callApi(bytes, mime, thinkingLevel);
      try {
        return StudyResult.fromJson(_extractJson(text));
      } catch (e) {
        if (e is StudyException) rethrow; // e.g. "Image unclear"
        if (attempt == 2) {
          throw StudyException(
            'The AI returned an unexpected format. Please try again.',
          );
        }
      }
    }
    throw StudyException('Something went wrong. Please try again.');
  }

  Future<String> _callApi(
    List<int> bytes,
    String mime,
    String? thinking,
  ) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
    );

    final body = <String, dynamic>{
      'system_instruction': {
        'parts': [
          {'text': _systemPrompt},
        ],
      },
      'contents': [
        {
          'parts': [
            {
              'inline_data': {'mime_type': mime, 'data': base64Encode(bytes)},
            },
            {
              'text':
                  'Explain this step by step, then make a quiz and flashcards.',
            },
          ],
        },
      ],
      if (thinking != null)
        'generationConfig': {
          'thinkingConfig': {'thinkingLevel': thinking},
        },
    };

    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));
    } catch (_) {
      throw StudyException('Network error. Check your internet connection.');
    }

    if (res.statusCode != 200) {
      final snippet = res.body.length > 200
          ? res.body.substring(0, 200)
          : res.body;
      throw StudyException('API error ${res.statusCode}: $snippet');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final parts = (data['candidates']?[0]?['content']?['parts'] ?? []) as List;

    // Skip "thought" parts; use the last real text part as the answer.
    final texts = parts
        .where((p) => p is Map && p['text'] != null && p['thought'] != true)
        .map((p) => p['text'].toString())
        .toList();

    if (texts.isEmpty) {
      throw StudyException('The AI returned an empty response. Try again.');
    }
    return texts.last;
  }

  Map<String, dynamic> _extractJson(String text) {
    final cleaned = text.replaceAll(RegExp(r'```(?:json)?'), '').trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1) {
      throw const FormatException('No JSON found');
    }
    return jsonDecode(cleaned.substring(start, end + 1))
        as Map<String, dynamic>;
  }

  String _mimeFor(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
