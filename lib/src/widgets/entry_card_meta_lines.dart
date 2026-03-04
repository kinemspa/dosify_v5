import 'package:flutter/material.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/presentation/medication_display_helpers.dart';

List<Widget> buildEntryCardInventoryMetaLines(
  BuildContext context, {
  required Medication medication,
  String? lastEntryLine,
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
    if (lastEntryLine != null)
      Text(
        lastEntryLine,
        style: metaStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
  ];
}
