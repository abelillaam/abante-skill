import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class TriviaQuestion {
  const TriviaQuestion({required this.question, required this.answers, required this.correctAnswer});

  final String question;

  final List<String> answers;
  final String correctAnswer;
}

class TriviaService {
  TriviaService._();

  static const _endpoint = 'https://opentdb.com/api.php?amount=1&category=18&type=multiple&encode=url3986';

  static Future<TriviaQuestion> fetchRandomQuestion() => _fetchWithRetry(retriesLeft: 1);

  static Future<TriviaQuestion> _fetchWithRetry({required int retriesLeft}) async {
    final response = await http.get(Uri.parse(_endpoint)).timeout(const Duration(seconds: 10));
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // Open Trivia DB rate-limits to ~1 request per 5s per IP (HTTP 429,
    // response_code 5). Tapping "Next Question" quickly triggers this
    // constantly, so wait it out and retry once rather than surfacing it
    // as a connection failure.
    if (body['response_code'] == 5 && retriesLeft > 0) {
      await Future.delayed(const Duration(seconds: 5));
      return _fetchWithRetry(retriesLeft: retriesLeft - 1);
    }

    if (response.statusCode != 200 || body['response_code'] != 0) {
      throw Exception('Trivia request failed (${response.statusCode})');
    }

    final result = (body['results'] as List<dynamic>).first as Map<String, dynamic>;
    final question = Uri.decodeComponent(result['question'] as String);
    final correctAnswer = Uri.decodeComponent(result['correct_answer'] as String);
    final incorrectAnswers = (result['incorrect_answers'] as List<dynamic>)
        .map((a) => Uri.decodeComponent(a as String))
        .toList();

    final answers = [correctAnswer, ...incorrectAnswers]..shuffle(Random());

    return TriviaQuestion(question: question, answers: answers, correctAnswer: correctAnswer);
  }
}
