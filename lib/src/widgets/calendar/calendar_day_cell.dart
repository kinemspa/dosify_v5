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

    final doseCount = doses.length;
    final doseCountText = doseCount > 9 ? '9+' : '$doseCount';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date number
            Padding(
              padding: kCalendarDayNumberPadding,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: kCalendarDayNumberSize,
                    height: kCalendarDayNumberSize,
                    decoration: isToday
                        ? BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: calendarDayNumberTextStyle(context)?.copyWith(
                          color: _getTextColor(colorScheme),
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  if (doseCount > 0)
                    Positioned(
                      right: -kSpacingXS,
                      bottom: -kSpacingXS,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: kSpacingXS,
                          vertical: kSpacingXS / 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(
                            alpha: kOpacityFaint,
                          ),
                          borderRadius: BorderRadius.circular(
                            kBorderRadiusSmall,
                          ),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: kOpacityMediumLow,
                            ),
                            width: kBorderWidthThin,
                          ),
                        ),
                        child: Text(
                          doseCountText,
                          style: calendarDayCountBadgeTextStyle(context)
                              ?.copyWith(
                                color: isCurrentMonth
                                    ? colorScheme.primary
                                    : colorScheme.primary.withValues(
                                        alpha: kOpacityMedium,
                                      ),
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Dose indicators (dots)
            if (doses.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: kCalendarDayDoseIndicatorPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Wrap(
                        spacing: kCalendarDoseIndicatorSpacing,
                        runSpacing: kCalendarDoseIndicatorSpacing,
                        alignment: WrapAlignment.center,
                        children: doses.take(5).map((dose) {
                          return CalendarDoseIndicator(dose: dose);
                        }).toList(),
                      ),
                      if (doses.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: kSpacingXS / 2),
                          child: Text(
                            '+${doses.length - 5}',
                            style: calendarDayOverflowTextStyle(context)
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(
                                        alpha: kCalendarDayOverflowTextOpacity,
                                      ),
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (isSelected) {
      return colorScheme.primary.withValues(alpha: kOpacitySubtleLow);
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
      return colorScheme.primary.withValues(alpha: kOpacityMediumHigh);
    }
    if (isToday) {
      return colorScheme.primary.withValues(alpha: kOpacitySubtle);
    }
    return colorScheme.outlineVariant.withValues(alpha: kOpacityMinimal);
  }

  double _getBorderWidth() {
    if (isSelected) {
      return kBorderWidthThick;
    }
    if (isToday) {
      return kBorderWidthMedium;
    }
    return kBorderWidthThin;
  }

  Color _getTextColor(ColorScheme colorScheme) {
    if (isToday) {
      return colorScheme.onPrimary;
    }
    if (!isCurrentMonth) {
      return colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMediumLow);
    }
    return colorScheme.onSurface;
  }
}
