import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiAssistantService {
  AiAssistantService._internal();
  static final AiAssistantService instance = AiAssistantService._internal();

  static const modelName = 'gemini-3.1-flash-lite';

  static const systemInstruction = '''
You are the HarvestHub Farm Products Assistant, built into a local-produce
marketplace app. Answer only questions about fruits, vegetables, grains,
dairy, herbs, and other farm products: nutrition, seasonality, storage,
freshness, and simple recipe/pairing ideas. Keep answers short (2-4
sentences), friendly, and practical — this is a mobile chat bubble, not an
article. If asked about a farmer's live stock, pickup times, or order
status, say plainly that you can't check live data yet. If asked something
unrelated to farm products or this app, politely redirect to what you can
help with instead of answering it.
''';

  GenerativeModel? model;
    
  GenerativeModel? resolveModel() {
    if (model != null) return model;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;
    model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction),
    );
    return model;
  }

 
  static const List<String> suggestedQuestions = [
    'Which fruits are rich in Vitamin C?',
    'How should tomatoes be stored?',
    'Which vegetables are seasonal?',
    'What are the health benefits of spinach?',
    'Suggest vegetables for a healthy salad.',
  ];

  Future<String> ask(String question) async {
    final model = resolveModel();

    if (model == null) {
      return predefinedAnswer(question);
    }

    try {
      final response = await model.generateContent([Content.text(question)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return predefinedAnswer(question);
      }
      return text;
    } catch (e) {
      debugPrint('AI-AssistantService: Gemini call failed ($e) — falling back.');
      return predefinedAnswer(question);
    }
  }

  String predefinedAnswer(String question) {
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