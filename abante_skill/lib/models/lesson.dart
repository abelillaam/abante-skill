import 'package:flutter/material.dart';

enum LessonStatus { completed, active, locked }

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.status,
    required this.totalModules,
    this.completedModules = 0,
    this.exerciseInstruction,
    this.exerciseStarterCode,
    this.exerciseLanguage,
    this.exerciseFileName,
    this.theoryCards,
  });

  final String id;
  final String title;
  final String summary;
  final IconData icon;
  final LessonStatus status;
  final int totalModules;
  final int completedModules;

  /// The AI-generated coding exercise for this lesson, cached here once
  /// generated so reopening the lesson shows the same exercise instead of
  /// generating a new one each time. Null until first generated.
  final String? exerciseInstruction;
  final String? exerciseStarterCode;
  final String? exerciseLanguage;
  final String? exerciseFileName;

  /// The AI-generated theory cards shown on the concept briefing screen,
  /// cached here once generated for the same reason as the exercise above —
  /// otherwise every reopen would show different (AI-regenerated) content.
  /// Each map has keys: heading, analogy, snippet, language.
  final List<Map<String, String>>? theoryCards;

  bool get hasCachedExercise => exerciseInstruction != null;
  bool get hasCachedTheory => theoryCards != null && theoryCards!.isNotEmpty;

  Lesson copyWith({
    LessonStatus? status,
    int? completedModules,
    String? exerciseInstruction,
    String? exerciseStarterCode,
    String? exerciseLanguage,
    String? exerciseFileName,
    List<Map<String, String>>? theoryCards,
  }) =>
      Lesson(
        id: id,
        title: title,
        summary: summary,
        icon: icon,
        status: status ?? this.status,
        totalModules: totalModules,
        completedModules: completedModules ?? this.completedModules,
        exerciseInstruction: exerciseInstruction ?? this.exerciseInstruction,
        exerciseStarterCode: exerciseStarterCode ?? this.exerciseStarterCode,
        exerciseLanguage: exerciseLanguage ?? this.exerciseLanguage,
        exerciseFileName: exerciseFileName ?? this.exerciseFileName,
        theoryCards: theoryCards ?? this.theoryCards,
      );
}

class LessonUnit {
  const LessonUnit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.lessons,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Lesson> lessons;

  /// A unit unlocks once every lesson in it is no longer locked — i.e. the
  /// previous unit finished and handed off an active lesson into this one.
  bool get isLocked => lessons.every((lesson) => lesson.status == LessonStatus.locked);

  LessonUnit copyWith({List<Lesson>? lessons}) => LessonUnit(
        id: id,
        title: title,
        subtitle: subtitle,
        icon: icon,
        lessons: lessons ?? this.lessons,
      );
}

const mockUnits = [
  LessonUnit(
    id: 'unit-1',
    title: 'Python Basics',
    subtitle: 'Unit 1',
    icon: Icons.menu_book_rounded,
    lessons: [
      Lesson(
        id: 'variables',
        title: 'Variables & Data Types',
        summary: 'Learn how to store and label information in your programs.',
        icon: Icons.data_object_rounded,
        status: LessonStatus.completed,
        totalModules: 3,
        completedModules: 3,
      ),
      Lesson(
        id: 'operators',
        title: 'Operators & Expressions',
        summary: 'Combine values using math and comparison operators.',
        icon: Icons.calculate_rounded,
        status: LessonStatus.completed,
        totalModules: 3,
        completedModules: 3,
      ),
      Lesson(
        id: 'conditionals',
        title: 'Conditionals',
        summary: 'Make your code branch and react with if / else logic.',
        icon: Icons.alt_route_rounded,
        status: LessonStatus.active,
        totalModules: 3,
        completedModules: 0,
      ),
      Lesson(
        id: 'loops',
        title: 'Loops',
        summary: 'Repeat actions automatically with for and while loops.',
        icon: Icons.loop_rounded,
        status: LessonStatus.locked,
        totalModules: 3,
      ),
    ],
  ),
  LessonUnit(
    id: 'unit-2',
    title: 'Functions & Data Structures',
    subtitle: 'Unit 2',
    icon: Icons.widgets_rounded,
    lessons: [
      Lesson(
        id: 'functions',
        title: 'Functions',
        summary: 'Package up reusable logic into callable blocks.',
        icon: Icons.functions_rounded,
        status: LessonStatus.locked,
        totalModules: 4,
      ),
      Lesson(
        id: 'lists',
        title: 'Lists & Collections',
        summary: 'Store and manipulate groups of related values.',
        icon: Icons.view_list_rounded,
        status: LessonStatus.locked,
        totalModules: 3,
      ),
      Lesson(
        id: 'projects',
        title: 'Mini Project',
        summary: 'Put it all together and build something real.',
        icon: Icons.rocket_launch_rounded,
        status: LessonStatus.locked,
        totalModules: 2,
      ),
    ],
  ),
];
