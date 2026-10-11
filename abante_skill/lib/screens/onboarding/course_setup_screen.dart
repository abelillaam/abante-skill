import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/groq_client.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/curriculum_generating_overlay.dart';
import '../auth/auth_flow.dart';
import '../main_shell.dart';
import 'onboarding_questionnaire_screen.dart';

/// Builds a signed-in user's personalized course from their onboarding
/// answers, then opens the app. If the AI can't build it, the person can
/// retry or change their answers — they're never dropped into a generic
/// sample course.
class CourseSetupScreen extends StatefulWidget {
  const CourseSetupScreen({super.key, required this.answers});

  final OnboardingAnswers answers;

  @override
  State<CourseSetupScreen> createState() => _CourseSetupScreenState();
}

class _CourseSetupScreenState extends State<CourseSetupScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _failed = false);
    try {
      await SessionService.createCurriculum(
        user,
        track: widget.answers.track,
        level: widget.answers.level,
        dailyGoal: widget.answers.dailyGoal,
      );
    } on GroqUnavailable {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (route) => false);
  }

  void _changeAnswers() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingQuestionnaireScreen(alreadySignedIn: true)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_failed) return const CurriculumGeneratingOverlay();

    final onHero = AppColors.onHero;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.splashGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AbanteMark(size: 88, animate: false),
                const SizedBox(height: 24),
                Text(
                  "Couldn't build your course",
                  textAlign: TextAlign.center,
                  style: AppTheme.headline(fontSize: 22, weight: FontWeight.w800, color: onHero),
                ),
                const SizedBox(height: 10),
                Text(
                  'The course builder is busy or your connection dropped. '
                  'Your account is ready — give it a moment and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, height: 1.45, color: onHero.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _build,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Try again'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _changeAnswers,
                  child: Text(
                    'Change my answers',
                    style: TextStyle(color: onHero, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
