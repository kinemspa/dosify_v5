import 'package:flutter/material.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:skedux/src/widgets/detail_page_scaffold.dart';
import 'package:skedux/src/widgets/schedule_status_chip.dart';

class ScheduleDetailHeaderBanner extends StatelessWidget {
  const ScheduleDetailHeaderBanner({
    required this.schedule,
    required this.nextEntry,
    required this.title,
    required this.onPauseResumePressed,
    super.key,
    this.medication,
  });

  final Schedule schedule;
  final DateTime? nextEntry;
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
        label: 'Entry',
        value: _entryDisplay(schedule, medication),
        valueMaxLines: 4,
      ),
      row1Right: _HeaderPauseResumeAction(
        schedule: schedule,
        onPressed: onPauseResumePressed,
      ),
      row2Left: DetailStatItem(
        icon: Icons.repeat,
        label: 'Frequency',
        value: _scheduleTypeText(schedule),
        valueMaxLines: schedule.hasDaysOfMonth ? 3 : 1,
      ),
      row2Right: DetailStatItem(
        icon: Icons.access_time,
        label: 'Times',
        value: _timesText(context, schedule),
        alignEnd: true,
        valueMaxLines: 6,
      ),
      row3Left: DetailStatItem(
        icon: Icons.event_outlined,
        label: 'Next',
        value: nextEntry == null ? '—' : _nextDateText(context, nextEntry!),
      ),
      row3Right: DetailStatItem(
        icon: Icons.timer_outlined,
        label: 'In',
        value: nextEntry == null ? '—' : _timeUntil(nextEntry!),
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

  String _entryDisplay(Schedule s, Medication? med) {
    if (med != null) {
      final showSlash =
          s.entryVolumeMicroliter != null &&
          (s.entryIU != null || med.form == MedicationForm.multiDoseVial);

      final metricsLine = MedicationDisplayHelpers.entryMetricsSummary(
        med,
        entryTabletQuarters: s.entryTabletQuarters,
        entryCapsules: s.entryCapsules,
        entrySyringes: s.entrySyringes,
        entryVials: s.entryVials,
        entryVolumeMicroliter: s.entryVolumeMicroliter?.toDouble(),
        syringeUnits: s.entryIU?.toDouble(),
        entryMassMcg: null,
        separator: showSlash ? ' / ' : ' × ',
      ).trim();

      final strengthLabel =
          MedicationDisplayHelpers.strengthOrConcentrationLabel(med).trim();
      final normalizedStrengthLabel = strengthLabel.replaceFirst(
        RegExp(
          r'^(med\s+strength|tablet\s+strength|strength)\s*[:\-]?\s*',
          caseSensitive: false,
        ),
        '',
      );

      final lines = <String>[];
      if (metricsLine.isNotEmpty) lines.add(metricsLine);
      if (normalizedStrengthLabel.isNotEmpty) {
        final strengthPrefix = med.form == MedicationForm.tablet
            ? 'Tablet Strength'
            : 'Med Strength';
        lines.add('$strengthPrefix - $normalizedStrengthLabel');
      }
      if (s.entryMassMcg != null) {
        lines.add(
          'Entry strength - ${MedicationDisplayHelpers.formatEntryMassFromMcg(med, s.entryMassMcg!.toDouble())}',
        );
      }

      if (lines.isNotEmpty) return lines.join('\n');
    }

    final entryValue = s.entryValue;
    final formatted = entryValue == entryValue.roundToDouble()
        ? entryValue.toStringAsFixed(0)
        : entryValue
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'\\.0+$'), '')
              .replaceFirst(RegExp(r'(\\.\\d*[1-9])0+$'), r'$1');
    return '$formatted ${s.entryUnit}';
  }

  String _scheduleTypeText(Schedule schedule) {
    if (schedule.hasCycle) return 'Cycle';
    if (schedule.hasDaysOfMonth) {
      final days = (schedule.daysOfMonth ?? const <int>[]).toList()..sort();
      if (days.isEmpty) return 'Days of month';
      return 'Days of month\n${days.join(', ')}';
    }
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
    final cs = Theme.of(context).colorScheme;
    final badge = ScheduleStatusChip(schedule: schedule, solid: true);
    if (schedule.isCompleted) return badge;

    // Hint icon beside the badge shows the action available (pause vs resume).
    // Always use onPrimary because the banner renders over the gradient header.
    final isActive = schedule.status == ScheduleStatus.active;
    final hintIcon = isActive
        ? Icons.pause_circle_outline_rounded
        : Icons.play_circle_outline_rounded;

    final button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(kBorderRadiusChipTight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingS,
          vertical: kSpacingXXS,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge,
            const SizedBox(width: kSpacingXXS),
            Icon(
              hintIcon,
              size: kIconSizeXSmall,
              color: cs.onPrimary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );

    final pausedUntil = schedule.pausedUntil;
    if (!isActive && pausedUntil != null) {
      final formatted = MaterialLocalizations.of(
        context,
      ).formatShortMonthDay(pausedUntil.toLocal());
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          button,
          const SizedBox(height: kSpacingXXS),
          Text(
            'Until $formatted',
            style: microHelperTextStyle(
              context,
              color: cs.onPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }

    return button;
  }
}
