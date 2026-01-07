// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/dose_card.dart';
import 'package:dosifi_v5/src/widgets/dose_summary_row.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class UpNextDoseCard extends StatelessWidget {
  const UpNextDoseCard({
    required this.dose,
    required this.onDoseTap,
    this.onQuickAction,
    this.showMedicationName = true,
    this.medicationName,
    this.strengthOrConcentrationLabel,
    this.doseMetrics,
    this.primaryActionLabel,
    super.key,
  });

  final CalculatedDose? dose;
  final void Function(CalculatedDose dose) onDoseTap;
  final ValueChanged<DoseStatus>? onQuickAction;
  final bool showMedicationName;
  final String? medicationName;
  final String? strengthOrConcentrationLabel;
  final String? doseMetrics;
  final String? primaryActionLabel;

  @override
  Widget build(BuildContext context) {
    if (dose == null) {
      return SectionFormCard(
        neutral: true,
        title: 'Up next',
        children: [Text('No upcoming doses', style: mutedTextStyle(context))],
      );
    }

    final hasDetails =
        (medicationName != null && medicationName!.trim().isNotEmpty) &&
        (strengthOrConcentrationLabel != null &&
            strengthOrConcentrationLabel!.trim().isNotEmpty) &&
        (doseMetrics != null && doseMetrics!.trim().isNotEmpty);

    return SectionFormCard(
      neutral: true,
      title: 'Up next',
      children: [
        if (hasDetails)
          DoseCard(
            dose: dose!,
            medicationName: medicationName!,
            strengthOrConcentrationLabel: strengthOrConcentrationLabel!,
            doseMetrics: doseMetrics!,
            primaryActionLabel: primaryActionLabel,
            onQuickAction: onQuickAction,
            onTap: () => onDoseTap(dose!),
          )
        else
          DoseSummaryRow(
            dose: dose!,
            showMedicationName: showMedicationName,
            onTap: () => onDoseTap(dose!),
          ),
      ],
    );
  }
}
