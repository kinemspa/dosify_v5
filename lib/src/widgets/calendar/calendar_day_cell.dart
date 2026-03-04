// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_entry_block.dart';

/// Calendar day cell for month view
class CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final List<CalculatedEntry> entries;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback? onTap;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.entries,
    this.isCurrentMonth = true,
    this.isToday = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final borderRadius = BorderRadius.circular(kCalendarDayCellBorderRadius);

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(colorScheme),
          borderRadius: borderRadius,
          border: Border.all(
            color: _getBorderColor(colorScheme),
            width: _getBorderWidth(),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
          final effectiveNumberPadding =
            constraints.maxHeight <
                (kCalendarDayNumberPadding.vertical +
                  kCalendarDayNumberSize)
              ? kNoPadding
              : kCalendarDayNumberPadding;

          final effectiveDayNumberSize =
            (constraints.maxHeight - effectiveNumberPadding.vertical)
              .clamp(0.0, kCalendarDayNumberSize);

          final headerHeight =
            effectiveNumberPadding.vertical + effectiveDayNumberSize;
            final indicatorsMinHeight =
                kCalendarDayEntryIndicatorPadding.vertical +
              kCalendarEntryIndicatorSize;
            final canShowIndicators =
                entries.isNotEmpty &&
                (constraints.maxHeight - headerHeight) >= indicatorsMinHeight;

            final indicatorCount = entries.length > kCalendarMonthMaxEntryIndicators
                ? kCalendarMonthMaxEntryIndicators
                : entries.length;
            final overflowCount = entries.length - indicatorCount;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: effectiveNumberPadding,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: effectiveDayNumberSize,
                        height: effectiveDayNumberSize,
                        child: FittedBox(
                          alignment: Alignment.topLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${date.day}',
                            style: calendarDayNumberTextStyle(context)?.copyWith(
                              color: _getTextColor(colorScheme),
                              fontWeight: (isToday || isSelected)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canShowIndicators)
                  Expanded(
                    child: ClipRect(
                      child: Padding(
                        padding: kCalendarDayEntryIndicatorPadding,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: kCalendarEntryIndicatorSpacing,
                            runSpacing: kCalendarEntryIndicatorSpacing,
                            children: [
                              for (final entry in entries.take(indicatorCount))
                                CalendarEntryIndicator(entry: entry),
                              if (overflowCount > 0)
                                Text(
                                  '+$overflowCount',
                                  style: microHelperTextStyle(
                                    context,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(
                                          alpha: kCalendarDayOverflowTextOpacity,
                                        ),
                                  )?.copyWith(fontWeight: kFontWeightSemiBold),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (isSelected) {
      return colorScheme.primary.withValues(alpha: kOpacitySubtle);
    }
    if (isToday) {
      return colorScheme.primary.withValues(alpha: kOpacityFaint);
    }
    if (!isCurrentMonth) {
      return colorScheme.onSurfaceVariant.withValues(alpha: kOpacityFaint);
    }
    return colorScheme.surface.withValues(alpha: kOpacityTransparent);
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    if (isSelected) {
      return colorScheme.primary;
    }
    if (isToday) {
      return colorScheme.primary;
    }
    return colorScheme.outlineVariant.withValues(alpha: kOpacityMinimal);
  }

  double _getBorderWidth() {
    if (isSelected) {
      return kBorderWidthThick;
    }
    if (isToday) {
      return kBorderWidthThin;
    }
    return kBorderWidthThin;
  }

  Color _getTextColor(ColorScheme colorScheme) {
    if (isSelected) return colorScheme.primary;
    if (isToday) return colorScheme.primary;
    if (!isCurrentMonth) {
      return colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMediumLow);
    }
    return colorScheme.onSurface.withValues(alpha: kOpacityHigh);
  }
}
