// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class ScheduleDetailPage extends StatefulWidget {
  const ScheduleDetailPage({required this.scheduleId, super.key});
  final String scheduleId;

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  DateTime _selectedDate = DateTime.now();
  late final DoseLogRepository _doseLogRepo;

  @override
  void initState() {
    super.initState();
    _doseLogRepo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
  }

  /// Generate unique ID using timestamp + random suffix
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'dose_$timestamp\_$random';
  }

  Future<void> _recordDoseAction({
    required Schedule schedule,
    required DateTime scheduledTime,
    required DoseAction action,
  }) async {
    final log = DoseLog(
      id: _generateId(),
      scheduleId: schedule.id,
      scheduleName: schedule.name,
      medicationId: schedule.medicationId ?? '',
      medicationName: schedule.medicationName,
      scheduledTime: scheduledTime.toUtc(),
      doseValue: schedule.doseValue,
      doseUnit: schedule.doseUnit,
      action: action,
    );

    await _doseLogRepo.upsert(log);

    if (!mounted) return;

    final actionText = action == DoseAction.taken
        ? 'taken'
        : action == DoseAction.skipped
            ? 'skipped'
            : 'snoozed for 15 minutes';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dose $actionText')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Schedule>('schedules');
    final schedule = box.get(widget.scheduleId);

    if (schedule == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Schedule not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Schedule> box, _) {
        final s = box.get(widget.scheduleId) ?? schedule;
        final nextDose = _nextOccurrence(s);

        return DetailPageScaffold(
          title: s.name,
          onEdit: () => context.push('/schedules/edit/${widget.scheduleId}'),
          onDelete: () => _confirmDelete(context, s),
          statsBannerContent: _buildScheduleHeader(context, s, nextDose),
          sections: _buildSections(context, s, nextDose),
        );
      },
    );
  }

  Widget _buildScheduleHeader(
    BuildContext context,
    Schedule s,
    DateTime? nextDose,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact header
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    s.medicationName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: s.active
                    ? Colors.green.withValues(alpha: 0.25)
                    : Colors.grey.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: s.active ? Colors.greenAccent : Colors.white54,
                ),
              ),
              child: Text(
                s.active ? 'Active' : 'Paused',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Next dose with action buttons
        if (nextDose != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          DateFormat('EEE').format(nextDose).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          DateFormat('d').format(nextDose),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(nextDose).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Dose',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            TimeOfDay.fromDateTime(nextDose).format(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatNumber(s.doseValue)} ${s.doseUnit}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getTimeUntil(nextDose),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _recordDoseAction(
                          schedule: s,
                          scheduledTime: nextDose,
                          action: DoseAction.taken,
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text(
                          'Take',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _recordDoseAction(
                          schedule: s,
                          scheduledTime: nextDose,
                          action: DoseAction.snoozed,
                        ),
                        icon: const Icon(Icons.snooze, size: 16),
                        label: const Text(
                          'Snooze',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () => _recordDoseAction(
                        schedule: s,
                        scheduledTime: nextDose,
                        action: DoseAction.skipped,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Frequency pills
        Row(
          children: [
            _buildSmallChip(
              context,
              icon: Icons.repeat,
              label: _frequencyText(s),
            ),
            const SizedBox(width: 8),
            _buildSmallChip(
              context,
              icon: Icons.schedule,
              label: _timesText(context, s),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeUntil(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.inMinutes < 60) {
      return 'in ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'in ${diff.inHours}h';
    } else {
      return 'in ${diff.inDays}d';
    }
  }

  List<Widget> _buildSections(
    BuildContext context,
    Schedule s,
    DateTime? nextDose,
  ) {
    return [
      // Week selector and daily doses
      _buildWeekSelector(context, s),

      // Schedule Details Card
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SectionFormCard(
          neutral: true,
          title: 'Schedule Details',
          children: [
            buildDetailInfoRow(
              context,
              label: 'Dose',
              value: _getDoseDisplay(s),
            ),
            buildDetailInfoRow(
              context,
              label: 'Frequency',
              value: _frequencyText(s),
            ),
            buildDetailInfoRow(
              context,
              label: 'Times',
              value: _timesText(context, s),
            ),
          ],
        ),
      ),
    ];
  }

  String _getDoseDisplay(Schedule s) {
    // TODO: Get medication from database to show strength
    // For now just show the dose
    return '${_formatNumber(s.doseValue)} ${s.doseUnit}';
  }

  Widget _buildWeekSelector(BuildContext context, Schedule s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekDays = List.generate(7, (i) => today.add(Duration(days: i)));

    // Get doses for selected date
    final selectedDoses = _getDosesForDate(_selectedDate, s);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionFormCard(
        neutral: true,
        title: 'Upcoming',
        children: [
          // Week selector - more compact
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weekDays.length,
              itemBuilder: (context, index) {
                final date = weekDays[index];
                final isSelected =
                    date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final hasDoses = _hasDosesOnDate(date, s);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 48,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isToday
                            ? Theme.of(context).colorScheme.primary.withValues(
                                alpha: kOpacityLow,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected || isToday
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('EEE').format(date),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (hasDoses) ...[
                            const SizedBox(height: 1),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Doses for selected day
          if (selectedDoses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No doses scheduled',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...selectedDoses.map((dt) => _buildDoseCard(context, dt, s)),
        ],
      ),
    );
  }

  bool _hasDosesOnDate(DateTime date, Schedule s) {
    final onDay = s.hasCycle && s.cycleEveryNDays != null
        ? (() {
            final anchor = s.cycleAnchorDate ?? DateTime.now();
            final a = DateTime(anchor.year, anchor.month, anchor.day);
            final d0 = DateTime(date.year, date.month, date.day);
            final diff = d0.difference(a).inDays;
            return diff >= 0 && diff % s.cycleEveryNDays! == 0;
          })()
        : s.daysOfWeek.contains(date.weekday);
    return onDay;
  }

  List<DateTime> _getDosesForDate(DateTime date, Schedule s) {
    final doses = <DateTime>[];
    final onDay = _hasDosesOnDate(date, s);

    if (onDay) {
      final times = s.timesOfDay ?? [s.minutesOfDay];
      for (final minutes in times) {
        final dt = DateTime(
          date.year,
          date.month,
          date.day,
          minutes ~/ 60,
          minutes % 60,
        );
        doses.add(dt);
      }
    }
    return doses;
  }

  Widget _buildDoseCard(BuildContext context, DateTime dt, Schedule s) {
    final isPast = dt.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPast
              ? Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: isPast
              ? Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                )
              : Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 18,
              color: isPast
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TimeOfDay.fromDateTime(dt).format(context),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isPast
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${_formatNumber(s.doseValue)} ${s.doseUnit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPast
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isPast)
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.outline,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  String _frequencyText(Schedule schedule) {
    if (schedule.hasCycle && schedule.cycleEveryNDays != null) {
      final n = schedule.cycleEveryNDays!;
      return 'Every $n day${n == 1 ? '' : 's'}';
    }
    final ds = schedule.daysOfWeek.toList()..sort();
    if (ds.length == 7) {
      return 'Every day';
    }
    const dlabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return ds.map((i) => dlabels[i - 1]).join(', ');
  }

  String _timesText(BuildContext context, Schedule schedule) {
    final ts = schedule.timesOfDay ?? [schedule.minutesOfDay];
    return ts
        .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context))
        .join(', ');
  }

  DateTime? _nextOccurrence(Schedule s) {
    final now = DateTime.now();
    final times = s.timesOfDay ?? [s.minutesOfDay];
    for (var d = 0; d < 60; d++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: d));
      final onDay =
          s.hasCycle && s.cycleEveryNDays != null && s.cycleEveryNDays! > 0
          ? (() {
              final anchor = s.cycleAnchorDate ?? now;
              final a = DateTime(anchor.year, anchor.month, anchor.day);
              final d0 = DateTime(date.year, date.month, date.day);
              final diff = d0.difference(a).inDays;
              return diff >= 0 && diff % s.cycleEveryNDays! == 0;
            })()
          : s.daysOfWeek.contains(date.weekday);
      if (onDay) {
        for (final minutes in times) {
          final dt = DateTime(
            date.year,
            date.month,
            date.day,
            minutes ~/ 60,
            minutes % 60,
          );
          if (dt.isAfter(now)) return dt;
        }
      }
    }
    return null;
  }

  Future<void> _confirmDelete(BuildContext context, Schedule schedule) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete schedule?'),
            content: Text(
              'Delete "${schedule.name}"? This will cancel its notifications.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok || !context.mounted) return;

    await ScheduleScheduler.cancelFor(schedule.id);
    await Hive.box<Schedule>('schedules').delete(schedule.id);
    if (context.mounted) {
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted "${schedule.name}"')));
    }
  }
}
