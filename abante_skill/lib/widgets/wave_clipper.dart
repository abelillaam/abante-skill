import 'package:flutter/material.dart';

/// Clips a gentle single-crest wave along the bottom edge. Used to give
/// header bands a "shoreline" silhouette instead of a plain rounded corner.
class WaveClipper extends CustomClipper<Path> {
  const WaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 32);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 18,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 36,
      size.width,
      size.height - 8,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Clips [child] into a [WaveClipper] silhouette and casts a matching
/// drop shadow, so the wave band appears to float above the page.
class WaveBand extends StatelessWidget {
  const WaveBand({super.key, required this.child, this.color = Colors.white, this.elevation = 10});

  final Widget child;
  final Color color;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return PhysicalShape(
      clipper: const WaveClipper(),
      color: color,
      elevation: elevation,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: child,
    );
  }
}
