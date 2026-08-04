import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/workout_model.dart';

class WorkoutRepository {
  final ApiClient _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  WorkoutRepository(this._client);

  Future<List<WorkoutModel>> getAll({int page = 1, int limit = 20}) async {
    try {
      final response = await _client.get(
        ApiConstants.workouts,
        params: {'page': page, 'limit': limit},
      );
      final data = response.data['data'];
      final workouts = (data['workouts'] as List)
          .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
          .toList();
      await _saveLocal(workouts);
      return workouts;
    } catch (_) {
      return _getLocal();
    }
  }

  Future<WorkoutModel> getById(String id) async {
    try {
      final response = await _client.get('${ApiConstants.workouts}/$id');
      return WorkoutModel.fromJson(response.data['data']);
    } catch (_) {
      final workouts = await _getLocal();
      return workouts.firstWhere((w) => w.id == id);
    }
  }

  Future<WorkoutModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(ApiConstants.workouts, data: data);
      final workout = WorkoutModel.fromJson(response.data['data']);
      await _addLocal(workout);
      return workout;
    } catch (_) {
      final workout = WorkoutModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'local',
        title: data['title'] as String? ?? 'Workout',
        goal: data['goal'] as String?,
        date: DateTime.now(),
        duration: data['duration'] as int?,
        calories: data['calories'] as int?,
        notes: data['notes'] as String?,
        exercises: (data['exercises'] as List?)
                ?.map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
      await _addLocal(workout);
      return workout;
    }
  }

  Future<WorkoutModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.put('${ApiConstants.workouts}/$id', data: data);
      return WorkoutModel.fromJson(response.data['data']);
    } catch (_) {
      throw Exception('Update failed offline');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.delete('${ApiConstants.workouts}/$id');
    } catch (_) {}
    await _removeLocal(id);
  }

  Future<void> addExercise(String workoutId, Map<String, dynamic> exerciseData) async {
    try {
      await _client.post('${ApiConstants.workouts}/$workoutId/exercises', data: exerciseData);
    } catch (_) {
      // Local fallback
    }
    final workouts = await _getLocal();
    final idx = workouts.indexWhere((w) => w.id == workoutId);
    if (idx >= 0) {
      final exList = List<Map<String, dynamic>>.from(
        workouts[idx].exercises.map((e) => e.toJson()),
      );
      exList.add(exerciseData);
      final updated = WorkoutModel.fromJson({
        ...workouts[idx].toJson(),
        'exercises': exList,
      });
      workouts[idx] = updated;
      await _saveLocal(workouts);
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final workouts = await _getLocal();
    final total = workouts.length;
    final totalDuration = workouts.fold<int>(0, (s, w) => s + (w.duration ?? 0));
    final totalCalories = workouts.fold<int>(0, (s, w) => s + (w.calories ?? 0));
    return {
      'totalWorkouts': total,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
      'recent': workouts.take(7).map((w) => {
        'date': w.date.toIso8601String(),
        'duration': w.duration,
        'calories': w.calories,
      }).toList(),
    };
  }

  Future<void> _saveLocal(List<WorkoutModel> workouts) async {
    final json = workouts.map((w) => w.toJson()).toList();
    await _storage.write(key: 'local_workouts', value: jsonEncode(json));
  }

  Future<List<WorkoutModel>> _getLocal() async {
    final json = await _storage.read(key: 'local_workouts');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _addLocal(WorkoutModel workout) async {
    final workouts = await _getLocal();
    workouts.insert(0, workout);
    await _saveLocal(workouts);
  }

  Future<void> _removeLocal(String id) async {
    final workouts = await _getLocal();
    workouts.removeWhere((w) => w.id == id);
    await _saveLocal(workouts);
  }
}
