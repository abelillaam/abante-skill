import 'package:shared_preferences/shared_preferences.dart';

/// Caps how many trivia questions can be answered per day, stored locally
/// on-device (resets automatically at midnight, per device).
class DailyQuizLimiter {
  DailyQuizLimiter._();

  static const dailyLimit = 10;

  static const _dateKey = 'trivia_quiz_date';
  static const _countKey = 'trivia_quiz_count';

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Returns how many questions have been answered today, resetting the
  /// stored count first if the stored date isn't today.
  static Future<int> getAnsweredToday() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString(_dateKey);
    if (storedDate != _todayKey()) return 0;
    return prefs.getInt(_countKey) ?? 0;
  }

  static Future<int> getRemainingToday() async {
    final answered = await getAnsweredToday();
    return (dailyLimit - answered).clamp(0, dailyLimit);
  }

  /// Records one answered question, rolling the counter over to a fresh day
  /// if needed.
  static Future<void> recordAnswer() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final alreadyToday = prefs.getString(_dateKey) == today;
    final current = alreadyToday ? (prefs.getInt(_countKey) ?? 0) : 0;
    await prefs.setString(_dateKey, today);
    await prefs.setInt(_countKey, current + 1);
  }
}
