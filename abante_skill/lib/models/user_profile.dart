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
    this.photoBase64,
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

  /// Small JPEG profile photo, base64-encoded, or null for the initial-letter
  /// avatar. Stored inline in the user's Firestore doc (it's resized to a few
  /// KB on upload), so no separate file storage is needed.
  final String? photoBase64;

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  UserProfile copyWith({String? name, String? username, String? bio, String? photoBase64, bool clearPhoto = false}) =>
      UserProfile(
        name: name ?? this.name,
        username: username ?? this.username,
        email: email,
        bio: bio ?? this.bio,
        streakDays: streakDays,
        totalXp: totalXp,
        lessonsCompleted: lessonsCompleted,
        weekCompleted: weekCompleted,
        photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
      );
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
