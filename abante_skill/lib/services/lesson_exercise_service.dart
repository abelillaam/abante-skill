import 'groq_client.dart';

class LessonExercise {
  const LessonExercise({
    required this.instruction,
    required this.starterCode,
    required this.language,
    required this.fileName,
  });

  final String instruction;
  final String starterCode;
  final String language;
  final String fileName;
}

/// Generates the hands-on coding exercise for a lesson, tailored to that
/// lesson's actual topic via Groq — instead of a fixed, unrelated task.
class LessonExerciseService {
  LessonExerciseService._();

  static const _systemPrompt = '''
You are a coding exercise designer for a coding education app. Given a
lesson's title and summary, and the student's experience level, create ONE
short, specific hands-on coding exercise that teaches exactly that concept,
pitched at that student's level — simpler and more guided for a beginner,
more independent and less hand-held for someone more advanced.

Critical rule: "starterCode" must NEVER contain the solution, a working
implementation, or any code that already accomplishes the task. It may only
contain: a comment describing what to do, blank lines, import/setup
boilerplate the task doesn't hinge on, and at most an empty function
signature or variable declaration left unfinished (e.g. "age = " or
"def check_age():\\n    # your code here"). The student must still have to
write the actual logic themselves. If you are unsure whether a line gives
away the answer, leave it out.

Respond with ONLY valid JSON (no markdown) matching exactly this schema:
{
  "instruction": "one clear paragraph describing the task",
  "starterCode": "boilerplate/comments only, per the rule above — never the solution",
  "language": "lowercase language name matching the lesson topic, e.g. python, javascript, html",
  "fileName": "an appropriate filename for that language, e.g. main.py, index.html, script.js"
}
''';

  /// Generates this lesson's exercise. Throws [GroqUnavailable] if the AI
  /// can't be reached even after retrying — callers show a "try again" state
  /// rather than an unrelated placeholder task.
  static Future<LessonExercise> generate({
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

    final instruction = parsed['instruction'] as String?;
    if (instruction == null || instruction.trim().isEmpty) {
      throw const GroqUnavailable('no instruction in reply');
    }
    return LessonExercise(
      instruction: instruction,
      starterCode: parsed['starterCode'] as String? ?? '',
      language: parsed['language'] as String? ?? 'python',
      fileName: parsed['fileName'] as String? ?? 'main.py',
    );
  }
}
