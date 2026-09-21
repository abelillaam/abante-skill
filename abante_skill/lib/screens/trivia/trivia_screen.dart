import 'package:flutter/material.dart';

import '../../services/daily_quiz_limiter.dart';
import '../../services/trivia_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pressable_scale.dart';

enum _QuizState { loading, error, question, answered, limitReached }

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  _QuizState _state = _QuizState.loading;
  TriviaQuestion? _question;
  String? _selectedAnswer;
  int _score = 0;
  int _asked = 0;
  int _remainingToday = DailyQuizLimiter.dailyLimit;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() => _state = _QuizState.loading);

    final remaining = await DailyQuizLimiter.getRemainingToday();
    if (!mounted) return;
    if (remaining <= 0) {
      setState(() {
        _remainingToday = 0;
        _state = _QuizState.limitReached;
      });
      return;
    }

    try {
      final question = await TriviaService.fetchRandomQuestion();
      if (!mounted) return;
      setState(() {
        _question = question;
        _selectedAnswer = null;
        _remainingToday = remaining;
        _state = _QuizState.question;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _QuizState.error);
    }
  }

  Future<void> _onSelectAnswer(String answer) async {
    if (_state != _QuizState.question) return;
    final correct = answer == _question!.correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _state = _QuizState.answered;
      _asked++;
      if (correct) _score++;
      _remainingToday = (_remainingToday - 1).clamp(0, DailyQuizLimiter.dailyLimit);
    });
    await DailyQuizLimiter.recordAnswer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CS Trivia'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Score: $_score/$_asked  ·  $_remainingToday left today',
                style: AppTheme.stat(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _QuizState.loading:
        return const Center(child: CircularProgressIndicator());
      case _QuizState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text(
                "Couldn't load a question",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Check your connection and try again.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _loadQuestion, child: const Text('Retry')),
            ],
          ),
        );
      case _QuizState.limitReached:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 44, color: AppColors.streak),
              const SizedBox(height: 14),
              const Text(
                "That's today's 10 questions!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Final score: $_score/$_asked · come back tomorrow for more.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      case _QuizState.question:
      case _QuizState.answered:
        final question = _question!;
        final answered = _state == _QuizState.answered;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
                ],
              ),
              child: Text(
                question.question,
                style: AppTheme.headline(fontSize: 18, weight: FontWeight.w800).copyWith(height: 1.35),
              ),
            ),
            const SizedBox(height: 20),
            for (final answer in question.answers) ...[
              _AnswerTile(
                label: answer,
                state: !answered
                    ? _AnswerTileState.neutral
                    : answer == question.correctAnswer
                        ? _AnswerTileState.correct
                        : answer == _selectedAnswer
                            ? _AnswerTileState.wrong
                            : _AnswerTileState.neutral,
                onTap: () => _onSelectAnswer(answer),
              ),
              const SizedBox(height: 12),
            ],
            const Spacer(),
            if (answered)
              SizedBox(
                width: double.infinity,
                child: PressableScale(
                  child: FilledButton.icon(
                    onPressed: _loadQuestion,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Next Question'),
                  ),
                ),
              ),
          ],
        );
    }
  }
}

enum _AnswerTileState { neutral, correct, wrong }

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.label, required this.state, required this.onTap});

  final String label;
  final _AnswerTileState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _AnswerTileState.correct => AppColors.success,
      _AnswerTileState.wrong => AppColors.error,
      _AnswerTileState.neutral => AppColors.border,
    };
    final background = switch (state) {
      _AnswerTileState.correct => AppColors.success.withValues(alpha: 0.1),
      _AnswerTileState.wrong => AppColors.error.withValues(alpha: 0.1),
      _AnswerTileState.neutral => AppColors.surface,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: state == _AnswerTileState.neutral ? 1.5 : 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
            if (state == _AnswerTileState.correct) const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            if (state == _AnswerTileState.wrong) const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
          ],
        ),
      ),
    );
  }
}
