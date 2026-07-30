import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../data/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

class DashboardState {
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final String? error;

  const DashboardState({this.stats, this.isLoading = false, this.error});

  DashboardState copyWith({
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repo;
  DashboardNotifier(this._repo) : super(const DashboardState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _repo.getStats();
      state = DashboardState(stats: stats);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.watch(dashboardRepositoryProvider));
});
