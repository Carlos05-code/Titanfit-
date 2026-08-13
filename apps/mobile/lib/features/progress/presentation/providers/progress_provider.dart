import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../data/repositories/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.watch(apiClientProvider));
});

class ProgressState {
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final String? error;

  const ProgressState({this.stats, this.isLoading = false, this.error});

  ProgressState copyWith({
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
  }) {
    return ProgressState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  final ProgressRepository _repo;
  ProgressNotifier(this._repo) : super(const ProgressState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true);
    try {
      final stats = await _repo.getStats();
      state = ProgressState(stats: stats);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final progressProvider = StateNotifierProvider<ProgressNotifier, ProgressState>(
  (ref) {
    return ProgressNotifier(ref.watch(progressRepositoryProvider));
  },
);
