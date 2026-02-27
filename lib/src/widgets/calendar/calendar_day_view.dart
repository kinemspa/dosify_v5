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

  /// When true, hours with no scheduled doses are rendered at
  /// [kCalendarHourHeightCollapsed] instead of [kCalendarHourHeight].
  bool _collapseEmptyHours = true;

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
    if (!_scrollController.hasClients) return;
    final now = DateTime.now();
    if (_isToday(widget.date)) {
      final currentHour = now.hour;
      if (currentHour >= _startHour && currentHour <= _endHour) {
        final scrollPosition = _hourTop(currentHour);
        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (widget.doses.isNotEmpty) {
      // Non-today: scroll to the earliest scheduled dose.
      final firstDoseHour = widget.doses
          .map((d) => d.scheduledTime.hour)
          .reduce((a, b) => a < b ? a : b);
      _scrollController.animateTo(
        _hourTop(firstDoseHour),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Cumulative Y offset from the top of the list to the start of [hour].
  /// Accounts for collapsed empty-hour rows.
  double _hourTop(int hour) {
    var y = 0.0;
    for (var h = _startHour; h < hour; h++) {
      final hasDose = _getDosesForHour(h).isNotEmpty;
      y += _collapseEmptyHours && !hasDose
          ? kCalendarHourHeightCollapsed
          : kCalendarHourHeight;
    }
    return y;
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

    final rowHeight = (_collapseEmptyHours && _getDosesForHour(currentHour).isEmpty)
        ? kCalendarHourHeightCollapsed
        : kCalendarHourHeight;
    final minuteFraction = currentMinute / 60.0;
    return _hourTop(currentHour) + minuteFraction * rowHeight;
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
              final doses = _getDosesForHour(hour);
              return _HourRow(
                hour: hour,
                doses: doses,
                onDoseTap: widget.onDoseTap,
                isSelected: widget.selectedHour == hour,
                onHourTap: widget.onHourTap,
                isCollapsed: _collapseEmptyHours && doses.isEmpty,
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
        _DayDateBanner(
          date: widget.date,
          collapseEmptyHours: _collapseEmptyHours,
          // Only show the toggle when there are doses to collapse/expand.
          onToggleCollapse: hasDoses
              ? () {
                  setState(() => _collapseEmptyHours = !_collapseEmptyHours);
                  // Re-scroll after the layout updates so the view snaps to the
                  // right position instead of drifting on the stale offset.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToCurrentHour(),
                  );
                }
              : null,
        ),
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
    this.isCollapsed = false,
  });

  final int hour;
  final List<CalculatedDose> doses;
  final void Function(CalculatedDose dose)? onDoseTap;
  final bool isSelected;
  final void Function(int hour)? onHourTap;
  /// When true the row is rendered at [kCalendarHourHeightCollapsed] with only
  /// the time label visible. Only set when the hour contains no scheduled doses.
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rowHeight =
        isCollapsed ? kCalendarHourHeightCollapsed : kCalendarHourHeight;

    return SizedBox(
      height: rowHeight,
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
                    ).colorScheme.outline.withAlpha(
                          isCollapsed ? (0.10 * 255).round() : (0.2 * 255).round(),
                        ),
                  ),
                ),
                color: isSelected
                    ? colorScheme.primary.withAlpha((0.06 * 255).round())
                    : null,
              ),
              child: isCollapsed || doses.isEmpty
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
  const _DayDateBanner({
    required this.date,
    this.collapseEmptyHours = true,
    this.onToggleCollapse,
  });

  final DateTime date;
  final bool collapseEmptyHours;
  final VoidCallback? onToggleCollapse;

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
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isToday
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: kOpacityHigh),
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          if (onToggleCollapse != null)
            Tooltip(
              message: collapseEmptyHours
                  ? 'Show all hours'
                  : 'Hide empty hours',
              child: IconButton(
                icon: Icon(
                  collapseEmptyHours
                      ? Icons.unfold_more_rounded
                      : Icons.unfold_less_rounded,
                  size: kIconSizeSmall,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: onToggleCollapse,
                color: isToday
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: kOpacityHigh),
              ),
            ),
        ],
      ),
    );
  }
}
