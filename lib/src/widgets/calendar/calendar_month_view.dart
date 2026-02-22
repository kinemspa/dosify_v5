import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_day_cell.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:flutter/material.dart';

/// A month view showing a calendar grid with doses.
///
/// Displays a traditional calendar grid (6 weeks) with day cells showing dose indicators.
/// Features:
/// - 6-week grid (ensures all dates visible)
/// - Day headers (Sun-Sat or Mon-Sun configurable)
/// - Day cells with dot indicators
/// - Current day highlight
/// - Other month dates at reduced opacity
/// - Tap date → callback for day selection
/// - Swipe left/right → navigate months
class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({
    required this.month,
    required this.doses,
    this.onDayTap,
    this.onDateChanged,
    this.selectedDate,
    this.startWeekOnMonday = false,
    super.key,
  });

  final DateTime month;
  final List<CalculatedDose> doses;
  final void Function(DateTime date)? onDayTap;
  final void Function(DateTime date)? onDateChanged;
  final DateTime? selectedDate;
  final bool startWeekOnMonday;

  /// Get the first date to display (may be in previous month)
  DateTime get _firstDateToDisplay {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final weekday = firstDayOfMonth.weekday; // 1-7 (Mon-Sun)

    // For Monday-first weeks: Mon -> 0, Tue -> 1, ... Sun -> 6.
    // For Sunday-first weeks: Sun -> 0, Mon -> 1, ... Sat -> 6.
    final daysToSubtract = startWeekOnMonday
        ? (weekday + 6) % 7
        : weekday % 7;
    return firstDayOfMonth.subtract(Duration(days: daysToSubtract));
  }

  /// Get all dates to display — only enough rows to cover the whole month.
  /// For months where the last day falls on the final column (e.g. Feb 2026
  /// with Sun-first weeks ends on Saturday), this yields exactly 4 rows instead
  /// of always returning 6 (42 days).
  List<DateTime> get _datesToDisplay {
    final first = _firstDateToDisplay;
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // Column index (0-based) of the last day of the month
    final lastDayColumnIndex = startWeekOnMonday
        ? (lastDayOfMonth.weekday + 6) % 7 // Mon=0 … Sun=6
        : lastDayOfMonth.weekday % 7; // Sun=0, Mon=1 … Sat=6

    // Pad to end of that week row (0 padding when already at the last column)
    final paddingAfter = lastDayColumnIndex == 6 ? 0 : (6 - lastDayColumnIndex);
    final last = lastDayOfMonth.add(Duration(days: paddingAfter));
    final totalDays = last.difference(first).inDays + 1;

    final dates = <DateTime>[];
    DateTime current = first;
    for (int i = 0; i < totalDays; i++) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isCurrentMonth(DateTime date) {
    return date.year == month.year && date.month == month.month;
  }

  List<CalculatedDose> _getDosesForDay(DateTime day) {
    return doses.where((dose) {
      return dose.scheduledTime.year == day.year &&
          dose.scheduledTime.month == day.month &&
          dose.scheduledTime.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final datesToDisplay = _datesToDisplay;
    final rowCount = datesToDisplay.length ~/ 7;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (onDateChanged == null) return;

        // Swipe left = next month, swipe right = previous month
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -500) {
            // Swipe left - next month
            final nextMonth = DateTime(month.year, month.month + 1, 1);
            onDateChanged!(nextMonth);
          } else if (details.primaryVelocity! > 500) {
            // Swipe right - previous month
            final prevMonth = DateTime(month.year, month.month - 1, 1);
            onDateChanged!(prevMonth);
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day headers
          _DayHeaders(
            startWeekOnMonday: startWeekOnMonday,
            todayWeekday: DateTime.now().weekday,
            selectedWeekday: selectedDate?.weekday,
          ),
          // Calendar grid
          SizedBox(
            height: rowCount * kCalendarDayHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: kCalendarDayHeight,
              ),
              itemCount: datesToDisplay.length,
              itemBuilder: (context, index) {
                final date = datesToDisplay[index];
                final dayDoses = _getDosesForDay(date);
                final isToday = _isToday(date);
                final isCurrentMonth = _isCurrentMonth(date);
                final isSelected =
                    selectedDate != null &&
                    date.year == selectedDate!.year &&
                    date.month == selectedDate!.month &&
                    date.day == selectedDate!.day;

                return CalendarDayCell(
                  date: date,
                  doses: dayDoses,
                  isCurrentMonth: isCurrentMonth,
                  isToday: isToday,
                  isSelected: isSelected,
                  onTap: onDayTap != null ? () => onDayTap!(date) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeaders extends StatelessWidget {
  const _DayHeaders({
    required this.startWeekOnMonday,
    this.todayWeekday,
    this.selectedWeekday,
  });

  final bool startWeekOnMonday;
  final int? todayWeekday; // 1-7 (Mon-Sun)
  final int? selectedWeekday;

  List<String> get _dayNames {
    if (startWeekOnMonday) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else {
      return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    }
  }

  int _getWeekdayForIndex(int index) {
    // Convert index to weekday (1-7)
    if (startWeekOnMonday) {
      return index + 1; // Mon=1, Tue=2, ... Sun=7
    } else {
      return index == 0 ? 7 : index; // Sun=7, Mon=1, ... Sat=6
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: kCalendarMonthDayHeaderHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: kOpacityMinimal),
          ),
        ),
      ),
      child: Row(
        children: List.generate(_dayNames.length, (index) {
          final dayName = _dayNames[index];
          final weekday = _getWeekdayForIndex(index);
          final isToday = todayWeekday == weekday;
          final isSelected = selectedWeekday == weekday && !isToday;

          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isToday
                    ? colorScheme.primary.withValues(alpha: kOpacitySubtle)
                    : isSelected
                    ? colorScheme.primary.withValues(alpha: kOpacityFaint)
                    : null,
              ),
              child: Center(
                child: Text(
                  dayName,
                  style: helperTextStyle(context)?.copyWith(
                    color: isToday
                        ? colorScheme.primary
                        : isSelected
                        ? colorScheme.onSurface.withValues(alpha: kOpacityHigh)
                        : colorScheme.onSurface.withValues(
                            alpha: kOpacityMedium,
                          ),
                    fontWeight: isToday || isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
