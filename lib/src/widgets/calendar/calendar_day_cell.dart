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
                        style: calendarDayNumberTextStyle(context)?.copyWith(
                          color: _getTextColor(colorScheme),
                          fontWeight: (isToday || isSelected)
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
                        padding: kCalendarDayCountBadgePadding,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.onPrimary.withValues(
                                  alpha: kOpacityFaint,
                                )
                              : colorScheme.primary.withValues(
                                  alpha: kOpacityFaint,
                                ),
                          borderRadius: BorderRadius.circular(
                            kBorderRadiusChipTight,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.onPrimary.withValues(
                                    alpha: kOpacityMediumLow,
                                  )
                                : colorScheme.outlineVariant.withValues(
                                    alpha: kOpacityMediumLow,
                                  ),
                            width: kBorderWidthThin,
                          ),
                        ),
                        child: Text(
                          doseCountText,
                          style: calendarDayCountBadgeTextStyle(context)
                              ?.copyWith(
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : (isCurrentMonth
                                          ? colorScheme.primary
                                          : colorScheme.primary.withValues(
                                              alpha: kOpacityMedium,
                                            )),
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (doses.isNotEmpty)
              Expanded(
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
                                      width: kCalendarDoseIndicatorSpacing,
                                    ),
                                  ],
                                )
                                .toList()
                              ..removeLast(),
                      ),
                      if (doses.length > kCalendarMonthMaxDoseIndicators)
                        Padding(
                          padding: const EdgeInsets.only(top: kSpacingXS / 2),
                          child: Text(
                            '+${doses.length - kCalendarMonthMaxDoseIndicators}',
                            style: calendarDayOverflowTextStyle(context)
                                ?.copyWith(
                                  color: isSelected
                                      ? colorScheme.onPrimary.withValues(
                                          alpha: kOpacityMediumHigh,
                                        )
                                      : colorScheme.onSurfaceVariant.withValues(
                                          alpha:
                                              kCalendarDayOverflowTextOpacity,
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
    return colorScheme.onSurface;
  }
}
