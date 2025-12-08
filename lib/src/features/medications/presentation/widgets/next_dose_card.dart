import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Card Area - "Active Schedule Card" look
        Container(
          height: 100, // Compact fixed height
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Stack(
            children: [
              // Page View
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _dayDoses.isEmpty
                    ? Center(
                        child: Text(
                          'No doses',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    : PageView.builder(
                        controller: _dosePageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _dayDoses.length,
                        itemBuilder: (context, index) {
                          return _buildDoseCardContent(_dayDoses[index], index, _dayDoses.length);
                        },
                      ),
              ),

              // Left Arrow (conditionally visible)
              if (_dayDoses.length > 1)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _dosePageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 48),
                      iconSize: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              // Right Arrow (conditionally visible)
              if (_dayDoses.length > 1)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _dosePageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 48),
                      iconSize: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8), // Reduced spacing

        // Calendar Strip
        _buildCalendarStrip(),
      ],
    );
  }

  // NOTE: Replaced _buildDoseCard with _buildDoseCardContent that doesn't have its own container
  // effectively merging it into the parent container look or keeping it transparent.
  // Wait, if I want swipeable pages, the "Card" look should probably remain?
  // "Active Schedule card looks good. This is how I want the next dose card to look like."
  // The Active Schedule card is a single container.
  // So the Next Dose Card should be a single container that swipes CONTENT.
  // YES.

  Widget _buildDoseCardContent(CalculatedDose dose, int index, int total) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTaken = dose.status == DoseStatus.taken;
    final isOverdue = dose.status == DoseStatus.overdue;
    final isSkipped = dose.status == DoseStatus.skipped;
    final isSnoozed = dose.status == DoseStatus.snoozed;

    // Determine Icon and Colors using design system
    IconData statusIcon = Icons.notifications_active_rounded;
    Color iconColor = colorScheme.primary;
    Color badgeBg = colorScheme.primary.withValues(alpha: 0.12);
    
    // Dynamic status label
    String statusLabel = 'Next Dose';
    if (isTaken) {
      statusIcon = Icons.check_circle_rounded;
      iconColor = Colors.green.shade600;
      badgeBg = Colors.green.withValues(alpha: 0.12);
      statusLabel = 'Taken';
    } else if (isSkipped) {
      statusIcon = Icons.cancel_rounded;
      iconColor = Colors.grey.shade600;
      badgeBg = Colors.grey.withValues(alpha: 0.12);
      statusLabel = 'Skipped';
    } else if (isSnoozed) {
      statusIcon = Icons.snooze_rounded;
      iconColor = Colors.orange.shade600;
      badgeBg = Colors.orange.withValues(alpha: 0.12);
      statusLabel = 'Snoozed';
    } else if (isOverdue) {
      statusIcon = Icons.warning_rounded;
      iconColor = Colors.red.shade600;
      badgeBg = Colors.red.withValues(alpha: 0.12);
      statusLabel = 'Missed';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingS),
      child: InkWell(
        onTap: () => _showDoseActionSheet(dose),
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        child: Container(
          decoration: softWhiteCardDecoration(context),
          padding: const EdgeInsets.symmetric(
            horizontal: kCardPadding,
            vertical: kCardPadding + 2,
          ),
          child: Row(
            children: [
              // Leading icon badge - matching medication type cards
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                ),
                child: Icon(statusIcon, size: 20, color: iconColor),
              ),
              const SizedBox(width: kCardPadding),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSpacingS - 1,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(kBorderRadiusChip),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: iconColor,
                              fontWeight: kFontWeightBold,
                              letterSpacing: 0.6,
                              fontSize: 9,
                            ),
                      ),
                    ),
                    const SizedBox(height: kSpacingXS + 2),
                    
                    // Time - Large and Bold
                    Text(
                      DateFormat('h:mm a').format(dose.scheduledTime),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: kFontWeightExtraBold,
                            color: colorScheme.onSurface.withValues(alpha: kOpacityHigh),
                            height: 1.0,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: kSpacingXS - 1),
                    
                    // Dose Amount
                    Row(
                      children: [
                        Icon(
                          Icons.medication_rounded,
                          size: kIconSizeSmall - 2,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMedium),
                        ),
                        const SizedBox(width: kSpacingXS),
                        Text(
                          '${_formatNumber(dose.doseValue)} ${dose.doseUnit}',
                          style: bodyTextStyle(context)?.copyWith(
                                fontWeight: kFontWeightSemiBold,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Right Side: Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM').format(dose.scheduledTime).toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
                          fontWeight: kFontWeightBold,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                  ),
                  Text(
                    DateFormat('d').format(dose.scheduledTime),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: kOpacityHigh),
                          fontWeight: kFontWeightExtraBold,
                          height: 1.0,
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


  Widget _buildEmptyState() {
    return const SizedBox.shrink();
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
    if (isTaken) statusIcon = Icons.check;
    else if (isSkipped) statusIcon = Icons.block;
    else if (isSnoozed) statusIcon = Icons.snooze;
    else if (isOverdue) statusIcon = Icons.warning_amber_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Reduced vertical padding
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced internal padding
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
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                        if (total > 1)
                          Text(
                            '${index + 1}/$total',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                         if (dose.status != DoseStatus.pending)
                          _buildStatusBadge(dose.status),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
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
      height: 72, // Slightly reduced
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
                  borderRadius: BorderRadius.circular(8), // Less rounded, "squarer" (was 8, keeping 8 is actually square-ish for small items. User said "some square elements". Maybe reduce to 4?)
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
                        fontSize: 9,
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                                shape: BoxShape.rectangle, // SQUARE ELEMENTS
                                borderRadius: BorderRadius.circular(1),
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

        // Deduct stock when dose is taken
        final medBox = Hive.box<Medication>('medications');
        final currentMed = medBox.get(widget.medication.id);
        if (currentMed != null) {
          final newStockValue = (currentMed.stockValue - dose.doseValue).clamp(0.0, double.infinity);
          await medBox.put(
            currentMed.id,
            currentMed.copyWith(stockValue: newStockValue),
          );
        }

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
      onDelete: () async {
        // When deleting/undoing a dose, restore the stock if it was taken
        final logId =
            '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
        final logBox = Hive.box<DoseLog>('dose_logs');
        final existingLog = logBox.get(logId);
        
        if (existingLog != null && existingLog.action == DoseAction.taken) {
          // Restore stock when undoing a taken dose
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(widget.medication.id);
          if (currentMed != null) {
            final newStockValue = currentMed.stockValue + dose.doseValue;
            await medBox.put(
              currentMed.id,
              currentMed.copyWith(stockValue: newStockValue),
            );
          }
        }

        final repo = DoseLogRepository(logBox);
        await repo.delete(logId);

        if (mounted) {
          setState(() {
            _calculateDosesForWeek(_selectedDate);
            _updateDayDoses();
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Dose log deleted')));
        }
      },
    );
  }
}
