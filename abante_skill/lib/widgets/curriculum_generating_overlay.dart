import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'brand_mark.dart';
import 'ocean_bubbles.dart';

/// Full-screen "building your curriculum" state shown while the AI
/// generates a new user's lessons.
class CurriculumGeneratingOverlay extends StatelessWidget {
  const CurriculumGeneratingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.splashGradient,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: 70, left: -24, child: OceanBubble(size: 70, opacity: 0.25)),
            const Positioned(top: 160, right: -16, child: OceanBubble(size: 44, opacity: 0.3)),
            const Positioned(bottom: 140, left: 32, child: OceanBubble(size: 26, opacity: 0.35)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AbanteMark(size: 96),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onHero),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Building your curriculum',
                    style: AppTheme.headline(fontSize: 19, weight: FontWeight.w800, color: AppColors.onHero),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personalizing lessons just for you',
                    style: TextStyle(color: AppColors.onHero.withValues(alpha: 0.75), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
