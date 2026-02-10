import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';

List<Widget> buildDoseCardInventoryMetaLines(
  BuildContext context, {
  required Medication medication,
  String? lastDoseLine,
}) {
  final stockInfo = MedicationDisplayHelpers.calculateStock(medication);
  final location = MedicationDisplayHelpers.primaryStorageLocation(medication);

  final cs = Theme.of(context).colorScheme;
  final metaStyle = microHelperTextStyle(
    context,
  )?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh));

  return <Widget>[
    Text(
      stockInfo.label,
      style: metaStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    if (location != null)
      Text(
        location,
        style: metaStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    if (lastDoseLine != null)
      Text(
        lastDoseLine,
        style: metaStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
  ];
}
