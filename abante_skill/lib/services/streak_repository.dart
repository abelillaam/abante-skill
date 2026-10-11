import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'push_notification_service.dart';

/// Tracks practice time against the user's onboarding daily goal, and
/// credits one streak day — with a celebratory notification — the first
/// time that goal is reached each day.
///
/// Practice time is counted in seconds (see `PracticeTimeTracker`), kept
/// per account — on this device for instant updates and in the user's
/// Firestore doc (`practiceToday`) so it follows them across devices and
/// never mixes between accounts on a shared phone.
class StreakRepository {
  StreakRepository._();

  /// How often counted time is also written to Firestore (it's saved on the
  /// device on every update regardless).
  static const _remoteSyncInterval = Duration(seconds: 60);

  static int streakDays = 0;
  static List<bool> weekCompleted = List.filled(7, false);
  static int goalMinutes = 15;

  /// Seconds practiced today by the signed-in user. Listen to this to show
  /// progress live.
  static final secondsToday = ValueNotifier<int>(0);
  static int get minutesToday => secondsToday.value ~/ 60;

  static String? _uid;
  static String _secondsDate = '';
  static DateTime? _lastRemoteSync;
  static String? _lastStreakDate;
  static String? _previousStreakDate;

  static String _localSecondsKey(String uid) => 'practice_seconds_$uid';
  static String _localDateKey(String uid) => 'practice_date_$uid';

  /// Whether the yyyy-MM-dd [dateKey] falls in the current Monday-first week.
  static bool _isThisWeek(String? dateKey) {
    if (dateKey == null) return false;
    final date = DateTime.tryParse(dateKey);
    if (date == null) return false;
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return !date.isBefore(monday);
  }

  static CollectionReference<Map<String, dynamic>> get _users => FirebaseFirestore.instance.collection('users');

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _today() => _dateKey(DateTime.now());
  static String _yesterday() => _dateKey(DateTime.now().subtract(const Duration(days: 1)));

  static int _parseGoalMinutes(String? goal) {
    if (goal == null) return 15;
    final match = RegExp(r'\d+').firstMatch(goal);
    return match == null ? 15 : int.parse(match.group(0)!);
  }

  /// Loads streak state and today's practice time for [user]. Breaks the
  /// streak if a whole calendar day was missed.
  static Future<void> load(User user) async {
    if (_uid != user.uid) {
      // A different account than what's in memory: never carry time over.
      _uid = user.uid;
      secondsToday.value = 0;
      _lastStreakDate = null;
    }
    final today = _today();
    var remoteSeconds = 0;
    try {
      final data = (await _users.doc(user.uid).get()).data();
      streakDays = (data?['streakDays'] as num?)?.toInt() ?? 0;
      weekCompleted = (data?['weekCompleted'] as List<dynamic>?)?.cast<bool>() ?? List.filled(7, false);
      _lastStreakDate = data?['lastStreakDate'] as String?;
      goalMinutes = _parseGoalMinutes(data?['dailyGoal'] as String?);
      final practice = data?['practiceToday'] as Map<String, dynamic>?;
      if (practice?['date'] == today) remoteSeconds = (practice?['seconds'] as num?)?.toInt() ?? 0;

      if (_lastStreakDate != null && _lastStreakDate != _today() && _lastStreakDate != _yesterday()) {
        streakDays = 0;
        await _users.doc(user.uid).set({'streakDays': 0}, SetOptions(merge: true));
      }
    } catch (_) {
      // Keep whatever is already cached in memory.
    }

    var localSeconds = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_localDateKey(user.uid)) == today) {
        localSeconds = prefs.getInt(_localSecondsKey(user.uid)) ?? 0;
      }
    } catch (_) {}

    if (_uid != user.uid) return; // Signed out or switched while loading.
    if (_secondsDate != today) secondsToday.value = 0;
    _secondsDate = today;
    // Take the larger of device and account so neither copy loses time
    // (practice on another phone, or a sync that hadn't gone out yet).
    secondsToday.value = max(secondsToday.value, max(localSeconds, remoteSeconds));
  }

  /// Forgets the signed-in user's streak state (on log out).
  static void reset() {
    streakDays = 0;
    weekCompleted = List.filled(7, false);
    secondsToday.value = 0;
    goalMinutes = 15;
    _uid = null;
    _secondsDate = '';
    _lastRemoteSync = null;
    _lastStreakDate = null;
  }

  /// Adds [seconds] of practice for today and saves it — on the device right
  /// away, to the account at most once a minute unless [syncNow] — then
  /// credits a streak day the first time the daily goal is reached.
  static Future<void> addSeconds(User user, int seconds, {bool syncNow = false}) async {
    if (seconds <= 0 && !syncNow) return;
    if (_uid != user.uid) {
      _uid = user.uid;
      secondsToday.value = 0;
    }
    final today = _today();
    if (_secondsDate != today) {
      // New day (e.g. practicing past midnight): start from zero.
      _secondsDate = today;
      secondsToday.value = 0;
    }
    secondsToday.value += max(0, seconds);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localDateKey(user.uid), today);
      await prefs.setInt(_localSecondsKey(user.uid), secondsToday.value);
    } catch (_) {}

    final reachedGoal = secondsToday.value >= goalMinutes * 60 && _lastStreakDate != today;
    final last = _lastRemoteSync;
    if (syncNow || reachedGoal || last == null || DateTime.now().difference(last) >= _remoteSyncInterval) {
      await _syncPractice(user, today);
    }
    if (!reachedGoal) return;

    streakDays = _lastStreakDate == _yesterday() ? streakDays + 1 : 1;
    _previousStreakDate = _lastStreakDate;
    _lastStreakDate = today;

    final weekdayIndex = DateTime.now().weekday - 1; // Monday-first, matches UserProfile.weekCompleted
    if (weekdayIndex == 0 || !_isThisWeek(_previousStreakDate)) weekCompleted = List.filled(7, false);
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

  static Future<void> _syncPractice(User user, String today) async {
    _lastRemoteSync = DateTime.now();
    try {
      await _users.doc(user.uid).set({
        'practiceToday': {'date': today, 'seconds': secondsToday.value},
      }, SetOptions(merge: true));
    } catch (_) {
      // Saved on the device already; the next sync will catch up.
    }
  }
}
