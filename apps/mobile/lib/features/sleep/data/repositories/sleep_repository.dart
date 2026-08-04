import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/sleep_record.dart';

class SleepRepository {
  final ApiClient _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SleepRepository(this._client);

  Future<SleepRecord> record(String sleepTime, String wakeTime) async {
    try {
      final response = await _client.post(
        ApiConstants.sleep,
        data: {'sleepTime': sleepTime, 'wakeTime': wakeTime},
      );
      final record = SleepRecord.fromJson(response.data['data']);
      await _addLocal(record);
      return record;
    } catch (_) {
      final sleep = DateTime.parse(sleepTime);
      final wake = DateTime.parse(wakeTime);
      final duration = (wake.difference(sleep).inMinutes / 60).roundToDouble();
      final score = duration >= 7 && duration <= 9 ? 100.0 :
                    duration >= 6 ? 75.0 :
                    duration >= 5 ? 50.0 : 25.0;

      final record = SleepRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sleepTime: sleep,
        wakeTime: wake,
        duration: duration,
        score: score,
      );
      await _addLocal(record);
      return record;
    }
  }

  Future<Map<String, dynamic>> getHistory({int days = 7}) async {
    try {
      final response = await _client.get(
        ApiConstants.sleepHistory,
        params: {'days': days},
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (_) {
      return _getHistoryLocal(days);
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _client.get(ApiConstants.sleepStats);
      return response.data['data'] as Map<String, dynamic>;
    } catch (_) {
      return _getStatsLocal();
    }
  }

  Future<void> _addLocal(SleepRecord record) async {
    final records = await _getAllLocal();
    records.insert(0, record);
    final json = records.map((r) => r.toJson()).toList();
    await _storage.write(key: 'local_sleep', value: jsonEncode(json));
  }

  Future<List<SleepRecord>> _getAllLocal() async {
    final json = await _storage.read(key: 'local_sleep');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => SleepRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> _getHistoryLocal(int days) async {
    final all = await _getAllLocal();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final filtered = all.where((r) => r.sleepTime.isAfter(cutoff)).toList();
    final avgScore = filtered.isEmpty ? 0.0 : filtered.fold<double>(0, (s, r) => s + r.score) / filtered.length;
    final avgDuration = filtered.isEmpty ? 0.0 : filtered.fold<double>(0, (s, r) => s + r.duration) / filtered.length;
    return {
      'records': filtered.map((r) => r.toJson()).toList(),
      'avgScore': avgScore.round(),
      'avgDuration': (avgDuration * 10).roundToDouble() / 10,
      'totalRecords': filtered.length,
    };
  }

  Future<Map<String, dynamic>> _getStatsLocal() async {
    final all = await _getAllLocal();
    final avgScore = all.isEmpty ? 0.0 : all.fold<double>(0, (s, r) => s + r.score) / all.length;
    final avgDuration = all.isEmpty ? 0.0 : all.fold<double>(0, (s, r) => s + r.duration) / all.length;
    return {
      'totalRecords': all.length,
      'avgScore': avgScore.round(),
      'avgDuration': (avgDuration * 10).roundToDouble() / 10,
      'recent': all.take(7).map((r) => r.toJson()).toList(),
    };
  }
}
