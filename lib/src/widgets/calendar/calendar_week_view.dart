import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/schedules/domain/calculated_entry.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/widgets/entry_status_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A week view showing a 7-column grid with entries.
///
/// Displays 7 days (Mon-Sun) with hourly rows (major hours only).
/// Features:
/// - 7-column grid layout
/// - Day headers with dates
/// - Compact entry indicators
/// - Current day highlight
/// - Tap day header → switch to Day view
/// - Tap entry → select day (prefers [onDayTap] when provided)
/// - Swipe left/right → navigate weeks
class CalendarWeekView extends StatelessWidget {
  const CalendarWeekView({
    required this.startDate,
    required this.entries,
    this.selectedDate,
    this.onEntryTap,
    this.onDateChanged,
    this.onDayTap,
    super.key,
  });

  final DateTime startDate;
  final List<CalculatedEntry> entries;
  final DateTime? selectedDate;
  final void Function(CalculatedEntry entry)? onEntryTap;
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

  List<CalculatedEntry> _getEntriesForDay(DateTime day) {
    return entries.where((entry) {
      return entry.scheduledTime.year == day.year &&
          entry.scheduledTime.month == day.month &&
          entry.scheduledTime.day == day.day;
    }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  @override
  Widget build(BuildContext context) {
    final hasEntries = entries.isNotEmpty;

    if (!hasEntries) {
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
              'No entries scheduled',
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
            entries: entries,
            onDayTap: onDayTap,
          ),
          // Week grid
          SizedBox(
            height: kCalendarWeekGridHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(7, (index) {
                final day = startDate.add(Duration(days: index));
                final dayEntries = _getEntriesForDay(day);
                final isToday = _isToday(day);
                final isSelected = _isSelected(day);

                return Expanded(
                  child: _DayColumn(
                    date: day,
                    entries: dayEntries,
                    isToday: isToday,
                    isSelected: isSelected,
                    onEntryTap: onEntryTap,
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
    required this.entries,
    this.selectedDate,
    this.onDayTap,
  });

  final DateTime startDate;
  final List<CalculatedEntry> entries;
  final DateTime? selectedDate;
  final void Function(DateTime date)? onDayTap;

  bool _hasEntriesOnDay(DateTime date) {
    return entries.any(
      (d) =>
          d.scheduledTime.year == date.year &&
          d.scheduledTime.month == date.month &&
          d.scheduledTime.day == date.day,
    );
  }

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

          final hasEntries = _hasEntriesOnDay(day);

          return Expanded(
            child: InkWell(
              onTap: onDayTap != null ? () => onDayTap!(day) : null,
              child: Container(
                margin: kCalendarWeekHeaderCellMargin,
                decoration: (isToday || isSelected)
                    ? BoxDecoration(
                        // Use a clearly visible fill so selected tiles stand out
                        // in both light and dark themes.
                        color: isToday
                            ? colorScheme.primary.withValues(alpha: kOpacitySubtle)
                            : colorScheme.primary.withValues(alpha: kOpacitySubtleLow),
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
                    // Date number + optional entry dot at the TOP of the tile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasEntries) ...
                          [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isToday || isSelected
                                    ? colorScheme.primary
                                    : colorScheme.primary
                                        .withValues(alpha: kOpacityMediumHigh),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 2),
                          ],
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
                    const SizedBox(height: kCalendarWeekHeaderLabelGap),
                    // Day name label BELOW the number
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
    required this.entries,
    required this.isToday,
    required this.isSelected,
    this.onEntryTap,
    this.onDayTap,
  });

  final DateTime date;
  final List<CalculatedEntry> entries;
  final bool isToday;
  final bool isSelected;
  final void Function(CalculatedEntry entry)? onEntryTap;
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayFill = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: kOpacityFaint),
      colorScheme.surface,
    );
    // In dark mode a 28% primary fill is clearly visible; in light mode blend
    // into the surface so it stays subtle.
    final selectedFill = isDark
        ? colorScheme.primary.withValues(alpha: 0.28)
        : Color.alphaBlend(
            colorScheme.primary.withValues(alpha: kOpacitySubtleLow),
            colorScheme.surface,
          );

    return InkWell(
      onTap: onDayTap != null ? () => onDayTap!(date) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? todayFill : isSelected ? selectedFill : null,
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
        child: entries.isEmpty
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                padding: kCalendarWeekColumnPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: entries.map((entry) {
                    final VoidCallback? onTap = onDayTap != null
                        ? () => onDayTap!(date)
                        : (onEntryTap != null ? () => onEntryTap!(entry) : null);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: kListItemSpacing),
                      child: _CompactEntryIndicator(entry: entry, onTap: onTap),
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}

class _CompactEntryIndicator extends StatelessWidget {
  const _CompactEntryIndicator({required this.entry, this.onTap});

  final CalculatedEntry entry;
  final VoidCallback? onTap;

  String _getDisplayText() {
    // Try to show entry value (e.g. "10", "0.5") if it's short
    if (entry.entryValue > 0) {
      String val = entry.entryValue == entry.entryValue.roundToDouble()
          ? entry.entryValue.toInt().toString()
          : entry.entryValue.toString();
      if (val.length <= 3) return val;
    }

    // Fallback to 1 letter of schedule name
    if (entry.scheduleName.isNotEmpty) {
      return entry.scheduleName[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final schedule = Hive.box<Schedule>('schedules').get(entry.scheduleId);
    final disabled = schedule != null && !schedule.isActive;
    final statusColor = entryStatusVisual(
      context,
      entry.status,
      disabled: disabled,
    ).color;
    final timeText = DateFormat('ha').format(entry.scheduledTime).toLowerCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: Container(
        height: kCalendarWeekEntryIndicatorHeight,
        padding: kCalendarWeekEntryIndicatorPadding,
        decoration: buildInsetSectionDecoration(
          context: context,
          borderRadius: kBorderRadiusSmall,
          backgroundOpacity: 1.0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showTime =
                constraints.maxWidth >= kCalendarWeekEntryIndicatorMinWidthForTime;

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
                        style: calendarWeekEntryIndicatorValueTextStyle(
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
                    style: calendarWeekEntryIndicatorValueTextStyle(
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
                    style: calendarWeekEntryIndicatorTimeTextStyle(
                      context,
                      color: Theme.of(context).colorScheme.onSurface,
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
      width: kCalendarEntryIndicatorSize,
      height: kCalendarEntryIndicatorSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
