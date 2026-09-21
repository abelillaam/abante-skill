import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Tracks the user's hearts (lesson attempts) with a Duolingo-style regen
/// timer, persisted in Firestore under `users/{uid}` so they survive
/// reopening a lesson or restarting the app.
class HeartsRepository {
  HeartsRepository._();

  static const maxHearts = 3;
  static const regenInterval = Duration(hours: 4);

  static int hearts = maxHearts;
  static DateTime? nextHeartAt;

  static CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  /// Loads hearts from Firestore, catching up any hearts that regenerated
  /// while the app was closed.
  static Future<void> load(User user) async {
    try {
      final data = (await _users.doc(user.uid).get()).data();
      hearts = (data?['hearts'] as num?)?.toInt() ?? maxHearts;
      final storedNext = (data?['heartsRegenAt'] as Timestamp?)?.toDate();

      DateTime? next = storedNext;
      final now = DateTime.now();
      while (next != null && hearts < maxHearts && !now.isBefore(next)) {
        hearts++;
        next = hearts >= maxHearts ? null : next.add(regenInterval);
      }
      nextHeartAt = next;

      if (hearts != ((data?['hearts'] as num?)?.toInt() ?? maxHearts) || next != storedNext) {
        await _persist(user);
      }
    } catch (_) {
      // Keep whatever is already cached in memory.
    }
  }

  /// Records a lost heart (e.g. a wrong lesson answer) and starts the regen
  /// timer if this is the first heart lost since being full.
  static Future<void> loseHeart(User user) async {
    hearts = (hearts - 1).clamp(0, maxHearts);
    nextHeartAt ??= DateTime.now().add(regenInterval);
    await _persist(user);
  }

  static Future<void> _persist(User user) async {
    try {
      await _users.doc(user.uid).set({
        'hearts': hearts,
        'heartsRegenAt': nextHeartAt == null ? null : Timestamp.fromDate(nextHeartAt!),
      }, SetOptions(merge: true));
    } catch (_) {
      // Local state already updated; a sync hiccup shouldn't block the UI.
    }
  }

  /// Time remaining until the next heart regenerates, or null if hearts are
  /// already full.
  static Duration? timeUntilNextHeart() {
    if (nextHeartAt == null) return null;
    final remaining = nextHeartAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
