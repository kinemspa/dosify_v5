// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/widgets/entry_card.dart';
import 'package:dosifi_v5/src/widgets/entry_summary_row.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class UpNextEntryCard extends StatelessWidget {
  const UpNextEntryCard({
    required this.entry,
    required this.onEntryTap,
    this.onQuickAction,
    this.showMedicationName = true,
    this.medicationName,
    this.strengthOrConcentrationLabel,
    this.entryMetrics,
    this.primaryActionLabel,
    this.medicationFormIcon,
    super.key,
  });

  final CalculatedEntry? entry;
  final void Function(CalculatedEntry entry) onEntryTap;
  final ValueChanged<EntryStatus>? onQuickAction;
  final bool showMedicationName;
  final String? medicationName;
  final String? strengthOrConcentrationLabel;
  final String? entryMetrics;
  final String? primaryActionLabel;
  final IconData? medicationFormIcon;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return SectionFormCard(
        neutral: true,
        title: 'Up next',
        children: [Text('No upcoming entries', style: mutedTextStyle(context))],
      );
    }

    final hasDetails =
        (medicationName != null && medicationName!.trim().isNotEmpty) &&
        (strengthOrConcentrationLabel != null &&
            strengthOrConcentrationLabel!.trim().isNotEmpty) &&
        (entryMetrics != null && entryMetrics!.trim().isNotEmpty);

    return SectionFormCard(
      neutral: true,
      title: 'Up next',
      children: [
        if (hasDetails)
          EntryCard(
            entry: entry!,
            medicationName: medicationName!,
            strengthOrConcentrationLabel: strengthOrConcentrationLabel!,
            entryMetrics: entryMetrics!,
            primaryActionLabel: primaryActionLabel,
            medicationFormIcon: medicationFormIcon,
            onQuickAction: onQuickAction,
            onTap: () => onEntryTap(entry!),
          )
        else
          EntrySummaryRow(
            entry: entry!,
            showMedicationName: showMedicationName,
            onTap: () => onEntryTap(entry!),
          ),
      ],
    );
  }
}
