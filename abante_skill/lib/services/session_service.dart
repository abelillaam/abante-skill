import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'curriculum_repository.dart';
import 'curriculum_service.dart';
import 'google_auth_service.dart';
import 'hearts_repository.dart';
import 'push_notification_service.dart';
import 'streak_repository.dart';
import 'user_repository.dart';

/// Owns what happens around signing in and out: restoring a returning
/// user's saved progress, building a curriculum for a new one, and wiping
/// all in-memory state on sign-out so the next person on this device starts
/// clean.
class SessionService {
  SessionService._();

  /// Bumped whenever progress changes (lesson finished, tab switched), so
  /// screens kept alive under the bottom nav know to reload their data.
  static final refreshTick = ValueNotifier<int>(0);

  static void requestRefresh() => refreshTick.value++;

  /// Loads [user]'s saved curriculum. Returns false if they have none yet
  /// (brand-new account, or never finished onboarding). Throws if Firestore
  /// can't be reached, so an offline returning user is never mistaken for a
  /// new one.
  static Future<bool> restore(User user) async {
    final saved = await UserRepository.fetchCurriculum(user.uid);
    if (saved == null) return false;
    CurriculumRepository.units = saved;
    CurriculumRepository.level = await UserRepository.loadLevel(user.uid);
    await Future.wait([HeartsRepository.load(user), StreakRepository.load(user)]);
    unawaited(PushNotificationService.saveTokenIfSignedIn());
    return true;
  }

  /// Generates and saves a fresh curriculum from onboarding answers.
  /// Throws [GroqUnavailable] if the AI couldn't build one; nothing is
  /// saved in that case.
  static Future<void> createCurriculum(
    User user, {
    required String track,
    required String level,
    required String dailyGoal,
  }) async {
    CurriculumRepository.units = await CurriculumService.generate(track: track, level: level, dailyGoal: dailyGoal);
    CurriculumRepository.level = level;
    try {
      await UserRepository.saveUser(
        user: user,
        track: track,
        level: level,
        dailyGoal: dailyGoal,
        curriculum: CurriculumRepository.units,
      );
    } catch (_) {
      // Don't block reaching the app over a Firestore hiccup; the curriculum
      // is already in memory and is saved again on the next progress write.
    }
    await Future.wait([HeartsRepository.load(user), StreakRepository.load(user)]);
    unawaited(PushNotificationService.saveTokenIfSignedIn());
  }

  /// Forgets everything belonging to the signed-in user.
  static void clearLocalState() {
    CurriculumRepository.reset();
    HeartsRepository.reset();
    StreakRepository.reset();
  }

  static Future<void> signOut() async {
    clearLocalState();
    await GoogleAuthService.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
