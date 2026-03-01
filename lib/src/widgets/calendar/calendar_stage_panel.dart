// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_shared.dart';
import 'package:dosifi_v5/src/widgets/dose_card.dart';
import 'package:dosifi_v5/src/widgets/dose_summary_row.dart';

/// Displays a scrollable list of doses for a single day, grouped by hour.
///
/// Used in [DoseCalendarWidget] when the view is set to `CalendarView.day`
/// and `requireHourSelectionInDayView` is false. The widget owns its own
/// scroll state and scroll-hint visibility.
class CalendarDayStagePanel extends StatefulWidget {
  const CalendarDayStagePanel({
    super.key,
    required this.doses,
    required this.currentDate,
    required this.isFullVariant,
    required this.onDoseTap,
    required this.onOpenDoseActionSheet,
    required this.onDateChanged,
  });

  /// All calculated doses for the current date range.
  final List<CalculatedDose> doses;

  /// The date being shown in day-stage mode.
  final DateTime currentDate;

  /// Whether the parent uses [CalendarVariant.full] (affects bottom padding).
  final bool isFullVariant;

  /// Called when the user taps a dose card (primary tap).
  final void Function(CalculatedDose dose) onDoseTap;

  /// Called when the user presses a quick-action button on a dose card.
  /// Pass `null` for [initialStatus] to open the sheet at the default tab.
  final void Function(CalculatedDose dose, {DoseStatus? initialStatus})
  onOpenDoseActionSheet;

  /// Called when the user swipes left/right to change the displayed date.
  final void Function(DateTime date) onDateChanged;

  @override
  State<CalendarDayStagePanel> createState() => _CalendarDayStagePanelState();
}

class _CalendarDayStagePanelState extends State<CalendarDayStagePanel> {
  final ScrollController _scrollController = ScrollController();
  bool _showDownHint = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateDownHint(ScrollMetrics metrics) {
    final shouldShow = metrics.maxScrollExtent > (metrics.pixels + 0.5);
    if (_showDownHint == shouldShow) return;
    if (!mounted) return;
    setState(() => _showDownHint = shouldShow);
  }

