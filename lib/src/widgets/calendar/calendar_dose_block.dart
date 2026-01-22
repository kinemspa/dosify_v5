// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/dose_status_ui.dart';
import 'package:dosifi_v5/src/widgets/schedule_status_badge.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Displays a dose block in calendar views
class CalendarDoseBlock extends StatelessWidget {
  final CalculatedDose dose;
  final VoidCallback? onTap;
  final bool compact;

  const CalendarDoseBlock({
    super.key,
    required this.dose,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);
    final disabled = schedule != null && !schedule.isActive;
    final statusVisual = doseStatusVisual(context, dose.status, disabled: disabled);
    final statusColor = statusVisual.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: Container(
        height: compact
            ? kCalendarDoseBlockMinHeight
            : kCalendarDoseBlockHeight,
        padding: compact
            ? const EdgeInsets.all(kFieldSpacing)
            : const EdgeInsets.all(kSpacingS),
        decoration: BoxDecoration(
          color: _getBackgroundColor(
            colorScheme,
            statusColor: statusColor,
            disabled: disabled,
          ),
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          border: Border.all(
            color: _getBorderColor(
              colorScheme,
              statusColor: statusColor,
              disabled: disabled,
            ),
            width: kBorderWidthMedium,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Schedule name
            Flexible(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dose.scheduleName,
                      style: calendarDoseBlockTitleTextStyle(
                        context,
                        color: _getTextColor(
                          colorScheme,
                          statusColor: statusColor,
                          disabled: disabled,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (schedule != null && !schedule.isActive && !compact) ...[
                    const SizedBox(width: kSpacingXS),
                    ScheduleStatusBadge(schedule: schedule, dense: true),
                  ],
                ],
              ),
            ),

            if (!compact) ...[
              const SizedBox(height: kSpacingXS),

              // Dose description
              Text(
                dose.doseDescription,
                style: calendarDoseBlockSubtitleTextStyle(
                  context,
                  color: _getTextColor(
                    colorScheme,
                    statusColor: statusColor,
                    disabled: disabled,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Status badge
              _buildStatusBadge(
                context,
                disabled: disabled,
                statusVisual: statusVisual,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context, {
    required bool disabled,
    required ({Color color, IconData icon}) statusVisual,
  }) {
    if (!disabled && dose.status == DoseStatus.pending) {
      return const SizedBox.shrink();
    }

    final label = doseStatusLabel(dose.status, disabled: disabled);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          statusVisual.icon,
          size: kIconSizeXXSmall,
          color: statusVisual.color,
        ),
        const SizedBox(width: kSpacingXS),
        Text(
          label,
          style: microHelperTextStyle(context, color: statusVisual.color)
              ?.copyWith(fontWeight: kFontWeightSemiBold),
        ),
      ],
    );
  }

  Color _getBackgroundColor(
    ColorScheme colorScheme, {
    required Color statusColor,
    required bool disabled,
  }) {
    if (disabled) {
      return statusColor.withValues(alpha: kOpacityFaint);
    }

    switch (dose.status) {
      case DoseStatus.taken:
        return statusColor.withValues(alpha: kOpacitySubtle);
      case DoseStatus.skipped:
        return statusColor.withValues(alpha: kOpacitySubtleLow);
      case DoseStatus.snoozed:
        return statusColor.withValues(alpha: kOpacitySubtle);
      case DoseStatus.due:
      case DoseStatus.overdue:
        return statusColor.withValues(alpha: kOpacityMinimal);
      case DoseStatus.pending:
        return statusColor.withValues(alpha: kOpacityFaint);
    }
  }

  Color _getBorderColor(
    ColorScheme colorScheme, {
    required Color statusColor,
    required bool disabled,
  }) {
    if (disabled) {
      return colorScheme.outline.withValues(alpha: kOpacityVeryLow);
    }

    switch (dose.status) {
      case DoseStatus.taken:
        return statusColor.withValues(alpha: kOpacityMediumLow);
      case DoseStatus.skipped:
        return statusColor.withValues(alpha: kOpacityVeryLow);
      case DoseStatus.snoozed:
        return statusColor.withValues(alpha: kOpacityMediumHigh);
      case DoseStatus.due:
      case DoseStatus.overdue:
        return statusColor.withValues(alpha: kOpacityHigh);
      case DoseStatus.pending:
        return colorScheme.outline.withValues(alpha: kOpacityVeryLow);
    }
  }

  Color _getTextColor(
    ColorScheme colorScheme, {
    required Color statusColor,
    required bool disabled,
  }) {
    if (disabled) {
      return statusColor.withValues(alpha: kOpacityMediumHigh);
    }
    switch (dose.status) {
      case DoseStatus.taken:
      case DoseStatus.skipped:
      case DoseStatus.snoozed:
      case DoseStatus.due:
      case DoseStatus.overdue:
        return statusColor;
      case DoseStatus.pending:
        return statusColor.withValues(alpha: kOpacityMediumHigh);
    }
  }
}

/// Compact dose indicator (dot) for month view
class CalendarDoseIndicator extends StatelessWidget {
  final CalculatedDose dose;

  const CalendarDoseIndicator({super.key, required this.dose});

  @override
  Widget build(BuildContext context) {
    final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);
    final disabled = schedule != null && !schedule.isActive;

    final visual = doseStatusVisual(context, dose.status, disabled: disabled);
    final color = dose.status == DoseStatus.pending
        ? visual.color.withValues(alpha: kOpacityMediumLow)
        : visual.color;

    return Container(
      width: kCalendarDoseIndicatorSize,
      height: kCalendarDoseIndicatorSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(kCalendarDoseIndicatorBorderRadius),
      ),
    );
  }
}
