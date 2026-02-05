import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class ReportTimeRangeSelectorRow extends StatelessWidget {
  const ReportTimeRangeSelectorRow({
    required this.value,
    required this.onChanged,
    super.key,
    this.label = 'Range',
  });

  final String label;
  final ReportTimeRangePreset value;
  final ValueChanged<ReportTimeRangePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return LabelFieldRow(
      label: label,
      field: SmallDropdown36<ReportTimeRangePreset>(
        value: value,
        items: ReportTimeRangePreset.values
            .map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(ReportTimeRange(p).label),
              ),
            )
            .toList(growable: false),
        onChanged: (next) {
          if (next == null) return;
          onChanged(next);
        },
      ),
    );
  }
}
