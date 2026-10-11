import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Round avatar: the user's uploaded photo if they have one, otherwise
/// their initial on a mauve circle.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.initial, this.photoBase64, this.radius = 22});

  final String initial;
  final String? photoBase64;
  final double radius;

  static final _cache = <String, Uint8List>{};

  Uint8List? get _bytes {
    final data = photoBase64;
    if (data == null || data.isEmpty) return null;
    try {
      return _cache.putIfAbsent(data, () => base64Decode(data));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      child: bytes != null
          ? null
          : Text(
              initial,
              style: TextStyle(color: AppColors.onPrimary, fontSize: radius * 0.75, fontWeight: FontWeight.w800),
            ),
    );
  }
}
