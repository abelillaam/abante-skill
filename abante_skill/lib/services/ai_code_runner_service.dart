import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/groq_config.dart';

class AiRunResult {
  const AiRunResult({required this.output, required this.correct});

  /// What the AI predicts would print to the console (or an error message).
  /// This is a simulation, not real execution — it can occasionally be wrong.
  final String output;

  /// Whether the AI judged the code to satisfy the task instructions.
  /// Always true when there's no task (sandbox mode).
  final bool correct;
}

/// Simulates running a code snippet via Groq: predicts console output and,
/// for a graded exercise, judges whether the code solves it. This is an AI
/// prediction, not real code execution.
class AiCodeRunnerService {
  AiCodeRunnerService._();

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static const _systemPrompt = '''
You are a code execution simulator for a coding education app. Given source
code in a specific language, determine EXACTLY what would be printed to
stdout if it were run — or the error message it would raise, formatted like
a real interpreter/compiler error, if it would fail to run.

You must always commit to a specific, concrete prediction. Never refuse,
hedge, or say you cannot verify/determine/simulate the output — mentally
trace through the code step by step and give your best concrete answer even
if you are uncertain. The "output" field must only ever contain what a real
terminal would show (program output or an error message) — never a
disclaimer, apology, or explanation of your own limitations.

If task instructions are given, also judge whether the code correctly
satisfies them (ignoring style — only whether the behavior is correct).
If no task instructions are given, "correct" should always be true.

Respond with ONLY valid JSON (no markdown) matching exactly this schema:
{ "output": "the predicted stdout or error text", "correct": true or false }
''';

  static Future<AiRunResult> run({
    required String code,
    required String language,
    String? taskInstruction,
  }) async {
    final userContent = StringBuffer('Language: $language\n');
    if (taskInstruction != null) {
      userContent.writeln('Task instructions: $taskInstruction');
    }
    userContent.writeln('\nCode:\n$code');

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
            'temperature': 0.2,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': userContent.toString()},
            ],
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('AI code runner request failed (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = body['choices'][0]['message']['content'] as String;
    final parsed = jsonDecode(content) as Map<String, dynamic>;

    return AiRunResult(
      output: parsed['output'] as String? ?? '',
      correct: taskInstruction == null ? true : (parsed['correct'] as bool? ?? false),
    );
  }
}
