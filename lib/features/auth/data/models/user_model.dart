class UserModel {
  final String id;
  final String email;
  final String name;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? fitnessLevel;
  final List<String>? goals;
  final int xpPoints;
  final int level;
  final int disciplineScore;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.fitnessLevel,
    this.goals,
    this.xpPoints = 0,
    this.level = 1,
    this.disciplineScore = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      fitnessLevel: json['fitnessLevel'] as String?,
      goals: (json['goals'] as List?)?.cast<String>(),
      xpPoints: json['xpPoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      disciplineScore: json['disciplineScore'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'age': age,
    'gender': gender,
    'height': height,
    'weight': weight,
    'fitnessLevel': fitnessLevel,
    'goals': goals,
    'xpPoints': xpPoints,
    'level': level,
    'disciplineScore': disciplineScore,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'createdAt': createdAt.toIso8601String(),
  };
}
