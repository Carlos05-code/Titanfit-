import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/reminder.dart';

final remindersProvider =
    StateNotifierProvider<RemindersNotifier, List<Reminder>>(
      (ref) => RemindersNotifier(),
    );

class RemindersNotifier extends StateNotifier<List<Reminder>> {
  final _storage = const FlutterSecureStorage();
  static const _key = 'titan_reminders';

  RemindersNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
      } else {
        state = defaultReminders
            .map(
              (r) => Reminder(
                id: r.id,
                title: r.title,
                subtitle: r.subtitle,
                icon: r.icon,
                time: r.time,
                days: List.from(r.days),
              ),
            )
            .toList();
      }
    } catch (_) {
      state = defaultReminders
          .map(
            (r) => Reminder(
              id: r.id,
              title: r.title,
              subtitle: r.subtitle,
              icon: r.icon,
              time: r.time,
              days: List.from(r.days),
            ),
          )
          .toList();
    }
  }

  Future<void> _persist() async {
    await _storage.write(
      key: _key,
      value: jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  void toggleEnabled(String id) {
    state = state.map((r) {
      if (r.id == id) r.enabled = !r.enabled;
      return r;
    }).toList();
    _persist();
  }

  void updateTime(String id, TimeOfDay time) {
    state = state.map((r) {
      if (r.id == id) r.time = time;
      return r;
    }).toList();
    _persist();
  }

  void updateDays(String id, List<int> days) {
    state = state.map((r) {
      if (r.id == id) r.days = days;
      return r;
    }).toList();
    _persist();
  }
}

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        title: const Text('Reminders'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reminders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ReminderTile(reminder: reminders[i]),
      ),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  final Reminder reminder;
  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reminder.enabled
            ? AppColors.cardBackground
            : AppColors.divider.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reminder.enabled
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  (reminder.enabled ? AppColors.primary : AppColors.textMuted)
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              reminder.icon,
              color: reminder.enabled ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: reminder.enabled
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.subtitle,
                  style: TextStyle(
                    color: reminder.enabled
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reminder.time.format(context)} · ${_daysLabel(reminder.days)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: reminder.enabled,
            onChanged: (_) =>
                ref.read(remindersProvider.notifier).toggleEnabled(reminder.id),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  String _daysLabel(List<int> days) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (days.length == 7) return 'Every day';
    if (days.every((d) => d < 5)) return 'Weekdays';
    return days.map((d) => names[d]).join(', ');
  }
}
