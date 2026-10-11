import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/google_auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/google_button.dart';
import '../../widgets/pressable_scale.dart';
import 'auth_flow.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.onboardingTrack, this.onboardingLevel, this.onboardingDailyGoal});

  /// Answers from the onboarding questionnaire, if the user came from there.
  /// Null when reached directly (e.g. via the "Sign up" link on Login).
  final String? onboardingTrack;
  final String? onboardingLevel;
  final String? onboardingDailyGoal;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const _minPasswordLength = 8;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _emailError;
  String? _passwordError;

  OnboardingAnswers? get _answers {
    final track = widget.onboardingTrack;
    final level = widget.onboardingLevel;
    final dailyGoal = widget.onboardingDailyGoal;
    if (track == null || level == null || dailyGoal == null) return null;
    return OnboardingAnswers(track: track, level: level, dailyGoal: dailyGoal);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _emailError = email.isEmpty
          ? 'Enter your email'
          : (isValidEmail(email) ? null : "That email address doesn't look right");
      _passwordError = password.length < _minPasswordLength
          ? 'Use at least $_minPasswordLength characters'
          : (RegExp(r'[A-Za-z]').hasMatch(password) && RegExp(r'\d').hasMatch(password)
                ? null
                : 'Mix letters and numbers');
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _enter(User user) async {
    await enterApp(context, user, answers: _answers);
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // A verified email lets Firebase safely *link* a later Google sign-in
      // to this account instead of replacing the password sign-in.
      result.user?.sendEmailVerification().catchError((_) {});
      if (mounted) await _enter(result.user!);
    } on FirebaseAuthException catch (e) {
      _showMessage(friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      User? user;
      try {
        user = (await GoogleAuthService.signIn()).user;
      } on GoogleAccountLinkRequired catch (pending) {
        if (!mounted) return;
        user = await linkGoogleToExistingAccount(context, pending);
      }
      // If this Google account already has Abante progress, enterApp keeps
      // it (and says so) rather than building a new curriculum over it.
      if (user != null && mounted) await _enter(user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      _showMessage('Google sign-in failed: ${e.description ?? e.code}');
    } on FirebaseAuthException catch (e) {
      _showMessage(friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "You're almost in!",
      subtitle: 'Create an account to save your progress.',
      child: _buildForm(),
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
          errorText: _emailError,
        ),
        const SizedBox(height: 18),
        AppTextField(
          label: 'Password',
          hint: 'At least $_minPasswordLength characters',
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
          controller: _passwordController,
          errorText: _passwordError,
          onSubmitted: (_) => _createAccount(),
        ),
        const SizedBox(height: 24),
        PressableScale(
          child: FilledButton(
            onPressed: _isLoading ? null : _createAccount,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : const Text('Create Account'),
          ),
        ),
        const SizedBox(height: 20),
        const OrDivider(),
        const SizedBox(height: 20),
        GoogleSignInButton(onPressed: _signUpWithGoogle, isLoading: _isGoogleLoading),
        const SizedBox(height: 10),
        Text(
          'Already have an account with this Google email? Your progress carries over.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                children: [
                  const TextSpan(text: 'Already have an account? '),
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
