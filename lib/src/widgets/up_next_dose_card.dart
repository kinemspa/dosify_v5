// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/dose_summary_row.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class UpNextDoseCard extends StatelessWidget {
  const UpNextDoseCard({
    required this.dose,
    required this.onDoseTap,
    this.showMedicationName = true,
    super.key,
  });

  final CalculatedDose? dose;
  final void Function(CalculatedDose dose) onDoseTap;
  final bool showMedicationName;

  @override
  Widget build(BuildContext context) {
    if (dose == null) {
      return SectionFormCard(
        neutral: true,
        title: 'Up next',
        children: [Text('No upcoming doses', style: mutedTextStyle(context))],
      );
    }

    return SectionFormCard(
      neutral: true,
      title: 'Up next',
      children: [
        DoseSummaryRow(
          dose: dose!,
          showMedicationName: showMedicationName,
          onTap: () => onDoseTap(dose!),
        ),
      ],
    );
  }
}
