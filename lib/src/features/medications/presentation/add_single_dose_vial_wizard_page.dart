// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/presentation/add_vial_wizard_page.dart';
export 'package:skedux/src/features/medications/presentation/add_vial_wizard_page.dart' show VialMedType;

class AddSingleDoseVialWizardPage extends StatelessWidget {
  const AddSingleDoseVialWizardPage({
    super.key,
    this.initial,
    this.initialMedicationId,
  });
  final Medication? initial;
  final String? initialMedicationId;

  @override
  Widget build(BuildContext context) => AddVialWizardPage(
        vialMedType: VialMedType.singleDoseVial,
        initial: initial,
        initialMedicationId: initialMedicationId,
      );
}