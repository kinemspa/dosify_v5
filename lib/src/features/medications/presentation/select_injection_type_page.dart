// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/selection_cards.dart';

class SelectInjectionTypePage extends StatelessWidget {
  const SelectInjectionTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Select Injection Type',
        forceBackButton: true,
      ),
      body: ListView(
        padding: kPagePaddingNoBottom,
        children: [
          const SelectionHeaderCard(
            icon: Icons.vaccines,
            title: 'Select injection type',
            subtitle: 'We’ll tailor fields for the syringe or vial you use',
          ),
          const SizedBox(height: kSpacingL),
          SelectionOptionCard(
            icon: Icons.colorize,
            title: 'Pre-Filled Syringe',
            subtitle: 'Ready to use single dose syringe',
            onTap: () => context.push('/medications/add/injection/pfs'),
          ),
          const SizedBox(height: kSpacingL),
          SelectionOptionCard(
            icon: Icons.local_drink,
            title: 'Single Dose Vial',
            subtitle: 'One time use vial',
            onTap: () => context.push('/medications/add/injection/single'),
          ),
          const SizedBox(height: kSpacingL),
          SelectionOptionCard(
            icon: Icons.addchart,
            title: 'Multi Dose Vial',
            subtitle: 'Step-by-step guided setup for reconstitution',
            onTap: () => context.push('/medications/add/injection/multi'),
          ),
          const SizedBox(height: kSpacingXXL),
        ],
      ),
    );
  }
}
