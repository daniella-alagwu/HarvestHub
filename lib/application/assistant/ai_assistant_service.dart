import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiAssistantService {
  AiAssistantService._internal();
  static final AiAssistantService instance = AiAssistantService._internal();

  static const _modelName = 'gemini-3.1-flash-lite';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent';

  static const _systemInstruction = '''
You are Flora, the HarvestHub Farm Products Assistant, built into a
local-produce marketplace app. Answer questions about fruits, vegetables,
grains, dairy, herbs, and other farm products: nutrition, seasonality,
storage, freshness, and simple recipe/pairing ideas. Keep answers short
(2-4 sentences), warm, and practical — this is a mobile chat bubble, not
an article. If asked about a specific farmer's live stock, pickup times,
or order status, say plainly that you can't check live data yet. If asked
something unrelated to farm products or this app, gently redirect to what
you can help with instead of answering it.
''';


  static const List<String> suggestedQuestions = [
    'Which fruits are rich in Vitamin C?',
    'How should tomatoes be stored?',
    'Which vegetables are seasonal?',
    'What are the health benefits of spinach?',
    'Suggest vegetables for a healthy salad.',
  ];

  Future<String> ask(String question) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
 
      debugPrint(
        'AiAssistantService: GEMINI_API_KEY is missing/empty in .env — '
        'serving a predefined answer instead of calling Gemini. '
        'See AI_ASSISTANT_SETUP.md §2-3.',
      );
      return _predefinedAnswer(question);
    }

    try {
      final uri = Uri.parse('$_endpoint?key=$apiKey');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': _systemInstruction},
            ],
          },
          'contents': [
            {
              'parts': [
                {'text': question},
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
       
        debugPrint(
          'AiAssistantService: Gemini returned ${response.statusCode}: '
          '${response.body}',
        );
        return _predefinedAnswer(question);
      }

      final text = _extractText(jsonDecode(response.body));
      if (text == null || text.trim().isEmpty) {
        debugPrint('AiAssistantService: empty Gemini response body: ${response.body}');
        return _predefinedAnswer(question);
      }
      return text.trim();
    } catch (e) {
      debugPrint('AiAssistantService: request failed ($e) — falling back.');
      return _predefinedAnswer(question);
    }
  }

  String? _extractText(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;
      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;
      return parts.map((p) => (p['text'] as String?) ?? '').join();
    } catch (_) {
      return null;
    }
  }

  
  String _predefinedAnswer(String question) {
    final q = question.toLowerCase();

    if (q.contains('vitamin c')) {
      return 'Great vitamin C sources include oranges, strawberries, kiwi, '
          'bell peppers, and guava. Bell peppers actually have more vitamin '
          'C per gram than most citrus fruits!';
    }
    if (q.contains('tomato') && q.contains('stor')) {
      return 'Store ripe tomatoes at room temperature, stem-side down, out '
          'of direct sunlight — refrigeration dulls their flavor and '
          'texture. Only refrigerate if they\'re very ripe and you need a '
          'few extra days.';
    }
    if (q.contains('seasonal')) {
      return 'Seasonality depends on your region, but generally: leafy '
          'greens and peas thrive in cooler months, while tomatoes, corn, '
          'and peppers peak in summer. Check a listing\'s farmer for '
          'what\'s fresh near you right now.';
    }
    if (q.contains('spinach')) {
      return 'Spinach is rich in iron, vitamin K, and antioxidants, and '
          'it\'s low in calories. Pairing it with a vitamin-C-rich food '
          '(like citrus or bell pepper) helps your body absorb its iron '
          'better.';
    }
    if (q.contains('salad')) {
      return 'A well-rounded salad works well with a leafy base (spinach '
          'or romaine), a crunchy veggie (cucumber or bell pepper), '
          'something sweet (cherry tomatoes or apple), and a protein '
          '(chickpeas or grilled chicken).';
    }

    return "I can help with basic questions about fruits, vegetables, "
        "storage, nutrition, and seasonality. Try asking something like "
        "\"${suggestedQuestions.first}\"";
  }
}