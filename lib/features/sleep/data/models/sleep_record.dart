class SleepRecord {
  final String id;
  final DateTime sleepTime;
  final DateTime wakeTime;
  final double duration;
  final double score;
  final DateTime createdAt;

  SleepRecord({
    required this.id,
    required this.sleepTime,
    required this.wakeTime,
    required this.duration,
    required this.score,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      id: json['id'] as String,
      sleepTime: DateTime.parse(json['sleepTime'] as String),
      wakeTime: DateTime.parse(json['wakeTime'] as String),
      duration: (json['duration'] as num).toDouble(),
      score: (json['score'] as num).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sleepTime': sleepTime.toIso8601String(),
    'wakeTime': wakeTime.toIso8601String(),
    'duration': duration,
    'score': score,
    'createdAt': createdAt.toIso8601String(),
  };
}
