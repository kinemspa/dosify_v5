import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A week view showing a 7-column grid with doses.
///
/// Displays 7 days (Mon-Sun) with hourly rows (major hours only).
/// Features:
/// - 7-column grid layout
/// - Day headers with dates
/// - Compact dose indicators
/// - Current day highlight
/// - Tap day header → switch to Day view
/// - Tap dose → select day (prefers [onDayTap] when provided)
/// - Swipe left/right → navigate weeks
class CalendarWeekView extends StatelessWidget {
  const CalendarWeekView({
    required this.startDate,
    required this.doses,
    this.selectedDate,
    this.onDoseTap,
    this.onDateChanged,
    this.onDayTap,
    super.key,
  });

  final DateTime startDate;
  final List<CalculatedDose> doses;
  final DateTime? selectedDate;
  final void Function(CalculatedDose dose)? onDoseTap;
  final void Function(DateTime date)? onDateChanged;
  final void Function(DateTime date)? onDayTap;

  DateTime get endDate => startDate.add(const Duration(days: 6));

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    if (selectedDate == null) return false;
    return date.year == selectedDate!.year &&
        date.month == selectedDate!.month &&
        date.day == selectedDate!.day;
  }

  List<CalculatedDose> _getDosesForDay(DateTime day) {
    return doses.where((dose) {
      return dose.scheduledTime.year == day.year &&
          dose.scheduledTime.month == day.month &&
          dose.scheduledTime.day == day.day;
    }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  @override
  Widget build(BuildContext context) {
    final hasDoses = doses.isNotEmpty;

    if (!hasDoses) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: kSectionSpacing),
            Text(
              'No doses scheduled',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
              ),
            ),
            const SizedBox(height: kCardInnerSpacing),
            Text(
              '${DateFormat.MMMd().format(startDate)} - ${DateFormat.MMMd().format(endDate)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.4 * 255).round()),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (onDateChanged == null) return;

        // Swipe left = next week, swipe right = previous week
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -500) {
            // Swipe left
            onDateChanged!(startDate.add(const Duration(days: 7)));
          } else if (details.primaryVelocity! > 500) {
            // Swipe right
            onDateChanged!(startDate.subtract(const Duration(days: 7)));
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day headers
          _WeekHeader(
            startDate: startDate,
            selectedDate: selectedDate,
            onDayTap: onDayTap,
          ),
          // Week grid
          SizedBox(
            height: kCalendarWeekGridHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(7, (index) {
                final day = startDate.add(Duration(days: index));
                final dayDoses = _getDosesForDay(day);
                final isToday = _isToday(day);
                final isSelected = _isSelected(day);

                return Expanded(
                  child: _DayColumn(
                    date: day,
                    doses: dayDoses,
                    isToday: isToday,
                    isSelected: isSelected,
                    onDoseTap: onDoseTap,
                    onDayTap: onDayTap,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.startDate,
    this.selectedDate,
    this.onDayTap,
  });

  final DateTime startDate;
  final DateTime? selectedDate;
  final void Function(DateTime date)? onDayTap;

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    final selected = selectedDate;
    if (selected == null) return false;
    return date.year == selected.year &&
        date.month == selected.month &&
        date.day == selected.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kCalendarWeekHeaderHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outline.withAlpha((0.2 * 255).round()),
          ),
        ),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final day = startDate.add(Duration(days: index));
          final isToday = _isToday(day);
          final isSelected = _isSelected(day) && !isToday;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Expanded(
            child: InkWell(
              onTap: onDayTap != null ? () => onDayTap!(day) : null,
              child: Container(
                margin: kCalendarWeekHeaderCellMargin,
                decoration: (isToday || isSelected)
                    ? BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(
                                alpha: kOpacityFaint,
                              )
                            : null,
                        border: Border.all(
                          color: colorScheme.primary,
                          width: kBorderWidthThin,
                        ),
                        borderRadius: BorderRadius.circular(
                          kCalendarWeekHeaderCellBorderRadius,
                        ),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.E().format(day),
                      style: calendarWeekHeaderDayLabelTextStyle(context)
                          ?.copyWith(
                            color: isToday
                                ? colorScheme.primary
                                : isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withAlpha(
                                    (0.6 * 255).round(),
                                  ),
                            fontWeight: (isToday || isSelected)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                    ),
                    const SizedBox(height: kCalendarWeekHeaderLabelGap),
                    Text(
                      day.day.toString(),
                      style: calendarWeekHeaderDayNumberTextStyle(context)
                          ?.copyWith(
                            color: isToday
                                ? colorScheme.primary
                                : isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(
                                    alpha: kOpacityHigh,
                                  ),
                            fontWeight: (isToday || isSelected)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
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
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.date,
    required this.doses,
    required this.isToday,
    required this.isSelected,
    this.onDoseTap,
    this.onDayTap,
  });

  final DateTime date;
  final List<CalculatedDose> doses;
  final bool isToday;
  final bool isSelected;
  final void Function(CalculatedDose dose)? onDoseTap;
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final todayFill = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: kOpacityFaint),
      colorScheme.surface,
    );

    return InkWell(
      onTap: onDayTap != null ? () => onDayTap!(date) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? todayFill : null,
          border: Border(
            right: BorderSide(
              color: colorScheme.outline.withAlpha(
                (kOpacityFaint * 255).round(),
              ),
            ),
            top: isSelected
                ? BorderSide(
                    color: colorScheme.primary,
                    width: kBorderWidthThick,
                  )
                : BorderSide.none,
          ),
        ),
        child: doses.isEmpty
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                padding: kCalendarWeekColumnPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: doses.map((dose) {
                    final VoidCallback? onTap = onDayTap != null
                        ? () => onDayTap!(date)
                        : (onDoseTap != null ? () => onDoseTap!(dose) : null);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: kListItemSpacing),
                      child: _CompactDoseIndicator(dose: dose, onTap: onTap),
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}

class _CompactDoseIndicator extends StatelessWidget {
  const _CompactDoseIndicator({required this.dose, this.onTap});

  final CalculatedDose dose;
  final VoidCallback? onTap;

  Color _statusColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    switch (dose.status) {
      case DoseStatus.taken:
        return kDoseStatusTakenGreen;
      case DoseStatus.skipped:
        return cs.error;
      case DoseStatus.snoozed:
        return kDoseStatusSnoozedOrange;
      case DoseStatus.overdue:
        return kDoseStatusMissedDarkRed;
      case DoseStatus.pending:
        return cs.primary;
    }
  }

  String _getDisplayText() {
    // Try to show dose value (e.g. "10", "0.5") if it's short
    if (dose.doseValue > 0) {
      String val = dose.doseValue == dose.doseValue.roundToDouble()
          ? dose.doseValue.toInt().toString()
          : dose.doseValue.toString();
      if (val.length <= 3) return val;
    }

    // Fallback to 1 letter of schedule name
    if (dose.scheduleName.isNotEmpty) {
      return dose.scheduleName[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);
    final timeText = DateFormat('ha').format(dose.scheduledTime).toLowerCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: Container(
        height: kCalendarWeekDoseIndicatorHeight,
        padding: kCalendarWeekDoseIndicatorPadding,
        decoration: buildInsetSectionDecoration(
          context: context,
          borderRadius: kBorderRadiusSmall,
          backgroundOpacity: 1.0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showTime =
                constraints.maxWidth >= kCalendarWeekDoseIndicatorMinWidthForTime;

            if (!showTime) {
              return Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatusDot(color: statusColor),
                    const SizedBox(width: kSpacingXS),
                    Flexible(
                      child: Text(
                        _getDisplayText(),
                        style: calendarWeekDoseIndicatorValueTextStyle(
                          context,
                          color: statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                _StatusDot(color: statusColor),
                const SizedBox(width: kSpacingXS),
                Expanded(
                  child: Text(
                    _getDisplayText(),
                    style: calendarWeekDoseIndicatorValueTextStyle(
                      context,
                      color: statusColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: kSpacingXS),
                Flexible(
                  child: Text(
                    timeText,
                    style: calendarWeekDoseIndicatorTimeTextStyle(
                      context,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: kOpacityMediumHigh),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kCalendarDoseIndicatorSize,
      height: kCalendarDoseIndicatorSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
