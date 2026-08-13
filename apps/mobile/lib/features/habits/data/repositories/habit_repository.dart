import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/habit_model.dart';

class HabitRepository {
  final ApiClient _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  HabitRepository(this._client);

  Future<List<HabitModel>> getToday() async {
    try {
      final response = await _client.get(ApiConstants.habits);
      final habits = (response.data['data'] as List)
          .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return habits;
    } catch (_) {
      return _getTodayLocal();
    }
  }

  Future<HabitModel> checkIn(String type, {String? date}) async {
    try {
      final response = await _client.post(
        ApiConstants.habitCheckin,
        data: {'type': type, 'date': date},
      );
      return HabitModel.fromJson(response.data['data']);
    } catch (_) {
      return _checkInLocal(type);
    }
  }

  Future<Map<String, dynamic>> getStreaks() async {
    return {'currentStreak': 0, 'longestStreak': 0, 'disciplineScore': 0};
  }

  Future<List<HabitModel>> _getTodayLocal() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final habits = await _getAllLocal();
    return habits
        .where(
          (h) =>
              h.date.year == today.year &&
              h.date.month == today.month &&
              h.date.day == today.day,
        )
        .toList();
  }

  Future<HabitModel> _checkInLocal(String type) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final habits = await _getAllLocal();
    final existing = habits.indexWhere(
      (h) =>
          h.type == type &&
          h.date.year == today.year &&
          h.date.month == today.month &&
          h.date.day == today.day,
    );

    if (existing >= 0) {
      final updated = HabitModel(
        id: habits[existing].id,
        type: type,
        completed: !habits[existing].completed,
        date: today,
      );
      habits[existing] = updated;
      await _saveAllLocal(habits);
      return updated;
    }

    final habit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      completed: true,
      date: today,
    );
    habits.add(habit);
    await _saveAllLocal(habits);
    return habit;
  }

  Future<List<HabitModel>> _getAllLocal() async {
    final json = await _storage.read(key: 'local_habits');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllLocal(List<HabitModel> habits) async {
    final json = habits.map((h) => h.toJson()).toList();
    await _storage.write(key: 'local_habits', value: jsonEncode(json));
  }
}
