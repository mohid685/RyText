import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyCbDc91aTOsb013wDeVXf2TxDhelDs-IfM'; // Replace with your actual API key
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  
  // List of available models to try
  static const List<String> _models = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-pro',
  ];

  static Future<String> askRyAI(String question, {String? context}) async {
    final prompt = context != null 
        ? "Context: $context\n\nUser Question: $question\n\nPlease provide a helpful, concise response as RyAI, a friendly AI assistant in the RyText messaging app."
        : "User Question: $question\n\nPlease provide a helpful, concise response as RyAI, a friendly AI assistant in the RyText messaging app.";

    // Try each model until one works
    for (String model in _models) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 1024,
            },
            'safetySettings': [
              {
                'category': 'HARM_CATEGORY_HARASSMENT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
              },
              {
                'category': 'HARM_CATEGORY_HATE_SPEECH',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
              },
              {
                'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
              },
              {
                'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 
                      'Sorry, I couldn\'t process your request right now.';
          print('✅ RyAI success with model: $model');
          return text;
        } else if (response.statusCode == 404) {
          print('❌ Model $model not found, trying next model...');
          continue; // Try next model
        } else {
          print('❌ Gemini API Error with $model: ${response.statusCode} - ${response.body}');
          continue; // Try next model
        }
      } catch (e) {
        print('❌ Error with model $model: $e');
        continue; // Try next model
      }
    }
    
    // If all models failed
    return 'Sorry, I\'m having trouble connecting to the AI service right now. Please check your internet connection and try again later.';
  }

  static bool isRyAIMessage(String text) {
    return text.toLowerCase().startsWith('@ryai');
  }

  static String extractQuestionFromRyAIMessage(String text) {
    if (isRyAIMessage(text)) {
      return text.substring(5).trim(); // Remove "@ryai" and trim
    }
    return text;
  }

  // Debug method to list available models
  static Future<void> listAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📋 Available Gemini models:');
        final models = data['models'] as List?;
        if (models != null) {
          for (var model in models) {
            final name = model['name'] ?? 'Unknown';
            final supportedMethods = model['supportedGenerationMethods'] as List?;
            print('  - $name (methods: ${supportedMethods?.join(', ') ?? 'unknown'})');
          }
        }
      } else {
        print('❌ Failed to list models: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error listing models: $e');
    }
  }
}
