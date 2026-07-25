import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/badges.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/wave_clipper.dart';
import '../lesson/lesson_overview_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Lesson? activeLesson;
    for (final unit in mockUnits) {
      for (final lesson in unit.lessons) {
        if (lesson.status == LessonStatus.active) {
          activeLesson = lesson;
          break;
        }
      }
      if (activeLesson != null) break;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _DashboardHeader(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  if (activeLesson != null) _ContinueLearningCard(lesson: activeLesson),
                  for (final unit in mockUnits) ...[
                    _UnitBanner(unit: unit),
                    const SizedBox(height: 12),
                    for (final lesson in unit.lessons) _LessonListCard(lesson: lesson),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final progress = lesson.totalModules == 0 ? 0.0 : lesson.completedModules / lesson.totalModules;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: PressableScale(
        child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => showLessonOverviewSheet(context, lesson),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.07), blurRadius: 22, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: progress == 0 ? 1 : progress,
                          strokeWidth: 3,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      Icon(lesson.icon, color: AppColors.primary, size: 24),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTINUE LEARNING',
                        style: AppTheme.stat(
                          fontSize: 11,
                          color: AppColors.primary,
                          weight: FontWeight.w700,
                        ).copyWith(letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.headline(fontSize: 16, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lesson.completedModules}/${lesson.totalModules} modules · keep going!',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return WaveBand(
      color: AppColors.surface,
      elevation: 6,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
        color: AppColors.surface,
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, Adrianne',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Python track · Beginner',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const StreakBadge(days: 4),
                const SizedBox(width: 8),
                const HeartsBadge(hearts: 3),
              ],
            ),
            const SizedBox(height: 16),
            const _DailyGoalBar(minutesDone: 6, minutesGoal: 15),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalBar extends StatelessWidget {
  const _DailyGoalBar({required this.minutesDone, required this.minutesGoal});

  final int minutesDone;
  final int minutesGoal;

  @override
  Widget build(BuildContext context) {
    final progress = (minutesDone / minutesGoal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.track_changes_rounded, size: 15, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Daily goal',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
              ],
            ),
            AnimatedCounter(
              value: minutesDone,
              suffix: '/$minutesGoal min',
              style: AppTheme.stat(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ],
    );
  }
}

class _UnitBanner extends StatelessWidget {
  const _UnitBanner({required this.unit});

  final LessonUnit unit;

  @override
  Widget build(BuildContext context) {
    final locked = unit.isLocked;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: locked
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
        color: locked ? AppColors.surface : null,
        borderRadius: BorderRadius.circular(20),
        border: locked ? Border.all(color: AppColors.border) : null,
        boxShadow: locked
            ? null
            : [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8)),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.subtitle.toUpperCase(),
                  style: TextStyle(
                    color: locked ? AppColors.textSecondary : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unit.title,
                  style: AppTheme.headline(
                    color: locked ? AppColors.textSecondary : Colors.white,
                    fontSize: 19,
                    weight: FontWeight.w800,
                  ),
                ),
                if (locked) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Finish the unit above to unlock',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: locked ? AppColors.background : Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              locked ? Icons.lock_rounded : unit.icon,
              color: locked ? AppColors.locked : Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonListCard extends StatelessWidget {
  const _LessonListCard({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final isLocked = lesson.status == LessonStatus.locked;
    final isActive = lesson.status == LessonStatus.active;
    final isCompleted = lesson.status == LessonStatus.completed;

    final iconBg = switch (lesson.status) {
      LessonStatus.completed => AppColors.success,
      LessonStatus.active => AppColors.primary,
      LessonStatus.locked => AppColors.background,
    };
    final iconColor = isLocked ? AppColors.locked : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: PressableScale(
        child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isLocked ? null : () => showLessonOverviewSheet(context, lesson),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: isActive ? Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5) : null,
              boxShadow: isLocked
                  ? null
                  : [
                      BoxShadow(
                        color: (isActive ? AppColors.primary : AppColors.textPrimary)
                            .withValues(alpha: isActive ? 0.14 : 0.05),
                        blurRadius: isActive ? 20 : 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                  child: Icon(isLocked ? Icons.lock_rounded : lesson.icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: AppTheme.headline(
                          fontSize: 15,
                          weight: FontWeight.w700,
                          color: isLocked ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lesson.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: lesson.totalModules == 0 ? 0 : lesson.completedModules / lesson.totalModules,
                            minHeight: 6,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isCompleted)
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22)
                else if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                      'Start',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  )
                else
                  const Icon(Icons.lock_outline_rounded, color: AppColors.locked, size: 20),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
