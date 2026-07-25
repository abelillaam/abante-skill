import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Abante's mark: a terminal prompt caught mid-line, rising out of a sunrise
/// gradient. It reads as "forward" (the chevron) and "code" (the prompt +
/// blinking cursor) at once — an original glyph rather than a borrowed
/// mascot silhouette.
class AbanteMark extends StatefulWidget {
  const AbanteMark({super.key, this.size = 128});

  final double size;

  @override
  State<AbanteMark> createState() => _AbanteMarkState();
}

class _AbanteMarkState extends State<AbanteMark> with TickerProviderStateMixin {
  late final _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final _float = Tween(begin: -5.0, end: 5.0).animate(
    CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
  );

  late final _cursorController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _floatController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.5,
      height: s * 1.5,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Soft halo — the "sunrise" glow behind the mark.
          Container(
            width: s * 1.4,
            height: s * 1.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.streak.withValues(alpha: 0.30),
                  AppColors.streak.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _float,
            builder: (context, child) => Transform.translate(offset: Offset(0, _float.value), child: child),
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.splashGradient,
                ),
                borderRadius: BorderRadius.circular(s * 0.3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('>', style: AppTheme.code(fontSize: s * 0.42, color: Colors.white, weight: FontWeight.w700)),
                    SizedBox(width: s * 0.05),
                    FadeTransition(
                      opacity: _cursorController,
                      child: Container(
                        width: s * 0.1,
                        height: s * 0.34,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
