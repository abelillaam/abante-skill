import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/lesson.dart';

class EarnedCertificate {
  const EarnedCertificate({required this.unitId, required this.unitTitle, required this.earnedAt});

  final String unitId;
  final String unitTitle;
  final DateTime earnedAt;
}

/// Tracks which lesson units a user has fully completed, each earning a
/// simple completion certificate. Persisted in Firestore under
/// `users/{uid}.certificates`, keyed by unit id.
class CertificateRepository {
  CertificateRepository._();

  static CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  /// If every lesson in [unit] is completed and a certificate for it hasn't
  /// been awarded yet, records one and returns it. Returns null otherwise.
  static Future<EarnedCertificate?> awardIfUnitComplete(User user, LessonUnit unit) async {
    final allDone = unit.lessons.isNotEmpty && unit.lessons.every((l) => l.status == LessonStatus.completed);
    if (!allDone) return null;

    try {
      final existing = await loadEarned(user);
      if (existing.containsKey(unit.id)) return null;

      final earnedAt = DateTime.now();
      await _users.doc(user.uid).update({
        'certificates.${unit.id}': Timestamp.fromDate(earnedAt),
      });
      return EarnedCertificate(unitId: unit.id, unitTitle: unit.title, earnedAt: earnedAt);
    } catch (_) {
      return null;
    }
  }

  /// Loads all certificates the user has earned so far, keyed by unit id.
  static Future<Map<String, DateTime>> loadEarned(User user) async {
    try {
      final data = (await _users.doc(user.uid).get()).data();
      final raw = data?['certificates'] as Map<String, dynamic>?;
      if (raw == null) return {};
      return raw.map((key, value) => MapEntry(key, (value as Timestamp).toDate()));
    } catch (_) {
      return {};
    }
  }
}
