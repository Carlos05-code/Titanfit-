import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../data/models/sleep_record.dart';
import '../../data/repositories/sleep_repository.dart';

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  return SleepRepository(ref.watch(apiClientProvider));
});

class SleepState {
  final List<SleepRecord> records;
  final bool isLoading;
  final String? error;
  final double avgScore;
  final double avgDuration;

  const SleepState({
    this.records = const [],
    this.isLoading = false,
    this.error,
    this.avgScore = 0,
    this.avgDuration = 0,
  });

  SleepState copyWith({
    List<SleepRecord>? records,
    bool? isLoading,
    String? error,
    double? avgScore,
    double? avgDuration,
  }) {
    return SleepState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      avgScore: avgScore ?? this.avgScore,
      avgDuration: avgDuration ?? this.avgDuration,
    );
  }
}

class SleepNotifier extends StateNotifier<SleepState> {
  final SleepRepository _repo;
  SleepNotifier(this._repo) : super(const SleepState());

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repo.getHistory();
      final records = (data['records'] as List)
          .map((e) => SleepRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      state = SleepState(
        records: records,
        avgScore: (data['avgScore'] as num?)?.toDouble() ?? 0,
        avgDuration: (data['avgDuration'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> recordSleep(String sleepTime, String wakeTime) async {
    try {
      await _repo.record(sleepTime, wakeTime);
      await loadHistory();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final sleepProvider = StateNotifierProvider<SleepNotifier, SleepState>((ref) {
  return SleepNotifier(ref.watch(sleepRepositoryProvider));
});
