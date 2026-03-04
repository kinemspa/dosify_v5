// ignore_for_file: unused_element, unused_local_variable

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/utils/datetime_formatter.dart';
import 'package:skedux/src/core/notifications/low_stock_notifier.dart';
import 'package:skedux/src/core/notifications/notification_service.dart';
import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:skedux/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:skedux/src/features/schedules/data/schedule_scheduler.dart';
import 'package:skedux/src/features/schedules/domain/calculated_entry.dart';
import 'package:skedux/src/features/schedules/domain/entry_log_ids.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/data/entry_log_repository.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';
import 'package:skedux/src/widgets/entry_card.dart';
import 'package:skedux/src/widgets/entry_action_sheet.dart';
import 'package:skedux/src/widgets/entry_status_badge.dart';
import 'package:skedux/src/widgets/entry_status_ui.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class NextEntryCard extends StatefulWidget {
  const NextEntryCard({
    required this.medication,
    required this.schedules,
    super.key,
  });

  final Medication medication;
  final List<Schedule> schedules;

  @override
  State<NextEntryCard> createState() => _NextEntryCardState();
}

class _NextEntryCardState extends State<NextEntryCard>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;

  // Cache of calculated entries for the selected week
  List<CalculatedEntry> _weekEntries = [];

  // Entries for the currently selected day
  List<CalculatedEntry> _dayEntries = [];

  @override
  void initState() {
    super.initState();
    // Always default to today when entering medication details
    _selectedDate = DateTime.now();
    _calculateEntriesForWeek(_selectedDate);
    _updateDayEntries();
  }

  void _findNextEntry() {
    // Simple logic to find the next future entry and jump to it
    final now = DateTime.now();
    CalculatedEntry? next;

    // Look ahead 30 days
    for (int i = 0; i < 30; i++) {
      final date = now.add(Duration(days: i));
      final entries = _calculateEntriesForDay(date);
      final futureEntries = entries
          .where((d) => d.scheduledTime.isAfter(now))
          .toList();

      if (futureEntries.isNotEmpty) {
        futureEntries.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        next = futureEntries.first;
        break;
      }
    }

    if (next != null) {
      setState(() {
        _selectedDate = next!.scheduledTime;
        _calculateEntriesForWeek(_selectedDate);
        _updateDayEntries();
      });
    }
  }

  void _calculateEntriesForWeek(DateTime date) {
    // Calculate start of week (Monday)
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    _weekEntries.clear();

    // This is a simplified calculation. In a real app, we'd use a robust scheduler service.
    // For now, we iterate days and schedules.
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      _weekEntries.addAll(_calculateEntriesForDay(day));
    }
  }

  List<CalculatedEntry> _calculateEntriesForDay(DateTime date) {
    final entries = <CalculatedEntry>[];
    final logsBox = Hive.box<EntryLog>('entry_logs');

    for (final schedule in widget.schedules) {
      // Check if schedule is active on this day
      bool isScheduled = false;

      // Check days of week (1=Mon..7=Sun)
      if (schedule.daysOfWeek.contains(date.weekday)) {
        isScheduled = true;
      }

      // Also check cycle or days of month if implemented (skipping for now as per previous logic)
      // Note: Schedule model has cycleEveryNDays and daysOfMonth but logic is complex without anchor.
      // Assuming daysOfWeek is primary for this view.

      if (isScheduled) {
        // Create entry times
        // Use timesOfDay (minutes from midnight)
        final times = schedule.timesOfDay ?? [schedule.minutesOfDay];

        for (final minutes in times) {
          final hour = minutes ~/ 60;
          final minute = minutes % 60;
          final dt = DateTime(date.year, date.month, date.day, hour, minute);

          // Check status
          final logId = '${schedule.id}_${dt.millisecondsSinceEpoch}';
          final log = logsBox.get(logId);

          entries.add(
            CalculatedEntry(
              scheduleId: schedule.id,
              scheduleName: schedule.name,
              medicationName: widget.medication.name,
              scheduledTime: dt,
              entryValue: schedule.entryValue,
              entryUnit: schedule.entryUnit,
              existingLog: log,
            ),
          );
        }
      }
    }

    entries.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return entries;
  }

  String _formLabel(MedicationForm form) {
    return form.toString().split('.').last; // Simplified
  }

  void _updateDayEntries() {
    _dayEntries = _weekEntries
        .where(
          (d) =>
              d.scheduledTime.year == _selectedDate.year &&
              d.scheduledTime.month == _selectedDate.month &&
              d.scheduledTime.day == _selectedDate.day,
        )
        .toList();
    _dayEntries.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      // If we moved to a different week, recalculate
      final currentWeekStart = _weekEntries.isNotEmpty
          ? _weekEntries.first.scheduledTime.subtract(
              Duration(days: _weekEntries.first.scheduledTime.weekday - 1),
            )
          : DateTime.now(); // Fallback

      // Check if date is outside the currently calculated week range
      // Actually, simpler to just always recalculate for the week of the selected date
      _calculateEntriesForWeek(date);
      _updateDayEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isViewingToday = _isToday(_selectedDate);

    // Get week range for display
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Entries for selected day
        ClipRect(
          child: AnimatedSize(
            duration: kAnimationNormal,
            curve: kCurveEmphasized,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: kAnimationNormal,
              switchInCurve: kCurveEmphasized,
              switchOutCurve: kCurveEmphasized,
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(1.0, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: kCurveEmphasized,
                        ),
                      ),
                  child: child,
                );
              },
              child: _dayEntries.isEmpty
                  ? GestureDetector(
                      key: ValueKey(_selectedDate.toString()),
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity == null) return;
                        if (details.primaryVelocity! < 0) {
                          _onDaySelected(
                            _selectedDate.add(const Duration(days: 1)),
                          );
                        } else if (details.primaryVelocity! > 0) {
                          _onDaySelected(
                            _selectedDate.subtract(const Duration(days: 1)),
                          );
                        }
                      },
                      child: _buildEmptyState(context),
                    )
                  : Column(
                      key: ValueKey(_selectedDate.toString()),
                      children: [
                        for (int i = 0; i < _dayEntries.length; i++) ...[
                          _buildEntryCardContent(
                            _dayEntries[i],
                            i,
                            _dayEntries.length,
                          ),
                          if (i != _dayEntries.length - 1)
                            const SizedBox(height: kSpacingXS),
                        ],
                      ],
                    ),
            ),
          ),
        ),

        // Day and Date centered below entry card (compact) — locale-aware
        Padding(
          padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
          child: Center(
            child: Text(
              DateTimeFormatter.formatFullDate(context, _selectedDate),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        // Calendar Strip with date range
        _buildCalendarStrip(),
      ],
    );
  }

  Widget _buildEntryCardContent(CalculatedEntry entry, int index, int total) {
    final schedule = widget.schedules.cast<Schedule?>().firstWhere(
      (s) => s?.id == entry.scheduleId,
      orElse: () => null,
    );

    final strengthLabel = MedicationDisplayHelpers.strengthOrConcentrationLabel(
      widget.medication,
    );

    final metrics = schedule == null
        ? '${_formatNumber(entry.entryValue)} ${entry.entryUnit}'
        : _entryMetricsLabel(schedule);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kSpacingXS),
      decoration: buildInsetSectionDecoration(context: context),
      child: EntryCard(
        entry: entry,
        medicationName: widget.medication.name,
        strengthOrConcentrationLabel: strengthLabel,
        entryMetrics: metrics,
        compact: true,
        medicationFormIcon: MedicationDisplayHelpers.medicationFormIcon(
          widget.medication.form,
        ),
        entryNumber: schedule == null
            ? null
            : ScheduleOccurrenceService.occurrenceNumber(
                schedule,
                entry.scheduledTime,
              ),
        onQuickAction: (status) =>
            _showEntryActionSheet(entry, initialStatus: status),
        onTap: () => _showEntryActionSheet(entry),
      ),
    );
  }

  String _entryMetricsLabel(Schedule schedule) {
    final summary = schedule.displayMetrics(widget.medication);
    if (summary.isNotEmpty) return summary;
    return '${_formatNumber(schedule.entryValue)} ${schedule.entryUnit}';
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SizedBox(
      height: 72,
      child: Center(
        child: Text(
          'Nothing scheduled',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(CalculatedEntry entry, int index, int total) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTaken = entry.status == EntryStatus.logged;
    final isOverdue = entry.status == EntryStatus.overdue;
    final isSkipped = entry.status == EntryStatus.skipped;
    final isSnoozed = entry.status == EntryStatus.snoozed;

    Color cardColor = colorScheme.surface;
    Color borderColor = colorScheme.outlineVariant;

    if (isTaken) {
      cardColor = kEntryStatusTakenGreenAdaptive(context).withValues(alpha: 0.1);
      borderColor = kEntryStatusTakenGreenAdaptive(context).withValues(alpha: 0.5);
    } else if (isOverdue) {
      cardColor = colorScheme.errorContainer.withValues(alpha: 0.2);
      borderColor = colorScheme.error.withValues(alpha: 0.5);
    }

    // Determine Icon
    IconData statusIcon = Icons.notifications_outlined; // Default Pending
    if (isTaken)
      statusIcon = Icons.check;
    else if (isSkipped)
      statusIcon = Icons.block;
    else if (isSnoozed)
      statusIcon = Icons.snooze;
    else if (isOverdue)
      statusIcon = Icons.warning_amber_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ), // Reduced vertical padding
      child: InkWell(
        onTap: () => _showEntryActionSheet(entry),
        borderRadius: BorderRadius.circular(12), // Slightly less rounded
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (total > 1 && Theme.of(context).brightness != Brightness.dark)
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ), // Reduced internal padding
          child: Row(
            children: [
              // Leading Circular Icon (Status Based)
              Container(
                width: 36, // Slightly smaller
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTaken
                      ? kEntryStatusTakenGreenAdaptive(context).withValues(alpha: 0.2)
                      : (isOverdue
                            ? colorScheme.errorContainer
                            : colorScheme.primaryContainer),
                ),
                child: Icon(
                  statusIcon,
                  size: 18,
                  color: isTaken
                      ? kEntryStatusTakenGreenAdaptive(context)
                      : (isOverdue ? colorScheme.error : colorScheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ROW 1: "Next Entry" Label & Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Next Entry ${DateFormat('MMM d').format(entry.scheduledTime)}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                        if (total > 1)
                          Text(
                            '${index + 1}/$total',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.outline,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // ROW 2: Time (Big)
                    Text(
                      DateTimeFormatter.formatTime(context, entry.scheduledTime),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isOverdue
                            ? colorScheme.error
                            : colorScheme.primary,
                        height: 1.1,
                      ),
                    ),

                    // ROW 3: Instruction/Amount + Status Badge
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${_formatNumber(entry.entryValue)} ${entry.entryUnit}', // "1 tablet"
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        EntryStatusBadge(
                          status: entry.status,
                          disabled:
                              !(Hive.box<Schedule>('schedules')
                                      .get(entry.scheduleId)
                                      ?.isActive ??
                                  true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarStrip() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final calendarRow = GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0) {
            // Swipe left - go to next week (same day of week)
            setState(() {
              final newDate = _selectedDate.add(const Duration(days: 7));
              _selectedDate = newDate;
              _calculateEntriesForWeek(_selectedDate);
              _updateDayEntries(); // Sync entry card with new date
            });
          } else if (details.primaryVelocity! > 0) {
            // Swipe right - go to previous week (same day of week)
            setState(() {
              final newDate = _selectedDate.subtract(const Duration(days: 7));
              _selectedDate = newDate;
              _calculateEntriesForWeek(_selectedDate);
              _updateDayEntries(); // Sync entry card with new date
            });
          }
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final day = startOfWeek.add(Duration(days: index));
          final isSelected =
              day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;
          final isToday = _isToday(day);

          // Find entries for this day
          final dayEntries = _weekEntries
              .where(
                (d) =>
                    d.scheduledTime.year == day.year &&
                    d.scheduledTime.month == day.month &&
                    d.scheduledTime.day == day.day,
              )
              .toList();

          return Expanded(
            child: GestureDetector(
              onTap: () => _onDaySelected(day),
              child: AnimatedContainer(
                duration: kAnimationFast,
                curve: kCurveEmphasized,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
                decoration: BoxDecoration(
                  // Today = light fill, Selected = primary fill
                  color: isSelected
                      ? colorScheme.primary
                      : isToday
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                  // Selected gets outline when also today
                  border: isSelected && isToday
                      ? Border.all(
                          color: colorScheme.primary,
                          width: kBorderWidthMedium,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Day Name
                    Text(
                      DateFormat('E').format(day).substring(0, 1),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: kFontWeightMedium,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : isToday
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Day Number
                    Text(
                      day.day.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: kFontWeightBold,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : isToday
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Entry indicator squares (status colored)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dayEntries.take(3).map((entry) {
                        final statusColor = _getStatusColor(entry.status);
                        return Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            color: isSelected
                                ? colorScheme.onPrimary.withValues(
                                    alpha: kOpacityMedium,
                                  )
                                : isToday
                                ? colorScheme.onPrimaryContainer.withValues(
                                    alpha: kOpacityMedium,
                                  )
                                : statusColor,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );

    final isViewingToday = _isToday(_selectedDate);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        calendarRow,
        // Today button (left) + Date range (right) in same row - no nudging
        Padding(
          padding: const EdgeInsets.only(top: kSpacingXS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Today button (only when not viewing today)
              if (!isViewingToday)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                      _calculateEntriesForWeek(_selectedDate);
                      _updateDayEntries();
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                        size: 12,
                        color: colorScheme.primary,
                      ),
                      Text(
                        'Today',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: kFontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              // Date range
              Text(
                '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(EntryStatus status) {
    return entryStatusVisual(context, status, disabled: false).color;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  void _showEntryActionSheet(CalculatedEntry entry, {EntryStatus? initialStatus}) {
    Future<void> cancelNotificationForEntry() async {
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

    EntryActionSheet.show(
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
          scheduleName: entry.scheduleName,
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
        await cancelNotificationForEntry();

        // Deduct stock when entry is taken
        final medBox = Hive.box<Medication>('medications');
        final currentMed = medBox.get(widget.medication.id);
        if (currentMed != null) {
          final schedule = Hive.box<Schedule>('schedules').get(entry.scheduleId);
          final effectiveEntryValue = request.actualEntryValue ?? entry.entryValue;
          final effectiveEntryUnit = request.actualEntryUnit ?? entry.entryUnit;
          final delta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: currentMed,
            schedule: schedule,
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
        setState(() {
          _calculateEntriesForWeek(_selectedDate);
          _updateDayEntries();
        });
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
          scheduleName: entry.scheduleName,
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

        await cancelNotificationForEntry();
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
            body: '${entry.scheduleName} | Snoozed until $time',
            payload:
                'entry:${entry.scheduleId}:${entry.scheduledTime.millisecondsSinceEpoch}',
            actions: NotificationService.upcomingEntryActions,
            expandedLines: <String>[entry.scheduleName, 'Snoozed until $time'],
          );
        }

        if (!mounted) return;
        setState(() {
          _calculateEntriesForWeek(_selectedDate);
          _updateDayEntries();
        });

        final now = DateTime.now();
        final sameDay =
            request.actionTime.year == now.year &&
            request.actionTime.month == now.month &&
            request.actionTime.day == now.day;
        final time = DateTimeFormatter.formatTime(context, request.actionTime);
        final label = sameDay
            ? 'Reminder snoozed until $time'
            : 'Reminder snoozed until ${MaterialLocalizations.of(context).formatMediumDate(request.actionTime)} | $time';
        showAppSnackBar(context, label);
      },
      onSkip: (request) async {
        final logId = EntryLogIds.occurrenceId(
          scheduleId: entry.scheduleId,
          scheduledTime: entry.scheduledTime,
        );
        final log = EntryLog(
          id: logId,
          scheduleId: entry.scheduleId,
          scheduleName: entry.scheduleName,
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
        await cancelNotificationForEntry();

        if (!mounted) return;
        setState(() {
          _calculateEntriesForWeek(_selectedDate);
          _updateDayEntries();
        });
        showAppSnackBar(context, 'Entry skipped');
      },
      onDelete: (request) async {
        final baseId = EntryLogIds.occurrenceId(
          scheduleId: entry.scheduleId,
          scheduledTime: entry.scheduledTime,
        );
        final logBox = Hive.box<EntryLog>('entry_logs');
        final existingLog =
            logBox.get(baseId) ??
            logBox.get(EntryLogIds.legacySnoozeIdFromBase(baseId));

        // When deleting/undoing a entry, restore the stock if it was taken
        if (existingLog != null && existingLog.action == EntryAction.logged) {
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(widget.medication.id);
          if (currentMed != null) {
            final schedule = Hive.box<Schedule>(
              'schedules',
            ).get(entry.scheduleId);
            final oldValue =
                existingLog.actualEntryValue ?? existingLog.entryValue;
            final oldUnit = existingLog.actualEntryUnit ?? existingLog.entryUnit;
            final delta = MedicationStockAdjustment.tryCalculateStockDelta(
              medication: currentMed,
              schedule: schedule,
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
        await cancelNotificationForEntry();

        if (!mounted) return;
        setState(() {
          _calculateEntriesForWeek(_selectedDate);
          _updateDayEntries();
        });
        showAppSnackBar(context, 'Entry removed');
      },
    );
  }
}
