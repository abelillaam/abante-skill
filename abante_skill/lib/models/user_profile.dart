class UserProfile {
  const UserProfile({
    required this.name,
    required this.username,
    required this.email,
    required this.bio,
    required this.streakDays,
    required this.totalXp,
    required this.lessonsCompleted,
    required this.weekCompleted,
  });

  final String name;
  final String username;
  final String email;
  final String bio;
  final int streakDays;
  final int totalXp;
  final int lessonsCompleted;

  /// 7 booleans, Monday first, marking which days this week hit the goal.
  final List<bool> weekCompleted;
}

const mockProfile = UserProfile(
  name: 'Adrianne',
  username: 'adriannecodes',
  email: 'adrianne@example.com',
  bio: "Learning Python one lesson at a time 🐍",
  streakDays: 4,
  totalXp: 860,
  lessonsCompleted: 2,
  weekCompleted: [true, true, true, true, false, false, false],
);
