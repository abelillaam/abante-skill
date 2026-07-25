import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'animated_counter.dart';

const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class StreakCard extends StatefulWidget {
  const StreakCard({super.key, required this.days, required this.weekCompleted, this.todayIndex = 3});

  final int days;

  /// 7 booleans, Monday first, marking which days this week hit their goal.
  final List<bool> weekCompleted;
  final int todayIndex;

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final _scale = Tween(begin: 1.0, end: 1.12).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );
  late final _wobble = Tween(begin: -0.04, end: 0.04).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.streak, AppColors.streakDeep],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.streak.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScaleTransition(
                scale: _scale,
                child: RotationTransition(
                  turns: _wobble,
                  child: const Text('🔥', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedCounter(
                    value: widget.days,
                    duration: const Duration(milliseconds: 1200),
                    style: AppTheme.stat(fontSize: 32, color: Colors.white, weight: FontWeight.w800),
                  ),
                  Text(
                    'day streak',
                    style: AppTheme.headline(fontSize: 13, weight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'On fire!',
                  style: AppTheme.headline(fontSize: 11, weight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final done = widget.weekCompleted[i];
              final isToday = i == widget.todayIndex;
              return Column(
                children: [
                  Text(
                    _dayLetters[i],
                    style: AppTheme.headline(fontSize: 11, weight: FontWeight.w700, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? Colors.white : Colors.white.withValues(alpha: 0.18),
                      border: isToday ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: done
                        ? const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.streakDeep)
                        : null,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
