// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_shared.dart';
import 'package:dosifi_v5/src/widgets/entry_card.dart';
import 'package:dosifi_v5/src/widgets/entry_summary_row.dart';

/// Displays a scrollable list of entries for a single day, grouped by hour.
///
/// Used in [EntryCalendarWidget] when the view is set to `CalendarView.day`
/// and `requireHourSelectionInDayView` is false. The widget owns its own
/// scroll state and scroll-hint visibility.
class CalendarDayStagePanel extends StatefulWidget {
  const CalendarDayStagePanel({
    super.key,
    required this.entries,
    required this.currentDate,
    required this.isFullVariant,
    required this.onEntryTap,
    required this.onOpenEntryActionSheet,
    required this.onDateChanged,
  });

  /// All calculated entries for the current date range.
  final List<CalculatedEntry> entries;

  /// The date being shown in day-stage mode.
  final DateTime currentDate;

  /// Whether the parent uses [CalendarVariant.full] (affects bottom padding).
  final bool isFullVariant;

  /// Called when the user taps a entry card (primary tap).
  final void Function(CalculatedEntry entry) onEntryTap;

  /// Called when the user presses a quick-action button on a entry card.
  /// Pass `null` for [initialStatus] to open the sheet at the default tab.
  final void Function(CalculatedEntry entry, {EntryStatus? initialStatus})
  onOpenEntryActionSheet;

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

  Widget _buildEntryCardFor(CalculatedEntry entry) {
    final schedule = Hive.box<Schedule>('schedules').get(entry.scheduleId);
    final med = (schedule?.medicationId != null)
        ? Hive.box<Medication>('medications').get(schedule!.medicationId)
        : null;

    final strengthLabel = med != null
        ? MedicationDisplayHelpers.strengthOrConcentrationLabel(med)
        : '';

    final metrics = med != null && schedule != null
        ? schedule.displayMetrics(med)
        : '${entry.entryValue} ${entry.entryUnit}';

    return EntryCard(
      entry: entry,
      medicationName: med?.name ?? entry.medicationName,
      strengthOrConcentrationLabel: strengthLabel,
      entryMetrics: metrics,
      isActive: schedule?.isActive ?? true,
      medicationFormIcon: med == null
          ? null
          : MedicationDisplayHelpers.medicationFormIcon(med.form),
      entryNumber: schedule == null
          ? null
          : ScheduleOccurrenceService.occurrenceNumber(
              schedule,
              entry.scheduledTime,
            ),
      onQuickAction: (status) => widget.onOpenEntryActionSheet(
        entry,
        initialStatus: status,
      ),
      onTap: () => widget.onEntryTap(entry),
    );
  }

  Widget _buildHourSection({
    required int hour,
    required List<CalculatedEntry> hourEntries,
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
          for (final entry in hourEntries)
            Padding(
              padding: kCalendarStageEntryCardPadding,
              child: _buildEntryCardFor(entry),
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

    final dayEntries = widget.entries.where((entry) {
      return entry.scheduledTime.year == widget.currentDate.year &&
          entry.scheduledTime.month == widget.currentDate.month &&
          entry.scheduledTime.day == widget.currentDate.day;
    }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    if (dayEntries.isEmpty) {
      return const CalendarNoEntriesState();
    }

    final entriesByHour = <int, List<CalculatedEntry>>{};
    for (final entry in dayEntries) {
      entriesByHour.putIfAbsent(entry.scheduledTime.hour, () => []).add(entry);
    }
    final hours = entriesByHour.keys.toList()..sort();

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
            final hourEntries = entriesByHour[hour] ?? const [];
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
                _buildHourSection(hour: hour, hourEntries: hourEntries),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A compact panel showing entry cards for a selected hour in day-view mode.
///
/// Used in [EntryCalendarWidget] when `requireHourSelectionInDayView` is true.
class CalendarSelectedHourPanel extends StatelessWidget {
  const CalendarSelectedHourPanel({
    super.key,
    required this.entries,
    required this.currentDate,
    required this.selectedHour,
    required this.isFullVariant,
    required this.onEntryTap,
    required this.onOpenEntryActionSheet,
  });

  final List<CalculatedEntry> entries;
  final DateTime currentDate;
  final int selectedHour;
  final bool isFullVariant;
  final void Function(CalculatedEntry entry) onEntryTap;
  final void Function(CalculatedEntry entry, {EntryStatus? initialStatus})
  onOpenEntryActionSheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dayEntries = entries.where((entry) {
      return entry.scheduledTime.year == currentDate.year &&
          entry.scheduledTime.month == currentDate.month &&
          entry.scheduledTime.day == currentDate.day &&
          entry.scheduledTime.hour == selectedHour;
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
              child: dayEntries.isEmpty
                  ? const CalendarNoEntriesState(showIcon: false, compact: true)
                  : ListView.builder(
                      padding: calendarStageListPadding(listBottomPadding),
                      itemCount: dayEntries.length,
                      itemBuilder: (context, index) {
                        final entry = dayEntries[index];
                        final schedule =
                            Hive.box<Schedule>('schedules').get(entry.scheduleId);
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
                            return EntryCard(
                              entry: entry,
                              medicationName: med.name,
                              strengthOrConcentrationLabel: strengthLabel,
                              entryMetrics: metrics,
                              isActive: schedule.isActive,
                              medicationFormIcon:
                                  MedicationDisplayHelpers.medicationFormIcon(
                                    med.form,
                                  ),
                              entryNumber:
                                  ScheduleOccurrenceService.occurrenceNumber(
                                    schedule,
                                    entry.scheduledTime,
                                  ),
                              onQuickAction: (status) =>
                                  onOpenEntryActionSheet(
                                    entry,
                                    initialStatus: status,
                                  ),
                              onTap: () => onEntryTap(entry),
                            );
                          }
                        }

                        return EntrySummaryRow(
                          entry: entry,
                          showMedicationName: true,
                          onTap: () => onEntryTap(entry),
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
