// ignore_for_file: unused_element

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/core/notifications/low_stock_notifier.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_log_ids.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/data/entry_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_entry_metrics.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/widgets/confirm_schedule_edit_dialog.dart';
import 'package:dosifi_v5/src/widgets/entry_action_sheet.dart';
import 'package:dosifi_v5/src/widgets/entry_card.dart';
import 'package:dosifi_v5/src/widgets/next_entry_row.dart';
import 'package:dosifi_v5/src/widgets/schedule_status_chip.dart';
import 'package:dosifi_v5/src/widgets/schedule_pause_dialog.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_status_ui.dart';

/// Enhanced expandable schedule card for medication detail page
/// Shows schedule summary by default, expands to show full details
class EnhancedScheduleCard extends StatefulWidget {
  const EnhancedScheduleCard({
    super.key,
    required this.schedule,
    required this.medication,
    this.showEntryCardWhenPossible = true,
  });

  final Schedule schedule;
  final Medication medication;
  final bool showEntryCardWhenPossible;

  @override
  State<EnhancedScheduleCard> createState() => _EnhancedScheduleCardState();
}

class _EnhancedScheduleCardState extends State<EnhancedScheduleCard> {
  bool _isExpanded = false;

  Future<void> _cancelNotificationForEntry(CalculatedEntry entry) async {
    try {
      await NotificationService.cancel(
        ScheduleScheduler.entryNotificationIdFor(
          entry.scheduleId,
          entry.scheduledTime,
        ),
      );
      for (final overdueId in ScheduleScheduler.overdueNotificationIdsFor(
        entry.scheduleId,
        entry.scheduledTime,
      )) {
        await NotificationService.cancel(overdueId);
      }
    } catch (_) {
      // Best-effort cancellation only.
    }
  }

