import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'animated_counter.dart';

class StreakBadge extends StatefulWidget {
  const StreakBadge({super.key, required this.days});

  final int days;

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final _glow = Tween(begin: 0.5, end: 1.0).animate(
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
      padding: const EdgeInsets.only(left: 10, right: 12, top: 7, bottom: 7),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _glow,
            child: const Icon(Icons.local_fire_department_rounded, color: AppColors.streak, size: 17),
          ),
          const SizedBox(width: 6),
          AnimatedCounter(value: widget.days, style: AppTheme.stat(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }
}

class HeartsBadge extends StatelessWidget {
  const HeartsBadge({super.key, required this.hearts, this.maxHearts = 3});

  final int hearts;
  final int maxHearts;

  @override
  Widget build(BuildContext context) {
    return _CounterPill(
      icon: Icons.favorite_rounded,
      color: AppColors.heart,
      value: hearts,
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.icon, required this.color, required this.value});

  final IconData icon;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          AnimatedCounter(value: value, style: AppTheme.stat(fontSize: 14, color: color)),
        ],
      ),
    );
  }
}
