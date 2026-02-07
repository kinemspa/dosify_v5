import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/widgets/combined_reports_history_widget.dart';
import 'package:dosifi_v5/src/widgets/unified_empty_state.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class ActivityCard extends StatefulWidget {
  const ActivityCard({
    super.key,
    this.title = 'Activity',
    required this.medications,
    required this.includedMedicationIds,
    this.onIncludedMedicationIdsChanged,
    required this.rangePreset,
    required this.onRangePresetChanged,
    this.isExpanded,
    this.onExpandedChanged,
    this.reserveReorderHandleGutterWhenCollapsed = false,
    this.neutral = true,
    this.frameless = true,
  });

  final String title;
  final List<Medication> medications;
  final Set<String> includedMedicationIds;

  /// When null, the card displays a non-interactive included-meds label.
  final ValueChanged<Set<String>>? onIncludedMedicationIdsChanged;

  final ReportTimeRangePreset rangePreset;
  final ValueChanged<ReportTimeRangePreset> onRangePresetChanged;

  /// If provided, expansion state is controlled by the parent.
  final bool? isExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  final bool reserveReorderHandleGutterWhenCollapsed;
  final bool neutral;
  final bool frameless;

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _internalExpanded = true;

  bool get _expanded => widget.isExpanded ?? _internalExpanded;

  void _setExpanded(bool expanded) {
    widget.onExpandedChanged?.call(expanded);
    if (widget.isExpanded != null) return;
    if (!mounted) return;
    setState(() => _internalExpanded = expanded);
  }

  @override
  Widget build(BuildContext context) {
    final meds = widget.medications.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return CollapsibleSectionFormCard(
      neutral: widget.neutral,
      frameless: widget.frameless,
      title: widget.title,
      isExpanded: _expanded,
      reserveReorderHandleGutterWhenCollapsed:
          widget.reserveReorderHandleGutterWhenCollapsed,
      onExpandedChanged: _setExpanded,
      children: [
        if (meds.isEmpty)
          const UnifiedEmptyState(title: 'No medications')
        else ...[
          Row(
            children: [
              Expanded(
                child: widget.onIncludedMedicationIdsChanged == null
                    ? Text(
                        '${widget.includedMedicationIds.length}/${meds.length} meds',
                        style: helperTextStyle(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : MultiSelectDropdown36<String>(
                        items: meds
                            .map(
                              (m) => MultiSelectItem<String>(
                                value: m.id,
                                label: m.name,
                              ),
                            )
                            .toList(growable: false),
                        selectedValues: widget.includedMedicationIds,
                        onChanged: widget.onIncludedMedicationIdsChanged!,
                        buttonLabel:
                            '${widget.includedMedicationIds.length}/${meds.length} meds',
                      ),
              ),
              const SizedBox(width: kSpacingXS),
              SizedBox(
                width: kCompactControlMaxWidth,
                child: SmallDropdown36<ReportTimeRangePreset>(
                  value: widget.rangePreset,
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
                    widget.onRangePresetChanged(next);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingS),
          const SizedBox(height: kSpacingXS),
          if (widget.includedMedicationIds.isEmpty)
            const UnifiedEmptyState(title: 'No medications selected')
          else
            CombinedReportsHistoryWidget(
              includedMedicationIds: widget.includedMedicationIds,
              embedInParentCard: true,
              rangePreset: widget.rangePreset,
            ),
        ],
      ],
    );
  }
}
