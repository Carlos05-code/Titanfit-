import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'titanfit_channel',
      'TitanFit Reminders',
      channelDescription: 'Workout and habit reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleMorningReminder() async {
    await showNotification(
      id: 1,
      title: 'Good Morning Titan!',
      body: 'Time to start your discipline routine. Rise and grind!',
    );
  }

  Future<void> scheduleWorkoutReminder() async {
    await showNotification(
      id: 2,
      title: 'Workout Time',
      body: "Don't skip today's workout. Every rep counts!",
    );
  }

  Future<void> scheduleStretchReminder() async {
    await showNotification(
      id: 3,
      title: 'Stretch Break',
      body: 'Take 5 minutes to stretch and keep your body flexible.',
    );
  }

  Future<void> scheduleSleepReminder() async {
    await showNotification(
      id: 4,
      title: 'Wind Down',
      body: '30 minutes until your target bedtime. Prepare for rest.',
    );
  }
}
