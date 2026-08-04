import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_container.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/progress_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(progressProvider.notifier).loadStats());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Progress'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientContainer(
              colors: [AppColors.accentPurple, AppColors.primaryDark],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.background)),
                  const SizedBox(height: 4),
                  Text('Your journey so far', style: TextStyle(fontSize: 13, color: AppColors.background.withValues(alpha: 0.8))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(value: '${state.stats?['totalWorkouts'] ?? 0}', label: 'Workouts'),
                      _StatItem(value: '${state.stats?['totalHabits'] ?? 0}', label: 'Habits'),
                      _StatItem(value: '${state.stats?['avgSleepScore'] ?? 0}', label: 'Sleep Avg'),
                      _StatItem(value: '${state.stats?['achievements'] ?? 0}', label: 'Achievements'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Workout Volume'),
            const SizedBox(height: 12),
            _VolumeChart(),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Sleep Quality'),
            const SizedBox(height: 12),
            _SleepChart(),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Achievements'),
            const SizedBox(height: 12),
            _AchievementGrid(stats: state.stats),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Body Stats'),
            const SizedBox(height: 12),
            _BodyStats(user: user),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.background)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.background.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 18,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _VolumeChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rng = Random(42);
    final barData = List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: 30 + rng.nextDouble() * 170,
            color: AppColors.primary,
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 200,
              color: AppColors.divider,
            ),
          ),
        ],
      );
    });

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Text(days[value.toInt().clamp(0, 6)],
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barData,
      )),
    );
  }
}

class _SleepChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rng = Random(7);
    final data = List.generate(7, (i) {
      return PieChartSectionData(
        value: 20 + rng.nextDouble() * 60,
        color: [AppColors.accentPurple, AppColors.primary, AppColors.accentBlue][i % 3],
        radius: 28,
        title: '${(5 + i)}h',
        titleStyle: const TextStyle(fontSize: 9, color: AppColors.background, fontWeight: FontWeight.bold),
      );
    });

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(PieChartData(
              sections: data,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            )),
          ),
          const SizedBox(width: 16),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendDot(color: AppColors.accentPurple, label: 'Deep'),
              SizedBox(height: 8),
              _LegendDot(color: AppColors.primary, label: 'Light'),
              SizedBox(height: 8),
              _LegendDot(color: AppColors.accentBlue, label: 'REM'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _AchievementGrid({this.stats});

  @override
  Widget build(BuildContext context) {
    final unlocked = [
      {'icon': Icons.emoji_events, 'label': 'First Workout', 'unlocked': true},
      {'icon': Icons.local_fire_department, 'label': '7-Day Streak', 'unlocked': (stats?['totalWorkouts'] ?? 0) >= 7},
      {'icon': Icons.bedtime, 'label': 'Sleep Master', 'unlocked': (stats?['avgSleepScore'] ?? 0) >= 80},
      {'icon': Icons.fitness_center, 'label': '100 Workouts', 'unlocked': (stats?['totalWorkouts'] ?? 0) >= 100},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: unlocked.length,
      itemBuilder: (_, i) => _AchievementBadge(data: unlocked[i]),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AchievementBadge({required this.data});

  @override
  Widget build(BuildContext context) {
    final unlocked = data['unlocked'] as bool;
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? AppColors.cardBackground : AppColors.divider.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            data['icon'] as IconData,
            color: unlocked ? AppColors.accentYellow : AppColors.textMuted,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            data['label'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: unlocked ? AppColors.textSecondary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyStats extends StatelessWidget {
  final dynamic user;
  const _BodyStats({this.user});

  @override
  Widget build(BuildContext context) {
    final weight = user?.weight;
    final height = user?.height;
    final bmi = (weight != null && height != null && height > 0)
        ? (weight / ((height / 100) * (height / 100))).toStringAsFixed(1)
        : '--';

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Icon(Icons.monitor_weight, color: AppColors.primary),
                const SizedBox(height: 8),
                const Text('Weight', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(weight != null ? '$weight kg' : '--',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Icon(Icons.straighten, color: AppColors.accentBlue),
                const SizedBox(height: 8),
                const Text('Height', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(height != null ? '$height cm' : '--',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Icon(Icons.calculate, color: AppColors.accent),
                const SizedBox(height: 8),
                const Text('BMI', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(bmi,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: bmi != '--'
                        ? (double.parse(bmi) < 18.5
                            ? AppColors.accentYellow
                            : double.parse(bmi) < 25
                                ? AppColors.primary
                                : AppColors.error)
                        : AppColors.textPrimary,
                  )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
