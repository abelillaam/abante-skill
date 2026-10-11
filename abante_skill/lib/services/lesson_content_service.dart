import 'groq_client.dart';

class TheoryCard {
  const TheoryCard({required this.heading, required this.analogy, required this.snippet, required this.language});

  final String heading;
  final String analogy;
  final String snippet;
  final String language;
}

/// Generates the "theory card" explanations shown before a lesson's coding
/// exercise, tailored to that specific lesson's actual topic via Groq.
class LessonContentService {
  LessonContentService._();

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

  /// Generates this lesson's theory cards. Throws [GroqUnavailable] if the
  /// AI can't be reached even after retrying — callers show a "try again"
  /// state rather than unrelated placeholder content.
  static Future<List<TheoryCard>> generate({
    required String lessonTitle,
    required String lessonSummary,
    String? level,
  }) async {
    final parsed = await GroqClient.chatJson(
      system: _systemPrompt,
      user:
          'Lesson title: $lessonTitle\nLesson summary: $lessonSummary\n'
          'Student experience level: ${level ?? 'Beginner'}',
    );
    final language = parsed['language'] as String? ?? 'code';
    final rawCards = parsed['cards'] as List<dynamic>? ?? [];

    final cards = rawCards
        .whereType<Map<String, dynamic>>()
        .map(
          (c) => TheoryCard(
            heading: c['heading'] as String? ?? '',
            analogy: c['analogy'] as String? ?? '',
            snippet: c['snippet'] as String? ?? '',
            language: language,
          ),
        )
        .where((c) => c.heading.isNotEmpty)
        .toList();

    if (cards.isEmpty) throw const GroqUnavailable('no cards in reply');
    return cards;
  }
}
