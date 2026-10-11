import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/ocean_bubbles.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/update_dialog.dart';
import 'auth/login_screen.dart';
import 'onboarding/onboarding_questionnaire_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onHero = AppColors.onHero;
    return UpdateCheck(
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.splashGradient,
            ),
          ),
          child: Stack(
            children: [
              const Positioned(top: 60, left: -30, child: OceanBubble(size: 90, opacity: 0.3)),
              const Positioned(top: 140, right: -20, child: OceanBubble(size: 56, opacity: 0.35)),
              const Positioned(bottom: 220, right: 40, child: OceanBubble(size: 34, opacity: 0.4)),
              const Positioned(bottom: 120, left: 24, child: OceanBubble(size: 22, opacity: 0.45)),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                      child: Column(
                        children: [
                          const Spacer(flex: 4),
                          const AbanteMark(size: 132),
                          const SizedBox(height: 24),
                          Text(
                            'Abante',
                            style: AppTheme.headline(
                              fontSize: 38,
                              weight: FontWeight.w800,
                              color: onHero,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Build skills that move you forward',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: onHero.withValues(alpha: 0.75)),
                          ),
                          const Spacer(flex: 5),
                          PressableScale(
                            child: SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).push(MaterialPageRoute(builder: (_) => const OnboardingQuestionnaireScreen()));
                                },
                                child: const Text('Get Started'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          PressableScale(
                            child: SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: onHero,
                                  backgroundColor: Colors.white.withValues(alpha: AppColors.isDark ? 0.06 : 0.35),
                                  side: BorderSide(color: onHero.withValues(alpha: 0.35), width: 1.5),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
      ),
    );
  }
}
