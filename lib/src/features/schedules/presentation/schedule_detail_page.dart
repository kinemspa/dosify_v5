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
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/pages/add_schedule_wizard_page.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_status_ui.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/next_dose_date_badge.dart';
import 'package:dosifi_v5/src/widgets/schedule_status_chip.dart';
import 'package:dosifi_v5/src/widgets/schedule_pause_dialog.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class ScheduleDetailPage extends StatefulWidget {
  const ScheduleDetailPage({required this.scheduleId, super.key});
  final String scheduleId;

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late final DoseLogRepository _doseLogRepo;

  Future<void> _openEditScheduleDialog(Schedule schedule) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kBorderRadiusLarge),
        ),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: AddScheduleWizardPage(initial: schedule),
        );
      },
    );
  }

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
                size: kEmptyStateIconSize,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: kSpacingL),
              Text('Schedule not found', style: sectionTitleStyle(context)),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Schedule> box, _) {
        try {
          final s = box.get(widget.scheduleId) ?? schedule;
          final nextDose = _nextOccurrence(s);
          final mergedTitle = _mergedTitle(s);

          return DetailPageScaffold(
            title: 'Schedule Details',
            expandedTitle: mergedTitle,
            expandedHeight: kDetailHeaderExpandedHeightCompact,
            onEdit: () => _openEditScheduleDialog(s),
            onDelete: () => _confirmDelete(context, s),
            statsBannerContent: _buildScheduleHeader(
              context,
              s,
              nextDose,
              title: mergedTitle,
            ),
            sections: _buildSections(context, s, nextDose),
          );
        } catch (e) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(kSpacingXXL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: kEmptyStateIconSize,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: kSpacingM),
                      Text(
                        'Unable to open schedule details',
                        style: sectionTitleStyle(context),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: kSpacingM),
                      FilledButton(
                        onPressed: () => context.pop(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildScheduleHeader(
    BuildContext context,
    Schedule s,
    DateTime? nextDose, {
    required String title,
  }) {
    final cs = Theme.of(context).colorScheme;
    final headerOnPrimary = cs.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Details',
          style: helperTextStyle(
            context,
            color: headerOnPrimary.withValues(alpha: kOpacityMediumHigh),
          )?.copyWith(fontWeight: kFontWeightSemiBold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: kSpacingXXS),
        Text(
          title,
          style: detailHeaderBannerTitleTextStyle(
            context,
          )?.copyWith(color: headerOnPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: kSpacingM),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DetailStatItem(
                icon: Icons.medication_outlined,
                label: 'Dose',
                value: _getDoseDisplay(s),
              ),
            ),
            const SizedBox(width: kPageHorizontalPadding),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildHeaderStatusBadge(context, s),
              ),
            ),
          ],
        ),
        const SizedBox(height: kCardInnerSpacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DetailStatItem(
                icon: Icons.repeat,
                label: 'Type',
                value: _scheduleTypeText(s),
              ),
            ),
            const SizedBox(width: kPageHorizontalPadding),
            Expanded(
              child: DetailStatItem(
                icon: Icons.access_time,
                label: 'Times',
                value: _timesText(context, s),
                alignEnd: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: kCardInnerSpacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NextDoseDateBadge(
                nextDose: nextDose,
                isActive: s.isActive,
                dense: true,
                showNextLabel: false,
                activeColor: headerOnPrimary,
              ),
            ),
            const SizedBox(width: kPageHorizontalPadding),
            Expanded(
              child: DetailStatItem(
                icon: Icons.timer_outlined,
                label: 'In',
                value: nextDose == null ? '—' : _getTimeUntil(nextDose),
                alignEnd: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderStatusBadge(BuildContext context, Schedule s) {
    final badge = ScheduleStatusChip(schedule: s, dense: true);
    if (s.isCompleted) return badge;

    final isActive = s.isActive;
    final cs = Theme.of(context).colorScheme;
    final label = isActive ? 'Pause' : 'Resume';
    final icon = isActive ? Icons.pause_rounded : Icons.play_arrow_rounded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _promptPauseFromHeader(context, s),
            borderRadius: BorderRadius.circular(kBorderRadiusChip),
            child: badge,
          ),
        ),
        const SizedBox(height: kSpacingXS),
        TextButton.icon(
          onPressed: () => _promptPauseFromHeader(context, s),
          style: TextButton.styleFrom(
            padding: kCompactButtonPadding,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            foregroundColor: cs.onPrimary.withValues(alpha: kOpacityMedium),
          ),
          icon: Icon(icon, size: kIconSizeSmall),
          label: Text(label, style: helperTextStyle(context)),
        ),
      ],
    );
  }

  Future<void> _promptPauseFromHeader(BuildContext context, Schedule s) async {
    final choice = await showSchedulePauseDialog(context, schedule: s);
    if (choice == null) return;

    switch (choice) {
      case SchedulePauseDialogChoice.resume:
        await _setScheduleStatus(context, s, active: true, pausedUntil: null);
        return;
      case SchedulePauseDialogChoice.pauseIndefinitely:
        await _setScheduleStatus(context, s, active: false, pausedUntil: null);
        return;
      case SchedulePauseDialogChoice.pauseUntilDate:
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        );
        if (picked == null) return;
        final endOfDay = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
        );
        await _setScheduleStatus(
          context,
          s,
          active: false,
          pausedUntil: endOfDay,
        );
        return;
    }
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

  String _formatDateTime(BuildContext context, DateTime dt) {
    return '${DateFormat('EEE, MMM d, y').format(dt)} • ${TimeOfDay.fromDateTime(dt).format(context)}';
  }

  List<Widget> _buildSections(
    BuildContext context,
    Schedule s,
    DateTime? nextDose,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: kSpacingS),
        child: SectionFormCard(
          neutral: true,
          title: 'Schedule Details',
          titleStyle: reviewCardTitleStyle(context),
          children: _buildScheduleDetailsCardChildren(context, s),
        ),
      ),
    ];
  }

  List<Widget> _buildScheduleDetailsCardChildren(
    BuildContext context,
    Schedule s,
  ) {
    final startAtLabel = s.startAt == null
        ? 'Not set'
        : _formatDateTime(context, s.startAt!);
    final endAtLabel = s.endAt == null
        ? 'Not set'
        : _formatDateTime(context, s.endAt!);

    return [
      buildDetailInfoRow(
        context,
        label: 'Name',
        value: s.name.trim().isEmpty ? '—' : s.name,
        onTap: () => context.push('/schedules/edit/${s.id}'),
      ),
      buildDetailInfoRow(
        context,
        label: 'Dose',
        value: _getDoseDisplay(s),
        onTap: () => context.push('/schedules/edit/${s.id}'),
      ),
      buildDetailInfoRow(
        context,
        label: 'Type',
        value: _scheduleTypeText(s),
        onTap: () => context.push('/schedules/edit/${s.id}'),
        maxLines: 2,
      ),
      buildDetailInfoRow(
        context,
        label: 'Times',
        value: _timesText(context, s),
        onTap: () => context.push('/schedules/edit/${s.id}'),
        maxLines: 2,
      ),
      buildDetailInfoRow(
        context,
        label: 'Start',
        value: startAtLabel,
        onTap: () => context.push('/schedules/edit/${s.id}'),
        maxLines: 2,
      ),
      buildDetailInfoRow(
        context,
        label: 'End',
        value: endAtLabel,
        onTap: () => context.push('/schedules/edit/${s.id}'),
        maxLines: 2,
      ),
    ];
  }

  Future<void> _setScheduleStatus(
    BuildContext context,
    Schedule s, {
    required bool active,
    required DateTime? pausedUntil,
  }) async {
    if (s.active == active && s.pausedUntil == pausedUntil) return;

    try {
      final scheduleBox = Hive.box<Schedule>('schedules');
      final updated = s.copyWith(active: active, pausedUntil: pausedUntil);

      await ScheduleScheduler.cancelFor(s.id);
      await scheduleBox.put(s.id, updated);

      if (updated.isActive) {
        await ScheduleScheduler.scheduleFor(updated);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Schedule set to ${scheduleStatusLabel(updated)}'),
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

    final cs = Theme.of(context).colorScheme;

    final doses = _getDosesForDate(date, s);

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            children: [
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpacingS,
                    vertical: kSpacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(kBorderRadiusChipTight),
                  ),
                  child: Text(
                    'TODAY',
                    style: microHelperTextStyle(
                      context,
                      color: cs.onPrimary,
                    )?.copyWith(fontWeight: kFontWeightExtraBold),
                  ),
                ),
              if (isToday) const SizedBox(width: kSpacingS),
              Text(
                DateFormat('EEE, MMM d').format(date),
                style: bodyTextStyle(context)?.copyWith(
                  fontWeight: kFontWeightBold,
                  color: isToday ? cs.primary : cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingS),
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
    final cs = Theme.of(context).colorScheme;
    final isTaken = existingLog?.action == DoseAction.taken;
    final hasLog = existingLog != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingS),
      child: Container(
        padding: const EdgeInsets.all(kSpacingM),
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
                    : cs.surfaceContainerHighest.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          border: hasLog
              ? Border.all(
                  color: _getActionColor(context, existingLog.action),
                  width: 1.5,
                )
              : (isToday
                    ? Border.all(color: cs.primary, width: 1.5)
                    : Border.all(color: cs.outline.withValues(alpha: 0.2))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasLog ? _getActionIcon(existingLog.action) : Icons.schedule,
                  size: kIconSizeSmall,
                  color: hasLog
                      ? _getActionColor(context, existingLog.action)
                      : (isToday ? cs.primary : cs.onSurfaceVariant),
                ),
                const SizedBox(width: kSpacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TimeOfDay.fromDateTime(dt).format(context),
                        style: cardTitleStyle(
                          context,
                        )?.copyWith(color: cs.onSurface),
                      ),
                      Text(
                        _getDoseDisplay(s),
                        style: helperTextStyle(
                          context,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasLog)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kSpacingS,
                      vertical: kSpacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: _getActionColor(context, existingLog.action),
                      borderRadius: BorderRadius.circular(
                        kBorderRadiusChipTight,
                      ),
                    ),
                    child: Text(
                      _getActionLabel(existingLog.action).toUpperCase(),
                      style:
                          microHelperTextStyle(
                            context,
                            color: statusColorOnPrimary(
                              context,
                              _getActionColor(context, existingLog.action),
                            ),
                          )?.copyWith(fontWeight: kFontWeightExtraBold),
                    ),
                  ),
              ],
            ),

            // Show notes and injection site if logged
            if (hasLog && existingLog.notes != null) ...[
              const SizedBox(height: kSpacingS),
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
                        style: helperTextStyle(
                          context,
                          color: cs.onSurfaceVariant,
                        )?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    if (injectionSite != null) ...[
                      const SizedBox(height: kSpacingXS),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: kIconSizeXXSmall,
                            color: cs.primary,
                          ),
                          const SizedBox(width: kSpacingXS),
                          Text(
                            injectionSite,
                            style: helperTextStyle(
                              context,
                              color: cs.primary,
                            )?.copyWith(fontWeight: kFontWeightSemiBold),
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
              const SizedBox(height: kSpacingS),
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
                        icon: const Icon(Icons.check, size: kIconSizeXSmall),
                        label: Text(
                          existingLog != null ? 'Edit' : 'Take',
                          style: microHelperTextStyle(context)?.copyWith(
                            fontWeight: kFontWeightSemiBold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: kDenseButtonContentPadding,
                        ),
                      ),
                    ),
                    const SizedBox(width: kSpacingXS),
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
                        icon: const Icon(Icons.snooze, size: kIconSizeXSmall),
                        label: Text(
                          'Snooze',
                          style: microHelperTextStyle(context)?.copyWith(
                            fontWeight: kFontWeightSemiBold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: kDenseButtonContentPadding,
                        ),
                      ),
                    ),
                    const SizedBox(width: kSpacingXS),
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
                        icon: const Icon(Icons.close, size: kIconSizeXSmall),
                        label: Text(
                          'Skip',
                          style: microHelperTextStyle(context)?.copyWith(
                            fontWeight: kFontWeightSemiBold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: kDenseButtonContentPadding,
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
                        icon: const Icon(Icons.edit, size: kIconSizeXSmall),
                        label: Text(
                          'Edit',
                          style: microHelperTextStyle(context)?.copyWith(
                            fontWeight: kFontWeightSemiBold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: kDenseButtonContentPadding,
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

  String _scheduleTypeText(Schedule schedule) {
    if (schedule.daysOfMonth?.isNotEmpty == true) return 'Days of month';
    if (schedule.hasCycle && schedule.cycleEveryNDays != null) {
      final n = schedule.cycleEveryNDays!;
      return 'Every $n day${n == 1 ? '' : 's'}';
    }
    final ds = schedule.daysOfWeek.toList();
    if (ds.length == 7) return 'Daily';
    return 'Days of week';
  }

  String _timesText(BuildContext context, Schedule schedule) {
    final ts = schedule.timesOfDay ?? [schedule.minutesOfDay];
    return ts
        .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context))
        .join('\n');
  }

  DateTime? _nextOccurrence(Schedule s) {
    return ScheduleOccurrenceService.nextOccurrence(s);
  }

  Future<void> _confirmDelete(BuildContext context, Schedule schedule) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            final cs = Theme.of(context).colorScheme;
            return AlertDialog(
              titleTextStyle: dialogTitleTextStyle(context),
              contentTextStyle: dialogContentTextStyle(context),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok || !context.mounted) return;

    await ScheduleScheduler.cancelFor(schedule.id);
    await Hive.box<Schedule>('schedules').delete(schedule.id);
    if (context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Deleted "${schedule.name}"')),
      );
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
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      titleTextStyle: dialogTitleTextStyle(context),
      contentTextStyle: dialogContentTextStyle(context),
      title: Text(widget.existingLog != null ? 'Edit Dose' : _actionLabel),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notes field
            TextFormField(
              controller: widget.notesController,
              decoration: buildFieldDecoration(
                context,
                label: 'Notes (optional)',
                hint: 'Add any notes about this dose...',
              ),
              maxLines: 3,
              textCapitalization: kTextCapitalizationDefault,
            ),

            // Injection site field (only for injections)
            if (widget.isInjection) ...[
              const SizedBox(height: kSpacingM),
              TextFormField(
                controller: _injectionSiteController,
                decoration: buildFieldDecoration(
                  context,
                  label: 'Injection Site (optional)',
                  hint: 'e.g., Left arm, Right thigh...',
                ),
                textCapitalization: kTextCapitalizationDefault,
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
            style: TextButton.styleFrom(foregroundColor: cs.error),
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
