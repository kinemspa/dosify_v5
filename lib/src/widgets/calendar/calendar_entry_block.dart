// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/entry_status_ui.dart';
import 'package:dosifi_v5/src/widgets/schedule_status_badge.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Displays a entry block in calendar views
class CalendarEntryBlock extends StatelessWidget {
  final CalculatedEntry entry;
  final VoidCallback? onTap;
  final bool compact;

  const CalendarEntryBlock({
    super.key,
    required this.entry,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final schedule = Hive.box<Schedule>('schedules').get(entry.scheduleId);
    final disabled = schedule != null && !schedule.isActive;
    final statusVisual = entryStatusVisual(context, entry.status, disabled: disabled);
    final statusColor = statusVisual.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: Container(
        height: compact
            ? kCalendarEntryBlockMinHeight
            : kCalendarEntryBlockHeight,
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
                      entry.scheduleName,
                      style: calendarEntryBlockTitleTextStyle(
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

              // Entry description
              Text(
                entry.entryDescription,
                style: calendarEntryBlockSubtitleTextStyle(
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
    if (!disabled && entry.status == EntryStatus.pending) {
      return const SizedBox.shrink();
    }

    final label = entryStatusLabel(entry.status, disabled: disabled);
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

    switch (entry.status) {
      case EntryStatus.logged:
        return statusColor.withValues(alpha: kOpacitySubtle);
      case EntryStatus.skipped:
        return statusColor.withValues(alpha: kOpacitySubtleLow);
      case EntryStatus.snoozed:
        return statusColor.withValues(alpha: kOpacitySubtle);
      case EntryStatus.due:
      case EntryStatus.overdue:
        return statusColor.withValues(alpha: kOpacityMinimal);
      case EntryStatus.pending:
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

    switch (entry.status) {
      case EntryStatus.logged:
        return statusColor.withValues(alpha: kOpacityMediumLow);
      case EntryStatus.skipped:
        return statusColor.withValues(alpha: kOpacityVeryLow);
      case EntryStatus.snoozed:
        return statusColor.withValues(alpha: kOpacityMediumHigh);
      case EntryStatus.due:
      case EntryStatus.overdue:
        return statusColor.withValues(alpha: kOpacityHigh);
      case EntryStatus.pending:
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
    switch (entry.status) {
      case EntryStatus.logged:
      case EntryStatus.skipped:
      case EntryStatus.snoozed:
      case EntryStatus.due:
      case EntryStatus.overdue:
        return statusColor;
      case EntryStatus.pending:
        return statusColor.withValues(alpha: kOpacityMediumHigh);
    }
  }
}

/// Compact entry indicator (dot) for month view
class CalendarEntryIndicator extends StatelessWidget {
  final CalculatedEntry entry;

  const CalendarEntryIndicator({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final schedule = Hive.box<Schedule>('schedules').get(entry.scheduleId);
    final disabled = schedule != null && !schedule.isActive;

    final visual = entryStatusVisual(context, entry.status, disabled: disabled);
    final color = entry.status == EntryStatus.pending
        ? visual.color.withValues(alpha: kOpacityMediumLow)
        : visual.color;

    return Container(
      width: kCalendarEntryIndicatorSize,
      height: kCalendarEntryIndicatorSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(kCalendarEntryIndicatorBorderRadius),
      ),
    );
  }
}
