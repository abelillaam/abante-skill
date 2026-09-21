import '../models/lesson.dart';

/// Holds the current user's curriculum for this app session.
/// Starts out as the mock demo curriculum and gets replaced once
/// [CurriculumService.generate] produces a real one after signup.
class CurriculumRepository {
  CurriculumRepository._();

  static List<LessonUnit> units = mockUnits;

  /// The user's onboarding experience level (e.g. "Beginner", "Pro"), used
  /// to tailor generated lesson exercises/theory to their actual skill —
  /// not just the lesson topic. Null if unknown (falls back to a sensible
  /// default in the generation prompts).
  static String? level;

  /// Marks [lessonId] as completed and unlocks the next lesson in sequence
  /// (across unit boundaries), updating [units] in place. Returns true if a
  /// matching lesson was found and updated.
  static bool markLessonCompleted(String lessonId) {
    final flatIds = [for (final unit in units) for (final lesson in unit.lessons) lesson.id];
    final completedIndex = flatIds.indexOf(lessonId);
    if (completedIndex == -1) return false;
    final nextId = completedIndex + 1 < flatIds.length ? flatIds[completedIndex + 1] : null;

    units = [
      for (final unit in units)
        unit.copyWith(
          lessons: [
            for (final lesson in unit.lessons)
              if (lesson.id == lessonId)
                lesson.copyWith(status: LessonStatus.completed, completedModules: lesson.totalModules)
              else if (lesson.id == nextId && lesson.status == LessonStatus.locked)
                lesson.copyWith(status: LessonStatus.active)
              else
                lesson,
          ],
        ),
    ];
    return true;
  }

  /// Caches a generated exercise onto [lessonId] so future opens reuse it
  /// instead of generating a new (different) one each time. Returns true if
  /// a matching lesson was found and updated.
  static bool cacheExercise(
    String lessonId, {
    required String instruction,
    required String starterCode,
    required String language,
    required String fileName,
  }) {
    final exists = units.any((unit) => unit.lessons.any((lesson) => lesson.id == lessonId));
    if (!exists) return false;

    units = [
      for (final unit in units)
        unit.copyWith(
          lessons: [
            for (final lesson in unit.lessons)
              if (lesson.id == lessonId)
                lesson.copyWith(
                  exerciseInstruction: instruction,
                  exerciseStarterCode: starterCode,
                  exerciseLanguage: language,
                  exerciseFileName: fileName,
                )
              else
                lesson,
          ],
        ),
    ];
    return true;
  }
}
