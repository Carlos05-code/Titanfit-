import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/workout_model.dart';

class TrackedSet {
  final int setNumber;
  final int reps;
  final double weight;
  final DateTime timestamp;

  TrackedSet({
    required this.setNumber,
    this.reps = 0,
    this.weight = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'reps': reps,
    'weight': weight,
    'timestamp': timestamp.toIso8601String(),
  };
}

class SessionExercise {
  final String name;
  final List<TrackedSet> completedSets;
  int targetSets;
  int targetReps;
  double targetWeight;
  bool isComplete;

  SessionExercise({
    required this.name,
    this.completedSets = const [],
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight = 0,
    this.isComplete = false,
  });

  int get totalReps => completedSets.fold(0, (s, set) => s + set.reps);
  int get completedSetCount => completedSets.length;
}

enum SessionStatus { idle, active, paused, completed }

class WorkoutSessionState {
  final SessionStatus status;
  final String title;
  final List<SessionExercise> exercises;
  final int currentExerciseIndex;
  final int elapsedSeconds;
  final int restSecondsRemaining;
  final bool isResting;

  const WorkoutSessionState({
    this.status = SessionStatus.idle,
    this.title = '',
    this.exercises = const [],
    this.currentExerciseIndex = 0,
    this.elapsedSeconds = 0,
    this.restSecondsRemaining = 0,
    this.isResting = false,
  });

  WorkoutSessionState copyWith({
    SessionStatus? status,
    String? title,
    List<SessionExercise>? exercises,
    int? currentExerciseIndex,
    int? elapsedSeconds,
    int? restSecondsRemaining,
    bool? isResting,
  }) {
    return WorkoutSessionState(
      status: status ?? this.status,
      title: title ?? this.title,
      exercises: exercises ?? this.exercises,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
      isResting: isResting ?? this.isResting,
    );
  }

  SessionExercise? get currentExercise =>
      currentExerciseIndex < exercises.length ? exercises[currentExerciseIndex] : null;
}

class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  Timer? _timer;
  Timer? _restTimer;

  WorkoutSessionNotifier() : super(const WorkoutSessionState());

  void startSession(String title, List<ExerciseModel> exercises) {
    state = WorkoutSessionState(
      status: SessionStatus.active,
      title: title,
      exercises: exercises.map((e) => SessionExercise(
        name: e.name,
        targetSets: e.sets ?? 3,
        targetReps: e.reps ?? 10,
        targetWeight: e.weight ?? 0,
      )).toList(),
      currentExerciseIndex: 0,
      elapsedSeconds: 0,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void pauseSession() {
    _timer?.cancel();
    _restTimer?.cancel();
    state = state.copyWith(status: SessionStatus.paused, isResting: false);
  }

  void resumeSession() {
    state = state.copyWith(status: SessionStatus.active);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  TrackedSet logSet({int reps = 0, double weight = 0}) {
    final ex = state.currentExercise;
    if (ex == null) {
      return TrackedSet(setNumber: 1);
    }

    final setNumber = ex.completedSetCount + 1;
    final tracked = TrackedSet(setNumber: setNumber, reps: reps, weight: weight);
    ex.completedSets.add(tracked);
    ex.targetWeight = weight > 0 ? weight : ex.targetWeight;
    ex.targetReps = reps > 0 ? reps : ex.targetReps;

    if (ex.completedSetCount >= ex.targetSets) {
      ex.isComplete = true;
    }

    state = state.copyWith(
      exercises: [...state.exercises],
      isResting: true,
      restSecondsRemaining: 90,
    );

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.restSecondsRemaining <= 1) {
        _restTimer?.cancel();
        state = state.copyWith(isResting: false, restSecondsRemaining: 0);
      } else {
        state = state.copyWith(restSecondsRemaining: state.restSecondsRemaining - 1);
      }
    });

    return tracked;
  }

  void skipRest() {
    _restTimer?.cancel();
    state = state.copyWith(isResting: false, restSecondsRemaining: 0);
  }

  void nextExercise() {
    if (state.currentExerciseIndex < state.exercises.length - 1) {
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex + 1);
    }
  }

  void prevExercise() {
    if (state.currentExerciseIndex > 0) {
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex - 1);
    }
  }

  Map<String, dynamic> endSession() {
    _timer?.cancel();
    _restTimer?.cancel();
    final elapsed = state.elapsedSeconds;
    final totalSets = state.exercises.fold(0, (s, e) => s + e.completedSetCount);
    final totalReps = state.exercises.fold(0, (s, e) => s + e.totalReps);
    const calsPerMin = 7;
    final estCalories = (elapsed ~/ 60) * calsPerMin;

    state = state.copyWith(status: SessionStatus.completed);

    return {
      'title': state.title,
      'duration': elapsed ~/ 60,
      'calories': estCalories,
      'exercises': state.exercises.where((e) => e.completedSetCount > 0).map((e) => {
        'name': e.name,
        'sets': e.completedSetCount,
        'reps': e.targetReps,
        'weight': e.targetWeight,
      }).toList(),
      'totalSets': totalSets,
      'totalReps': totalReps,
    };
  }

  void reset() {
    _timer?.cancel();
    _restTimer?.cancel();
    state = const WorkoutSessionState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }
}

final workoutSessionProvider = StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>((ref) {
  return WorkoutSessionNotifier();
});
