import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_status_ui.dart';

class ScheduleStatusBadge extends StatelessWidget {
  const ScheduleStatusBadge({
    required this.schedule,
    this.dense = false,
    super.key,
  });

  final Schedule schedule;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (schedule.isActive) return const SizedBox.shrink();

    final label = scheduleStatusLabel(schedule);

    final textColor = switch (schedule.status) {
      ScheduleStatus.paused => cs.primary,
      ScheduleStatus.disabled => cs.onSurfaceVariant,
      ScheduleStatus.completed => cs.onSurfaceVariant,
      ScheduleStatus.active => cs.primary,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? kSpacingXS : kSpacingS,
        vertical: dense ? kSpacingXXS : kSpacingXS,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: scheduleStatusBadgeTextStyle(
              context,
              dense: dense,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
