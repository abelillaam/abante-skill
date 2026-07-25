import 'package:flutter/material.dart';

/// Abante's palette: a colorful coral-reef ocean — vivid turquoise, coral,
/// and sandy accents against clean white surfaces. Multi-hue on purpose:
/// this is meant to read as a lively sea, not a single corporate blue.
class AppColors {
  AppColors._();

  // Brand — ocean blues
  static const primary = Color(0xFF00A3C4);
  static const primaryDark = Color(0xFF0B4F79);
  static const primaryLight = Color(0xFFB6EFF5);
  static const accent = Color(0xFF00D1B2);

  // Reef accents — the "colorful" part of the palette
  static const coral = Color(0xFFFF6F5E);
  static const coralDeep = Color(0xFFE24A3B);
  static const sunsetPink = Color(0xFFFF8FA3);
  static const sandy = Color(0xFFFFB648);
  static const sandyDeep = Color(0xFFE58A1F);
  static const seafoam = Color(0xFF2ED9A3);

  // Surfaces
  static const background = Color(0xFFF2FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFE3F6F5);
  static const border = Color(0xFFD9EFF3);

  // Ink surfaces (code panels, dark chips)
  static const ink = Color(0xFF042634);
  static const inkRaised = Color(0xFF0B3A49);
  static const inkText = Color(0xFFE1F7F3);
  static const inkTextDim = Color(0xFF7FAEB8);

  // Text
  static const textPrimary = Color(0xFF0B2836);
  static const textSecondary = Color(0xFF5B7A85);

  // Status
  static const success = seafoam;
  static const error = coralDeep;
  static const streak = sandy;
  static const streakDeep = sandyDeep;
  static const heart = coral;
  static const locked = Color(0xFFC7DEE3);

  static const splashGradient = [primaryDark, primary, accent];
}
