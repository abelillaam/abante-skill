import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/google_auth_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../main_shell.dart';
import '../onboarding/course_setup_screen.dart';
import '../onboarding/onboarding_questionnaire_screen.dart';

/// Answers from the onboarding questionnaire.
class OnboardingAnswers {
  const OnboardingAnswers({required this.track, required this.level, required this.dailyGoal});

  final String track;
  final String level;
  final String dailyGoal;
}

/// Takes a freshly signed-in [user] into the app:
///
/// * Existing account (has saved progress) → restores it and opens the app.
///   This is the "merge" path: signing up again — with Google or otherwise —
///   for an account that already exists never overwrites its progress.
/// * New account with onboarding [answers] → builds their curriculum first
///   (on [CourseSetupScreen], which handles retrying if the AI is busy).
/// * New account without answers (e.g. first-ever "Continue with Google"
///   from the login screen) → sends them through onboarding.
///
/// Returns false (after showing an error) if progress couldn't be checked,
/// e.g. no internet; the caller should stay on its screen.
Future<bool> enterApp(BuildContext context, User user, {OnboardingAnswers? answers}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final bool hasAccount;
  try {
    hasAccount = await SessionService.restore(user);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text("Couldn't reach the server. Check your connection and try again.")),
    );
    return false;
  }

  if (!hasAccount) {
    if (answers == null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingQuestionnaireScreen(alreadySignedIn: true)),
        (route) => false,
      );
      return true;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => CourseSetupScreen(answers: answers)),
      (route) => false,
    );
    return true;
  } else if (answers != null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Welcome back! This account already exists, so we kept all your progress.')),
    );
  }

  navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (route) => false);
  return true;
}

/// Plain-language messages for the Firebase Auth errors people actually hit.
String friendlyAuthError(FirebaseAuthException e) {
  return switch (e.code) {
    'invalid-email' => "That email address doesn't look right.",
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' || 'wrong-password' || 'invalid-credential' =>
      'Wrong email or password. If you signed up with Google, use "Continue with Google" instead.',
    'email-already-in-use' =>
      'An account with this email already exists. Log in instead — or use "Continue with Google" if that\'s how you signed up.',
    'weak-password' => 'Pick a stronger password (at least 8 characters).',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'network-request-failed' => 'No internet connection. Check your connection and try again.',
    'requires-recent-login' => 'For security, please confirm your identity and try again.',
    _ => e.message ?? 'Something went wrong. Try again.',
  };
}

bool isValidEmail(String email) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

/// Handles [GoogleAccountLinkRequired]: asks for the existing account's
/// password, signs in, and links Google to it so both sign-in methods open
/// the same account. Returns the signed-in user, or null if cancelled.
Future<User?> linkGoogleToExistingAccount(BuildContext context, GoogleAccountLinkRequired pending) async {
  final password = await promptForPassword(
    context,
    title: 'Link your Google account',
    message:
        '${pending.email} already has an Abante account with a password. Enter it once to link Google — after that, both ways of signing in open the same account and progress.',
    actionLabel: 'Link accounts',
  );
  if (password == null || !context.mounted) return null;
  try {
    await GoogleAuthService.linkPending(pending, password);
    return FirebaseAuth.instance.currentUser;
  } on FirebaseAuthException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyAuthError(e))));
    }
    return null;
  }
}

/// A small dialog asking for a password. Returns null if cancelled.
Future<String?> promptForPassword(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
  bool destructive = false,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      var obscured = true;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: obscured,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.transparent),
                    icon: Icon(
                      obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => obscured = !obscured),
                  ),
                ),
                onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(actionLabel, style: TextStyle(color: destructive ? AppColors.error : AppColors.primary)),
            ),
          ],
        ),
      );
    },
  );
}
