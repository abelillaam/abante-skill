import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'push_notification_service.dart';

/// Tracks practice time against the user's onboarding daily goal, and
/// credits one streak day — with a celebratory notification — the first
/// time that goal is reached each day. Minutes-today is kept locally per
/// device; streakDays/weekCompleted live in Firestore alongside the rest
/// of the profile, matching what the Profile screen already reads.
class StreakRepository {
  StreakRepository._();

  static const _minutesKey = 'daily_minutes_count';
  static const _minutesDateKey = 'daily_minutes_date';

  static int streakDays = 0;
  static List<bool> weekCompleted = List.filled(7, false);
  static int minutesToday = 0;
  static int goalMinutes = 15;
  static String? _lastStreakDate;

  static CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _today() => _dateKey(DateTime.now());
  static String _yesterday() => _dateKey(DateTime.now().subtract(const Duration(days: 1)));

  static int _parseGoalMinutes(String? goal) {
    if (goal == null) return 15;
    final match = RegExp(r'\d+').firstMatch(goal);
    return match == null ? 15 : int.parse(match.group(0)!);
  }

  /// Loads streak state from Firestore and today's practice minutes from
  /// local storage. Breaks the streak if a whole calendar day was missed.
  static Future<void> load(User user) async {
    try {
      final data = (await _users.doc(user.uid).get()).data();
      streakDays = (data?['streakDays'] as num?)?.toInt() ?? 0;
      weekCompleted = (data?['weekCompleted'] as List<dynamic>?)?.cast<bool>() ?? List.filled(7, false);
      _lastStreakDate = data?['lastStreakDate'] as String?;
      goalMinutes = _parseGoalMinutes(data?['dailyGoal'] as String?);

      if (_lastStreakDate != null && _lastStreakDate != _today() && _lastStreakDate != _yesterday()) {
        streakDays = 0;
        await _users.doc(user.uid).set({'streakDays': 0}, SetOptions(merge: true));
      }
    } catch (_) {
      // Keep whatever is already cached in memory.
    }

    final prefs = await SharedPreferences.getInstance();
    minutesToday = prefs.getString(_minutesDateKey) == _today() ? (prefs.getInt(_minutesKey) ?? 0) : 0;
  }

  /// Adds practice minutes for today (e.g. time spent in a lesson), and
  /// credits a streak day the first time the daily goal is reached.
  static Future<void> addMinutes(User user, int minutes) async {
    if (minutes <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    if (prefs.getString(_minutesDateKey) != today) minutesToday = 0;
    minutesToday += minutes;
    await prefs.setString(_minutesDateKey, today);
    await prefs.setInt(_minutesKey, minutesToday);

    if (minutesToday < goalMinutes || _lastStreakDate == today) return;

    streakDays = _lastStreakDate == _yesterday() ? streakDays + 1 : 1;
    _lastStreakDate = today;

    final weekdayIndex = DateTime.now().weekday - 1; // Monday-first, matches UserProfile.weekCompleted
    if (weekdayIndex == 0) weekCompleted = List.filled(7, false);
    weekCompleted[weekdayIndex] = true;

    try {
      await _users.doc(user.uid).set({
        'streakDays': streakDays,
        'weekCompleted': weekCompleted,
        'lastStreakDate': _lastStreakDate,
      }, SetOptions(merge: true));
    } catch (_) {
      // Local state already updated; a sync hiccup shouldn't block the UI.
    }

    await PushNotificationService.showLocalNotification(
      title: "You hit today's goal! \u{1F525}",
      body: '$streakDays day streak — keep it going!',
    );
  }
}
