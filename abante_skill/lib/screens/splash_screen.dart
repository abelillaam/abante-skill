import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/ocean_bubbles.dart';
import '../widgets/pressable_scale.dart';
import 'onboarding/onboarding_questionnaire_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.splashGradient,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: 60, left: -30, child: OceanBubble(size: 90, opacity: 0.08)),
            const Positioned(top: 140, right: -20, child: OceanBubble(size: 56, opacity: 0.1)),
            const Positioned(bottom: 220, right: 40, child: OceanBubble(size: 34, opacity: 0.12)),
            const Positioned(bottom: 120, left: 24, child: OceanBubble(size: 22, opacity: 0.14)),
            SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 4),
                    const AbanteMark(),
                    const SizedBox(height: 32),
                    Text(
                      'Abante',
                      style: AppTheme.headline(
                        fontSize: 34,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build skills that move you forward',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const Spacer(flex: 5),
                    PressableScale(
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OnboardingQuestionnaireScreen()),
                            );
                          },
                          child: const Text('Get Started'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    PressableScale(
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text('I Already Have an Account'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}
