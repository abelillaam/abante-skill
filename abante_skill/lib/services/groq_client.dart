import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/groq_config.dart';

/// Thrown when Groq couldn't produce a usable answer even after retrying.
class GroqUnavailable implements Exception {
  const GroqUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'GroqUnavailable: $reason';
}

/// Sends a JSON-mode chat request to Groq, retrying the failures that are
/// usually temporary — rate limits (Groq's free tier caps tokens per
/// minute, which a burst like "build curriculum, then open a lesson" easily
/// hits), server hiccups, and timeouts — instead of giving up on the first
/// one.
class GroqClient {
  GroqClient._();

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'openai/gpt-oss-120b';
  static const _maxAttempts = 3;

  /// Returns the model's reply parsed as a JSON object. Throws
  /// [GroqUnavailable] if every attempt fails.
  static Future<Map<String, dynamic>> chatJson({
    required String system,
    required String user,
    double temperature = 0.7,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    var lastReason = 'unknown error';
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(_endpoint),
              headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${GroqConfig.apiKey}'},
              body: jsonEncode({
                'model': _model,
                'response_format': {'type': 'json_object'},
                'temperature': temperature,
                // Less hidden "thinking" = faster replies and fewer tokens
                // against the per-minute limit; plenty for lesson content.
                'reasoning_effort': 'low',
                'messages': [
                  {'role': 'system', 'content': system},
                  {'role': 'user', 'content': user},
                ],
              }),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final content = body['choices'][0]['message']['content'] as String;
          return jsonDecode(content) as Map<String, dynamic>;
        }

        lastReason = 'HTTP ${response.statusCode}';
        final retryable = response.statusCode == 429 || response.statusCode >= 500;
        if (!retryable || attempt == _maxAttempts) break;
        await Future.delayed(_retryDelay(response, attempt));
      } on TimeoutException {
        lastReason = 'timed out';
        if (attempt == _maxAttempts) break;
      } on FormatException {
        // The model returned malformed JSON — asking again usually fixes it.
        lastReason = 'invalid JSON';
        if (attempt == _maxAttempts) break;
      } catch (e) {
        lastReason = e.toString();
        if (attempt == _maxAttempts) break;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    throw GroqUnavailable(lastReason);
  }

  /// Waits as long as Groq asks (Retry-After), within reason, else backs off.
  static Duration _retryDelay(http.Response response, int attempt) {
    final retryAfter = double.tryParse(response.headers['retry-after'] ?? '');
    if (retryAfter != null && retryAfter > 0) {
      return Duration(milliseconds: (retryAfter.clamp(1, 20) * 1000).round());
    }
    return Duration(seconds: attempt * 3);
  }
}
