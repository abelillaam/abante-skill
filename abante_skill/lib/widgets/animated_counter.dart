import 'package:flutter/material.dart';

/// Animates from 0 up to [value] once, on first build. Used to give static
/// stat numbers (streaks, XP, hearts) a bit of life when a screen appears.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text('$prefix${animatedValue.round()}$suffix', style: style);
      },
    );
  }
}
