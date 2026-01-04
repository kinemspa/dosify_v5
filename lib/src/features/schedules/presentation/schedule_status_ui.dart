import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

String scheduleStatusLabel(Schedule s) {
  return switch (s.status) {
    ScheduleStatus.active => 'Active',
    ScheduleStatus.paused => 'Paused',
    ScheduleStatus.disabled => 'Disabled',
    ScheduleStatus.completed => 'Completed',
  };
}

IconData scheduleStatusIcon(Schedule s) {
  return switch (s.status) {
    ScheduleStatus.active => Icons.play_circle_outline,
    ScheduleStatus.paused => Icons.pause_circle_outline,
    ScheduleStatus.disabled => Icons.block_outlined,
    ScheduleStatus.completed => Icons.check_circle_outline,
  };
}
