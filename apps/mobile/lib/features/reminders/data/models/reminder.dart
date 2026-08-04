import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  TimeOfDay time;
  List<int> days;
  bool enabled;

  Reminder({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.time,
    required this.days,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'iconCodePoint': icon.codePoint,
    'hour': time.hour,
    'minute': time.minute,
    'days': days,
    'enabled': enabled,
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    title: json['title'],
    subtitle: json['subtitle'],
    icon: IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'),
    time: TimeOfDay(hour: json['hour'] ?? 7, minute: json['minute'] ?? 0),
    days: List<int>.from(json['days'] ?? [0,1,2,3,4,5,6]),
    enabled: json['enabled'] ?? true,
  );
}

final defaultReminders = [
  Reminder(
    id: 'wakeup',
    title: 'Wake Up',
    subtitle: 'Rise and shine, Titan',
    icon: const IconData(0xe4d8, fontFamily: 'MaterialIcons'),
    time: const TimeOfDay(hour: 6, minute: 0),
    days: [0,1,2,3,4,5,6],
  ),
  Reminder(
    id: 'workout',
    title: 'Workout Time',
    subtitle: 'Time to crush your workout',
    icon: const IconData(0xe4c5, fontFamily: 'MaterialIcons'),
    time: const TimeOfDay(hour: 7, minute: 30),
    days: [0,1,2,3,4,5],
  ),
  Reminder(
    id: 'stretch',
    title: 'Stretch Break',
    subtitle: 'Stand up and stretch',
    icon: const IconData(0xe409, fontFamily: 'MaterialIcons'),
    time: const TimeOfDay(hour: 12, minute: 0),
    days: [0,1,2,3,4,5,6],
  ),
  Reminder(
    id: 'sleep',
    title: 'Wind Down',
    subtitle: 'Prepare for bed',
    icon: const IconData(0xe192, fontFamily: 'MaterialIcons'),
    time: const TimeOfDay(hour: 21, minute: 30),
    days: [0,1,2,3,4,5,6],
  ),
];
