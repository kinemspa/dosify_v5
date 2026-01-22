import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';

String doseStatusLabel(DoseStatus status, {required bool disabled}) {
  if (disabled) return 'DISABLED';

  return switch (status) {
    DoseStatus.taken => 'TAKEN',
    DoseStatus.skipped => 'SKIPPED',
    DoseStatus.snoozed => 'SNOOZED',
    DoseStatus.due => 'OVERDUE',
    DoseStatus.overdue => 'MISSED',
    DoseStatus.pending => 'PENDING',
  };
}

({Color color, IconData icon}) doseStatusVisual(
  BuildContext context,
  DoseStatus status, {
  required bool disabled,
}) {
  final cs = Theme.of(context).colorScheme;

  if (disabled) {
    return (
      color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
      icon: Icons.do_not_disturb_on_rounded,
    );
  }

  return switch (status) {
    DoseStatus.taken => (
      color: kDoseStatusTakenGreen,
      icon: Icons.check_rounded,
    ),
    DoseStatus.skipped => (
      color: kDoseStatusSkippedRed,
      icon: Icons.block_rounded,
    ),
    DoseStatus.snoozed => (
      color: kDoseStatusSnoozedOrange,
      icon: Icons.snooze_rounded,
    ),
    DoseStatus.due => (
      color: kDoseStatusOverdueAmber,
      icon: Icons.schedule_rounded,
    ),
    DoseStatus.overdue => (
      color: kDoseStatusMissedDarkRed,
      icon: Icons.warning_rounded,
    ),
    DoseStatus.pending => (
      color: cs.primary,
      icon: Icons.notifications_rounded,
    ),
  };
}

({Color color, IconData icon}) doseActionVisual(
  BuildContext context,
  DoseAction action,
) {
  return switch (action) {
    DoseAction.taken => (
      color: kDoseStatusTakenGreen,
      icon: Icons.check_rounded,
    ),
    DoseAction.skipped => (
      color: kDoseStatusSkippedRed,
      icon: Icons.block_rounded,
    ),
    DoseAction.snoozed => (
      color: kDoseStatusSnoozedOrange,
      icon: Icons.snooze_rounded,
    ),
  };
}
