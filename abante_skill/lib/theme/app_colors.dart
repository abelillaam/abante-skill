import 'package:flutter/material.dart';

/// Abante's palette: soft petal pinks grounded by dusty mauve, with a sage
/// alabaster for calm "success" moments. Built from five swatches:
///
///   Alabaster Grey #D8E2DC · Powder Petal #FFE5D9 · Pastel Pink #FFCAD4
///   Cherry Blossom #F4ACB7 · Dusty Mauve #9D8189
///
/// Every role below is a getter so the whole app can flip between light and
/// dark at runtime (see `ThemeController`). Light mode leans on the petals
/// for surfaces and uses mauve for actions; dark mode inverts that, with
/// cherry blossom as the action color on deep mauve-black surfaces.
class AppColors {
  AppColors._();

  /// Set by `ThemeController`; read by every role getter below.
  static bool isDark = false;

  // Raw palette swatches.
  static const alabasterGrey = Color(0xFFD8E2DC);
  static const powderPetal = Color(0xFFFFE5D9);
  static const pastelPink = Color(0xFFFFCAD4);
  static const cherryBlossom = Color(0xFFF4ACB7);
  static const dustyMauve = Color(0xFF9D8189);

  static Color _pick(Color light, Color dark) => isDark ? dark : light;

  // Brand
  static Color get primary => _pick(dustyMauve, cherryBlossom);
  static Color get primaryDark => _pick(const Color(0xFF7A6169), dustyMauve);
  static Color get primaryLight => _pick(pastelPink, const Color(0xFF5A4450));
  static Color get accent => _pick(cherryBlossom, pastelPink);

  /// Text/icons drawn on top of [primary].
  static Color get onPrimary => _pick(Colors.white, const Color(0xFF2B2026));

  // Surfaces
  static Color get background => _pick(const Color(0xFFFFF6F2), const Color(0xFF1E171B));
  static Color get surface => _pick(Colors.white, const Color(0xFF2A2126));
  static Color get surfaceSunken => _pick(powderPetal, const Color(0xFF352A30));
  static Color get border => _pick(const Color(0xFFF3DCD6), const Color(0xFF45373E));

  // Ink surfaces (code panels, dark chips)
  static Color get ink => _pick(const Color(0xFF3B2F35), const Color(0xFF151013));
  static Color get inkRaised => _pick(const Color(0xFF4A3C43), const Color(0xFF241B20));
  static Color get inkText => powderPetal;
  static Color get inkTextDim => _pick(const Color(0xFFCDB4BB), const Color(0xFFA88E96));

  // Text
  static Color get textPrimary => _pick(const Color(0xFF3D3036), const Color(0xFFFBEAE4));
  static Color get textSecondary => _pick(const Color(0xFF8A737B), const Color(0xFFC2A9B1));

  // Status
  static Color get success => _pick(const Color(0xFF6E9C82), const Color(0xFF9CC3AC));
  static Color get successSoft => _pick(alabasterGrey, const Color(0xFF2F3A34));
  static Color get error => _pick(const Color(0xFFD9677B), const Color(0xFFF28B9C));
  static Color get streak => cherryBlossom;
  static Color get streakDeep => _pick(dustyMauve, const Color(0xFF7A6169));
  static Color get heart => _pick(const Color(0xFFE2889A), cherryBlossom);
  static Color get locked => _pick(const Color(0xFFD9CDD1), const Color(0xFF5A4B52));

  /// The soft hero gradient used behind the splash, auth headers and
  /// profile banner.
  static List<Color> get splashGradient => isDark
      ? const [Color(0xFF2E2329), Color(0xFF4A3841), dustyMauve]
      : const [powderPetal, pastelPink, cherryBlossom];

  /// Text/icons drawn on top of [splashGradient].
  static Color get onHero => _pick(const Color(0xFF3D3036), powderPetal);
}
