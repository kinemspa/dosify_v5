import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_status_ui.dart';

class ScheduleStatusChip extends StatelessWidget {
  const ScheduleStatusChip({super.key, required this.schedule});

  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final label = scheduleStatusLabel(schedule);
    final (color, icon) = _presentation(context, schedule);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingS,
        vertical: kSpacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: kOpacityMinimal),
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(
          color: color.withValues(alpha: kOpacityMedium),
          width: kBorderWidthThin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: kIconSizeSmall, color: color),
          const SizedBox(width: kSpacingXS),
          Text(
            label,
            style: helperTextStyle(context, color: color)?.copyWith(
              fontWeight: kFontWeightSemiBold,
              fontSize: kFontSizeSmall,
            ),
          ),
        ],
      ),
    );
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
