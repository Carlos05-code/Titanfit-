import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/workout_provider.dart';
import '../providers/workout_session_provider.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseAnim;
  final _repsCtrl = TextEditingController(text: '10');
  final _weightCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(workoutSessionProvider);
    final ex = session.currentExercise;
    final elapsedStr = _formatTime(session.elapsedSeconds);

    if (session.status == SessionStatus.idle) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('No active workout')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(session.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmEnd(context),
        ),
        actions: [
          if (session.status == SessionStatus.active)
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () =>
                  ref.read(workoutSessionProvider.notifier).pauseSession(),
            )
          else if (session.status == SessionStatus.paused)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () =>
                  ref.read(workoutSessionProvider.notifier).resumeSession(),
            ),
        ],
      ),
      body: Column(
        children: [
          _TimerBar(elapsedStr: elapsedStr, status: session.status),
          if (session.status == SessionStatus.paused)
            Expanded(
              child: _PausedOverlay(
                onResume: () {
                  ref.read(workoutSessionProvider.notifier).resumeSession();
                },
              ),
            )
          else if (session.status == SessionStatus.completed)
            Expanded(
              child: _CompletedOverlay(
                onFinish: () {
                  context.pop();
                },
              ),
            )
          else
            Expanded(
              child: ex == null
                  ? const Center(
                      child: Text(
                        'All done!',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 24,
                        ),
                      ),
                    )
                  : _buildActiveSession(session, ex),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveSession(WorkoutSessionState session, SessionExercise ex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ProgressDots(
            total: session.exercises.length,
            current: session.currentExerciseIndex,
            completed: session.exercises.where((e) => e.isComplete).length,
          ),
          const SizedBox(height: 24),
          if (session.isResting) ...[
            _RestTimer(
              seconds: session.restSecondsRemaining,
              onSkip: () =>
                  ref.read(workoutSessionProvider.notifier).skipRest(),
            ),
            const SizedBox(height: 16),
          ],
          _ExerciseCard(
            name: ex.name,
            setCurrent: ex.completedSetCount + 1,
            setTarget: ex.targetSets,
            repsTarget: ex.targetReps,
          ),
          const SizedBox(height: 20),
          if (ex.completedSetCount >= ex.targetSets)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'All sets completed! Move to next exercise',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          _QuickRepSelector(controller: _repsCtrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _logSet,
                    icon: const Icon(Icons.fitness_center, size: 22),
                    label: Text(
                      'Log Set ${ex.completedSetCount + 1}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (ex.completedSets.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Completed Sets',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...ex.completedSets.map(
              (s) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${s.setNumber}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${s.reps} reps',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (s.weight > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '@ ${s.weight}kg',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      formatTimeOfDay(s.timestamp),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                if (session.currentExerciseIndex <
                    session.exercises.length - 1) {
                  ref.read(workoutSessionProvider.notifier).nextExercise();
                  _repsCtrl.text = session
                      .exercises[session.currentExerciseIndex + 1]
                      .targetReps
                      .toString();
                  _weightCtrl.text = session
                      .exercises[session.currentExerciseIndex + 1]
                      .targetWeight
                      .toString();
                }
              },
              icon: const Icon(Icons.skip_next),
              label: Text(
                session.currentExerciseIndex < session.exercises.length - 1
                    ? 'Next: ${session.exercises[session.currentExerciseIndex + 1].name}'
                    : 'Finish Workout',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logSet() {
    final reps = int.tryParse(_repsCtrl.text) ?? 10;
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    ref
        .read(workoutSessionProvider.notifier)
        .logSet(reps: reps, weight: weight);
    _pulseAnim.forward().then((_) => _pulseAnim.reverse());
  }

  void _confirmEnd(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('End Workout?'),
        content: const Text('Progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final data = ref
                  .read(workoutSessionProvider.notifier)
                  .endSession();
              ref.read(workoutProvider.notifier).createWorkout(data);
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('SAVE & FINISH'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _TimerBar extends StatelessWidget {
  final String elapsedStr;
  final SessionStatus status;
  const _TimerBar({required this.elapsedStr, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == SessionStatus.paused
                ? Icons.pause_circle_filled
                : Icons.timer,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            elapsedStr,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int total, current, completed;
  const _ProgressDots({
    required this.total,
    required this.current,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        Color color = AppColors.divider;
        if (i < completed) {
          color = AppColors.primary;
        } else if (i == current) {
          color = AppColors.accent;
        }
        return Container(
          width: i == current ? 28 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}

class _RestTimer extends StatelessWidget {
  final int seconds;
  final VoidCallback onSkip;
  const _RestTimer({required this.seconds, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final progressing = 1 - (seconds / 90);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REST',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${seconds}s',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressing,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onSkip,
            child: const Text(
              'Skip →',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final String name;
  final int setCurrent, setTarget, repsTarget;
  const _ExerciseCard({
    required this.name,
    required this.setCurrent,
    required this.setTarget,
    required this.repsTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.fitness_center, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set $setCurrent of $setTarget · $repsTarget reps',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickRepSelector extends StatelessWidget {
  final TextEditingController controller;
  const _QuickRepSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Reps: ',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        ...['6', '8', '10', '12', '15'].map(
          (r) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                controller.text = r;
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: r.length),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: controller.text == r
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: controller.text == r
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
                child: Text(
                  r,
                  style: TextStyle(
                    color: controller.text == r
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  final VoidCallback onResume;
  const _PausedOverlay({required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pause_circle_outline,
            size: 72,
            color: AppColors.accent,
          ),
          const SizedBox(height: 16),
          const Text(
            'PAUSED',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text(
              'RESUME',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedOverlay extends StatelessWidget {
  final VoidCallback onFinish;
  const _CompletedOverlay({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 72,
              color: AppColors.accentYellow,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'WORKOUT COMPLETE!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Great job, Titan',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onFinish,
            icon: const Icon(Icons.check, size: 24),
            label: const Text(
              'DONE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
