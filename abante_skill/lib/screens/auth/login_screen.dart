import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/google_button.dart';
import '../../widgets/pressable_scale.dart';
import '../main_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Log in to keep your streak going.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppTextField(
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 18),
          const AppTextField(
            label: 'Password',
            hint: 'Enter your password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          PressableScale(
            child: FilledButton(
              onPressed: () => _goToDashboard(context),
              child: const Text('Log In'),
            ),
          ),
          const SizedBox(height: 20),
          const _OrDivider(),
          const SizedBox(height: 20),
          GoogleSignInButton(onPressed: () => _goToDashboard(context)),
          const SizedBox(height: 28),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  children: [
                    TextSpan(text: "Don't have an account? "),
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
