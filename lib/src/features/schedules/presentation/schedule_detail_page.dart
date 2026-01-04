// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/enhanced_schedule_card.dart';
import 'package:dosifi_v5/src/widgets/calendar/dose_calendar_widget.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_header.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class ScheduleDetailPage extends StatefulWidget {
  const ScheduleDetailPage({required this.scheduleId, super.key});
  final String scheduleId;

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late final DoseLogRepository _doseLogRepo;

  String _mergedTitle(Schedule s) {
    final med = s.medicationName.trim();
    final name = s.name.trim();

    if (med.isEmpty) return name;
    if (name.isEmpty) return med;

    final nameLower = name.toLowerCase();
    final medLower = med.toLowerCase();
    if (nameLower.startsWith(medLower)) return name;

    return '$med - $name';
  }

  @override
  void initState() {
    super.initState();
    _doseLogRepo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
  }

  /// Generate unique ID using timestamp + random suffix
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'dose_$timestamp$random';
  }

  /// Check if there's already a log for this scheduled time
  DoseLog? _getExistingLog(DateTime scheduledTime) {
    final logs = _doseLogRepo.getByScheduleId(widget.scheduleId);
    final scheduledUtc = scheduledTime.toUtc();

    return logs.cast<DoseLog?>().firstWhere(
      (log) =>
          log!.scheduledTime.year == scheduledUtc.year &&
          log.scheduledTime.month == scheduledUtc.month &&
          log.scheduledTime.day == scheduledUtc.day &&
          log.scheduledTime.hour == scheduledUtc.hour &&
          log.scheduledTime.minute == scheduledUtc.minute,
      orElse: () => null,
    );
  }

  /// Show dialog to record dose with notes and injection site
  Future<void> _showRecordDoseDialog({
    required Schedule schedule,
    required DateTime scheduledTime,
    required DoseAction action,
    DoseLog? existingLog,
  }) async {
    final notesController = TextEditingController(text: existingLog?.notes);
    String? injectionSite = existingLog?.notes?.contains('Site:') == true
        ? existingLog!.notes!.split('Site:').last.trim()
        : null;

    final isInjection =
        schedule.medicationName.toLowerCase().contains('injection') ||
        schedule.doseUnit.toLowerCase().contains('syringe') ||
        schedule.doseUnit.toLowerCase().contains('vial');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DoseRecordDialog(
        action: action,
        existingLog: existingLog,
        isInjection: isInjection,
        notesController: notesController,
        initialInjectionSite: injectionSite,
      ),
    );

    if (result == null) return;

    if (result['delete'] == true && existingLog != null) {
      await _doseLogRepo.delete(existingLog.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dose log removed')));
      setState(() {});
      return;
    }

    final notes = result['notes'] as String?;
    final site = result['injectionSite'] as String?;
    final combinedNotes = [
      if (notes?.isNotEmpty == true) notes,
      if (site?.isNotEmpty == true) 'Site: $site',
    ].join('\n');

    final log = DoseLog(
      id: existingLog?.id ?? _generateId(),
      scheduleId: schedule.id,
      scheduleName: schedule.name,
      medicationId: schedule.medicationId ?? '',
      medicationName: schedule.medicationName,
      scheduledTime: scheduledTime.toUtc(),
      doseValue: schedule.doseValue,
      doseUnit: schedule.doseUnit,
      action: action,
      notes: combinedNotes.isEmpty ? null : combinedNotes,
    );

    await _doseLogRepo.upsert(log);

    if (!mounted) return;

    final actionText = action == DoseAction.taken
        ? 'taken'
        : action == DoseAction.skipped
        ? 'skipped'
        : 'snoozed for 15 minutes';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Dose $actionText')));

    setState(() {});
  }

  // Helper methods for dose action UI
  Color _getActionColor(BuildContext context, DoseAction action) {
    final cs = Theme.of(context).colorScheme;
    return switch (action) {
      DoseAction.taken => cs.primary,
      DoseAction.snoozed => cs.tertiary,
      DoseAction.skipped => cs.error,
    };
  }

  IconData _getActionIcon(DoseAction action) {
    return switch (action) {
      DoseAction.taken => Icons.check_circle,
      DoseAction.snoozed => Icons.snooze,
      DoseAction.skipped => Icons.cancel,
    };
  }

  String _getActionLabel(DoseAction action) {
    return switch (action) {
      DoseAction.taken => 'Taken',
      DoseAction.snoozed => 'Snoozed',
      DoseAction.skipped => 'Skipped',
    };
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
        final mergedTitle = _mergedTitle(s);

        return DetailPageScaffold(
          title: mergedTitle,
          onEdit: () => context.push('/schedules/edit/${widget.scheduleId}'),
          onDelete: () => _confirmDelete(context, s),
          statsBannerContent: _buildScheduleHeader(
            context,
            s,
            nextDose,
            title: mergedTitle,
          ),
          sections: _buildSections(context, s, nextDose),
        );
      },
    );
  }

  Widget _buildScheduleHeader(
    BuildContext context,
    Schedule s,
    DateTime? nextDose, {
    required String title,
  }) {
    final nextDoseText = nextDose == null
        ? 'None'
        : '${DateFormat('EEE, MMM d').format(nextDose)} • ${TimeOfDay.fromDateTime(nextDose).format(context)}';

    return DetailStatsBanner(
      title: title,
      row1Left: DetailStatItem(
        icon: Icons.medication_outlined,
        label: 'Dose',
        value: _getDoseDisplay(s),
      ),
      row1Right: DetailStatItem(
        icon: s.active ? Icons.play_circle_outline : Icons.pause_circle_outline,
        label: 'Status',
        value: s.active ? 'Active' : 'Paused',
      ),
      row2Left: DetailStatItem(
        icon: Icons.repeat,
        label: 'Frequency',
        value: _frequencyText(s),
      ),
      row2Right: DetailStatItem(
        icon: Icons.access_time,
        label: 'Times',
        value: _timesText(context, s),
      ),
      row3Left: DetailStatItem(
        icon: Icons.event,
        label: 'Next dose',
        value: nextDoseText,
      ),
      row3Right: DetailStatItem(
        icon: Icons.timer_outlined,
        label: 'In',
        value: nextDose == null ? '—' : _getTimeUntil(nextDose),
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
      _buildNextDoseCard(context, s),

      // Dose Calendar Section
      Padding(
        padding: const EdgeInsets.only(bottom: kSpacingS),
        child: SectionFormCard(
          neutral: true,
          title: 'Dose Calendar',
          children: [
            SizedBox(
              height: 400,
              child: DoseCalendarWidget(
                variant: CalendarVariant.compact,
                defaultView: CalendarView.week,
                scheduleId: s.id,
              ),
            ),
          ],
        ),
      ),

      // Schedule Details Card
      Padding(
        padding: const EdgeInsets.only(bottom: kSpacingS),
        child: SectionFormCard(
          neutral: true,
          title: 'Schedule Details',
          children: [
            buildDetailInfoRow(
              context,
              label: 'Dose',
              value: _getDoseDisplay(s),
            ),
            buildDetailInfoWidgetRow(
              context,
              label: 'Status',
              child: _buildStatusToggle(context, s),
            ),
            // Week 5: Show reconstitution badge if applicable
            if (s.medicationId != null) _buildReconstitutionBadge(s),
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
            // Week 5: Add Recalculate button for MDV schedules with reconstitution
            if (s.medicationId != null) _buildRecalculateButton(s),
          ],
        ),
      ),
    ];
  }

  Widget _buildNextDoseCard(BuildContext context, Schedule s) {
    final medId = s.medicationId;
    if (medId == null) return const SizedBox.shrink();

    final medBox = Hive.box<Medication>('medications');
    final med = medBox.get(medId);
    if (med == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingS),
      child: EnhancedScheduleCard(schedule: s, medication: med),
    );
  }

  Widget _buildStatusToggle(BuildContext context, Schedule s) {
    return Wrap(
      spacing: kSpacingS,
      runSpacing: kSpacingXS,
      children: [
        PrimaryChoiceChip(
          label: const Text('Active'),
          selected: s.active,
          onSelected: (selected) async {
            if (!selected) return;
            await _setScheduleActive(context, s, true);
          },
        ),
        PrimaryChoiceChip(
          label: const Text('Paused'),
          selected: !s.active,
          onSelected: (selected) async {
            if (!selected) return;
            await _setScheduleActive(context, s, false);
          },
        ),
      ],
    );
  }

  Future<void> _setScheduleActive(
    BuildContext context,
    Schedule s,
    bool active,
  ) async {
    if (s.active == active) return;

    try {
      final scheduleBox = Hive.box<Schedule>('schedules');
      final updated = Schedule(
        id: s.id,
        name: s.name,
        medicationName: s.medicationName,
        doseValue: s.doseValue,
        doseUnit: s.doseUnit,
        minutesOfDay: s.minutesOfDay,
        daysOfWeek: s.daysOfWeek,
        minutesOfDayUtc: s.minutesOfDayUtc,
        daysOfWeekUtc: s.daysOfWeekUtc,
        medicationId: s.medicationId,
        active: active,
        timesOfDay: s.timesOfDay,
        timesOfDayUtc: s.timesOfDayUtc,
        cycleEveryNDays: s.cycleEveryNDays,
        cycleAnchorDate: s.cycleAnchorDate,
        daysOfMonth: s.daysOfMonth,
        doseUnitCode: s.doseUnitCode,
        doseMassMcg: s.doseMassMcg,
        doseVolumeMicroliter: s.doseVolumeMicroliter,
        doseTabletQuarters: s.doseTabletQuarters,
        doseCapsules: s.doseCapsules,
        doseSyringes: s.doseSyringes,
        doseVials: s.doseVials,
        doseIU: s.doseIU,
        displayUnitCode: s.displayUnitCode,
        inputModeCode: s.inputModeCode,
        startAt: s.startAt,
        endAt: s.endAt,
        monthlyMissingDayBehaviorCode: s.monthlyMissingDayBehaviorCode,
        createdAt: s.createdAt,
      );

      await ScheduleScheduler.cancelFor(s.id);
      await scheduleBox.put(s.id, updated);

      if (updated.active) {
        await ScheduleScheduler.scheduleFor(updated);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.active ? 'Schedule resumed' : 'Schedule paused',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update schedule status: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ignore: unused_element
  Widget _buildNextDoseSection(
    BuildContext context,
    Schedule s,
    DateTime nextDose,
  ) {
    final existingLog = _getExistingLog(nextDose);
    final isTaken = existingLog?.action == DoseAction.taken;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingS),
      child: SectionFormCard(
        neutral: true,
        title: 'Next Dose',
        children: [
          buildDetailInfoRow(
            context,
            label: 'When',
            value:
                '${DateFormat('EEE, MMM d').format(nextDose)} • ${TimeOfDay.fromDateTime(nextDose).format(context)}',
            maxLines: 2,
          ),
          buildDetailInfoRow(
            context,
            label: 'Time until',
            value: _getTimeUntil(nextDose),
          ),
          if (existingLog != null)
            buildDetailInfoRow(
              context,
              label: 'Recorded',
              value:
                  '${_getActionLabel(existingLog.action)} at ${TimeOfDay.fromDateTime(existingLog.actionTime).format(context)}',
              highlighted: true,
            ),
          const SizedBox(height: kSpacingS),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showRecordDoseDialog(
                      schedule: s,
                      scheduledTime: nextDose,
                      action: DoseAction.taken,
                      existingLog: existingLog,
                    );
                  },
                  icon: Icon(
                    existingLog != null ? Icons.edit : Icons.check,
                    size: kIconSizeSmall,
                  ),
                  label: Text(existingLog != null ? 'Edit' : 'Take'),
                ),
              ),
              if (!isTaken) ...[
                const SizedBox(width: kSpacingS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showRecordDoseDialog(
                        schedule: s,
                        scheduledTime: nextDose,
                        action: DoseAction.snoozed,
                        existingLog: existingLog,
                      );
                    },
                    icon: Icon(Icons.snooze, size: kIconSizeSmall),
                    label: const Text('Snooze'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface.withValues(
                        alpha: kOpacityMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: kSpacingS),
                OutlinedButton(
                  onPressed: () {
                    _showRecordDoseDialog(
                      schedule: s,
                      scheduledTime: nextDose,
                      action: DoseAction.skipped,
                      existingLog: existingLog,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurface.withValues(
                      alpha: kOpacityMedium,
                    ),
                  ),
                  child: Icon(Icons.close, size: kIconSizeSmall),
                ),
              ],
            ],
          ),
          if (existingLog != null) ...[
            const SizedBox(height: kSpacingS),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getActionIcon(existingLog.action),
                  size: kIconSizeSmall,
                  color: _getActionColor(context, existingLog.action),
                ),
                const SizedBox(width: kSpacingXS),
                Text(
                  _getActionLabel(existingLog.action),
                  style: helperTextStyle(context)?.copyWith(
                    color: _getActionColor(context, existingLog.action),
                    fontWeight: kFontWeightSemiBold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Unified dose timeline showing past (with logs), today, and future doses
  // ignore: unused_element
  Widget _buildDoseTimeline(BuildContext context, Schedule s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get 7 days: 3 past + today + 3 future
    final days = List.generate(7, (i) => today.add(Duration(days: i - 3)));

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingS),
      child: SectionFormCard(
        neutral: true,
        title: 'Dose Timeline',
        children: [
          // Scrollable timeline
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isPast = date.isBefore(today);
                final hasDoses = _hasDosesOnDate(date, s);

                return _buildTimelineDay(
                  context,
                  s,
                  date,
                  isToday: isToday,
                  isPast: isPast,
                  hasDoses: hasDoses,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDay(
    BuildContext context,
    Schedule s,
    DateTime date, {
    required bool isToday,
    required bool isPast,
    required bool hasDoses,
  }) {
    if (!hasDoses) {
      return const SizedBox.shrink();
    }

    final doses = _getDosesForDate(date, s);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            children: [
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isToday) const SizedBox(width: 8),
              Text(
                DateFormat('EEE, MMM d').format(date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Doses for this day
          ...doses.map((dt) {
            final existingLog = _getExistingLog(dt);
            return _buildTimelineDoseCard(
              context,
              s,
              dt,
              existingLog: existingLog,
              isPast: isPast,
              isToday: isToday,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineDoseCard(
    BuildContext context,
    Schedule s,
    DateTime dt, {
    DoseLog? existingLog,
    required bool isPast,
    required bool isToday,
  }) {
    final isTaken = existingLog?.action == DoseAction.taken;
    final hasLog = existingLog != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasLog
              ? _getActionColor(
                  context,
                  existingLog.action,
                ).withValues(alpha: 0.1)
              : (isToday
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08)
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
          border: hasLog
              ? Border.all(
                  color: _getActionColor(context, existingLog.action),
                  width: 1.5,
                )
              : (isToday
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      )
                    : Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      )),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasLog ? _getActionIcon(existingLog.action) : Icons.schedule,
                  size: 18,
                  color: hasLog
                      ? _getActionColor(context, existingLog.action)
                      : (isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TimeOfDay.fromDateTime(dt).format(context),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _getDoseDisplay(s),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasLog)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getActionColor(context, existingLog.action),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getActionLabel(existingLog.action).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // Show notes and injection site if logged
            if (hasLog && existingLog.notes != null) ...[
              const SizedBox(height: 8),
              () {
                final notes = existingLog.notes!.trim();
                final hasInjectionSite = notes.contains('Site:');
                String displayNotes = notes;
                String? injectionSite;

                if (hasInjectionSite) {
                  final parts = notes.split('Site:');
                  displayNotes = parts[0].trim();
                  injectionSite = parts.length > 1 ? parts[1].trim() : null;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (displayNotes.isNotEmpty)
                      Text(
                        displayNotes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (injectionSite != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            injectionSite,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              }(),
            ],

            // Action buttons for future or today's doses
            if (!isPast || isToday) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (!isTaken) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.taken,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.check, size: 14),
                        label: Text(
                          existingLog != null ? 'Edit' : 'Take',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.snoozed,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.snooze, size: 14),
                        label: const Text(
                          'Snooze',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.skipped,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.close, size: 14),
                        label: const Text(
                          'Skip',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.taken,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDoseDisplay(Schedule s) {
    String trimZerosNumber(double value, {int decimals = 3}) {
      final fixed = value.toStringAsFixed(decimals);
      return fixed
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }

    String formatMass(int mcg) {
      if (mcg == 0) return '0 mcg';
      if (mcg.abs() >= 1000000) {
        final g = mcg / 1000000.0;
        return '${trimZerosNumber(g, decimals: 3)} g';
      }
      if (mcg.abs() >= 1000) {
        final mg = mcg / 1000.0;
        return '${trimZerosNumber(mg, decimals: 3)} mg';
      }
      return '$mcg mcg';
    }

    String formatVolume(int microliter) {
      final ml = microliter / 1000.0;
      return '${trimZerosNumber(ml, decimals: 3)} mL';
    }

    String formatCount(double count, String singular) {
      final label = (count == 1) ? singular : '${singular}s';
      return '${trimZerosNumber(count, decimals: 3)} $label';
    }

    String? countPart;
    if (s.doseTabletQuarters != null) {
      final q = s.doseTabletQuarters!;
      final count = q / 4.0;
      String amount;
      if (q == 1) {
        amount = '1/4';
      } else if (q == 2) {
        amount = '1/2';
      } else if (q == 3) {
        amount = '3/4';
      } else if (q % 4 == 0) {
        amount = (q ~/ 4).toString();
      } else {
        amount = trimZerosNumber(count, decimals: 3);
      }

      final label = (count == 1) ? 'tablet' : 'tablets';
      countPart = '$amount $label';
    } else if (s.doseCapsules != null) {
      final count = s.doseCapsules!.toDouble();
      countPart = formatCount(count, 'capsule');
    } else if (s.doseSyringes != null) {
      final count = s.doseSyringes!.toDouble();
      countPart = formatCount(count, 'syringe');
    } else if (s.doseVials != null) {
      final count = s.doseVials!.toDouble();
      countPart = formatCount(count, 'vial');
    }

    final parts = <String>[];
    if (countPart != null && countPart.isNotEmpty) {
      parts.add(countPart);
    }

    if (s.doseMassMcg != null) {
      parts.add(formatMass(s.doseMassMcg!));
    }

    if (s.doseVolumeMicroliter != null) {
      parts.add(formatVolume(s.doseVolumeMicroliter!));
    }

    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }

    // Fallback (legacy)
    return '${_formatNumber(s.doseValue)} ${s.doseUnit}'.trim();
  }

  /// Week 5: Build reconstitution badge if medication has reconstitution data
  Widget _buildReconstitutionBadge(Schedule s) {
    try {
      final medicationBox = Hive.box<Medication>('medications');
      final medication = medicationBox.get(s.medicationId);

      if (medication == null || medication.reconstitutedAt == null) {
        return const SizedBox.shrink();
      }

      final recon = medication.reconstitutedAt!;
      final expiry = medication.reconstitutedVialExpiry;
      final reconDate = '${recon.month}/${recon.day}/${recon.year}';

      String badgeText;
      Color badgeColor;
      IconData badgeIcon;

      if (expiry != null) {
        final now = DateTime.now();
        final daysLeft = expiry.difference(now).inDays;

        if (daysLeft < 0) {
          badgeText = 'Vial expired ${-daysLeft} days ago';
          badgeColor = Theme.of(context).colorScheme.error;
          badgeIcon = Icons.warning;
        } else if (daysLeft == 0) {
          badgeText = 'Vial expires today';
          badgeColor = Theme.of(context).colorScheme.error;
          badgeIcon = Icons.warning;
        } else if (daysLeft == 1) {
          badgeText = 'Vial expires tomorrow';
          badgeColor = Colors.orange;
          badgeIcon = Icons.info_outline;
        } else if (daysLeft <= 3) {
          badgeText = 'Vial expires in $daysLeft days';
          badgeColor = Colors.orange;
          badgeIcon = Icons.info_outline;
        } else {
          badgeText = 'Reconstituted on $reconDate';
          badgeColor = Theme.of(context).colorScheme.primary;
          badgeIcon = Icons.check_circle_outline;
        }
      } else {
        badgeText = 'Reconstituted on $reconDate';
        badgeColor = Theme.of(context).colorScheme.primary;
        badgeIcon = Icons.check_circle_outline;
      }

      return Padding(
        padding: const EdgeInsets.only(left: 120, top: 4, bottom: 8),
        child: Row(
          children: [
            Icon(badgeIcon, size: 14, color: badgeColor),
            const SizedBox(width: 4),
            Text(
              badgeText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  /// Week 5: Build recalculate button for MDV schedules with reconstitution
  Widget _buildRecalculateButton(Schedule s) {
    try {
      final medicationBox = Hive.box<Medication>('medications');
      final medication = medicationBox.get(s.medicationId);

      if (medication == null ||
          medication.form != MedicationForm.multiDoseVial ||
          medication.reconstitutedAt == null) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: OutlinedButton.icon(
          onPressed: () {
            // Open medication detail page which has the reconstitution calculator
            context.push('/medications/detail/${medication.id}');
          },
          icon: const Icon(Icons.calculate, size: 18),
          label: const Text('Recalculate Reconstitution'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
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

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
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
    return ScheduleOccurrenceService.nextOccurrence(s);
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

/// Dialog for recording a dose with notes and optional injection site
class _DoseRecordDialog extends StatefulWidget {
  final DoseAction action;
  final DoseLog? existingLog;
  final bool isInjection;
  final TextEditingController notesController;
  final String? initialInjectionSite;

  const _DoseRecordDialog({
    required this.action,
    required this.existingLog,
    required this.isInjection,
    required this.notesController,
    this.initialInjectionSite,
  });

  @override
  State<_DoseRecordDialog> createState() => _DoseRecordDialogState();
}

class _DoseRecordDialogState extends State<_DoseRecordDialog> {
  late final TextEditingController _injectionSiteController;

  @override
  void initState() {
    super.initState();
    _injectionSiteController = TextEditingController(
      text: widget.initialInjectionSite,
    );
  }

  @override
  void dispose() {
    _injectionSiteController.dispose();
    super.dispose();
  }

  String get _actionLabel {
    return switch (widget.action) {
      DoseAction.taken => 'Take Dose',
      DoseAction.snoozed => 'Snooze Dose',
      DoseAction.skipped => 'Skip Dose',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingLog != null ? 'Edit Dose' : _actionLabel),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notes field
            TextFormField(
              controller: widget.notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this dose...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            // Injection site field (only for injections)
            if (widget.isInjection) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _injectionSiteController,
                decoration: const InputDecoration(
                  labelText: 'Injection Site (optional)',
                  hintText: 'e.g., Left arm, Right thigh...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Delete button (if editing existing log)
        if (widget.existingLog != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop({'delete': true}),
            child: const Text('Delete'),
          ),

        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        // Save button
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            'notes': widget.notesController.text.trim(),
            'injectionSite': _injectionSiteController.text.trim(),
            'delete': false,
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
