import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_dose_block.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_shared.dart';
import 'package:flutter/material.dart';

/// A day view showing an hourly timeline with dose blocks.
///
/// Displays hours from 12 AM to 11 PM (full 24 hours) with doses positioned at their scheduled times.
/// Features:
/// - Hourly grid with time labels
/// - Current time indicator (red line)
/// - Dose blocks at scheduled times
/// - Auto-scroll to current hour
/// - Tap dose → detail callback
/// - Swipe left/right → navigate days
class CalendarDayView extends StatefulWidget {
  const CalendarDayView({
    required this.date,
    required this.doses,
    this.onDoseTap,
    this.selectedHour,
    this.onHourTap,
    this.onDateChanged,
    super.key,
  });

  final DateTime date;
  final List<CalculatedDose> doses;
  final void Function(CalculatedDose dose)? onDoseTap;
  final int? selectedHour;
  final void Function(int hour)? onHourTap;
  final void Function(DateTime date)? onDateChanged;

  @override
  State<CalendarDayView> createState() => _CalendarDayViewState();
}

class _CalendarDayViewState extends State<CalendarDayView> {
  late final ScrollController _scrollController;
  static const int _startHour = 0; // 12 AM (midnight)
  static const int _endHour = 23; // 11 PM
  static const int _hourCount = _endHour - _startHour + 1; // 24 hours

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Auto-scroll to current hour after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentHour();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentHour() {
    final now = DateTime.now();
    if (_isToday(widget.date)) {
      final currentHour = now.hour;
      if (currentHour >= _startHour && currentHour <= _endHour) {
        final hoursSinceStart = currentHour - _startHour;
        final scrollPosition = hoursSinceStart * kCalendarHourHeight;
        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  double _getCurrentTimePosition() {
    final now = DateTime.now();
    if (!_isToday(widget.date)) return -1;

    final currentHour = now.hour;
    final currentMinute = now.minute;

    if (currentHour < _startHour || currentHour > _endHour) return -1;

    final hoursSinceStart = currentHour - _startHour;
    final minuteFraction = currentMinute / 60.0;
    return (hoursSinceStart + minuteFraction) * kCalendarHourHeight;
  }

  List<CalculatedDose> _getDosesForHour(int hour) {
    return widget.doses.where((dose) {
      return dose.scheduledTime.hour == hour;
    }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  @override
  Widget build(BuildContext context) {
    final currentTimePosition = _getCurrentTimePosition();
    final hasDoses = widget.doses.isNotEmpty;

    final hourGrid = GestureDetector(
      onHorizontalDragEnd: (details) {
        if (widget.onDateChanged == null) return;

        // Swipe left = next day, swipe right = previous day
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -500) {
            // Swipe left
            widget.onDateChanged!(widget.date.add(const Duration(days: 1)));
          } else if (details.primaryVelocity! > 500) {
            // Swipe right
            widget.onDateChanged!(
              widget.date.subtract(const Duration(days: 1)),
            );
          }
        }
      },
      child: Stack(
        children: [
          // Scrollable hour grid
          ListView.builder(
            controller: _scrollController,
            itemCount: _hourCount,
            itemBuilder: (context, index) {
              final hour = _startHour + index;
              return _HourRow(
                hour: hour,
                doses: _getDosesForHour(hour),
                onDoseTap: widget.onDoseTap,
                isSelected: widget.selectedHour == hour,
                onHourTap: widget.onHourTap,
              );
            },
          ),
          // Current time indicator (if today)
          if (currentTimePosition >= 0)
            Positioned(
              left: 0,
              right: 0,
              top: currentTimePosition,
              child: const _CurrentTimeIndicator(),
            ),
        ],
      ),
    );

    return Column(
      children: [
        _DayDateBanner(date: widget.date),
        Expanded(
          child: hasDoses
              ? hourGrid
              : CalendarNoDosesState(date: widget.date, showDate: false),
        ),
      ],
    );
  }
}

class _HourRow extends StatelessWidget {
  const _HourRow({
    required this.hour,
    required this.doses,
    this.onDoseTap,
    this.isSelected = false,
    this.onHourTap,
  });

  final int hour;
  final List<CalculatedDose> doses;
  final void Function(CalculatedDose dose)? onDoseTap;
  final bool isSelected;
  final void Function(int hour)? onHourTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: kCalendarHourHeight,
      child: InkWell(
        onTap: onHourTap != null ? () => onHourTap!(hour) : null,
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          CalendarHourLabel(hour: hour, width: kCalendarStageHourLabelWidth),
          // Hour content area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withAlpha((0.2 * 255).round()),
                  ),
                ),
                color: isSelected
                    ? colorScheme.primary.withAlpha((0.06 * 255).round())
                    : null,
              ),
              child: doses.isEmpty
                  ? null
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kCardInnerSpacing,
                        vertical: kListItemSpacing,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: doses.map((dose) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: kListItemSpacing,
                            ),
                            child: CalendarDoseBlock(
                              dose: dose,
                              onTap: onDoseTap != null
                                  ? () => onDoseTap!(dose)
                                  : null,
                              compact: doses.length > 2,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _CurrentTimeIndicator extends StatelessWidget {
  const _CurrentTimeIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: kCalendarStageHourLabelWidth),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withAlpha((0.3 * 255).round()),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: kCardInnerSpacing),
      ],
    );
  }
}

/// Shows the current day's full date (e.g. "Saturday, 22 February") at the
/// top of the [CalendarDayView] so the user can confirm which day they are on.
class _DayDateBanner extends StatelessWidget {
  const _DayDateBanner({required this.date});

  final DateTime date;

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = _isToday;
    final label = DateFormat.MMMMEEEEd().format(date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: kPageHorizontalPadding,
        vertical: kSpacingS,
      ),
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primary.withValues(alpha: kOpacityFaint)
            : colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: kOpacityMinimal),
          ),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: isToday
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: kOpacityHigh),
          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
