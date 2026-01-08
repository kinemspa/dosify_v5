// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: Container(
        height: compact
            ? kCalendarDoseBlockMinHeight
            : kCalendarDoseBlockHeight,
        padding: compact ? const EdgeInsets.all(6) : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getBackgroundColor(colorScheme),
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          border: Border.all(color: _getBorderColor(colorScheme), width: 1),
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
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(colorScheme),
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
              const SizedBox(height: 4),

              // Dose description
              Text(
                dose.doseDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getTextColor(colorScheme).withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Status badge
              _buildStatusBadge(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);
    if (schedule != null && !schedule.isActive) {
      final disabledColor = colorScheme.onSurfaceVariant.withValues(
        alpha: kOpacityMediumHigh,
      );
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.do_not_disturb_on_rounded, size: 12, color: disabledColor),
          const SizedBox(width: 4),
          Text(
            'DISABLED',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: disabledColor,
            ),
          ),
        ],
      );
    }

    String label;
    IconData icon;

    switch (dose.status) {
      case DoseStatus.taken:
        label = 'TAKEN';
        icon = Icons.check_circle;
        break;
      case DoseStatus.skipped:
        label = 'SKIPPED';
        icon = Icons.cancel;
        break;
      case DoseStatus.snoozed:
        label = 'SNOOZED';
        icon = Icons.snooze;
        break;
      case DoseStatus.overdue:
        label = 'MISSED';
        icon = Icons.warning;
        break;
      case DoseStatus.pending:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _getStatusColor(colorScheme)),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _getStatusColor(colorScheme),
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (dose.status) {
      case DoseStatus.taken:
        return colorScheme.primaryContainer.withValues(alpha: 0.3);
      case DoseStatus.skipped:
        return colorScheme.errorContainer.withValues(alpha: 0.3);
      case DoseStatus.snoozed:
        return Colors.orange.withValues(alpha: 0.2);
      case DoseStatus.overdue:
        return colorScheme.errorContainer.withValues(alpha: 0.5);
      case DoseStatus.pending:
        return colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    }
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    switch (dose.status) {
      case DoseStatus.taken:
        return colorScheme.primary.withValues(alpha: 0.5);
      case DoseStatus.skipped:
        return colorScheme.error.withValues(alpha: 0.5);
      case DoseStatus.snoozed:
        return Colors.orange.withValues(alpha: 0.7);
      case DoseStatus.overdue:
        return colorScheme.error;
      case DoseStatus.pending:
        return colorScheme.outline.withValues(alpha: 0.3);
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (dose.status) {
      case DoseStatus.taken:
        return colorScheme.primary;
      case DoseStatus.skipped:
        return colorScheme.error;
      case DoseStatus.snoozed:
        return Colors.orange.shade800;
      case DoseStatus.overdue:
        return colorScheme.error;
      case DoseStatus.pending:
        return colorScheme.onSurface;
    }
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (dose.status) {
      case DoseStatus.taken:
        return colorScheme.primary;
      case DoseStatus.skipped:
        return colorScheme.error;
      case DoseStatus.snoozed:
        return Colors.orange;
      case DoseStatus.overdue:
        return colorScheme.error;
      case DoseStatus.pending:
        return colorScheme.onSurfaceVariant;
    }
  }
}

/// Compact dose indicator (dot) for month view
class CalendarDoseIndicator extends StatelessWidget {
  final CalculatedDose dose;

  const CalendarDoseIndicator({super.key, required this.dose});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);

    return Container(
      width: kCalendarDoseIndicatorSize,
      height: kCalendarDoseIndicatorSize,
      decoration: BoxDecoration(
        color: _getColor(colorScheme, schedule: schedule),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getColor(ColorScheme colorScheme, {Schedule? schedule}) {
    if (schedule != null && !schedule.isActive) {
      return colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    }
    switch (dose.status) {
      case DoseStatus.taken:
        return colorScheme.primary;
      case DoseStatus.skipped:
        return colorScheme.error;
      case DoseStatus.snoozed:
        return Colors.orange;
      case DoseStatus.overdue:
        return colorScheme.error;
      case DoseStatus.pending:
        return colorScheme.primary.withValues(alpha: 0.5);
    }
  }
}
