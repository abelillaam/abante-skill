import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/lesson.dart';
import '../models/lesson_icons.dart';
import '../models/user_profile.dart';

/// Reads and writes each user's profile + curriculum in Firestore, under
/// `users/{uid}`, so progress survives logging out and back in.
class UserRepository {
  UserRepository._();

  static CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  /// Deletes a user's Firestore document. Does not touch their Firebase Auth
  /// account — callers should also call `user.delete()` separately.
  static Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
  }

  /// A sensible profile to show immediately after sign-in, before Firestore
  /// data (if any) has loaded — built entirely from the Firebase Auth user
  /// so there's never a flash of hardcoded demo data.
  static UserProfile defaultProfileFor(User user) {
    final emailName = user.email?.split('@').first ?? 'there';
    return UserProfile(
      name: user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : emailName,
      username: emailName,
      email: user.email ?? '',
      bio: '',
      streakDays: 0,
      totalXp: 0,
      lessonsCompleted: 0,
      weekCompleted: List.filled(7, false),
    );
  }

  static Future<void> saveUser({
    required User user,
    String? track,
    String? level,
    String? dailyGoal,
    List<LessonUnit>? curriculum,
  }) async {
    final ref = _users.doc(user.uid);
    final isNewUser = !(await ref.get()).exists;
    final defaults = isNewUser ? defaultProfileFor(user) : null;

    final data = <String, dynamic>{
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
      'track': ?track,
      'level': ?level,
      'dailyGoal': ?dailyGoal,
      'curriculum': ?curriculum?.map(_unitToMap).toList(),
      if (defaults != null) ...{
        'name': defaults.name,
        'username': defaults.username,
        'bio': defaults.bio,
        'streakDays': defaults.streakDays,
        'totalXp': defaults.totalXp,
        'lessonsCompleted': defaults.lessonsCompleted,
        'weekCompleted': defaults.weekCompleted,
        'createdAt': FieldValue.serverTimestamp(),
      },
    };
    await ref.set(data, SetOptions(merge: true));
  }

  /// Persists profile edits (name/username/bio/stats) made from the Edit
  /// Profile screen.
  static Future<void> saveProfile(User user, UserProfile profile) async {
    await _users.doc(user.uid).set({
      'name': profile.name,
      'username': profile.username,
      'email': profile.email,
      'bio': profile.bio,
      'streakDays': profile.streakDays,
      'totalXp': profile.totalXp,
      'lessonsCompleted': profile.lessonsCompleted,
      'weekCompleted': profile.weekCompleted,
    }, SetOptions(merge: true));
  }

  /// Atomically adds [amount] XP to [user]'s profile, e.g. after completing
  /// a lesson.
  static Future<void> addXp(User user, int amount) async {
    await _users.doc(user.uid).set({
      'totalXp': FieldValue.increment(amount),
    }, SetOptions(merge: true));
  }

  /// Returns the saved profile for [user], or null if Firestore has nothing
  /// yet (e.g. never made it past signup, or Firestore couldn't be reached).
  static Future<UserProfile?> loadProfile(User user) async {
    try {
      final data = (await _users.doc(user.uid).get()).data();
      if (data == null || data['name'] == null) return null;
      return UserProfile(
        name: data['name'] as String,
        username: data['username'] as String? ?? (user.email?.split('@').first ?? ''),
        email: data['email'] as String? ?? user.email ?? '',
        bio: data['bio'] as String? ?? '',
        streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
        totalXp: (data['totalXp'] as num?)?.toInt() ?? 0,
        lessonsCompleted: (data['lessonsCompleted'] as num?)?.toInt() ?? 0,
        weekCompleted: (data['weekCompleted'] as List<dynamic>?)?.cast<bool>() ?? List.filled(7, false),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the user's saved onboarding experience level (e.g. "Beginner"),
  /// or null if unknown.
  static Future<String?> loadLevel(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      return doc.data()?['level'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Returns the saved curriculum for [uid], or null if the user has no
  /// saved curriculum yet (e.g. never finished onboarding, or Firestore
  /// couldn't be reached).
  static Future<List<LessonUnit>?> loadCurriculum(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      final rawUnits = doc.data()?['curriculum'] as List<dynamic>?;
      if (rawUnits == null || rawUnits.isEmpty) return null;
      return rawUnits.map((u) => _unitFromMap(u as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _unitToMap(LessonUnit unit) => {
        'id': unit.id,
        'title': unit.title,
        'subtitle': unit.subtitle,
        'iconIndex': unitIcons.indexOf(unit.icon),
        'lessons': unit.lessons.map(_lessonToMap).toList(),
      };

  static LessonUnit _unitFromMap(Map<String, dynamic> map) => LessonUnit(
        id: map['id'] as String,
        title: map['title'] as String,
        subtitle: map['subtitle'] as String,
        icon: unitIconAt((map['iconIndex'] as num?)?.toInt() ?? 0),
        lessons: (map['lessons'] as List<dynamic>)
            .map((l) => _lessonFromMap(l as Map<String, dynamic>))
            .toList(),
      );

  static Map<String, dynamic> _lessonToMap(Lesson lesson) => {
        'id': lesson.id,
        'title': lesson.title,
        'summary': lesson.summary,
        'iconIndex': lessonIcons.indexOf(lesson.icon),
        'status': lesson.status.name,
        'totalModules': lesson.totalModules,
        'completedModules': lesson.completedModules,
        'exerciseInstruction': ?lesson.exerciseInstruction,
        'exerciseStarterCode': ?lesson.exerciseStarterCode,
        'exerciseLanguage': ?lesson.exerciseLanguage,
        'exerciseFileName': ?lesson.exerciseFileName,
      };

  static Lesson _lessonFromMap(Map<String, dynamic> map) => Lesson(
        id: map['id'] as String,
        title: map['title'] as String,
        summary: map['summary'] as String,
        icon: lessonIconAt((map['iconIndex'] as num?)?.toInt() ?? 0),
        status: LessonStatus.values.byName(map['status'] as String),
        totalModules: (map['totalModules'] as num).toInt(),
        completedModules: (map['completedModules'] as num?)?.toInt() ?? 0,
        exerciseInstruction: map['exerciseInstruction'] as String?,
        exerciseStarterCode: map['exerciseStarterCode'] as String?,
        exerciseLanguage: map['exerciseLanguage'] as String?,
        exerciseFileName: map['exerciseFileName'] as String?,
      );
}
