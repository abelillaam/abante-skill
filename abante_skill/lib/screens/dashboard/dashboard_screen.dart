import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../models/user_profile.dart';
import '../../services/curriculum_repository.dart';
import '../../services/hearts_repository.dart';
import '../../services/session_service.dart';
import '../../services/streak_repository.dart';
import '../../services/user_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/badges.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/wave_clipper.dart';
import '../lesson/lesson_overview_sheet.dart';
import '../onboarding/onboarding_questionnaire_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    SessionService.refreshTick.addListener(_loadStats);
    _loadStats();
  }

  @override
  void dispose() {
    SessionService.refreshTick.removeListener(_loadStats);
    super.dispose();
  }

  Future<void> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final results = await Future.wait([
      UserRepository.loadProfile(user),
      HeartsRepository.load(user),
      StreakRepository.load(user),
    ]);
    if (!mounted) return;
    setState(() => _profile = results.first as UserProfile? ?? _profile);
  }

  /// For accounts that were left with the built-in sample course: confirm,
  /// then re-ask their preferences and build the real one.
  Future<void> _rebuildCourse() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Build your own course?'),
        content: const Text(
          "We'll ask your preferences again and build a course just for you. "
          'It replaces this sample course and its lesson progress — your XP, streak and hearts stay.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Not now')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Build my course')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OnboardingQuestionnaireScreen(alreadySignedIn: true)));
    if (mounted) setState(() {});
  }

  /// The unit holding the user's next lesson (not just the first unit).
  String? _currentUnitTitle(List<LessonUnit> units) {
    for (final unit in units) {
      if (unit.lessons.any((l) => l.status != LessonStatus.completed)) return unit.title;
    }
    return units.isEmpty ? null : 'All units complete!';
  }

  /// Opens a lesson and refreshes once the whole lesson flow (overview
  /// sheet + briefing + workspace) is done, since this screen stays mounted
  /// under the bottom nav and won't otherwise pick up completed/unlocked
  /// lessons, spent hearts, or practice time on its own.
  Future<void> _openLesson(Lesson lesson) async {
    await showLessonOverviewSheet(context, lesson);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final units = CurriculumRepository.units;
    Lesson? activeLesson;
    for (final unit in units) {
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
            ValueListenableBuilder<int>(
              // Updates live as practice time is counted.
              valueListenable: StreakRepository.secondsToday,
              builder: (context, seconds, _) => _DashboardHeader(
                profile: _profile,
                currentUnitTitle: _currentUnitTitle(units),
                hearts: HeartsRepository.hearts,
                streakDays: StreakRepository.streakDays,
                minutesDone: seconds ~/ 60,
                minutesGoal: StreakRepository.goalMinutes,
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  if (CurriculumRepository.isSampleCourse) _SampleCourseBanner(onBuild: _rebuildCourse),
                  if (activeLesson != null) _ContinueLearningCard(lesson: activeLesson, onTap: _openLesson),
                  for (final unit in units) ...[
                    _UnitBanner(unit: unit),
                    const SizedBox(height: 12),
                    for (final lesson in unit.lessons) _LessonListCard(lesson: lesson, onTap: _openLesson),
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
  const _ContinueLearningCard({required this.lesson, required this.onTap});

  final Lesson lesson;
  final ValueChanged<Lesson> onTap;

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
            onTap: () => onTap(lesson),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.07),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
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
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
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
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Icon(Icons.arrow_forward_rounded, color: AppColors.onPrimary, size: 20),
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
  const _DashboardHeader({
    this.profile,
    this.currentUnitTitle,
    required this.hearts,
    required this.streakDays,
    required this.minutesDone,
    required this.minutesGoal,
  });

  final UserProfile? profile;
  final String? currentUnitTitle;
  final int hearts;
  final int streakDays;
  final int minutesDone;
  final int minutesGoal;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fallbackName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'there');
    final displayName = profile?.name.trim().isNotEmpty == true ? profile!.name.trim() : fallbackName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

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
                ProfileAvatar(initial: initial, photoBase64: profile?.photoBase64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $displayName',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        currentUnitTitle ?? 'Ready to start learning',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                StreakBadge(days: streakDays),
                const SizedBox(width: 8),
                HeartsBadge(hearts: hearts),
              ],
            ),
            const SizedBox(height: 16),
            _DailyGoalBar(minutesDone: minutesDone, minutesGoal: minutesGoal),
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
    final progress = minutesGoal <= 0 ? 0.0 : (minutesDone / minutesGoal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes_rounded, size: 15, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Daily goal',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
              ],
            ),
            AnimatedCounter(value: minutesDone, suffix: '/$minutesGoal min', style: AppTheme.stat(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
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
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
        color: locked ? AppColors.surface : null,
        borderRadius: BorderRadius.circular(20),
        border: locked ? Border.all(color: AppColors.border) : null,
        boxShadow: locked
            ? null
            : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8))],
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
                    color: locked ? AppColors.textSecondary : AppColors.onPrimary.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unit.title,
                  style: AppTheme.headline(
                    color: locked ? AppColors.textSecondary : AppColors.onPrimary,
                    fontSize: 19,
                    weight: FontWeight.w800,
                  ),
                ),
                if (locked) ...[
                  const SizedBox(height: 4),
                  Text(
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
              color: locked ? AppColors.background : AppColors.onPrimary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              locked ? Icons.lock_rounded : unit.icon,
              color: locked ? AppColors.locked : AppColors.onPrimary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonListCard extends StatelessWidget {
  const _LessonListCard({required this.lesson, required this.onTap});

  final Lesson lesson;
  final ValueChanged<Lesson> onTap;

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
    final iconColor = isLocked ? AppColors.locked : AppColors.onPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: PressableScale(
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isLocked ? null : () => onTap(lesson),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: isActive ? Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5) : null,
                boxShadow: isLocked
                    ? null
                    : [
                        BoxShadow(
                          color: (isActive ? AppColors.primary : AppColors.textPrimary).withValues(
                            alpha: isActive ? 0.14 : 0.05,
                          ),
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
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: lesson.totalModules == 0 ? 0 : lesson.completedModules / lesson.totalModules,
                              minHeight: 6,
                              backgroundColor: AppColors.background,
                              valueColor: AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCompleted)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                        Text(
                          'Review',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success),
                        ),
                      ],
                    )
                  else if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        'Start',
                        style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    )
                  else
                    Icon(Icons.lock_outline_rounded, color: AppColors.locked, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the account still has the generic sample course (older app
/// versions saved it if the AI failed during sign-up).
class _SampleCourseBanner extends StatelessWidget {
  const _SampleCourseBanner({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('This is a sample course', style: AppTheme.headline(fontSize: 16, weight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Your personalized course didn't finish building when you signed up. "
            'Build it now to get lessons picked for your goals and level.',
            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              onPressed: onBuild,
              child: const Text('Build my course'),
            ),
          ),
        ],
      ),
    );
  }
}
