import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/curriculum_repository.dart';
import '../../services/curriculum_service.dart';
import '../../services/google_auth_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/user_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/google_button.dart';
import '../../widgets/ocean_bubbles.dart';
import '../../widgets/pressable_scale.dart';
import '../main_shell.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    this.onboardingTrack,
    this.onboardingLevel,
    this.onboardingDailyGoal,
  });

  /// Answers from the onboarding questionnaire, if the user came from there.
  /// Null when reached directly (e.g. via the "Sign up" link on Login).
  final String? onboardingTrack;
  final String? onboardingLevel;
  final String? onboardingDailyGoal;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isGeneratingCurriculum = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _finishSignUp() async {
    final track = widget.onboardingTrack;
    final level = widget.onboardingLevel;
    final dailyGoal = widget.onboardingDailyGoal;
    final user = FirebaseAuth.instance.currentUser;

    if (track != null && level != null && dailyGoal != null) {
      setState(() => _isGeneratingCurriculum = true);
      CurriculumRepository.units = await CurriculumService.generate(
        track: track,
        level: level,
        dailyGoal: dailyGoal,
      );
      CurriculumRepository.level = level;
      if (!mounted) return;
      setState(() => _isGeneratingCurriculum = false);
    }

    if (user != null) {
      try {
        await UserRepository.saveUser(
          user: user,
          track: track,
          level: level,
          dailyGoal: dailyGoal,
          curriculum: CurriculumRepository.units,
        );
      } catch (_) {
        // Don't block the user from reaching the app over a Firestore hiccup;
        // their auth account already exists either way.
      }
      unawaited(PushNotificationService.saveTokenIfSignedIn());
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  Future<void> _createAccount() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) await _finishSignUp();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not create account. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await GoogleAuthService.signIn();
      if (mounted) await _finishSignUp();
    } on GoogleSignInException catch (e) {
      if (!mounted || e.code == GoogleSignInExceptionCode.canceled) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${e.description ?? e.code}')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not sign in with Google. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AuthScaffold(
          title: "You're almost in!",
          subtitle: 'Create an account to save your progress.',
          child: _buildForm(),
        ),
        if (_isGeneratingCurriculum) const Positioned.fill(child: _CurriculumGeneratingOverlay()),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            controller: _emailController,
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Password',
            hint: 'At least 8 characters',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            controller: _passwordController,
          ),
          const SizedBox(height: 24),
          PressableScale(
            child: FilledButton(
              onPressed: _isLoading ? null : _createAccount,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Account'),
            ),
          ),
          const SizedBox(height: 20),
          const _OrDivider(),
          const SizedBox(height: 20),
          GoogleSignInButton(onPressed: _signUpWithGoogle, isLoading: _isGoogleLoading),
          const SizedBox(height: 28),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  children: [
                    TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Log in',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CurriculumGeneratingOverlay extends StatelessWidget {
  const _CurriculumGeneratingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.splashGradient,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(top: 70, left: -24, child: OceanBubble(size: 70, opacity: 0.1)),
          const Positioned(top: 160, right: -16, child: OceanBubble(size: 44, opacity: 0.12)),
          const Positioned(bottom: 140, left: 32, child: OceanBubble(size: 26, opacity: 0.14)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AbanteMark(size: 84),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'Building your curriculum',
                  style: AppTheme.headline(fontSize: 19, weight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Personalizing lessons just for you',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
