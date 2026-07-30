import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/sleep/data/models/sleep_record.dart';
import '../../features/sleep/presentation/providers/sleep_provider.dart';
import '../../features/workout/data/models/workout_model.dart';
import '../../features/workout/presentation/providers/workout_provider.dart';

class SleepRecommendation {
  final String title;
  final String message;
  final SleepAlertLevel level;
  final String? tip;

  const SleepRecommendation({
    required this.title,
    required this.message,
    required this.level,
    this.tip,
  });
}

enum SleepAlertLevel { good, fair, poor }

class RestDaySuggestion {
  final String title;
  final String message;
  final bool shouldRest;
  final int consecutiveDays;

  const RestDaySuggestion({
    required this.title,
    required this.message,
    required this.shouldRest,
    required this.consecutiveDays,
  });
}

class HealthInsights {
  static const double optimalMin = 7.0;
  static const double optimalMax = 9.0;
  static const double fairMin = 6.0;
  static const double fairMax = 10.0;
  static const int maxConsecutiveWorkouts = 4;

  static SleepRecommendation? analyzeSleep(List<SleepRecord> records) {
    if (records.isEmpty) return null;

    final now = DateTime.now();
    final last7 = records.where((r) =>
      r.sleepTime.isAfter(now.subtract(const Duration(days: 7)))
    ).toList();

    if (last7.isEmpty) return null;

    final avg = last7.fold<double>(0, (s, r) => s + r.duration) / last7.length;
    final shortNights = last7.where((r) => r.duration < optimalMin).length;
    final lastNight = last7.isNotEmpty ? last7.first.duration : 0;
    final chronic = shortNights >= 3;

    if (avg >= optimalMin && avg <= optimalMax && !chronic && lastNight >= optimalMin) {
      return SleepRecommendation(
        title: 'Sleep is on track',
        message: 'Averaging ${avg.toStringAsFixed(1)}h — keep it up!',
        level: SleepAlertLevel.good,
        tip: 'Maintain a consistent bedtime for best results.',
      );
    }

    if (chronic || avg < fairMin || avg > fairMax) {
      final isShort = avg < optimalMin;
      return SleepRecommendation(
        title: isShort ? '⚠️ Sleep debt accumulating' : '⚠️ Oversleeping detected',
        message: isShort
            ? 'Only ${avg.toStringAsFixed(1)}h avg over the last 7 days. '
              'You\'ve had $shortNights short nights. Chronic sleep loss impairs recovery, focus, and immune function.'
            : 'Averaging ${avg.toStringAsFixed(1)}h. Oversleeping can leave you groggy and disrupt your schedule.',
        level: SleepAlertLevel.poor,
        tip: isShort
            ? 'Try sleeping 30 min earlier each night this week.'
            : 'Aim for 7-9 hours. Try setting a consistent wake-up alarm.',
      );
    }

    if (lastNight < optimalMin) {
      return SleepRecommendation(
        title: '🌙 Recover tonight',
        message: 'You got ${lastNight.toStringAsFixed(1)}h last night. '
          'Aim for at least ${optimalMin}h tonight to stay sharp.',
        level: SleepAlertLevel.fair,
        tip: 'Avoid screens 30 min before bed and keep your room cool.',
      );
    }

    return SleepRecommendation(
      title: avg < optimalMin
          ? '📉 Slightly below target'
          : '📈 Slightly above target',
      message: avg < optimalMin
          ? 'Averaging ${avg.toStringAsFixed(1)}h — close to the ${optimalMin}h goal.'
          : 'Averaging ${avg.toStringAsFixed(1)}h — a bit over the ${optimalMax}h recommendation.',
      level: SleepAlertLevel.fair,
      tip: avg < optimalMin
          ? 'Even 15 extra minutes makes a difference.'
          : 'Try winding down a bit earlier.',
    );
  }

  static RestDaySuggestion suggestRestDay(List<WorkoutModel> workouts, {List<SleepRecord>? sleepRecords}) {
    if (workouts.isEmpty) {
      return const RestDaySuggestion(
        title: 'Start your journey',
        message: 'No workouts logged yet. Ready to begin?',
        shouldRest: false,
        consecutiveDays: 0,
      );
    }

    final sorted = List<WorkoutModel>.from(workouts)
      ..sort((a, b) => b.date.compareTo(a.date));

    int consecutive = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final w in sorted) {
      final wDate = DateTime(w.date.year, w.date.month, w.date.day);
      final expected = today.subtract(Duration(days: consecutive));
      if (wDate == expected) {
        consecutive++;
      } else {
        break;
      }
    }

    final weekCount = sorted.where((w) =>
      w.date.isAfter(now.subtract(const Duration(days: 7)))
    ).length;

    if (consecutive >= maxConsecutiveWorkouts) {
      return RestDaySuggestion(
        title: '🛑 Rest day recommended',
        message: 'You\'ve worked out $consecutive days straight! '
          'Your muscles need 24-48h to repair and grow. Take a day off to prevent injury and improve gains.',
        shouldRest: true,
        consecutiveDays: consecutive,
      );
    }

    if (weekCount >= 6) {
      return RestDaySuggestion(
        title: '⚡ High training load',
        message: '$weekCount workouts this week. Consider a rest day to avoid overtraining syndrome.',
        shouldRest: true,
        consecutiveDays: consecutive,
      );
    }

    if (weekCount >= 5) {
      return RestDaySuggestion(
        title: '💪 Great consistency',
        message: '$weekCount workouts this week. You\'re on track for excellent results.',
        shouldRest: false,
        consecutiveDays: consecutive,
      );
    }

    return RestDaySuggestion(
      title: '✅ On the right track',
      message: '$weekCount workouts this week. Keep showing up!',
      shouldRest: false,
      consecutiveDays: consecutive,
    );
  }
}

class HealthInsightsState {
  final SleepRecommendation? sleepRec;
  final RestDaySuggestion restSug;

  const HealthInsightsState({this.sleepRec, required this.restSug});
}

final healthInsightsProvider = Provider<HealthInsightsState>((ref) {
  final sleepState = ref.watch(sleepProvider);
  final workoutState = ref.watch(workoutProvider);
  return HealthInsightsState(
    sleepRec: HealthInsights.analyzeSleep(sleepState.records),
    restSug: HealthInsights.suggestRestDay(workoutState.workouts, sleepRecords: sleepState.records),
  );
});
