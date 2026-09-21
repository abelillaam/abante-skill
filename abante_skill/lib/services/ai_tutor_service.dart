import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/groq_config.dart';

/// Generates short, encouraging coding hints via Groq — guidance, not the
/// full answer, for whatever exercise/code the student currently has open.
class AiTutorService {
  AiTutorService._();

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static const _systemPrompt = '''
You are a friendly, encouraging coding tutor for a beginner. Given an
exercise's instructions and the student's current code, give a short hint
(2-4 sentences) that nudges them toward the solution WITHOUT writing the
full answer for them. Be warm and specific to what they've already typed.
''';

  static Future<String> getHint({
    required String instruction,
    required String code,
    required String language,
  }) async {
    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${GroqConfig.apiKey}',
          },
          body: jsonEncode({
            'model': 'openai/gpt-oss-120b',
            'temperature': 0.7,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {
                'role': 'user',
                'content': 'Exercise instructions: $instruction\n\n'
                    'Language: $language\n\n'
                    'My current code:\n$code',
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('AI tutor request failed (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['choices'][0]['message']['content'] as String).trim();
  }
}
