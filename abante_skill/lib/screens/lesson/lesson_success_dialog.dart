import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

Future<void> showLessonSuccessDialog(
  BuildContext context, {
  required VoidCallback onContinue,
  int xpEarned = 0,
  bool isReview = false,
  bool heartRestored = false,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LessonSuccessDialog(
      onContinue: onContinue,
      xpEarned: xpEarned,
      isReview: isReview,
      heartRestored: heartRestored,
    ),
  );
}

class _LessonSuccessDialog extends StatelessWidget {
  const _LessonSuccessDialog({
    required this.onContinue,
    required this.xpEarned,
    required this.isReview,
    required this.heartRestored,
  });

  final VoidCallback onContinue;
  final int xpEarned;
  final bool isReview;
  final bool heartRestored;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              isReview ? 'Review Complete!' : 'Lesson Complete!',
              style: AppTheme.headline(fontSize: 22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              isReview ? 'Nice refresher — practice makes it stick.' : "Great work — you're one step closer to your goal.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isReview)
                  _StatChip(
                    icon: Icons.favorite_rounded,
                    label: heartRestored ? '+1 Heart' : 'Hearts full',
                    color: AppColors.heart,
                  )
                else ...[
                  _StatChip(icon: Icons.bolt_rounded, label: '+$xpEarned XP', color: AppColors.primary),
                  const SizedBox(width: 12),
                  _StatChip(icon: Icons.check_circle_rounded, label: '+1 Lesson', color: AppColors.success),
                ],
              ],
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.stat(fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
