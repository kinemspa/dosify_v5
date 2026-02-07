import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/schedule_status_chip.dart';

class ScheduleDetailHeaderBanner extends StatelessWidget {
  const ScheduleDetailHeaderBanner({
    required this.schedule,
    required this.nextDose,
    required this.title,
    required this.onPauseResumePressed,
    super.key,
    this.medication,
  });

  final Schedule schedule;
  final DateTime? nextDose;
  final String title;
  final VoidCallback onPauseResumePressed;
  final Medication? medication;

  @override
  Widget build(BuildContext context) {
    return DetailStatsBanner(
      title: title,
      centerTitle: false,
      headerChips: null,
      row1Left: DetailStatItem(
        icon: Icons.medication_outlined,
        label: 'Dose',
        value: _doseDisplay(schedule, medication),
      ),
      row1Right: _HeaderPauseResumeAction(
        schedule: schedule,
        onPressed: onPauseResumePressed,
      ),
      row2Left: DetailStatItem(
        icon: Icons.repeat,
        label: 'Type',
        value: _scheduleTypeText(schedule),
      ),
      row2Right: DetailStatItem(
        icon: Icons.access_time,
        label: 'Times',
        value: _timesText(context, schedule),
        alignEnd: true,
      ),
      row3Left: DetailStatItem(
        icon: Icons.event_outlined,
        label: 'Next',
        value: nextDose == null ? '—' : _nextDateText(context, nextDose!),
      ),
      row3Right: DetailStatItem(
        icon: Icons.timer_outlined,
        label: 'In',
        value: nextDose == null ? '—' : _timeUntil(nextDose!),
        alignEnd: true,
      ),
    );
  }

  String _nextDateText(BuildContext context, DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isToday) return 'Today';
    return MaterialLocalizations.of(context).formatShortMonthDay(local);
  }

  String _doseDisplay(Schedule s, Medication? med) {
    if (med != null) {
      final metrics = MedicationDisplayHelpers.doseMetricsSummary(
        med,
        doseTabletQuarters: s.doseTabletQuarters,
        doseCapsules: s.doseCapsules,
        doseSyringes: s.doseSyringes,
        doseVials: s.doseVials,
        doseMassMcg: s.doseMassMcg?.toDouble(),
        doseVolumeMicroliter: s.doseVolumeMicroliter?.toDouble(),
        syringeUnits: s.doseIU?.toDouble(),
      ).trim();

      final strength = MedicationDisplayHelpers.strengthOrConcentrationLabel(
        med,
      ).trim();

      if (metrics.isNotEmpty && strength.isNotEmpty) {
        return '$metrics • $strength';
      }
    }

    final doseValue = s.doseValue;
    final formatted = doseValue == doseValue.roundToDouble()
        ? doseValue.toStringAsFixed(0)
        : doseValue
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'\\.0+$'), '')
              .replaceFirst(RegExp(r'(\\.\\d*[1-9])0+$'), r'$1');
    return '$formatted ${s.doseUnit}';
  }

  String _scheduleTypeText(Schedule schedule) {
    if (schedule.hasCycle) return 'Cycle';
    if (schedule.hasDaysOfMonth) return 'Days of month';
    final ds = schedule.daysOfWeek.toSet();
    if (ds.isEmpty || ds.length == 7) return 'Daily';
    return 'Days of week';
  }

  String _timesText(BuildContext context, Schedule s) {
    final times = ScheduleOccurrenceService.normalizedTimesOfDay(s);
    return times
        .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60))
        .map((t) => t.format(context))
        .join(', ');
  }

  String _timeUntil(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Now';

    final minutes = diff.inMinutes;
    if (minutes < 60) return '${minutes}m';

    final hours = diff.inHours;
    if (hours < 24) return '${hours}h';

    final days = diff.inDays;
    return '${days}d';
  }
}

class _HeaderPauseResumeAction extends StatelessWidget {
  const _HeaderPauseResumeAction({
    required this.schedule,
    required this.onPressed,
  });

  final Schedule schedule;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final badge = ScheduleStatusChip(schedule: schedule, solid: true);
    if (schedule.isCompleted) return badge;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(kBorderRadiusChipTight),
      child: badge,
    );
  }
}