  Widget _wrapWithScrollHint(Widget child) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical) {
              _updateDownHint(notification.metrics);
            }
            return false;
          },
          child: child,
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              opacity: _showDownHint ? 1 : 0,
              duration: kAnimationFast,
              curve: kCurveSnappy,
              child: Padding(
                padding: kCalendarStageScrollHintPadding,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: kCalendarStageScrollHintIconSize,
                  color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoseCardFor(CalculatedDose dose) {
    final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);
    final med = (schedule?.medicationId != null)
        ? Hive.box<Medication>('medications').get(schedule!.medicationId)
        : null;

    final strengthLabel = med != null
        ? MedicationDisplayHelpers.strengthOrConcentrationLabel(med)
        : '';

    final metrics = med != null && schedule != null
        ? schedule.displayMetrics(med)
        : '${dose.doseValue} ${dose.doseUnit}';

    return DoseCard(
      dose: dose,
      medicationName: med?.name ?? dose.medicationName,
      strengthOrConcentrationLabel: strengthLabel,
      doseMetrics: metrics,
      isActive: schedule?.isActive ?? true,
      medicationFormIcon: med == null
          ? null
          : MedicationDisplayHelpers.medicationFormIcon(med.form),
      doseNumber: schedule == null
          ? null
          : ScheduleOccurrenceService.occurrenceNumber(
              schedule,
              dose.scheduledTime,
            ),
      onQuickAction: (status) => widget.onOpenDoseActionSheet(
        dose,
        initialStatus: status,
      ),
      onTap: () => widget.onDoseTap(dose),
    );
  }

  Widget _buildHourSection({
    required int hour,
    required List<CalculatedDose> hourDoses,
  }) {
    return Padding(
      padding: kCalendarStageHourRowPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: kCalendarStageHourLabelPadding,
            child: Text(
              formatCalendarHour(hour),
              textAlign: TextAlign.left,
              style: calendarStageHourLabelTextStyle(context),
            ),
          ),
          for (final dose in hourDoses)
            Padding(
              padding: kCalendarStageDoseCardPadding,
              child: _buildDoseCardFor(dose),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      _updateDownHint(_scrollController.position);
    });

    final dayDoses = widget.doses.where((dose) {
      return dose.scheduledTime.year == widget.currentDate.year &&
          dose.scheduledTime.month == widget.currentDate.month &&
          dose.scheduledTime.day == widget.currentDate.day;
    }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    if (dayDoses.isEmpty) {
      return const CalendarNoDosesState();
    }

    final dosesByHour = <int, List<CalculatedDose>>{};
    for (final dose in dayDoses) {
      dosesByHour.putIfAbsent(dose.scheduledTime.hour, () => []).add(dose);
    }
    final hours = dosesByHour.keys.toList()..sort();

    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final listBottomPadding = widget.isFullVariant
        ? safeBottom + kPageBottomPadding
        : safeBottom + kSpacingXXL + kSpacingXL;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -500) {
            widget.onDateChanged(
              widget.currentDate.add(const Duration(days: 1)),
            );
          } else if (details.primaryVelocity! > 500) {
            widget.onDateChanged(
              widget.currentDate.subtract(const Duration(days: 1)),
            );
          }
        }
      },
      child: _wrapWithScrollHint(
        ListView.builder(
          controller: _scrollController,
          padding: calendarStageListPadding(listBottomPadding),
          itemCount: hours.length,
          itemBuilder: (context, index) {
            final hour = hours[index];
            final hourDoses = dosesByHour[hour] ?? const [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (index != 0)
                  Divider(
                    height: kSpacingM,
                    thickness: kBorderWidthThin,
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: kOpacityVeryLow),
                  ),
                _buildHourSection(hour: hour, hourDoses: hourDoses),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A compact panel showing dose cards for a selected hour in day-view mode.
///
/// Used in [DoseCalendarWidget] when `requireHourSelectionInDayView` is true.
class CalendarSelectedHourPanel extends StatelessWidget {
  const CalendarSelectedHourPanel({
    super.key,
    required this.doses,
    required this.currentDate,
    required this.selectedHour,
    required this.isFullVariant,
    required this.onDoseTap,
    required this.onOpenDoseActionSheet,
  });

  final List<CalculatedDose> doses;
  final DateTime currentDate;
  final int selectedHour;
  final bool isFullVariant;
  final void Function(CalculatedDose dose) onDoseTap;
  final void Function(CalculatedDose dose, {DoseStatus? initialStatus})
  onOpenDoseActionSheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dayDoses = doses.where((dose) {
      return dose.scheduledTime.year == currentDate.year &&
          dose.scheduledTime.month == currentDate.month &&
          dose.scheduledTime.day == currentDate.day &&
          dose.scheduledTime.hour == selectedHour;
    }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final listBottomPadding = isFullVariant
        ? safeBottom + kPageBottomPadding
        : safeBottom + kSpacingL;

    return Padding(
      padding: const EdgeInsets.only(top: kSpacingS),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingL,
                vertical: kSpacingM,
              ),
              child: Text(
                'Hour: ${formatCalendarHour(selectedHour)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: dayDoses.isEmpty
                  ? const CalendarNoDosesState(showIcon: false, compact: true)
                  : ListView.builder(
                      padding: calendarStageListPadding(listBottomPadding),
                      itemCount: dayDoses.length,
                      itemBuilder: (context, index) {
                        final dose = dayDoses[index];
                        final schedule =
                            Hive.box<Schedule>('schedules').get(dose.scheduleId);
                        final med = (schedule?.medicationId != null)
                            ? Hive.box<Medication>(
                                'medications',
                              ).get(schedule!.medicationId)
                            : null;

                        if (schedule != null && med != null) {
                          final strengthLabel =
                              MedicationDisplayHelpers
                                  .strengthOrConcentrationLabel(med);
                          final metrics = schedule.displayMetrics(med);

                          if (strengthLabel.trim().isNotEmpty &&
                              metrics.trim().isNotEmpty) {
                            return DoseCard(
                              dose: dose,
                              medicationName: med.name,
                              strengthOrConcentrationLabel: strengthLabel,
                              doseMetrics: metrics,
                              isActive: schedule.isActive,
                              medicationFormIcon:
                                  MedicationDisplayHelpers.medicationFormIcon(
                                    med.form,
                                  ),
                              doseNumber:
                                  ScheduleOccurrenceService.occurrenceNumber(
                                    schedule,
                                    dose.scheduledTime,
                                  ),
                              onQuickAction: (status) =>
                                  onOpenDoseActionSheet(
                                    dose,
                                    initialStatus: status,
                                  ),
                              onTap: () => onDoseTap(dose),
                            );
                          }
                        }

                        return DoseSummaryRow(
                          dose: dose,
                          showMedicationName: true,
                          onTap: () => onDoseTap(dose),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
