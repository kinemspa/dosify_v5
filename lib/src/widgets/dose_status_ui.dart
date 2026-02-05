import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';

String doseStatusLabel(DoseStatus status, {required bool disabled}) {
  return doseStatusLabelText(status, disabled: disabled);
}

({Color color, IconData icon}) doseStatusVisual(
  BuildContext context,
  DoseStatus status, {
  required bool disabled,
}) {
  return doseStatusVisualSpec(context, status, disabled: disabled);
}

({Color color, IconData icon}) doseActionVisual(
  BuildContext context,
  DoseAction action,
) {
  return doseActionVisualSpec(context, action);
}
