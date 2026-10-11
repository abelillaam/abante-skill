import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

/// Device-level preferences from the Profile screen (dark mode, sound
/// effects, notifications), persisted locally so they survive restarts.
class AppSettings {
  AppSettings._();

  static const _darkKey = 'settings_dark_mode';
  static const _soundKey = 'settings_sound_effects';
  static const _notificationsKey = 'settings_notifications';

  static bool darkMode = false;
  static bool soundEffects = true;
  static bool notifications = true;

  /// Loads saved preferences. Call once before `runApp` so the first frame
  /// already uses the right theme.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      darkMode = prefs.getBool(_darkKey) ?? false;
      soundEffects = prefs.getBool(_soundKey) ?? true;
      notifications = prefs.getBool(_notificationsKey) ?? true;
    } catch (_) {
      // Fall back to defaults.
    }
    AppColors.isDark = darkMode;
  }

  /// Switches the whole app between light and dark immediately.
  static Future<void> setDarkMode(bool value) async {
    darkMode = value;
    AppColors.isDark = value;
    _rebuildEverything();
    await _save(_darkKey, value);
  }

  static Future<void> setSoundEffects(bool value) async {
    soundEffects = value;
    await _save(_soundKey, value);
  }

  static Future<void> setNotifications(bool value) async {
    notifications = value;
    await _save(_notificationsKey, value);
  }

  static Future<void> _save(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {
      // In-memory value already applied.
    }
  }

  /// [AppColors] are plain getters, so widgets only pick up a palette change
  /// when they rebuild. Marking every element dirty repaints the whole tree
  /// with the new palette without losing any navigation or screen state.
  static void _rebuildEverything() {
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
  }
}

/// Short UI sound effects, respecting the "Sound Effects" preference.
class Sfx {
  Sfx._();

  static final _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static Future<void> correct() => _play('sounds/correct.wav', haptic: HapticFeedback.lightImpact);
  static Future<void> wrong() => _play('sounds/wrong.wav', haptic: HapticFeedback.mediumImpact);
  static Future<void> celebrate() => _play('sounds/celebrate.wav', haptic: HapticFeedback.heavyImpact);

  static Future<void> _play(String asset, {required Future<void> Function() haptic}) async {
    if (!AppSettings.soundEffects) return;
    try {
      await haptic();
      await _player.stop();
      await _player.play(AssetSource(asset), volume: 0.6);
    } catch (_) {
      // Sound is decoration; never let it break the flow.
    }
  }
}
