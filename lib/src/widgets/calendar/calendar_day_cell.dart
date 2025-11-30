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

    return InkWell(
      onTap: onTap,
      child: Container(
        height: kCalendarDayHeight,
        decoration: BoxDecoration(
          color: _getBackgroundColor(colorScheme),
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
              padding: const EdgeInsets.all(4),
              child: Container(
                width: 24,
                height: 24,
                decoration: isToday
                    ? BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getTextColor(colorScheme),
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),

            // Dose indicators (dots)
            if (doses.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        alignment: WrapAlignment.center,
                        children: doses.take(5).map((dose) {
                          return CalendarDoseIndicator(dose: dose);
                        }).toList(),
                      ),
                      if (doses.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '+${doses.length - 5}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
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
    if (isToday) {
      return colorScheme.primaryContainer.withValues(alpha: 0.1);
    }
    if (!isCurrentMonth) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    }
    return Colors.transparent;
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    if (isSelected) {
      return colorScheme.primary;
    }
    if (isToday) {
      return colorScheme.primary.withValues(alpha: 0.3);
    }
    return colorScheme.outlineVariant.withValues(alpha: 0.2);
  }

  double _getBorderWidth() {
    if (isSelected) {
      return 2.5;
    }
    if (isToday) {
      return 1.5;
    }
    return 1;
  }

  Color _getTextColor(ColorScheme colorScheme) {
    if (isToday) {
      return colorScheme.onPrimary;
    }
    if (!isCurrentMonth) {
      return colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    }
    return colorScheme.onSurface;
  }
}
