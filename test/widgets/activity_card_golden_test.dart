@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/widgets/cards/activity_card.dart';

ThemeData _goldenTheme() {
  const primarySeed = kDetailHeaderGradientStart;
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
  double width = 380,
  double? textScaleFactor,
}) {
  return MaterialApp(
    theme: _goldenTheme(),
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
      ),
      child: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('golden'),
            child: ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: width),
              child: Padding(
                padding: const EdgeInsets.all(kSpacingM),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Medication _testMedication({required String id, required String name}) {
  return Medication(
    id: id,
    form: MedicationForm.tablet,
    name: name,
    strengthValue: 25,
    strengthUnit: Unit.mg,
    stockValue: 30,
    stockUnit: StockUnit.tablets,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActivityCard goldens', () {
    testWidgets('compact width with large text', (tester) async {
      final meds = <Medication>[
        _testMedication(
          id: 'm1',
          name: 'Very Long Medication Name That Should Ellipsize',
        ),
      ];

      await tester.pumpWidget(
        _wrapForGolden(
          ActivityCard(
            medications: meds,
            includedMedicationIds: const <String>{},
            onIncludedMedicationIdsChanged: null,
            rangePreset: ReportTimeRangePreset.last7Days,
            onRangePresetChanged: (_) {},
            isExpanded: true,
            reserveReorderHandleGutterWhenCollapsed: true,
          ),
          width: 320,
          textScaleFactor: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/activity_card_compact_large_text.png'),
      );
    });
  });
}
