// ignore_for_file: unused_element, unused_local_variable

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/notifications/low_stock_notifier.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/widgets/dose_card.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';
import 'package:dosifi_v5/src/widgets/dose_status_badge.dart';
import 'package:dosifi_v5/src/widgets/dose_status_ui.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class NextDoseCard extends StatefulWidget {
  const NextDoseCard({
    required this.medication,
    required this.schedules,
    super.key,
  });

  final Medication medication;
  final List<Schedule> schedules;

  @override
  State<NextDoseCard> createState() => _NextDoseCardState();
}

class _NextDoseCardState extends State<NextDoseCard>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;

  // Cache of calculated doses for the selected week
  List<CalculatedDose> _weekDoses = [];

  // Doses for the currently selected day
  List<CalculatedDose> _dayDoses = [];

  @override
  void initState() {
    super.initState();
    // Always default to today when entering medication details
    _selectedDate = DateTime.now();
    _calculateDosesForWeek(_selectedDate);
    _updateDayDoses();
  }

  void _findNextDose() {
    // Simple logic to find the next future dose and jump to it
    final now = DateTime.now();
    CalculatedDose? next;

    // Look ahead 30 days
    for (int i = 0; i < 30; i++) {
      final date = now.add(Duration(days: i));
      final doses = _calculateDosesForDay(date);
      final futureDoses = doses
          .where((d) => d.scheduledTime.isAfter(now))
          .toList();

      if (futureDoses.isNotEmpty) {
        futureDoses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        next = futureDoses.first;
        break;
      }
    }

    if (next != null) {
      setState(() {
        _selectedDate = next!.scheduledTime;
        _calculateDosesForWeek(_selectedDate);
        _updateDayDoses();
      });
    }
  }

  void _calculateDosesForWeek(DateTime date) {
    // Calculate start of week (Monday)
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    _weekDoses.clear();

    // This is a simplified calculation. In a real app, we'd use a robust scheduler service.
    // For now, we iterate days and schedules.
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      _weekDoses.addAll(_calculateDosesForDay(day));
    }
  }

  List<CalculatedDose> _calculateDosesForDay(DateTime date) {
    final doses = <CalculatedDose>[];
    final logsBox = Hive.box<DoseLog>('dose_logs');

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
        // Create dose times
        // Use timesOfDay (minutes from midnight)
        final times = schedule.timesOfDay ?? [schedule.minutesOfDay];

        for (final minutes in times) {
          final hour = minutes ~/ 60;
          final minute = minutes % 60;
          final dt = DateTime(date.year, date.month, date.day, hour, minute);

          // Check status
          final logId = '${schedule.id}_${dt.millisecondsSinceEpoch}';
          final log = logsBox.get(logId);

          doses.add(
            CalculatedDose(
              scheduleId: schedule.id,
              scheduleName: schedule.name,
              medicationName: widget.medication.name,
              scheduledTime: dt,
              doseValue: schedule.doseValue,
              doseUnit: schedule.doseUnit,
              existingLog: log,
            ),
          );
        }
      }
    }

    doses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return doses;
  }

  String _formLabel(MedicationForm form) {
    return form.toString().split('.').last; // Simplified
  }

  void _updateDayDoses() {
    _dayDoses = _weekDoses
        .where(
          (d) =>
              d.scheduledTime.year == _selectedDate.year &&
              d.scheduledTime.month == _selectedDate.month &&
              d.scheduledTime.day == _selectedDate.day,
        )
        .toList();
    _dayDoses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      // If we moved to a different week, recalculate
      final currentWeekStart = _weekDoses.isNotEmpty
          ? _weekDoses.first.scheduledTime.subtract(
              Duration(days: _weekDoses.first.scheduledTime.weekday - 1),
            )
          : DateTime.now(); // Fallback

      // Check if date is outside the currently calculated week range
      // Actually, simpler to just always recalculate for the week of the selected date
      _calculateDosesForWeek(date);
      _updateDayDoses();
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
        // Doses for selected day
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
              child: _dayDoses.isEmpty
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
                        for (int i = 0; i < _dayDoses.length; i++) ...[
                          _buildDoseCardContent(
                            _dayDoses[i],
                            i,
                            _dayDoses.length,
                          ),
                          if (i != _dayDoses.length - 1)
                            const SizedBox(height: kSpacingXS),
                        ],
                      ],
                    ),
            ),
          ),
        ),

        // Day and Date centered below dose card (compact)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
          child: Center(
            child: Text(
              DateFormat('EEEE, MMMM d').format(_selectedDate),
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

  Widget _buildDoseCardContent(CalculatedDose dose, int index, int total) {
    final schedule = widget.schedules.cast<Schedule?>().firstWhere(
      (s) => s?.id == dose.scheduleId,
      orElse: () => null,
    );

    final strengthLabel = MedicationDisplayHelpers.strengthOrConcentrationLabel(
      widget.medication,
    );

    final metrics = schedule == null
        ? '${_formatNumber(dose.doseValue)} ${dose.doseUnit}'
        : _doseMetricsLabel(schedule);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kSpacingXS),
      decoration: buildInsetSectionDecoration(context: context),
      child: DoseCard(
        dose: dose,
        medicationName: widget.medication.name,
        strengthOrConcentrationLabel: strengthLabel,
        doseMetrics: metrics,
        compact: true,
        medicationFormIcon: MedicationDisplayHelpers.medicationFormIcon(
          widget.medication.form,
        ),
        doseNumber: schedule == null
            ? null
            : ScheduleOccurrenceService.occurrenceNumber(
                schedule,
                dose.scheduledTime,
              ),
        onQuickAction: (status) =>
            _showDoseActionSheet(dose, initialStatus: status),
        onTap: () => _showDoseActionSheet(dose),
      ),
    );
  }

  String _doseMetricsLabel(Schedule schedule) {
    final summary = MedicationDisplayHelpers.doseMetricsSummary(
      widget.medication,
      doseTabletQuarters: schedule.doseTabletQuarters,
      doseCapsules: schedule.doseCapsules,
      doseSyringes: schedule.doseSyringes,
      doseVials: schedule.doseVials,
      doseMassMcg: schedule.doseMassMcg?.toDouble(),
      doseVolumeMicroliter: schedule.doseVolumeMicroliter?.toDouble(),
      syringeUnits: schedule.doseIU?.toDouble(),
    );
    if (summary.isNotEmpty) return summary;
    return '${_formatNumber(schedule.doseValue)} ${schedule.doseUnit}';
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SizedBox(
      height: 72,
      child: Center(
        child: Text(
          'No doses scheduled',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildDoseCard(CalculatedDose dose, int index, int total) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTaken = dose.status == DoseStatus.taken;
    final isOverdue = dose.status == DoseStatus.overdue;
    final isSkipped = dose.status == DoseStatus.skipped;
    final isSnoozed = dose.status == DoseStatus.snoozed;

    Color cardColor = colorScheme.surface;
    Color borderColor = colorScheme.outlineVariant;

    if (isTaken) {
      cardColor = Colors.green.withValues(alpha: 0.1);
      borderColor = Colors.green.withValues(alpha: 0.5);
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
        onTap: () => _showDoseActionSheet(dose),
        borderRadius: BorderRadius.circular(12), // Slightly less rounded
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (total > 1)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                      ? Colors.green.withValues(alpha: 0.2)
                      : (isOverdue
                            ? colorScheme.errorContainer
                            : colorScheme.primaryContainer),
                ),
                child: Icon(
                  statusIcon,
                  size: 18,
                  color: isTaken
                      ? Colors.green
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
                    // ROW 1: "Next Dose" Label & Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Next Dose ${DateFormat('MMM d').format(dose.scheduledTime)}',
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
                                  fontSize: 10,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // ROW 2: Time (Big)
                    Text(
                      DateFormat('h:mm a').format(dose.scheduledTime),
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
                          '${_formatNumber(dose.doseValue)} ${dose.doseUnit}', // "1 tablet"
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        DoseStatusBadge(
                          status: dose.status,
                          disabled:
                              !(Hive.box<Schedule>('schedules')
                                      .get(dose.scheduleId)
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
              _calculateDosesForWeek(_selectedDate);
              _updateDayDoses(); // Sync dose card with new date
            });
          } else if (details.primaryVelocity! > 0) {
            // Swipe right - go to previous week (same day of week)
            setState(() {
              final newDate = _selectedDate.subtract(const Duration(days: 7));
              _selectedDate = newDate;
              _calculateDosesForWeek(_selectedDate);
              _updateDayDoses(); // Sync dose card with new date
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

          // Find doses for this day
          final dayDoses = _weekDoses
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
                    // Dose indicator squares (status colored)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dayDoses.take(3).map((dose) {
                        final statusColor = _getStatusColor(dose.status);
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
                      _calculateDosesForWeek(_selectedDate);
                      _updateDayDoses();
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

  Color _getStatusColor(DoseStatus status) {
    return doseStatusVisual(context, status, disabled: false).color;
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

  void _showDoseActionSheet(CalculatedDose dose, {DoseStatus? initialStatus}) {
    DoseActionSheet.show(
      context,
      dose: dose,
      initialStatus: initialStatus,
      onMarkTaken: (request) async {
        final logId =
            '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
        final log = DoseLog(
          id: logId,
          scheduleId: dose.scheduleId,
          scheduleName: dose.scheduleName,
          medicationId: widget.medication.id,
          medicationName: widget.medication.name,
          scheduledTime: dose.scheduledTime,
          actionTime: request.actionTime,
          doseValue: dose.doseValue,
          doseUnit: dose.doseUnit,
          action: DoseAction.taken,
          actualDoseValue: request.actualDoseValue,
          actualDoseUnit: request.actualDoseUnit,
          notes: request.notes?.isEmpty ?? true ? null : request.notes,
        );

        final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
        await repo.upsert(log);

        // Deduct stock when dose is taken
        final medBox = Hive.box<Medication>('medications');
        final currentMed = medBox.get(widget.medication.id);
        if (currentMed != null) {
          final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);
          final effectiveDoseValue = request.actualDoseValue ?? dose.doseValue;
          final effectiveDoseUnit = request.actualDoseUnit ?? dose.doseUnit;
          final delta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: currentMed,
            schedule: schedule,
            doseValue: effectiveDoseValue,
            doseUnit: effectiveDoseUnit,
            preferDoseValue: request.actualDoseValue != null,
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
          _calculateDosesForWeek(_selectedDate);
          _updateDayDoses();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dose marked as taken')));
      },
      onSnooze: (request) async {
        final logId =
            '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}_snooze';
        final log = DoseLog(
          id: logId,
          scheduleId: dose.scheduleId,
          scheduleName: dose.scheduleName,
          medicationId: widget.medication.id,
          medicationName: widget.medication.name,
          scheduledTime: dose.scheduledTime,
          actionTime: request.actionTime,
          doseValue: dose.doseValue,
          doseUnit: dose.doseUnit,
          action: DoseAction.snoozed,
          actualDoseValue: request.actualDoseValue,
          actualDoseUnit: request.actualDoseUnit,
          notes: request.notes?.isEmpty ?? true ? null : request.notes,
        );

        final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
        await repo.upsert(log);

        if (!mounted) return;
        setState(() {
          _calculateDosesForWeek(_selectedDate);
          _updateDayDoses();
        });

        final now = DateTime.now();
        final sameDay =
            request.actionTime.year == now.year &&
            request.actionTime.month == now.month &&
            request.actionTime.day == now.day;
        final time = TimeOfDay.fromDateTime(request.actionTime).format(context);
        final label = sameDay
            ? 'Dose snoozed until $time'
            : 'Dose snoozed until ${MaterialLocalizations.of(context).formatMediumDate(request.actionTime)} • $time';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(label)));
      },
      onSkip: (request) async {
        final logId =
            '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
        final log = DoseLog(
          id: logId,
          scheduleId: dose.scheduleId,
          scheduleName: dose.scheduleName,
          medicationId: widget.medication.id,
          medicationName: widget.medication.name,
          scheduledTime: dose.scheduledTime,
          actionTime: request.actionTime,
          doseValue: dose.doseValue,
          doseUnit: dose.doseUnit,
          action: DoseAction.skipped,
          actualDoseValue: request.actualDoseValue,
          actualDoseUnit: request.actualDoseUnit,
          notes: request.notes?.isEmpty ?? true ? null : request.notes,
        );

        final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
        await repo.upsert(log);

        if (!mounted) return;
        setState(() {
          _calculateDosesForWeek(_selectedDate);
          _updateDayDoses();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dose skipped')));
      },
      onDelete: (request) async {
        final logId =
            '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
        final logBox = Hive.box<DoseLog>('dose_logs');
        final existingLog = logBox.get(logId);

        // When deleting/undoing a dose, restore the stock if it was taken
        if (existingLog != null && existingLog.action == DoseAction.taken) {
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(widget.medication.id);
          if (currentMed != null) {
            final schedule = Hive.box<Schedule>(
              'schedules',
            ).get(dose.scheduleId);
            final oldValue =
                existingLog.actualDoseValue ?? existingLog.doseValue;
            final oldUnit = existingLog.actualDoseUnit ?? existingLog.doseUnit;
            final delta = MedicationStockAdjustment.tryCalculateStockDelta(
              medication: currentMed,
              schedule: schedule,
              doseValue: oldValue,
              doseUnit: oldUnit,
              preferDoseValue: existingLog.actualDoseValue != null,
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

        final repo = DoseLogRepository(logBox);
        await repo.delete(logId);

        if (!mounted) return;
        setState(() {
          _calculateDosesForWeek(_selectedDate);
          _updateDayDoses();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dose log deleted')));
      },
    );
  }
}
