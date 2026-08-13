import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/animated_stat_card.dart';
import '../../../../core/widgets/gradient_container.dart';
import '../../../../core/services/health_insights.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _greetAnim;

  @override
  void initState() {
    super.initState();
    _greetAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).loadStats();
    });
  }

  @override
  void dispose() {
    _greetAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final dash = ref.watch(dashboardProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: FadeTransition(
          opacity: _greetAnim,
          child: Text('${greeting()}, ${user?.name ?? 'Titan'}'),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LevelCard(xp: user?.xpPoints ?? 0, level: user?.level ?? 1),
            const SizedBox(height: 20),
            _InsightCards(),
            const SizedBox(height: 20),
            _SectionTitle(title: 'Today\'s Stats'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AnimatedStatCard(
                    icon: Icons.local_fire_department,
                    label: 'Streak',
                    value: '${user?.currentStreak ?? 0}d',
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedStatCard(
                    icon: Icons.stars,
                    label: 'Discipline',
                    value: '${user?.disciplineScore ?? 0}%',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AnimatedStatCard(
                    icon: Icons.fitness_center,
                    label: 'Workouts',
                    value: '${dash.stats?['totalWorkouts'] ?? 0}',
                    color: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedStatCard(
                    icon: Icons.bedtime,
                    label: 'Sleep',
                    value: '${dash.stats?['avgSleepScore'] ?? 0}%',
                    color: AppColors.accentPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Weekly Progress'),
            const SizedBox(height: 12),
            _WeeklyChart(stats: dash.stats),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Quick Actions'),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.fitness_center,
                  label: 'Workout',
                  color: AppColors.primary,
                  onTap: () => context.go('/workouts'),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.check_circle,
                  label: 'Habits',
                  color: AppColors.accentYellow,
                  onTap: () => context.go('/habits'),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.nightlight_round,
                  label: 'Sleep',
                  color: AppColors.accentPurple,
                  onTap: () => context.go('/sleep'),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.trending_up,
                  label: 'Progress',
                  color: AppColors.accentBlue,
                  onTap: () => context.go('/progress'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Today\'s Habit'),
            const SizedBox(height: 12),
            _HabitPreview(
              habit: 'Workout',
              done: false,
              onTap: () => context.go('/habits'),
            ),
          ],
        ),
      ),
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
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int xp;
  final int level;
  const _LevelCard({required this.xp, required this.level});

  @override
  Widget build(BuildContext context) {
    final xpInLevel = xp % 1000;
    return GradientContainer(
      colors: [AppColors.primary, AppColors.primaryDark],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LEVEL $level',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.background,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Titan Warrior',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.background.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: xpInLevel / 1000,
              backgroundColor: AppColors.background.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(AppColors.background),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${1000 - xpInLevel} XP to next level',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.background.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _WeeklyChart({this.stats});

  @override
  Widget build(BuildContext context) {
    final weekly = (stats?['weeklyWorkouts'] as List?) ?? const [];
    // Aggregate total workout minutes per day for the last 7 days.
    final totals = List<double>.filled(7, 0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final entry in weekly) {
      final date = DateTime.parse(entry['date'] as String);
      final day = DateTime(date.year, date.month, date.day);
      final diff = today.difference(day).inDays;
      if (diff >= 0 && diff < 7) {
        totals[6 - diff] += ((entry['duration'] as num?) ?? 0).toDouble();
      }
    }
    final spots = List.generate(7, (i) => FlSpot(i.toDouble(), totals[i]));
    final hasData = totals.any((t) => t > 0);

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: hasData
          ? LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppColors.divider, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(
                          days[value.toInt().clamp(0, 6)],
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: AppColors.background,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            )
          : const Center(
              child: Text(
                'Log a workout to see your weekly trend',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCards extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(healthInsightsProvider);
    return Column(
      children: [
        _RestDayCard(restSug: insights.restSug),
        if (insights.sleepRec != null) ...[
          const SizedBox(height: 8),
          _SleepRecCard(rec: insights.sleepRec!),
        ],
      ],
    );
  }
}

class _RestDayCard extends StatelessWidget {
  final RestDaySuggestion restSug;
  const _RestDayCard({required this.restSug});

  @override
  Widget build(BuildContext context) {
    final urgent = restSug.shouldRest;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: urgent
              ? [AppColors.error.withValues(alpha: 0.15), AppColors.surface]
              : [AppColors.primary.withValues(alpha: 0.1), AppColors.surface],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: urgent
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: urgent
                  ? AppColors.error.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              urgent ? Icons.restaurant : Icons.fitness_center,
              color: urgent ? AppColors.error : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restSug.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  restSug.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepRecCard extends StatelessWidget {
  final SleepRecommendation rec;
  const _SleepRecCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final color = rec.level == SleepAlertLevel.good
        ? AppColors.primary
        : rec.level == SleepAlertLevel.fair
        ? AppColors.accentYellow
        : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), AppColors.surface],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.bedtime, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (rec.tip != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '💡 ${rec.tip}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitPreview extends StatelessWidget {
  final String habit;
  final bool done;
  final VoidCallback onTap;
  const _HabitPreview({
    required this.habit,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (done ? AppColors.primary : AppColors.accentYellow)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center,
                color: done ? AppColors.primary : AppColors.accentYellow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Complete $habit',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
