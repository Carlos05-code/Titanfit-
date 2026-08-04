class HabitModel {
  final String id;
  final String type;
  final bool completed;
  final DateTime date;

  HabitModel({
    required this.id,
    required this.type,
    required this.completed,
    required this.date,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as String,
      type: json['type'] as String,
      completed: json['completed'] as bool,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'completed': completed,
    'date': date.toIso8601String(),
  };

  String get displayName {
    switch (type) {
      case 'WAKE_UP_EARLY': return 'Wake Up Early';
      case 'WORKOUT_COMPLETED': return 'Workout';
      case 'DRINK_WATER': return 'Hydrate';
      case 'EAT_HEALTHY': return 'Eat Healthy';
      case 'SLEEP_ON_TIME': return 'Sleep On Time';
      case 'STRETCH': return 'Stretch';
      case 'MEDITATE': return 'Meditate';
      default: return type;
    }
  }
}
