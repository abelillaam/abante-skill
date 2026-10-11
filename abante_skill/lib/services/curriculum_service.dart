import '../models/lesson.dart';
import '../models/lesson_icons.dart';
import 'groq_client.dart';

/// Generates a personalized lesson curriculum via Groq.
class CurriculumService {
  CurriculumService._();

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

  /// Generates a personalized curriculum. Throws [GroqUnavailable] if the
  /// AI can't produce one even after retrying — callers show a "try again"
  /// state rather than quietly saving a generic sample course.
  static Future<List<LessonUnit>> generate({
    required String track,
    required String level,
    required String dailyGoal,
  }) async {
    final parsed = await GroqClient.chatJson(
      system: _systemPrompt,
      user:
          'Track: $track. Experience level: $level. Daily goal: $dailyGoal. '
          'Generate a personalized coding curriculum.',
      timeout: const Duration(seconds: 45),
    );
    final units = _parseUnits(parsed);
    if (units.isEmpty) throw const GroqUnavailable('no units in reply');
    return units;
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
