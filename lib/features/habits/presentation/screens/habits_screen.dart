import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/habit_provider.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(habitProvider.notifier).loadToday());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Habits')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _HabitHeader(),
                const SizedBox(height: 16),
                ...HABIT_TYPES.map((type) => _HabitTile(
                      type: type,
                      isDone: state.habits
                          .where((h) => h.type == type.key)
                          .any((h) => h.completed),
                      onToggle: () =>
                          ref.read(habitProvider.notifier).checkIn(type.key),
                    )),
              ],
            ),
    );
  }
}

const HABIT_TYPES = [
  _HabitType('WAKE_UP_EARLY', 'Wake Up Early', Icons.wb_sunny, AppColors.accentYellow),
  _HabitType('WORKOUT_COMPLETED', 'Workout', Icons.fitness_center, AppColors.primary),
  _HabitType('DRINK_WATER', 'Hydrate', Icons.water_drop, AppColors.accentBlue),
  _HabitType('EAT_HEALTHY', 'Eat Healthy', Icons.restaurant, AppColors.accent),
  _HabitType('SLEEP_ON_TIME', 'Sleep On Time', Icons.bedtime, AppColors.accentPurple),
  _HabitType('STRETCH', 'Stretch', Icons.accessibility_new, AppColors.warning),
  _HabitType('MEDITATE', 'Meditate', Icons.self_improvement, Color(0xFFE8A0BF)),
];

class _HabitType {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _HabitType(this.key, this.label, this.icon, this.color);
}

class _HabitHeader extends StatelessWidget {
  const _HabitHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentBlue.withOpacity(0.2), AppColors.accentPurple.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Discipline',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your habits to build consistency',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final _HabitType type;
  final bool isDone;
  final VoidCallback onToggle;

  const _HabitTile({
    required this.type,
    required this.isDone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isDone
                      ? type.color.withOpacity(0.2)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(type.icon, color: isDone ? type.color : AppColors.textMuted),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isDone ? type.color : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
