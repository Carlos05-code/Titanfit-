import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/services/health_insights.dart';
import '../providers/sleep_provider.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sleepProvider.notifier).loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sleepProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Sleep'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _logSleep(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SleepScoreCard(score: state.avgScore.toInt(), avgDuration: state.avgDuration),
            const SizedBox(height: 16),
            _SleepRecBanner(),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'This Week'),
            const SizedBox(height: 12),
            _SleepWeeklyChart(records: state.records),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Recent Records'),
            const SizedBox(height: 12),
            if (state.records.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No sleep records yet', style: TextStyle(color: AppColors.textMuted)),
              ))
            else
              ...state.records.map((r) => _SleepRecordCard(r)),
          ],
        ),
      ),
    );
  }

  void _logSleep(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => _LogSleepSheet(onLog: (sleepTime, wakeTime) {
        ref.read(sleepProvider.notifier).recordSleep(sleepTime, wakeTime);
        Navigator.pop(ctx);
      }),
    );
  }
}

class _SleepScoreCard extends StatelessWidget {
  final int score;
  final double avgDuration;
  const _SleepScoreCard({required this.score, required this.avgDuration});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? AppColors.primary : score >= 60 ? AppColors.accentYellow : Colors.redAccent;
    final hours = avgDuration > 0 ? avgDuration.toStringAsFixed(1) : '--';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cardBackground, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90, height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90, height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text('$score', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sleep Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  score >= 80 ? 'Great sleep quality!' : score >= 60 ? 'Room for improvement' : 'Needs work',
                  style: TextStyle(color: color, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.bedtime, size: 16, color: AppColors.accentPurple),
                    const SizedBox(width: 4),
                    Text('${hours}h avg', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepRecBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(healthInsightsProvider);
    final rec = insights.sleepRec;
    if (rec == null) return const SizedBox.shrink();

    final color = rec.level == SleepAlertLevel.good
        ? AppColors.primary
        : rec.level == SleepAlertLevel.fair
            ? AppColors.accentYellow
            : AppColors.error;

    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.12), AppColors.surface],
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
              child: Icon(
                rec.level == SleepAlertLevel.good ? Icons.check_circle : Icons.info_outline,
                color: color, size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rec.title, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(rec.message, style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  if (rec.tip != null) ...[
                    const SizedBox(height: 4),
                    Text('💡 ${rec.tip}', style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepWeeklyChart extends StatelessWidget {
  final List<dynamic> records;
  const _SleepWeeklyChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final last7 = records.take(7).toList().reversed.toList();
    final spots = List.generate(last7.length, (i) {
      final r = last7[i];
      return FlSpot(i.toDouble(), (r.duration as num?)?.toDouble() ?? 7.0);
    });

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: spots.isEmpty
        ? const Center(child: Text('No data', style: TextStyle(color: AppColors.textMuted)))
        : LineChart(LineChartData(
            gridData: FlGridData(
              show: true,
              horizontalInterval: 2,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(color: AppColors.divider, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    return Text(days[value.toInt().clamp(0, 6)], style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.accentPurple,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4, color: AppColors.accentPurple, strokeWidth: 2, strokeColor: AppColors.background,
                  ),
                ),
                belowBarData: BarAreaData(show: true, color: AppColors.accentPurple.withValues(alpha: 0.1)),
              ),
            ],
          )),
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

class _SleepRecordCard extends StatelessWidget {
  final dynamic record;
  const _SleepRecordCard(this.record);

  @override
  Widget build(BuildContext context) {
    final score = record.score.toInt();
    final color = score >= 80 ? AppColors.primary : score >= 60 ? AppColors.accentYellow : Colors.redAccent;
    final duration = record.duration;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bedtime, color: AppColors.accentPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${duration.toStringAsFixed(1)} hours',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.stars, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text('Score: $score', style: TextStyle(color: color, fontSize: 12)),
                    const SizedBox(width: 16),
                    Text(formatDate(record.createdAt ?? DateTime.now()),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogSleepSheet extends StatefulWidget {
  final void Function(String sleepTime, String wakeTime) onLog;
  const _LogSleepSheet({required this.onLog});

  @override
  State<_LogSleepSheet> createState() => _LogSleepSheetState();
}

class _LogSleepSheetState extends State<_LogSleepSheet> {
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Log Sleep', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.nightlight_round, color: AppColors.accentPurple),
            title: const Text('Sleep Time', style: TextStyle(color: AppColors.textSecondary)),
            trailing: Text(_sleepTime.format(context), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _sleepTime);
              if (t != null) setState(() => _sleepTime = t);
            },
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny, color: AppColors.accentYellow),
            title: const Text('Wake Time', style: TextStyle(color: AppColors.textSecondary)),
            trailing: Text(_wakeTime.format(context), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _wakeTime);
              if (t != null) setState(() => _wakeTime = t);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                final sleepDt = DateTime(now.year, now.month, now.day, _sleepTime.hour, _sleepTime.minute);
                final wakeDt = DateTime(now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
                widget.onLog(sleepDt.toIso8601String(), wakeDt.toIso8601String());
              },
              child: const Text('SAVE'),
            ),
          ),
        ],
      ),
    );
  }
}
