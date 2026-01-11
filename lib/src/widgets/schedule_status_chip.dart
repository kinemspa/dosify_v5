import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_status_ui.dart';

class ScheduleStatusChip extends StatelessWidget {
  const ScheduleStatusChip({
    super.key,
    required this.schedule,
    this.dense = false,
  });

  final Schedule schedule;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final label = scheduleStatusLabel(schedule);
    final color = _statusColor(context, schedule);

    final fontSize = dense ? kFontSizeXXSmall : kFontSizeSmall;
    final horizontalPadding = dense ? kSpacingXXS : kSpacingS;
    final verticalPadding = dense ? kSpacingXXS : kSpacingXS;
    final borderRadius = dense ? kBorderRadiusChipTight : kBorderRadiusChip;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: kOpacityMinimal),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(alpha: kOpacityMedium),
          width: kBorderWidthThin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: helperTextStyle(
              context,
              color: color,
            )?.copyWith(fontWeight: kFontWeightSemiBold, fontSize: fontSize),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, Schedule schedule) {
    final cs = Theme.of(context).colorScheme;

    switch (schedule.status) {
      case ScheduleStatus.active:
        return cs.primary;
      case ScheduleStatus.paused:
        return cs.tertiary;
      case ScheduleStatus.disabled:
        return cs.error;
      case ScheduleStatus.completed:
        return cs.primary;
    }
  }
}

class ScheduleStatusIcon extends StatelessWidget {
  const ScheduleStatusIcon({super.key, required this.schedule, this.size});

  final Schedule schedule;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _presentation(context, schedule);
    return Icon(icon, size: size ?? kIconSizeXSmall, color: color);
  }

  (Color, IconData) _presentation(BuildContext context, Schedule schedule) {
    final cs = Theme.of(context).colorScheme;

    switch (schedule.status) {
      case ScheduleStatus.active:
        return (cs.primary, scheduleStatusIcon(schedule));
      case ScheduleStatus.paused:
        return (cs.tertiary, scheduleStatusIcon(schedule));
      case ScheduleStatus.disabled:
        return (cs.error, scheduleStatusIcon(schedule));
      case ScheduleStatus.completed:
        return (cs.primary, scheduleStatusIcon(schedule));
    }
  }
}
