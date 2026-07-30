import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../data/models/workout_model.dart';
import '../../data/repositories/workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(apiClientProvider));
});

class WorkoutState {
  final List<WorkoutModel> workouts;
  final bool isLoading;
  final String? error;

  const WorkoutState({
    this.workouts = const [],
    this.isLoading = false,
    this.error,
  });

  WorkoutState copyWith({
    List<WorkoutModel>? workouts,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutState(
      workouts: workouts ?? this.workouts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final WorkoutRepository _repository;
  WorkoutNotifier(this._repository) : super(const WorkoutState());

  Future<void> loadWorkouts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final workouts = await _repository.getAll();
      state = WorkoutState(workouts: workouts);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createWorkout(Map<String, dynamic> data) async {
    try {
      await _repository.create(data);
      await loadWorkouts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteWorkout(String id) async {
    try {
      await _repository.delete(id);
      await loadWorkouts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addExerciseToWorkout(String workoutId, Map<String, dynamic> exerciseData) async {
    try {
      await _repository.addExercise(workoutId, exerciseData);
      await loadWorkouts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  return WorkoutNotifier(ref.watch(workoutRepositoryProvider));
});
