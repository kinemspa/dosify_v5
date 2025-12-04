import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';
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

class _NextDoseCardState extends State<NextDoseCard> {
  late DateTime _selectedDate;
  late PageController _dosePageController;

  // Cache of calculated doses for the selected week
  List<CalculatedDose> _weekDoses = [];

  // Doses for the currently selected day
  List<CalculatedDose> _dayDoses = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dosePageController = PageController(viewportFraction: 0.9);
    _calculateDosesForWeek(_selectedDate);
    _updateDayDoses();

    // Try to find the actual next dose to set initial state
    _findNextDose();
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
              doseUnit: _formLabel(widget.medication.form),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Card Area
        SizedBox(
          height: 140,
          child: _dayDoses.isEmpty
              ? _buildEmptyState()
              : PageView.builder(
                  controller: _dosePageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _dayDoses.length,
                  itemBuilder: (context, index) {
                    return _buildDoseCard(
                      _dayDoses[index],
                      index,
                      _dayDoses.length,
                    );
                  },
                ),
        ),

        const SizedBox(height: kSpacingM),

        // Calendar Strip
        _buildCalendarStrip(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadiusM),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Center(
        child: Text(
          'No doses scheduled for ${DateFormat('EEE, MMM d').format(_selectedDate)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildDoseCard(CalculatedDose dose, int index, int total) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTaken = dose.status == DoseStatus.taken;
    final isOverdue = dose.status == DoseStatus.overdue;

    Color cardColor = colorScheme.surface;
    Color borderColor = colorScheme.outlineVariant;

    if (isTaken) {
      cardColor = Colors.green.withValues(alpha: 0.1);
      borderColor = Colors.green.withValues(alpha: 0.5);
    } else if (isOverdue) {
      cardColor = colorScheme.errorContainer.withValues(alpha: 0.2);
      borderColor = colorScheme.error.withValues(alpha: 0.5);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: () => _showDoseActionSheet(dose),
        borderRadius: BorderRadius.circular(kBorderRadiusM),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(kBorderRadiusM),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (total > 1)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
            ],
          ),
          padding: const EdgeInsets.all(kSpacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next Dose ${DateFormat('MMM d').format(dose.scheduledTime)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (total > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}/$total',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: kSpacingS),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('h:mm a').format(dose.scheduledTime),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOverdue
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: kSpacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatNumber(dose.doseValue)} ${dose.doseUnit}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        _buildStatusBadge(dose.status),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DoseStatus status) {
    Color color;
    String label;

    switch (status) {
      case DoseStatus.taken:
        color = Colors.green;
        label = 'Taken';
        break;
      case DoseStatus.skipped:
        color = Colors.grey;
        label = 'Skipped';
        break;
      case DoseStatus.snoozed:
        color = Colors.orange;
        label = 'Snoozed';
        break;
      case DoseStatus.overdue:
        color = Theme.of(context).colorScheme.error;
        label = 'Overdue';
        break;
      case DoseStatus.pending:
        color = Theme.of(context).colorScheme.primary;
        label = 'Scheduled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCalendarStrip() {
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final day = startOfWeek.add(Duration(days: index));
          final isSelected =
              day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;
          final isToday = _isToday(day);

          // Find doses for this day to show indicators
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
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday && !isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E').format(day).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Dose Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dayDoses
                          .take(3)
                          .map(
                            (d) => Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getStatusColor(d.status),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getStatusColor(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return Colors.green;
      case DoseStatus.overdue:
        return Theme.of(context).colorScheme.error;
      case DoseStatus.skipped:
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
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

  void _showDoseActionSheet(CalculatedDose dose) {
    DoseActionSheet.show(
      context,
      dose: dose,
      onMarkTaken: (notes) async {
        final logId =
            '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
        final log = DoseLog(
          id: logId,
          scheduleId: dose.scheduleId,
          scheduleName: dose.scheduleName,
          medicationId: widget.medication.id,
          medicationName: widget.medication.name,
          scheduledTime: dose.scheduledTime,
          doseValue: dose.doseValue,
          doseUnit: dose.doseUnit,
          action: DoseAction.taken,
          notes: notes?.isEmpty ?? true ? null : notes,
        );

        final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
        await repo.upsert(log);

        if (mounted) {
          setState(() {
            _calculateDosesForWeek(_selectedDate);
            _updateDayDoses();
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Dose marked as taken')));
        }
      },
      onSnooze: () {},
      onSkip: () async {
        final logId =
            '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
        final log = DoseLog(
          id: logId,
          scheduleId: dose.scheduleId,
          scheduleName: dose.scheduleName,
          medicationId: widget.medication.id,
          medicationName: widget.medication.name,
          scheduledTime: dose.scheduledTime,
          doseValue: dose.doseValue,
          doseUnit: dose.doseUnit,
          action: DoseAction.skipped,
        );

        final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
        await repo.upsert(log);

        if (mounted) {
          setState(() {
            _calculateDosesForWeek(_selectedDate);
            _updateDayDoses();
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Dose skipped')));
        }
      },
      onDelete: () {},
    );
  }
}
