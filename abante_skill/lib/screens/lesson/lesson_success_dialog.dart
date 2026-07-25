import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

Future<void> showLessonSuccessDialog(BuildContext context, {required VoidCallback onContinue}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LessonSuccessDialog(onContinue: onContinue),
  );
}

class _LessonSuccessDialog extends StatelessWidget {
  const _LessonSuccessDialog({required this.onContinue});

  final VoidCallback onContinue;

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
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Lesson Complete!',
              style: AppTheme.headline(fontSize: 22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              "Great work — you're one step closer to your goal.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(icon: Icons.bolt_rounded, label: '+10 XP', color: AppColors.primary),
                const SizedBox(width: 12),
                _StatChip(icon: Icons.local_fire_department_rounded, label: 'Streak +1', color: AppColors.streak),
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
