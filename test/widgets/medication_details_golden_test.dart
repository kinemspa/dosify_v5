@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_detail_header_identity.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_sealed_vials_editor_card.dart';
import 'package:dosifi_v5/src/widgets/status_pill.dart';

ThemeData _goldenTheme() {
  const primarySeed = kMedicationDetailGradientStart;
  const secondarySeed = kDoseStatusSnoozedOrange;

  final scheme = ColorScheme.fromSeed(
    seedColor: primarySeed,
  ).copyWith(primary: primarySeed, secondary: secondarySeed);

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}

Widget _wrapForGolden(
  Widget child, {
  double width = 320,
  double textScaleFactor = 1.3,
}) {
  return MaterialApp(
    theme: _goldenTheme(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
      child: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('golden'),
            child: ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: width),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Medication Details targeted goldens', () {
    testWidgets('header identity - compact width with large text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapForGolden(
          Builder(
            builder: (context) {
              final cs = Theme.of(context).colorScheme;

              return Container(
                color: cs.primary,
                padding: const EdgeInsets.all(kPageHorizontalPadding),
                child: MedicationDetailHeaderIdentity(
                  name: 'Very Long Medication Name That Should Ellipsize',
                  formLabel: 'tablet',
                  manufacturer: 'Acme Pharmaceuticals',
                  headerForeground: cs.onPrimary,
                  onPrimary: cs.onPrimary,
                  t: 0,
                  onTapName: () {},
                  onTapManufacturer: () {},
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/medication_details_header_identity_compact_large_text.png',
        ),
      );
    });

    testWidgets('sealed vials editor card - compact width with large text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapForGolden(
          Builder(
            builder: (context) {
              final cs = Theme.of(context).colorScheme;
              return Padding(
                padding: const EdgeInsets.all(kPageHorizontalPadding),
                child: MedicationSealedVialsEditorCard(
                  sealedVialsCountLabel: '12 sealed vials',
                  batchNumberValue: 'Not set',
                  batchNumberIsPlaceholder: true,
                  onEditBatchNumber: () {},
                  expiryValue: 'Feb 29, 2028',
                  expiryIsPlaceholder: false,
                  expiryIsWarning: true,
                  onEditExpiry: () {},
                  locationValue: 'Kitchen cabinet (top shelf)',
                  locationIsPlaceholder: false,
                  onEditLocation: () {},
                  conditionsRow: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kSpacingL,
                      vertical: kSpacingS,
                    ),
                    child: Wrap(
                      spacing: kFieldSpacing,
                      runSpacing: kFieldSpacing,
                      children: [
                        StatusPill(
                          label: 'Fridge',
                          color: cs.primary,
                          icon: Icons.ac_unit,
                          dense: true,
                        ),
                        StatusPill(
                          label: 'Light',
                          color: cs.primary,
                          icon: Icons.dark_mode_outlined,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/medication_details_sealed_vials_editor_compact_large_text.png',
        ),
      );
    });
  });
}
