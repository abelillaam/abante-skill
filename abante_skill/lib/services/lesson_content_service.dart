import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/groq_config.dart';

class TheoryCard {
  const TheoryCard({required this.heading, required this.analogy, required this.snippet, required this.language});

  final String heading;
  final String analogy;
  final String snippet;
  final String language;
}

/// Generic fallback used if generation fails, so the screen never breaks.
const fallbackTheoryCards = [
  TheoryCard(
    heading: 'Think of it like a light switch',
    analogy:
        "An if statement checks a condition and only runs code when it's true — just like a switch only turns "
        'the light on when it\'s flipped up.',
    snippet: 'if age >= 18:\n    print("You can vote!")',
    language: 'python',
  ),
  TheoryCard(
    heading: 'Add an alternative with else',
    analogy: 'When the condition is false, else gives your program a fallback path to take instead.',
    snippet: 'if age >= 18:\n    print("You can vote!")\nelse:\n    print("Not yet!")',
    language: 'python',
  ),
  TheoryCard(
    heading: 'Chain more checks with elif',
    analogy: 'Need more than two outcomes? elif lets you test additional conditions in order.',
    snippet: 'if score >= 90:\n    grade = "A"\nelif score >= 80:\n    grade = "B"\nelse:\n    grade = "C"',
    language: 'python',
  ),
];

/// Generates the "theory card" explanations shown before a lesson's coding
/// exercise, tailored to that specific lesson's actual topic via Groq.
class LessonContentService {
  LessonContentService._();

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static const _systemPrompt = '''
You are a coding curriculum content writer. Given a lesson title, summary,
and the student's experience level, write 3 short teaching cards that
explain that specific concept step by step, each building on the previous
one. Pitch the explanations and code examples at the student's actual
level — simpler wording and smaller examples for a beginner, more concise
and technical for someone more advanced. Respond with ONLY valid JSON (no
markdown) matching exactly this schema:

{
  "language": "lowercase language name the code snippets use, e.g. python, javascript, html",
  "cards": [
    { "heading": "short title", "analogy": "one relatable plain-English explanation, 1-2 sentences", "snippet": "a short code example illustrating it" }
  ]
}

Generate exactly 3 cards, ordered from the most basic idea to a slightly
more advanced one, specific to the given lesson topic — not a generic
programming example.
''';

  static Future<List<TheoryCard>> generate({
    required String lessonTitle,
    required String lessonSummary,
    String? level,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${GroqConfig.apiKey}',
            },
            body: jsonEncode({
              'model': 'openai/gpt-oss-120b',
              'response_format': {'type': 'json_object'},
              'temperature': 0.7,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {
                  'role': 'user',
                  'content': 'Lesson title: $lessonTitle\nLesson summary: $lessonSummary\n'
                      'Student experience level: ${level ?? 'Beginner'}',
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return fallbackTheoryCards;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final content = body['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final language = parsed['language'] as String? ?? 'code';
      final rawCards = parsed['cards'] as List<dynamic>? ?? [];

      final cards = rawCards
          .map(
            (c) => TheoryCard(
              heading: (c as Map<String, dynamic>)['heading'] as String? ?? '',
              analogy: c['analogy'] as String? ?? '',
              snippet: c['snippet'] as String? ?? '',
              language: language,
            ),
          )
          .where((c) => c.heading.isNotEmpty)
          .toList();

      return cards.isEmpty ? fallbackTheoryCards : cards;
    } catch (_) {
      return fallbackTheoryCards;
    }
  }
}
