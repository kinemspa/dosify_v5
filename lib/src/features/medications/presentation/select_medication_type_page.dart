// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/selection_cards.dart';

class SelectMedicationTypePage extends StatelessWidget {
  const SelectMedicationTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Medication Type',
        forceBackButton: true,
      ),
      body: ListView(
        padding: kPagePaddingNoBottom,
        children: [
          const SelectionHeaderCard(
            icon: Icons.add_circle_outline,
            title: 'Choose medication type',
            subtitle: 'We’ll tailor the fields for your choice',
          ),
          const SizedBox(height: kSpacingL),
          SelectionOptionCard(
            icon: Icons.add_circle,
            title: 'Tablet',
            subtitle: 'Solid pill dosage form',
            onTap: () => context.push('/medications/add/tablet'),
          ),
          const SizedBox(height: kSpacingL),
          SelectionOptionCard(
            icon: MdiIcons.pill,
            title: 'Capsule',
            subtitle: 'Powder or pellets in a gelatin shell',
            onTap: () => context.push('/medications/add/capsule'),
          ),
          const SizedBox(height: kSpacingL),
          SelectionOptionCard(
            icon: Icons.colorize,
            title: 'Injection',
            subtitle: 'Pre-filled syringes or vials',
            onTap: () => context.push('/medications/select-injection-type'),
          ),
          const SizedBox(height: kSpacingXXL),
        ],
      ),
    );
  }
}
