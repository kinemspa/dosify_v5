// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/add_solid_med_wizard_page.dart';

export 'add_solid_med_wizard_page.dart' show SolidMedType;

/// Thin wrapper - delegates to [AddSolidMedWizardPage] with [SolidMedType.capsule].
class AddCapsuleWizardPage extends StatelessWidget {
  const AddCapsuleWizardPage({
    super.key,
    this.initial,
    this.initialMedicationId,
  });

  final Medication? initial;
  final String? initialMedicationId;

  @override
  Widget build(BuildContext context) => AddSolidMedWizardPage(
    solidMedType: SolidMedType.capsule,
    initial: initial,
    initialMedicationId: initialMedicationId,
  );
}
