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
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _emailError;
  String? _passwordError;

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
    setState(() {
      _emailError = email.isEmpty
          ? 'Enter your email'
          : (isValidEmail(email) ? null : "That email address doesn't look right");
      _passwordError = _passwordController.text.isEmpty ? 'Enter your password' : null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) await enterApp(context, result.user!);
    } on FirebaseAuthException catch (e) {
      _showMessage(friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      User? user;
      try {
        user = (await GoogleAuthService.signIn()).user;
      } on GoogleAccountLinkRequired catch (pending) {
        if (!mounted) return;
        user = await linkGoogleToExistingAccount(context, pending);
      }
      if (user != null && mounted) await enterApp(context, user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      _showMessage('Google sign-in failed: ${e.description ?? e.code}');
    } on FirebaseAuthException catch (e) {
      _showMessage(friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Reset your password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your account's email and we'll send you a link to set a new password."),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.textSecondary),
              ),
              onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    if (!isValidEmail(email)) {
      _showMessage("That email address doesn't look right.");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      // Same message whether or not the account exists, so this can't be
      // used to discover who has an account.
      _showMessage('If an account exists for $email, a reset link is on its way. Check your inbox (and spam).');
    } on FirebaseAuthException catch (e) {
      _showMessage(friendlyAuthError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Log in to keep your streak going.',
      child: Column(
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
            hint: 'Enter your password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            controller: _passwordController,
            errorText: _passwordError,
            onSubmitted: (_) => _login(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          PressableScale(
            child: FilledButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : const Text('Log In'),
            ),
          ),
          const SizedBox(height: 20),
          const OrDivider(),
          const SizedBox(height: 20),
          GoogleSignInButton(onPressed: _loginWithGoogle, isLoading: _isGoogleLoading),
          const SizedBox(height: 28),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: 'Sign up',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "—— or ——" separator between email and Google sign-in.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
