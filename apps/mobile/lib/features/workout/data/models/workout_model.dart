class ExerciseModel {
  final String? id;
  final String name;
  final int? sets;
  final int? reps;
  final double? weight;
  final int? duration;
  final int? calories;
  final int order;

  ExerciseModel({
    this.id,
    required this.name,
    this.sets,
    this.reps,
    this.weight,
    this.duration,
    this.calories,
    this.order = 0,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      duration: json['duration'] as int?,
      calories: json['calories'] as int?,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sets': sets,
    'reps': reps,
    'weight': weight,
    'duration': duration,
    'calories': calories,
    'order': order,
  };
}

class WorkoutModel {
  final String id;
  final String userId;
  final String title;
  final String? goal;
  final DateTime date;
  final int? duration;
  final int? calories;
  final String? notes;
  final List<ExerciseModel> exercises;

  WorkoutModel({
    required this.id,
    required this.userId,
    required this.title,
    this.goal,
    required this.date,
    this.duration,
    this.calories,
    this.notes,
    this.exercises = const [],
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      goal: json['goal'] as String?,
      date: DateTime.parse(json['date'] as String),
      duration: json['duration'] as int?,
      calories: json['calories'] as int?,
      notes: json['notes'] as String?,
      exercises:
          (json['exercises'] as List?)
              ?.map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'goal': goal,
    'date': date.toIso8601String(),
    'duration': duration,
    'calories': calories,
    'notes': notes,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}
