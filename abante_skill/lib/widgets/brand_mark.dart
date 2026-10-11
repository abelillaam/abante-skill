import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Abante's logo — the smiling "growth" arrow rising past two bars — on its
/// powder-petal tile, gently floating with a soft cherry-blossom glow.
class AbanteMark extends StatefulWidget {
  const AbanteMark({super.key, this.size = 128, this.animate = true});

  final double size;
  final bool animate;

  @override
  State<AbanteMark> createState() => _AbanteMarkState();
}

class _AbanteMarkState extends State<AbanteMark> with SingleTickerProviderStateMixin {
  late final _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  late final _float = Tween(begin: -5.0, end: 5.0).animate(
    CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final logo = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(s * 0.23),
        boxShadow: [
          BoxShadow(
            color: AppColors.dustyMauve.withValues(alpha: 0.28),
            blurRadius: s * 0.22,
            offset: Offset(0, s * 0.1),
          ),
        ],
      ),
      child: Image.asset('assets/images/logo.png', width: s, height: s, filterQuality: FilterQuality.medium),
    );

    return SizedBox(
      width: s * 1.4,
      height: s * 1.4,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Soft glow behind the tile.
          Container(
            width: s * 1.4,
            height: s * 1.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.cherryBlossom.withValues(alpha: 0.45),
                  AppColors.cherryBlossom.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          if (widget.animate)
            AnimatedBuilder(
              animation: _float,
              builder: (context, child) => Transform.translate(offset: Offset(0, _float.value), child: child),
              child: logo,
            )
          else
            logo,
        ],
      ),
    );
  }
}

/// The logo artwork alone (transparent background) for small inline uses
/// like app bars and headers.
class AbanteGlyph extends StatelessWidget {
  const AbanteGlyph({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/logo_mark.png', width: size, height: size, filterQuality: FilterQuality.medium);
  }
}
