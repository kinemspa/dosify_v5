// Activity section extracted from medication_detail_page.dart (#166).
import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/widgets/cards/activity_card.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Activity card wrapper with owned range-preset and expand state.
///
/// [isExpanded] and [onExpandedChanged] are owned by the parent so the parent
/// can coordinate the reorder-handle gutter logic across all cards.
class MedicationActivitySection extends StatelessWidget {
  const MedicationActivitySection({
    super.key,
    required this.med,
    required this.isExpanded,
    required this.onExpandedChanged,
    required this.rangePreset,
    required this.onRangePresetChanged,
  });

  final Medication med;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final ReportTimeRangePreset rangePreset;
  final ValueChanged<ReportTimeRangePreset> onRangePresetChanged;

  @override
  Widget build(BuildContext context) {
    return ActivityCard(
      medications: [med],
      includedMedicationIds: {med.id},
      rangePreset: rangePreset,
      onRangePresetChanged: onRangePresetChanged,
      isExpanded: isExpanded,
      reserveReorderHandleGutterWhenCollapsed: true,
      onExpandedChanged: onExpandedChanged,
    );
  }
}
