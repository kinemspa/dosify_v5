import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_log.dart';

String entryStatusLabel(EntryStatus status, {required bool disabled}) {
  return entryStatusLabelText(status, disabled: disabled);
}

({Color color, IconData icon}) entryStatusVisual(
  BuildContext context,
  EntryStatus status, {
  required bool disabled,
}) {
  return entryStatusVisualSpec(context, status, disabled: disabled);
}

({Color color, IconData icon}) entryActionVisual(
  BuildContext context,
  EntryAction action,
) {
  return entryActionVisualSpec(context, action);
}
