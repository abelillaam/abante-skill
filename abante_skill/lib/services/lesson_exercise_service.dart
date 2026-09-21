import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/groq_config.dart';

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

/// Generic fallback used if generation fails, so the screen never breaks.
const fallbackExercise = LessonExercise(
  instruction: 'Create a variable named age, set it to 20, then write an '
      'if / else statement that prints "You can vote!" when age is 18 or older.',
  starterCode: '# Write your code below\n\n',
  language: 'python',
  fileName: 'main.py',
);

/// Generates the hands-on coding exercise for a lesson, tailored to that
/// lesson's actual topic via Groq — instead of a fixed, unrelated task.
class LessonExerciseService {
  LessonExerciseService._();

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

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

  static Future<LessonExercise> generate({
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

      if (response.statusCode != 200) return fallbackExercise;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final content = body['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      final instruction = parsed['instruction'] as String?;
      final starterCode = parsed['starterCode'] as String?;
      if (instruction == null || instruction.isEmpty) return fallbackExercise;

      return LessonExercise(
        instruction: instruction,
        starterCode: starterCode ?? '',
        language: parsed['language'] as String? ?? 'python',
        fileName: parsed['fileName'] as String? ?? 'main.py',
      );
    } catch (_) {
      return fallbackExercise;
    }
  }
}
