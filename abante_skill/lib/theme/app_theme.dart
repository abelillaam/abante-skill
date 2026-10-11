import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// Sora carries headlines and anything that should feel like a confident
  /// masthead. Inter (the base [ThemeData.textTheme]) carries body copy.
  static TextStyle headline({
    double fontSize = 24,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double height = 1.15,
  }) {
    return GoogleFonts.sora(
      fontSize: fontSize,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// JetBrains Mono for anything code-shaped — snippets, consoles.
  static TextStyle code({
    double fontSize = 14,
    Color? color,
    FontWeight weight = FontWeight.w500,
    double height = 1.6,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      color: color ?? AppColors.inkText,
      fontWeight: weight,
      height: height,
    );
  }

  /// JetBrains Mono for numerals — streaks, XP, hearts, stat tiles. Ties the
  /// "coding app" idea into the UI's typography instead of a mascot.
  static TextStyle stat({
    double fontSize = 15,
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) {
    return GoogleFonts.jetBrainsMono(fontSize: fontSize, color: color ?? AppColors.textPrimary, fontWeight: weight);
  }

  /// Builds the theme for the current [AppColors.isDark] mode.
  static ThemeData build() {
    final brightness = AppColors.isDark ? Brightness.dark : Brightness.light;
    final textTheme = GoogleFonts.interTextTheme(ThemeData(brightness: brightness).textTheme).copyWith(
      headlineLarge: GoogleFonts.sora(fontSize: 30, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SoftFadeTransitionsBuilder(),
          TargetPlatform.iOS: _SoftFadeTransitionsBuilder(),
          TargetPlatform.windows: _SoftFadeTransitionsBuilder(),
          TargetPlatform.macOS: _SoftFadeTransitionsBuilder(),
          TargetPlatform.linux: _SoftFadeTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(10),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: TextStyle(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        contentTextStyle: GoogleFonts.inter(fontSize: 14.5, height: 1.45, color: AppColors.textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.inkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.primary),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        textStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accent.withValues(alpha: AppColors.isDark ? 0.22 : 0.35),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.primary : AppColors.textSecondary);
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.isDark ? AppColors.surface : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColors.primary : AppColors.border;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}

class _SoftFadeTransitionsBuilder extends PageTransitionsBuilder {
  const _SoftFadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
