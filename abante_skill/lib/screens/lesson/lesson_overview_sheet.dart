import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../services/hearts_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pressable_scale.dart';
import 'concept_briefing_screen.dart';
import 'out_of_hearts_screen.dart';

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

  bool get _isReview => lesson.status == LessonStatus.completed;

  /// New lessons cost hearts on wrong answers, so they need at least one.
  /// Reviews of finished lessons are always open — they're how you earn
  /// hearts back.
  Future<void> _start(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    final user = FirebaseAuth.instance.currentUser;
    if (!_isReview && user != null) {
      await HeartsRepository.load(user);
      if (HeartsRepository.hearts <= 0) {
        await navigator.push(
          MaterialPageRoute(builder: (_) => OutOfHeartsScreen(nextHeartIn: HeartsRepository.timeUntilNextHeart())),
        );
        return;
      }
    }
    await navigator.push(MaterialPageRoute(builder: (_) => ConceptBriefingScreen(lesson: lesson)));
  }

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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: Icon(lesson.icon, color: AppColors.onPrimary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              lesson.title,
              style: AppTheme.headline(fontSize: 22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.summary,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
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
                valueColor: AlwaysStoppedAnimation(AppColors.success),
              ),
            ),
            if (_isReview) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, size: 18, color: AppColors.heart),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Review mode: no hearts lost, and passing earns one back.',
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            PressableScale(
              child: FilledButton(
                onPressed: () => _start(context),
                child: Text(_isReview ? 'Review Lesson' : 'Start Lesson'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
