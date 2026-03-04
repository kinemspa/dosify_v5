import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/widgets/entry_card.dart';

/// Test for EntryCard at very small widths to ensure no overflow.
/// This is a regression test to prevent layout issues on small screens.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  group('EntryCard small width regression tests', () {
    testWidgets('renders without overflow at 320px width', (tester) async {
      final entry = CalculatedEntry(
        scheduleId: 'schedule-1',
        scheduleName: 'Morning Routine',
        medicationName: 'Very Long Medication Name That Should Ellipsize',
        scheduledTime: DateTime(2026, 1, 26, 9),
        entryValue: 1,
        entryUnit: 'tablet',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: kDetailHeaderGradientStart,
            ),
            useMaterial3: true,
          ),
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: 320),
                child: Padding(
                  padding: const EdgeInsets.all(kSpacingM),
                  child: EntryCard(
                    entry: entry,
                    medicationName: 'Very Long Medication Name That Should Ellipsize',
                    strengthOrConcentrationLabel: '250 mcg/mL',
                    entryMetrics: '0.75 mL (75 units) • 1.25 mg equiv',
                    onTap: () {},
                    isActive: true,
                    compact: false,
                    showActions: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no overflow errors were thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 280px width (compact)', (tester) async {
      final entry = CalculatedEntry(
        scheduleId: 'schedule-1',
        scheduleName: 'Morning Routine with Very Long Name',
        medicationName: 'Very Long Medication Name',
        scheduledTime: DateTime(2026, 1, 26, 9),
        entryValue: 1,
        entryUnit: 'tablet',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: kDetailHeaderGradientStart,
            ),
            useMaterial3: true,
          ),
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: 280),
                child: Padding(
                  padding: const EdgeInsets.all(kSpacingS),
                  child: EntryCard(
                    entry: entry,
                    medicationName: 'Very Long Medication Name',
                    strengthOrConcentrationLabel: '250 mcg/mL',
                    entryMetrics: '0.75 mL (75 units)',
                    onTap: () {},
                    isActive: true,
                    compact: true,
                    showActions: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no overflow errors were thrown
      expect(tester.takeException(), isNull);
    });
  });
}
