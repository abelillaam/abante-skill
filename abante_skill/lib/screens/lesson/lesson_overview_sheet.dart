import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pressable_scale.dart';
import 'concept_briefing_screen.dart';

Future<void> showLessonOverviewSheet(BuildContext context, Lesson lesson) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _LessonOverviewSheet(lesson: lesson),
  );
}

class _LessonOverviewSheet extends StatelessWidget {
  const _LessonOverviewSheet({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final progress = lesson.totalModules == 0 ? 0.0 : lesson.completedModules / lesson.totalModules;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.12), blurRadius: 32, offset: const Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: Icon(lesson.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              lesson.title,
              style: AppTheme.headline(fontSize: 22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.summary,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  '${lesson.completedModules}/${lesson.totalModules} Modules Completed',
                  style: AppTheme.stat(fontSize: 12, color: AppColors.textSecondary, weight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.success),
              ),
            ),
            const SizedBox(height: 24),
            PressableScale(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ConceptBriefingScreen(lesson: lesson)),
                  );
                },
                child: const Text('Start Lesson'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
