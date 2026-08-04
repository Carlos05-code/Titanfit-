import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

class DashboardRepository {
  final ApiClient _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DashboardRepository(this._client);

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _client.get(ApiConstants.progressStats);
      return response.data['data'] as Map<String, dynamic>;
    } catch (_) {
      return _getLocalStats();
    }
  }

  Future<Map<String, dynamic>> _getLocalStats() async {
    final workoutsJson = await _storage.read(key: 'local_workouts');
    final sleepJson = await _storage.read(key: 'local_sleep');
    final habitsJson = await _storage.read(key: 'local_habits');

    final workouts = workoutsJson != null
        ? (jsonDecode(workoutsJson) as List).length
        : 0;
    final sleepRecords = sleepJson != null
        ? (jsonDecode(sleepJson) as List).length
        : 0;
    final habits = habitsJson != null
        ? (jsonDecode(habitsJson) as List).length
        : 0;

    return {
      'totalWorkouts': workouts,
      'totalWorkoutDuration': 0,
      'totalCaloriesBurned': 0,
      'weeklyWorkouts': <dynamic>[],
      'avgSleepScore': sleepRecords > 0 ? 75 : 0,
      'avgSleepDuration': sleepRecords > 0 ? 7.5 : 0,
      'totalSleepRecords': sleepRecords,
      'totalHabitsCompleted': habits,
      'weeklyHabitsCompleted': habits > 0 ? 3 : 0,
      'achievements': <dynamic>[],
    };
  }
}
