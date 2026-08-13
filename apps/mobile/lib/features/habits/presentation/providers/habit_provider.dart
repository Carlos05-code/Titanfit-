import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../data/models/habit_model.dart';
import '../../data/repositories/habit_repository.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(ref.watch(apiClientProvider));
});

class HabitState {
  final List<HabitModel> habits;
  final bool isLoading;
  final String? error;

  const HabitState({
    this.habits = const [],
    this.isLoading = false,
    this.error,
  });

  HabitState copyWith({
    List<HabitModel>? habits,
    bool? isLoading,
    String? error,
  }) {
    return HabitState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class HabitNotifier extends StateNotifier<HabitState> {
  final HabitRepository _repo;
  HabitNotifier(this._repo) : super(const HabitState());

  Future<void> loadToday() async {
    state = state.copyWith(isLoading: true);
    try {
      final habits = await _repo.getToday();
      state = HabitState(habits: habits);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> checkIn(String type) async {
    try {
      await _repo.checkIn(type);
      await loadToday();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, HabitState>((ref) {
  return HabitNotifier(ref.watch(habitRepositoryProvider));
});
