import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/widgets/combined_reports_history_widget.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class MedicationReportsWidget extends StatefulWidget {
  const MedicationReportsWidget({
    required this.medication,
    this.isExpanded = true,
    this.onExpandedChanged,
    this.embedInParentCard = false,
    this.rangePreset,
    this.onRangePresetChanged,
    this.showTimeRangeControl = true,
    super.key,
  });

  final Medication medication;
  final bool isExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final bool embedInParentCard;
  final ReportTimeRangePreset? rangePreset;
  final ValueChanged<ReportTimeRangePreset>? onRangePresetChanged;
  final bool showTimeRangeControl;

  @override
  State<MedicationReportsWidget> createState() =>
      _MedicationReportsWidgetState();
}

class _MedicationReportsWidgetState extends State<MedicationReportsWidget> {
  bool _isExpandedInternal = true;
  ReportTimeRangePreset _rangePresetInternal = ReportTimeRangePreset.allTime;

  @override
  void initState() {
    super.initState();
    _isExpandedInternal = widget.isExpanded;
    _rangePresetInternal = widget.rangePreset ?? ReportTimeRangePreset.allTime;
  }

  @override
  void didUpdateWidget(covariant MedicationReportsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onExpandedChanged != null && widget.isExpanded != oldWidget.isExpanded) {
      _isExpandedInternal = widget.isExpanded;
    }
    if (widget.rangePreset != null && widget.rangePreset != oldWidget.rangePreset) {
      _rangePresetInternal = widget.rangePreset!;
    }
  }

  ReportTimeRangePreset get _rangePreset =>
      widget.rangePreset ?? _rangePresetInternal;

  bool get _isExpanded =>
      widget.onExpandedChanged != null ? widget.isExpanded : _isExpandedInternal;

  void _setRangePreset(ReportTimeRangePreset next) {
    widget.onRangePresetChanged?.call(next);
    if (widget.rangePreset != null || !mounted) return;
    setState(() => _rangePresetInternal = next);
  }

  void _setExpanded(bool expanded) {
    widget.onExpandedChanged?.call(expanded);
    if (widget.onExpandedChanged != null || !mounted) return;
    setState(() => _isExpandedInternal = expanded);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final body = SectionFormCard(
      title: '${widget.medication.name} Activity',
      neutral: true,
      children: [
        if (widget.showTimeRangeControl)
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: kCompactControlWidth,
              child: SmallDropdown36<ReportTimeRangePreset>(
                value: _rangePreset,
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
                  _setRangePreset(next);
                },
              ),
            ),
          ),
        if (widget.showTimeRangeControl) const SizedBox(height: kSpacingXS),
        Divider(
          height: kSpacingM,
          thickness: kBorderWidthThin,
          color: cs.outlineVariant.withValues(alpha: kOpacityVeryLow),
        ),
        CombinedReportsHistoryWidget(
          includedMedicationIds: {widget.medication.id},
          embedInParentCard: true,
          rangePreset: _rangePreset,
        ),
      ],
    );

    if (widget.embedInParentCard) {
      return body;
    }

    return CollapsibleSectionFormCard(
      title: 'Activity',
      neutral: true,
      isExpanded: _isExpanded,
      onExpandedChanged: _setExpanded,
      children: [body],
    );
  }
}
