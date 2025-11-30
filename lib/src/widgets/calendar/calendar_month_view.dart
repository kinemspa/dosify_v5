import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_day_cell.dart';
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
    int weekday = firstDayOfMonth.weekday;

    // Adjust weekday if starting on Monday
    if (startWeekOnMonday) {
      weekday = weekday == 7 ? 0 : weekday; // Sunday becomes 0
    } else {
      weekday = weekday == 7 ? 0 : weekday; // Sunday becomes 0
    }

    // Calculate days to go back to start of week
    final daysToSubtract = startWeekOnMonday
        ? weekday
        : (weekday == 0 ? 0 : weekday);
    return firstDayOfMonth.subtract(Duration(days: daysToSubtract));
  }

  /// Get all dates to display (6 weeks = 42 days)
  List<DateTime> get _datesToDisplay {
    final dates = <DateTime>[];
    DateTime current = _firstDateToDisplay;

    for (int i = 0; i < 42; i++) {
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
        children: [
          // Day headers
          _DayHeaders(
            startWeekOnMonday: startWeekOnMonday,
            todayWeekday: DateTime.now().weekday,
            selectedWeekday: selectedDate?.weekday,
          ),
          // Calendar grid
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 280, // Compact grid height, panel hugs below
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0, // Square cells
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
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withAlpha((0.2 * 255).round()),
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
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
              ),
              child: Center(
                child: Text(
                  dayName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? colorScheme.primary
                        : isSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withAlpha((0.6 * 255).round()),
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
