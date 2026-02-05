@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/dose_card.dart';

ThemeData _goldenTheme() {
  const primarySeed = kDetailHeaderGradientStart;
  const secondarySeed = kDoseStatusSnoozedOrange;

  final scheme = ColorScheme.fromSeed(seedColor: primarySeed).copyWith(
    primary: primarySeed,
    secondary: secondarySeed,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}

Widget _wrapForGolden(Widget child) {
  return MaterialApp(
    theme: _goldenTheme(),
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: const ValueKey<String>('golden'),
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 380),
            child: Padding(
              padding: const EdgeInsets.all(kSpacingM),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

CalculatedDose _dose({
  required DateTime scheduledTime,
}) {
  return CalculatedDose(
    scheduleId: 'schedule-1',
    scheduleName: 'Morning Routine',
    medicationName: 'Test Medication',
    scheduledTime: scheduledTime,
    doseValue: 1,
    doseUnit: 'tablet',
  );
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  group('DoseCard goldens', () {
    testWidgets('pending (active)', (tester) async {
      final dose = _dose(
        scheduledTime: DateTime(2026, 1, 26, 9),
      );

      await tester.pumpWidget(
        _wrapForGolden(
          DoseCard(
            dose: dose,
            medicationName: 'Test Medication',
            strengthOrConcentrationLabel: '25 mg tablet',
            doseMetrics: '1 tablet',
            onTap: () {},
            isActive: true,
            compact: false,
            showActions: true,
            statusOverride: DoseStatus.pending,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/dose_card_pending.png'),
      );
    });

    testWidgets('taken (active)', (tester) async {
      final dose = _dose(
        scheduledTime: DateTime(2026, 1, 26, 9),
      );

      await tester.pumpWidget(
        _wrapForGolden(
          DoseCard(
            dose: dose,
            medicationName: 'Test Medication',
            strengthOrConcentrationLabel: '25 mg tablet',
            doseMetrics: '1 tablet',
            onTap: () {},
            isActive: true,
            compact: false,
            showActions: true,
            statusOverride: DoseStatus.taken,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/dose_card_taken.png'),
      );
    });

    testWidgets('overdue (active)', (tester) async {
      final dose = _dose(
        scheduledTime: DateTime(2026, 1, 26, 9),
      );

      await tester.pumpWidget(
        _wrapForGolden(
          DoseCard(
            dose: dose,
            medicationName: 'Test Medication',
            strengthOrConcentrationLabel: '25 mg tablet',
            doseMetrics: '1 tablet',
            onTap: () {},
            isActive: true,
            compact: false,
            showActions: true,
            statusOverride: DoseStatus.overdue,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/dose_card_missed.png'),
      );
    });

    testWidgets('disabled (inactive schedule)', (tester) async {
      final dose = _dose(
        scheduledTime: DateTime(2026, 1, 26, 9),
      );

      await tester.pumpWidget(
        _wrapForGolden(
          DoseCard(
            dose: dose,
            medicationName: 'Test Medication',
            strengthOrConcentrationLabel: '25 mg tablet',
            doseMetrics: '1 tablet',
            onTap: () {},
            isActive: false,
            compact: false,
            showActions: true,
            statusOverride: DoseStatus.pending,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/dose_card_disabled.png'),
      );
    });

    testWidgets('compact (pending)', (tester) async {
      final dose = _dose(
        scheduledTime: DateTime(2026, 1, 26, 9),
      );

      await tester.pumpWidget(
        _wrapForGolden(
          DoseCard(
            dose: dose,
            medicationName: 'Test Medication',
            strengthOrConcentrationLabel: '25 mg tablet',
            doseMetrics: '1 tablet',
            onTap: () {},
            isActive: true,
            compact: true,
            showActions: true,
            statusOverride: DoseStatus.pending,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/dose_card_compact_pending.png'),
      );
    });

    testWidgets('compact (long metrics)', (tester) async {
      final dose = _dose(
        scheduledTime: DateTime(2026, 1, 26, 9),
      );

      await tester.pumpWidget(
        _wrapForGolden(
          DoseCard(
            dose: dose,
            medicationName: 'Very Long Medication Name That Should Ellipsize',
            strengthOrConcentrationLabel: '250 mcg/mL',
            doseMetrics: '0.75 mL (75 units) • 1.25 mg equiv',
            onTap: () {},
            isActive: true,
            compact: true,
            showActions: true,
            statusOverride: DoseStatus.pending,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/dose_card_compact_long.png'),
      );
    });
  });
}
