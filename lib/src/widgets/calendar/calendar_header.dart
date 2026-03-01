// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';

/// Calendar view modes
enum CalendarView { month, week, day }

/// Header widget for calendar with navigation and view toggle
class CalendarHeader extends StatelessWidget {
  final DateTime currentDate;
  final CalendarView currentView;
  final DateTime? selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final void Function(CalendarView) onViewChanged;
  final bool showViewToggle;

  const CalendarHeader({
    super.key,
    required this.currentDate,
    required this.currentView,
    this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onViewChanged,
    this.showViewToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOnTodayContext = _isOnTodayContext();

    return Container(
      height: kCalendarHeaderHeight,
      padding: kCalendarHeaderPadding,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: kOpacityVeryLow,
            ),
            width: kBorderWidthMedium,
          ),
        ),
      ),
      child: Row(
        children: [
          // Navigation buttons
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPreviousMonth,
            tooltip: 'Previous',
            iconSize: kIconSizeMedium,
            padding: kNoPadding,
            constraints: kCalendarHeaderNavButtonConstraints,
          ),

          // Date display
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpacingXXS),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatTitle(),
                    style: calendarHeaderTitleTextStyle(context),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

          // Next button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNextMonth,
            tooltip: 'Next',
            iconSize: kIconSizeMedium,
            padding: kNoPadding,
            constraints: kCalendarHeaderNavButtonConstraints,
          ),

          const SizedBox(width: kSpacingXXS),

          // Today button
          IconButton(
            icon: Icon(
              isOnTodayContext ? Icons.check : Icons.today_rounded,
              color: isOnTodayContext ? colorScheme.primary : colorScheme.onPrimary,
            ),
            onPressed: onToday,
            tooltip: isOnTodayContext ? 'Today' : 'Back to Today',
            style: isOnTodayContext
                ? IconButton.styleFrom(
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: kOpacityMedium),
                      width: kBorderWidthThin,
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(kMinInteractiveDimension, kMinInteractiveDimension),
                  )
                : IconButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(kMinInteractiveDimension, kMinInteractiveDimension),
                  ),
          ),

          if (showViewToggle) ...[
            const SizedBox(width: kSpacingXXS),
            IconButton(
              icon: Icon(_getViewIcon()),
              onPressed: _cycleView,
              tooltip: 'Change view',
              iconSize: kIconSizeMedium,
              padding: kNoPadding,
              constraints: kCalendarHeaderNavButtonConstraints,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getViewIcon() {
    switch (currentView) {
      case CalendarView.day:
        return Icons.view_day;
      case CalendarView.week:
        return Icons.view_week;
      case CalendarView.month:
        return Icons.calendar_month;
    }
  }

  void _cycleView() {
    // Cycle in intended order: Month → Week → Day
    final orderedViews = [
      CalendarView.month,
      CalendarView.week,
      CalendarView.day,
    ];
    final currentIndex = orderedViews.indexOf(currentView);
    final nextIndex = (currentIndex + 1) % orderedViews.length;
    onViewChanged(orderedViews[nextIndex]);
  }

  bool _isOnTodayContext() {
    final today = DateTime.now();
    switch (currentView) {
      case CalendarView.day:
        return currentDate.year == today.year &&
            currentDate.month == today.month &&
            currentDate.day == today.day;
      case CalendarView.week:
        final weekStart = currentDate.subtract(
          Duration(days: currentDate.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));
        final todayDate = DateTime(today.year, today.month, today.day);
        final startDate = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );
        final endDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
        return !todayDate.isBefore(startDate) && !todayDate.isAfter(endDate);
      case CalendarView.month:
        // If a day is selected, show the filled 'Today' button unless the
        // selected day itself is today. Falls back to month-level check when
        // no day is selected (e.g. compact variant).
        if (selectedDate != null) {
          return selectedDate!.year == today.year &&
              selectedDate!.month == today.month &&
              selectedDate!.day == today.day;
        }
        return currentDate.year == today.year &&
            currentDate.month == today.month;
    }
  }

  String _formatTitle() {
    switch (currentView) {
      case CalendarView.day:
        return _formatDayTitle();
      case CalendarView.week:
        return _formatWeekTitle();
      case CalendarView.month:
        return _formatMonthTitle();
    }
  }

  String _formatDayTitle() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[currentDate.month - 1];
    final day = currentDate.day;
    final year = currentDate.year;
    return '$month $day, $year';
  }

  String _formatWeekTitle() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // Get start of week (Monday)
    final weekStart = currentDate.subtract(
      Duration(days: currentDate.weekday - 1),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));

    final startMonth = months[weekStart.month - 1];
    final endMonth = months[weekEnd.month - 1];
    final startDay = weekStart.day;
    final endDay = weekEnd.day;

    final separator = '–';
    if (weekStart.month == weekEnd.month) {
      return '$startMonth $startDay$separator$endDay, ${weekStart.year}';
    }
    return '$startMonth $startDay$separator$endMonth $endDay, ${weekStart.year}';
  }

  String _formatMonthTitle() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[currentDate.month - 1]} ${currentDate.year}';
  }
}

/// Toggle widget for switching calendar views
class CalendarViewToggle extends StatelessWidget {
  final CalendarView currentView;
  final void Function(CalendarView) onViewChanged;

  const CalendarViewToggle({
    super.key,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(context, label: 'Day', view: CalendarView.day),
          _buildToggleButton(context, label: 'Week', view: CalendarView.week),
          _buildToggleButton(context, label: 'Month', view: CalendarView.month),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required String label,
    required CalendarView view,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = currentView == view;

    return InkWell(
      onTap: () => onViewChanged(view),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : kColorTransparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurface.withValues(alpha: kOpacityHigh),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
