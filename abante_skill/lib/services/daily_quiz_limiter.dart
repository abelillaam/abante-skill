import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caps how many trivia questions each account can answer per day (resets
/// at midnight). The count is kept per account — on this device and in the
/// user's Firestore doc (`triviaToday`) — so accounts sharing a phone each
/// get their own 10, and the count follows an account to other phones.
class DailyQuizLimiter {
  DailyQuizLimiter._();

  static const dailyLimit = 10;

  /// The account/day the in-memory [_count] belongs to.
  static String? _loadedFor;
  static int _count = 0;

  static String get _uid {
    if (Firebase.apps.isEmpty) return 'guest';
    return FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _dateKey(String uid) => 'trivia_date_$uid';
  static String _countKey(String uid) => 'trivia_count_$uid';

  static DocumentReference<Map<String, dynamic>>? _doc(String uid) =>
      uid == 'guest' ? null : FirebaseFirestore.instance.collection('users').doc(uid);

  /// Loads today's count for the signed-in account (once per account per
  /// day), taking the larger of the device and account copies.
  static Future<void> _ensureLoaded() async {
    final uid = _uid;
    final today = _today();
    if (_loadedFor == '$uid|$today') return;

    var local = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_dateKey(uid)) == today) local = prefs.getInt(_countKey(uid)) ?? 0;
    } catch (_) {}

    var remote = 0;
    try {
      final data = (await _doc(uid)?.get())?.data();
      final trivia = data?['triviaToday'] as Map<String, dynamic>?;
      if (trivia?['date'] == today) remote = (trivia?['count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Offline: the device copy is still enforced.
    }

    _count = max(local, remote);
    _loadedFor = '$uid|$today';
  }

  /// How many questions the signed-in account has answered today.
  static Future<int> getAnsweredToday() async {
    await _ensureLoaded();
    return _count;
  }

  static Future<int> getRemainingToday() async {
    final answered = await getAnsweredToday();
    return (dailyLimit - answered).clamp(0, dailyLimit);
  }

  /// Records one answered question for the signed-in account.
  static Future<void> recordAnswer() async {
    await _ensureLoaded();
    final uid = _uid;
    final today = _today();
    _count++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dateKey(uid), today);
      await prefs.setInt(_countKey(uid), _count);
    } catch (_) {}
    try {
      await _doc(uid)?.set({
        'triviaToday': {'date': today, 'count': _count},
      }, SetOptions(merge: true));
    } catch (_) {
      // Saved on the device; the account copy catches up next answer.
    }
  }
}
