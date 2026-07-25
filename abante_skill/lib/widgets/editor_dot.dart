import 'package:flutter/material.dart';

/// A single "traffic light" dot used to dress up dark code panels like a
/// real editor window (macOS-style close/minimize/zoom dots).
class EditorDot extends StatelessWidget {
  const EditorDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
