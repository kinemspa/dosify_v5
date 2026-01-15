// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_dose_block.dart';

/// Calendar day cell for month view
class CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final List<CalculatedDose> doses;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback? onTap;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.doses,
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
            final headerHeight =
                kCalendarDayNumberPadding.vertical + kCalendarDayNumberSize;
            final indicatorsMinHeight =
                kCalendarDayDoseIndicatorPadding.vertical +
              kCalendarDoseIndicatorSize;
            final canShowIndicators =
                doses.isNotEmpty &&
                (constraints.maxHeight - headerHeight) >= indicatorsMinHeight;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: kCalendarDayNumberPadding,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: kCalendarDayNumberSize,
                        height: kCalendarDayNumberSize,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            '${date.day}',
                            style: calendarDayNumberTextStyle(context)
                                ?.copyWith(
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
                        padding: kCalendarDayDoseIndicatorPadding,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  doses
                                      .take(kCalendarMonthMaxDoseIndicators)
                                      .expand(
                                        (dose) => [
                                          CalendarDoseIndicator(dose: dose),
                                          const SizedBox(
                                            width:
                                                kCalendarDoseIndicatorSpacing,
                                          ),
                                        ],
                                      )
                                      .toList()
                                    ..removeLast(),
                            ),
                          ],
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
      return colorScheme.primary;
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
      return colorScheme.primary.withValues(alpha: kOpacityTransparent);
    }
    if (isToday) {
      return colorScheme.primary;
    }
    return colorScheme.outlineVariant.withValues(alpha: kOpacityMinimal);
  }

  double _getBorderWidth() {
    if (isSelected) {
      return kBorderWidthThin;
    }
    if (isToday) {
      return kBorderWidthThin;
    }
    return kBorderWidthThin;
  }

  Color _getTextColor(ColorScheme colorScheme) {
    if (isSelected) return colorScheme.onPrimary;
    if (isToday) return colorScheme.primary;
    if (!isCurrentMonth) {
      return colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMediumLow);
    }
    return colorScheme.onSurface.withValues(alpha: kOpacityHigh);
  }
}
