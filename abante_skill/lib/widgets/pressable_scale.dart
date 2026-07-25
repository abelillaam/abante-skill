import 'package:flutter/material.dart';

/// Wraps [child] with a subtle scale-down on press. Uses a [Listener]
/// rather than a gesture recognizer so it never competes with the child's
/// own tap handling (buttons, InkWell, etc.) — it only observes raw pointer
/// events and animates purely for feel.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.scale = 0.96});

  final Widget child;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setDown(true),
      onPointerUp: (_) => _setDown(false),
      onPointerCancel: (_) => _setDown(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
