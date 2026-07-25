import 'package:flutter/material.dart';

/// A simple translucent white circle used to scatter "bubble" decoration
/// across gradient ocean backgrounds.
class OceanBubble extends StatelessWidget {
  const OceanBubble({super.key, required this.size, this.opacity = 0.16});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