  Future<void> _showEntryActions(
    CalculatedEntry entry, {
    EntryStatus? initialStatus,
  }) {
    return EntryActionSheet.show(
      context,
      entry: entry,
      initialStatus: initialStatus,
      onMarkLogged: (request) async {
        final logId = EntryLogIds.occurrenceId(
          scheduleId: entry.scheduleId,
          scheduledTime: entry.scheduledTime,
        );
        final log = EntryLog(
          id: logId,
          scheduleId: entry.scheduleId,
          scheduleName: widget.schedule.name,
          medicationId: widget.medication.id,
          medicationName: widget.medication.name,
          scheduledTime: entry.scheduledTime,
          actionTime: request.actionTime,
          entryValue: entry.entryValue,
          entryUnit: entry.entryUnit,
          action: EntryAction.logged,
          actualEntryValue: request.actualEntryValue,
          actualEntryUnit: request.actualEntryUnit,
          notes: request.notes?.isEmpty ?? true ? null : request.notes,
        );

        final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
        await repo.upsertOccurrence(log);
        await _cancelNotificationForEntry(entry);

        final medBox = Hive.box<Medication>('medications');
        final currentMed = medBox.get(widget.medication.id);
        if (currentMed != null) {
          final effectiveEntryValue = request.actualEntryValue ?? entry.entryValue;
          final effectiveEntryUnit = request.actualEntryUnit ?? entry.entryUnit;
          final delta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: currentMed,
            schedule: widget.schedule,
            entryValue: effectiveEntryValue,
            entryUnit: effectiveEntryUnit,
            preferEntryValue: request.actualEntryValue != null,
          );
          if (delta != null) {
            final updated = MedicationStockAdjustment.deduct(
              medication: currentMed,
              delta: delta,
            );
            await medBox.put(currentMed.id, updated);
            await LowStockNotifier.handleStockChange(
              before: currentMed,
              after: updated,
            );
          }
        }

        if (!mounted) return;
        setState(() {});
        showAppSnackBar(context, 'Entry recorded');
      },
      onSnooze: (request) async {
        final logId = EntryLogIds.occurrenceId(
          scheduleId: entry.scheduleId,
          scheduledTime: entry.scheduledTime,
        );
        final log = EntryLog(
          id: logId,
          scheduleId: entry.scheduleId,
          scheduleName: widget.schedule.name,
          medicationId: widget.medication.id,
          medicationName: widget.medication.name,
          scheduledTime: entry.scheduledTime,
          actionTime: request.actionTime,
          entryValue: entry.entryValue,
          entryUnit: entry.entryUnit,
          action: EntryAction.snoozed,
          actualEntryValue: request.actualEntryValue,
          actualEntryUnit: request.actualEntryUnit,
          notes: request.notes?.isEmpty ?? true ? null : request.notes,
        );

        final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
        await repo.upsertOccurrence(log);

        await _cancelNotificationForEntry(entry);
        final when = request.actionTime;
        if (when.isAfter(DateTime.now())) {
          final time = DateTimeFormatter.formatTime(context, when);
          await NotificationService.scheduleAtAlarmClock(
            ScheduleScheduler.entryNotificationIdFor(
              entry.scheduleId,
              entry.scheduledTime,
            ),
            when,
            title: widget.medication.name,
            body: '${widget.schedule.name} | Snoozed until $time',
            payload:
                'entry:${entry.scheduleId}:${entry.scheduledTime.millisecondsSinceEpoch}',
            actions: NotificationService.upcomingEntryActions,
            expandedLines: <String>[
              widget.schedule.name,
              'Snoozed until $time',
            ],
          );
        }

        if (!mounted) return;
        setState(() {});
        showAppSnackBar(context, 'Reminder snoozed');
      },
      onSkip: (request) async {
        final logId = EntryLogIds.occurrenceId(
          scheduleId: entry.scheduleId,
          scheduledTime: entry.scheduledTime,
        );
        final log = EntryLog(
          id: logId,
          scheduleId: entry.scheduleId,
          scheduleName: widget.schedule.name,
          medicationId: widget.medication.id,
          medicationName: widget.medication.name,
          scheduledTime: entry.scheduledTime,
          actionTime: request.actionTime,
          entryValue: entry.entryValue,
          entryUnit: entry.entryUnit,
          action: EntryAction.skipped,
          actualEntryValue: request.actualEntryValue,
          actualEntryUnit: request.actualEntryUnit,
          notes: request.notes?.isEmpty ?? true ? null : request.notes,
        );

        final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
        await repo.upsertOccurrence(log);
        await _cancelNotificationForEntry(entry);

        if (!mounted) return;
        setState(() {});
        showAppSnackBar(context, 'Entry skipped');
      },
      onDelete: (request) async {
        final logBox = Hive.box<EntryLog>('entry_logs');
        final baseId = EntryLogIds.occurrenceId(
          scheduleId: entry.scheduleId,
          scheduledTime: entry.scheduledTime,
        );
        final existingLog =
            logBox.get(baseId) ??
            logBox.get(EntryLogIds.legacySnoozeIdFromBase(baseId));

        if (existingLog != null && existingLog.action == EntryAction.logged) {
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(widget.medication.id);
          if (currentMed != null) {
            final oldValue =
                existingLog.actualEntryValue ?? existingLog.entryValue;
            final oldUnit = existingLog.actualEntryUnit ?? existingLog.entryUnit;
            final delta = MedicationStockAdjustment.tryCalculateStockDelta(
              medication: currentMed,
              schedule: widget.schedule,
              entryValue: oldValue,
              entryUnit: oldUnit,
              preferEntryValue: existingLog.actualEntryValue != null,
            );
            if (delta != null) {
              await medBox.put(
                currentMed.id,
                MedicationStockAdjustment.restore(
                  medication: currentMed,
                  delta: delta,
                ),
              );
            }
          }
        }

        final repo = EntryLogRepository(logBox);
        await repo.deleteOccurrence(
          scheduleId: entry.scheduleId,
          scheduledTime: entry.scheduledTime,
        );
        await _cancelNotificationForEntry(entry);

        if (!mounted) return;
        setState(() {});
        showAppSnackBar(context, 'Entry removed');
      },
    );
  }

  Future<void> _promptEditSchedule() async {
    final confirmed = await showConfirmEditScheduleDialog(context);
    if (!confirmed || !mounted) return;
    context.push('/schedules/edit/${widget.schedule.id}');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final nextEntry = _getNextEntry();

    final strengthLabel = MedicationDisplayHelpers.strengthOrConcentrationLabel(
      widget.medication,
    );
    final metrics = widget.schedule.displayMetrics(widget.medication);

    final canShowEntryCard =
        nextEntry != null &&
        strengthLabel.trim().isNotEmpty &&
        metrics.trim().isNotEmpty;

    final showEntryCard = widget.showEntryCardWhenPossible && canShowEntryCard;

    return AnimatedContainer(
      duration: kAnimationNormal,
      curve: kCurveEmphasized,
      margin: const EdgeInsets.only(bottom: kSpacingS),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: kAnimationNormal,
          curve: kCurveEmphasized,
          padding: showEntryCard
              ? EdgeInsets.zero
              : EdgeInsets.all(_isExpanded ? kCardPadding : kSpacingM),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(kBorderRadiusMedium),
            border: _isExpanded
                ? Border.all(
                    color: colorScheme.outlineVariant.withValues(
                      alpha: kCardBorderOpacity,
                    ),
                    width: kBorderWidthThin,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showEntryCard)
                ValueListenableBuilder(
                  valueListenable: Hive.box<EntryLog>('entry_logs').listenable(),
                  builder: (context, Box<EntryLog> logBox, _) {
                    final baseId = EntryLogIds.occurrenceId(
                      scheduleId: widget.schedule.id,
                      scheduledTime: nextEntry,
                    );
                    final existingLog =
                        logBox.get(baseId) ??
                        logBox.get(EntryLogIds.legacySnoozeIdFromBase(baseId));

                    final entry = CalculatedEntry(
                      scheduleId: widget.schedule.id,
                      scheduleName: widget.schedule.name,
                      medicationName: widget.medication.name,
                      scheduledTime: nextEntry,
                      entryValue: widget.schedule.entryValue,
                      entryUnit: widget.schedule.entryUnit,
                      existingLog: existingLog,
                    );

                    return EntryCard(
                      entry: entry,
                      medicationName: widget.medication.name,
                      strengthOrConcentrationLabel: strengthLabel,
                      entryMetrics: metrics,
                      isActive: widget.schedule.isActive,
                      compact: true,
                      medicationFormIcon:
                          MedicationDisplayHelpers.medicationFormIcon(
                            widget.medication.form,
                          ),
                      entryNumber: ScheduleOccurrenceService.occurrenceNumber(
                        widget.schedule,
                        nextEntry,
                      ),
                      titleTrailing: ScheduleStatusChip(
                        schedule: widget.schedule,
                      ),
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      onQuickAction: (status) =>
                          _showEntryActions(entry, initialStatus: status),
                      onPrimaryAction: () => _showEntryActions(entry),
                    );
                  },
                )
              else
                // COLLAPSED STATE - Ultra Clean Single Row
                // In list mode (showEntryCardWhenPossible: false): tap navigates to detail,
                // no expand chevron. In normal mode: tap toggles expand.
                InkWell(
                  onTap: widget.showEntryCardWhenPossible
                      ? () => setState(() => _isExpanded = !_isExpanded)
                      : () => context.push(
                          '/schedules/detail/${widget.schedule.id}',
                        ),
                  borderRadius: BorderRadius.circular(kBorderRadiusMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // Schedule name (primary info)
                          Expanded(
                            child: Text(
                              widget.schedule.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: kFontWeightMedium,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Frequency (secondary info) - no time/day in saved schedule rows
                          Text(
                            _getFrequencyLabelShort(),
                            style: mutedTextStyle(context),
                          ),
                          const SizedBox(width: kSpacingS),
                          // Status on the right – always shown in list mode; in expand mode only when collapsed
                          if (!_isExpanded || !widget.showEntryCardWhenPossible) ...[
                            ScheduleStatusChip(schedule: widget.schedule),
                            const SizedBox(width: kSpacingXS),
                            GestureDetector(
                              onTap: _showPauseOptions,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: kSpacingXS,
                                ),
                                child: Icon(
                                  widget.schedule.isActive
                                      ? Icons.pause_circle_outline_rounded
                                      : Icons.play_circle_outline_rounded,
                                  size: kIconSizeMedium,
                                  color: colorScheme.onSurfaceVariant.withValues(
                                    alpha: kOpacityMedium,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: kSpacingXS),
                          ],
                          // Expand/collapse chevron – only shown in standalone mode (not list mode)
                          if (widget.showEntryCardWhenPossible)
                            Padding(
                              padding: const EdgeInsets.all(kSpacingXS),
                              child: AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0,
                                duration: kAnimationFast,
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: kIconSizeMedium,
                                  color: colorScheme.onSurfaceVariant.withValues(
                                    alpha: kOpacityMedium,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: kSpacingXS),
                      NextEntryRow(
                        schedule: widget.schedule,
                        nextEntry: nextEntry,
                        dense: true,
                      ),
                    ],
                  ),
                ),

              // EXPANDED STATE – only in standalone mode (not list mode)
              if (widget.showEntryCardWhenPossible)
                AnimatedCrossFade(
                duration: kAnimationNormal,
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: showEntryCard
                      ? const EdgeInsets.fromLTRB(
                          kCardPadding,
                          kSpacingL,
                          kCardPadding,
                          kCardPadding,
                        )
                      : const EdgeInsets.only(top: kSpacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Schedule Details Section
                      _buildExpandedSection(
                        context,
                        title: 'Schedule Details',
                        children: [
                          _buildDetailRow(
                            context,
                            'Frequency',
                            _getScheduleTypeText(),
                          ),
                          _buildDetailRow(
                            context,
                            'Amount',
                            _formatExpandedEntryDetails(
                              metrics: metrics,
                              strengthOrConcentrationLabel: strengthLabel,
                              fallbackEntry:
                                  '${_formatNumber(widget.schedule.entryValue)} ${widget.schedule.entryUnit}',
                            ),
                          ),
                          _buildDetailRow(context, 'Times', _getTimesText()),
                          _buildDetailRow(context, 'Days', _getDaysText()),
                          _buildDetailRow(
                            context,
                            'Started',
                            DateFormat(
                              'MMM d, yyyy',
                            ).format(widget.schedule.createdAt),
                          ),
                          _buildDetailRow(context, 'Ends', _getEndDateText()),
                        ],
                      ),
                      const SizedBox(height: kSpacingL),

                      // Action Buttons Row (Schedule-level actions only)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPrimaryIconAction(
                            context,
                            icon: Icons.edit_rounded,
                            onTap: _promptEditSchedule,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryIconAction(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: kLargeButtonHeight,
          height: kLargeButtonHeight,
          child: Icon(
            icon,
            size: kIconSizeMedium,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  // Premium info chip
  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isPrimary = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingM,
        vertical: kSpacingS,
      ),
      decoration: BoxDecoration(
        color: isPrimary
            ? colorScheme.primary.withValues(alpha: kOpacitySubtle)
            : colorScheme.onSurface.withValues(alpha: kOpacitySubtleLow),
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: kIconSizeSmall,
            color: isPrimary
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: kSpacingXS),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: kFontWeightMedium,
              color: isPrimary
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Primary action button
  Widget _buildPrimaryAction(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: kSpacingM),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: kFontWeightSemiBold,
            ),
          ),
        ),
      ),
    );
  }

  // Secondary action button
  Widget _buildSecondaryAction(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primary.withValues(alpha: kOpacitySubtle),
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        child: Container(
          padding: const EdgeInsets.all(kSpacingM),
          child: Icon(icon, size: kIconSizeMedium, color: colorScheme.primary),
        ),
      ),
    );
  }

  String _formatNextEntryShort(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.isNegative) {
      return 'Overdue';
    } else if (diff.inMinutes < 60) {
      return 'in ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return DateTimeFormatter.formatTime(context, dt);
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEE').format(dt);
    }
  }

  Widget _buildExpandedSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEntries() {
    final logs = _getRecentLogs();

    if (logs.isEmpty) {
      return Text(
        'No entries yet',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: [
        ...logs
            .take(3)
            .map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      _getActionIcon(log.action),
                      size: 14,
                      color: _getActionColor(log.action),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatLastTaken(log.actionTime)} | ${_getActionLabel(log.action)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (log.notes != null && log.notes!.isNotEmpty)
                      Icon(
                        Icons.note_outlined,
                        size: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                  ],
                ),
              ),
            ),
        if (logs.length > 3)
          TextButton(
            onPressed: () => context.pushNamed(
              'scheduleDetail',
              pathParameters: {'id': widget.schedule.id},
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View all history →',
              style: compactButtonTextStyle(context),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // Helper methods
  DateTime? _getNextEntry() {
    return ScheduleOccurrenceService.nextOccurrence(widget.schedule);
  }

  Map<String, dynamic> _getAdherenceData() {
    final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final logs = repo
        .getByDateRange(weekAgo, now)
        .where((log) => log.scheduleId == widget.schedule.id)
        .toList();

    final taken = logs.where((l) => l.action == EntryAction.logged).length;
    final total = logs.length;
    final rate = total > 0 ? (taken / total) * 100 : 0.0;

    return {'logged': taken, 'total': total, 'rate': rate};
  }

  List<EntryLog> _getRecentLogs() {
    final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
    final logs = repo.getByScheduleId(widget.schedule.id);
    logs.sort((a, b) => b.actionTime.compareTo(a.actionTime));
    return logs;
  }

  String _formatNextEntry(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.inMinutes < 60) {
      return 'in ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return 'Today at ${DateTimeFormatter.formatTime(context, dt)} (in ${hours}h ${minutes}m)';
    } else if (diff.inDays == 1) {
      return 'Tomorrow at ${DateTimeFormatter.formatTime(context, dt)}';
    } else {
      return '${DateFormat('EEEE').format(dt)} at ${DateTimeFormatter.formatTime(context, dt)}';
    }
  }

  String _formatLastTaken(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday ${DateTimeFormatter.formatTime(context, dt)}';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _getFrequencyText() {
    if (widget.schedule.hasCycle) {
      return 'Every ${widget.schedule.cycleEveryNDays} days';
    } else if (widget.schedule.hasDaysOfMonth) {
      final days = widget.schedule.daysOfMonth!.join(', ');
      return 'Days $days of month';
    } else if (widget.schedule.daysOfWeek.length == 7) {
      return 'Every day';
    } else {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final days = widget.schedule.daysOfWeek
          .map((d) => dayNames[d - 1])
          .join(', ');
      return days;
    }
  }

  String _getFrequencyLabelShort() {
    if (widget.schedule.hasCycle) {
      return 'Every ${widget.schedule.cycleEveryNDays} days';
    }
    if (widget.schedule.hasDaysOfMonth) {
      return 'Monthly';
    }
    if (widget.schedule.daysOfWeek.length == 7) {
      return 'Every day';
    }
    return 'Weekly';
  }

  String _getScheduleTypeText() {
    if (widget.schedule.hasCycle) return 'Cycle';
    if (widget.schedule.hasDaysOfMonth) return 'Monthly';
    if (widget.schedule.daysOfWeek.length == 7) return 'Daily';
    return 'Weekly';
  }

  String _getEndDateText() {
    final endAt = widget.schedule.endAt;
    if (endAt == null) return '—';
    return DateFormat('MMM d, yyyy').format(endAt);
  }

  String _formatExpandedEntryDetails({
    required String metrics,
    required String strengthOrConcentrationLabel,
    required String fallbackEntry,
  }) {
    final m = metrics.trim();
    final s = strengthOrConcentrationLabel.trim();

    final base = m.isNotEmpty ? m : fallbackEntry;
    if (s.isEmpty) return base;
    return '$base | $s';
  }

  String _getTimesText() {
    if (widget.schedule.hasMultipleTimes) {
      final times = widget.schedule.timesOfDay!
          .map((m) {
            final hour = m ~/ 60;
            final minute = m % 60;
            final dt = DateTime(0, 0, 0, hour, minute);
            return DateTimeFormatter.formatTime(context, dt);
          })
          .join(', ');
      return times;
    } else {
      final hour = widget.schedule.minutesOfDay ~/ 60;
      final minute = widget.schedule.minutesOfDay % 60;
      final dt = DateTime(0, 0, 0, hour, minute);
      return DateTimeFormatter.formatTime(context, dt);
    }
  }

  String _getDaysText() {
    return _getFrequencyText();
  }

  Color _getAdherenceColor(double rate) {
    if (rate >= 90) return kAdherenceGoodColor(context);
    if (rate >= 70) return kAdherenceWarningColor(context);
    return kAdherencePoorColor(context);
  }

  IconData _getActionIcon(EntryAction action) {
    switch (action) {
      case EntryAction.logged:
        return Icons.check_circle;
      case EntryAction.skipped:
        return Icons.block;
      case EntryAction.snoozed:
        return Icons.snooze;
    }
  }

  Color _getActionColor(EntryAction action) {
    return entryActionVisualSpec(context, action).color;
  }

  String _getActionLabel(EntryAction action) {
    switch (action) {
      case EntryAction.logged:
        return 'Logged';
      case EntryAction.skipped:
        return 'Skipped';
      case EntryAction.snoozed:
        return 'Snoozed';
    }
  }

  // Action handlers
  void _takeEntryNow() async {
    final now = DateTime.now();

    // Show quick confirmation dialog with notes option
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) {
        final notesController = TextEditingController();
        final siteController = TextEditingController();

        return AlertDialog(
          title: const Text('Record Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recording ${_formatNumber(widget.schedule.entryValue)} ${widget.schedule.entryUnit}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                textCapitalization: kTextCapitalizationDefault,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: siteController,
                textCapitalization: kTextCapitalizationDefault,
                decoration: const InputDecoration(
                  labelText: 'Injection site (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'notes': notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  'site': siteController.text.isEmpty
                      ? null
                      : siteController.text,
                });
              },
              child: const Text('Record'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      // Create entry log
      final logId = EntryLogIds.occurrenceId(
        scheduleId: widget.schedule.id,
        scheduledTime: now,
      );

      // Combine notes and injection site
      String? combinedNotes = result['notes'];
      if (result['site'] != null && result['site']!.isNotEmpty) {
        if (combinedNotes != null && combinedNotes.isNotEmpty) {
          combinedNotes = '$combinedNotes\nInjection site: ${result['site']}';
        } else {
          combinedNotes = 'Injection site: ${result['site']}';
        }
      }

      final log = EntryLog(
        id: logId,
        scheduleId: widget.schedule.id,
        scheduleName: widget.schedule.name,
        medicationId: widget.medication.id,
        medicationName: widget.medication.name,
        scheduledTime: now,
        entryValue: widget.schedule.entryValue,
        entryUnit: widget.schedule.entryUnit,
        action: EntryAction.logged,
        notes: combinedNotes,
      );

      final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
      await repo.upsert(log);

      // Update medication stock
      final medBox = Hive.box<Medication>('medications');
      final currentMed = medBox.get(widget.medication.id);
      if (currentMed != null) {
        final newStockValue =
            (currentMed.stockValue - widget.schedule.entryValue).clamp(
              0.0,
              double.infinity,
            );
        await medBox.put(
          currentMed.id,
          currentMed.copyWith(stockValue: newStockValue),
        );
      }

      if (mounted) {
        setState(() {});
        showAppSnackBar(context, 'Entry recorded');
      }
    }
  }

  void _skipEntry() async {
    final now = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Entry'),
        content: Text(
          'Skip ${_formatNumber(widget.schedule.entryValue)} ${widget.schedule.entryUnit}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final logId = EntryLogIds.occurrenceId(
        scheduleId: widget.schedule.id,
        scheduledTime: now,
      );
      final log = EntryLog(
        id: logId,
        scheduleId: widget.schedule.id,
        scheduleName: widget.schedule.name,
        medicationId: widget.medication.id,
        medicationName: widget.medication.name,
        scheduledTime: now,
        entryValue: widget.schedule.entryValue,
        entryUnit: widget.schedule.entryUnit,
        action: EntryAction.skipped,
      );

      final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
      await repo.upsert(log);

      if (mounted) {
        setState(() {});
        showAppSnackBar(context, 'Entry skipped');
      }
    }
  }

  void _snoozeEntry() async {
    final now = DateTime.now();

    final snoozeDuration = await showDialog<Duration>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Remind me in:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('15 minutes'),
              onTap: () => Navigator.pop(context, const Duration(minutes: 15)),
            ),
            ListTile(
              title: const Text('30 minutes'),
              onTap: () => Navigator.pop(context, const Duration(minutes: 30)),
            ),
            ListTile(
              title: const Text('1 hour'),
              onTap: () => Navigator.pop(context, const Duration(hours: 1)),
            ),
            ListTile(
              title: const Text('2 hours'),
              onTap: () => Navigator.pop(context, const Duration(hours: 2)),
            ),
          ],
        ),
      ),
    );

    if (snoozeDuration != null && mounted) {
      final logId = EntryLogIds.occurrenceId(
        scheduleId: widget.schedule.id,
        scheduledTime: now,
      );
      final log = EntryLog(
        id: logId,
        scheduleId: widget.schedule.id,
        scheduleName: widget.schedule.name,
        medicationId: widget.medication.id,
        medicationName: widget.medication.name,
        scheduledTime: now,
        entryValue: widget.schedule.entryValue,
        entryUnit: widget.schedule.entryUnit,
        action: EntryAction.snoozed,
        notes: 'Snoozed for ${snoozeDuration.inMinutes} minutes',
      );

      final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
      await repo.upsert(log);

      // Schedule a reminder notification at the snooze-until time.
      final snoozeUntil = now.add(snoozeDuration);
      await NotificationService.cancel(
        ScheduleScheduler.entryNotificationIdFor(widget.schedule.id, now),
      );
      final metrics = ScheduleEntryMetrics.format(widget.schedule);
      if (mounted) {
        final timeLabel = DateTimeFormatter.formatTime(context, snoozeUntil);
        await NotificationService.scheduleAtAlarmClock(
          ScheduleScheduler.entryNotificationIdFor(widget.schedule.id, now),
          snoozeUntil,
          title: widget.medication.name,
          body: '$metrics | Snoozed until $timeLabel',
          payload:
              'entry:${widget.schedule.id}:${now.millisecondsSinceEpoch}',
          actions: NotificationService.upcomingEntryActions,
          expandedLines: <String>[metrics, 'Snoozed until $timeLabel'],
        );
      }

      if (mounted) {
        setState(() {});
        showAppSnackBar(
          context,
          'Reminder snoozed for ${snoozeDuration.inMinutes} minutes',
        );
      }
    }
  }

  Future<void> _showPauseOptions() async {
    final choice = await showSchedulePauseDialog(
      context,
      schedule: widget.schedule,
    );
    if (!mounted || choice == null) return;

    final scheduleBox = Hive.box<Schedule>('schedules');

    switch (choice) {
      case SchedulePauseDialogChoice.resume:
        scheduleBox.put(
          widget.schedule.id,
          widget.schedule.copyWith(active: true, pausedUntil: null),
        );
        break;

      case SchedulePauseDialogChoice.pauseIndefinitely:
        scheduleBox.put(
          widget.schedule.id,
          widget.schedule.copyWith(active: false, pausedUntil: null),
        );
        break;

      case SchedulePauseDialogChoice.pauseUntilDate:
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(now.year, now.month, now.day),
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 10),
        );
        if (!mounted || picked == null) return;

        final endOfDay = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
          999,
        );

        scheduleBox.put(
          widget.schedule.id,
          widget.schedule.copyWith(active: false, pausedUntil: endOfDay),
        );
        break;
    }

    if (mounted) {
      setState(() {});
      final refreshed = scheduleBox.get(widget.schedule.id) ?? widget.schedule;
      showAppSnackBar(
        context,
        'Schedule set to ${scheduleStatusLabel(refreshed)}',
      );
    }
  }

  // Quick edit methods
  void _quickEditEntry() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: _formatNumber(widget.schedule.entryValue),
        );

        return AlertDialog(
          title: const Text('Edit Amount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  suffixText: widget.schedule.entryUnit,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      final current =
                          double.tryParse(controller.text) ??
                          widget.schedule.entryValue;
                      final newValue = (current - 0.5).clamp(0.1, 1000.0);
                      controller.text = _formatNumber(newValue);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    onPressed: () {
                      final current =
                          double.tryParse(controller.text) ??
                          widget.schedule.entryValue;
                      final newValue = (current + 0.5).clamp(0.1, 1000.0);
                      controller.text = _formatNumber(newValue);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value > 0) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result != widget.schedule.entryValue && mounted) {
      final scheduleBox = Hive.box<Schedule>('schedules');
      final updated = Schedule(
        id: widget.schedule.id,
        name: widget.schedule.name,
        medicationName: widget.schedule.medicationName,
        entryValue: result,
        entryUnit: widget.schedule.entryUnit,
        minutesOfDay: widget.schedule.minutesOfDay,
        daysOfWeek: widget.schedule.daysOfWeek,
        active: widget.schedule.active,
        medicationId: widget.schedule.medicationId,
        timesOfDay: widget.schedule.timesOfDay,
        cycleEveryNDays: widget.schedule.cycleEveryNDays,
        cycleAnchorDate: widget.schedule.cycleAnchorDate,
        daysOfMonth: widget.schedule.daysOfMonth,
        createdAt: widget.schedule.createdAt,
        minutesOfDayUtc: widget.schedule.minutesOfDayUtc,
        daysOfWeekUtc: widget.schedule.daysOfWeekUtc,
        timesOfDayUtc: widget.schedule.timesOfDayUtc,
      );
      scheduleBox.put(widget.schedule.id, updated);

      setState(() {});
      showAppSnackBar(
        context,
        'Amount updated to ${_formatNumber(result)} ${widget.schedule.entryUnit}',
      );
    }
  }

  void _quickEditTimes() {
    showAppSnackBar(
      context,
      'Time editing coming soon. Use the edit button to modify times.',
    );
  }
}
