import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/groq_config.dart';
import '../models/lesson.dart';
import '../models/lesson_icons.dart';

/// Generates a personalized lesson curriculum via Groq (Llama 3.3 70B).
class CurriculumService {
  CurriculumService._();

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static const _systemPrompt = '''
You are a curriculum designer for a coding education app. Given a learning
track, experience level, and daily time goal, generate a structured
curriculum. Respond with ONLY valid JSON (no markdown, no commentary)
matching exactly this schema:

{
  "units": [
    {
      "title": "string, e.g. Python Basics",
      "subtitle": "string, e.g. Unit 1",
      "lessons": [
        { "title": "string", "summary": "one sentence", "totalModules": integer between 2 and 5 }
      ]
    }
  ]
}

Generate 2-3 units, each with 3-5 lessons, ordered from foundational to
advanced for the given experience level. Keep titles concise.
''';

  /// Generates a curriculum, or returns [fallback] if the request or
  /// response parsing fails for any reason.
  static Future<List<LessonUnit>> generate({
    required String track,
    required String level,
    required String dailyGoal,
    List<LessonUnit> fallback = mockUnits,
  }) async {
    try {
      final response = await http.post(
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
              'content': 'Track: $track. Experience level: $level. Daily goal: $dailyGoal. '
                  'Generate a personalized coding curriculum.',
            },
          ],
        }),
      );

      if (response.statusCode != 200) return fallback;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final content = body['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final units = _parseUnits(parsed);
      return units.isEmpty ? fallback : units;
    } catch (_) {
      return fallback;
    }
  }

  static List<LessonUnit> _parseUnits(Map<String, dynamic> json) {
    final rawUnits = json['units'] as List<dynamic>? ?? [];
    var lessonCounter = 0;
    final units = <LessonUnit>[];

    for (var unitIndex = 0; unitIndex < rawUnits.length; unitIndex++) {
      final rawUnit = rawUnits[unitIndex] as Map<String, dynamic>;
      final rawLessons = rawUnit['lessons'] as List<dynamic>? ?? [];
      final lessons = <Lesson>[];

      for (var lessonIndex = 0; lessonIndex < rawLessons.length; lessonIndex++) {
        final rawLesson = rawLessons[lessonIndex] as Map<String, dynamic>;
        final isFirstLessonOverall = lessonCounter == 0;
        lessons.add(
          Lesson(
            id: 'lesson-$unitIndex-$lessonIndex',
            title: rawLesson['title'] as String? ?? 'Lesson ${lessonIndex + 1}',
            summary: rawLesson['summary'] as String? ?? '',
            icon: lessonIconAt(lessonCounter),
            status: isFirstLessonOverall ? LessonStatus.active : LessonStatus.locked,
            totalModules: (rawLesson['totalModules'] as num?)?.toInt() ?? 3,
          ),
        );
        lessonCounter++;
      }

      if (lessons.isEmpty) continue;

      units.add(
        LessonUnit(
          id: 'unit-$unitIndex',
          title: rawUnit['title'] as String? ?? 'Unit ${unitIndex + 1}',
          subtitle: rawUnit['subtitle'] as String? ?? 'Unit ${unitIndex + 1}',
          icon: unitIconAt(unitIndex),
          lessons: lessons,
        ),
      );
    }

    return units;
  }
}
