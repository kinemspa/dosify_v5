@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/schedules/domain/calculated_entry.dart';
import 'package:skedux/src/widgets/entry_card.dart';

ThemeData _goldenTheme() {
  const primarySeed = kDetailHeaderGradientStart;
  const secondarySeed = kEntryStatusSnoozedOrange;

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

Widget _wrapForGoldenConstrained(
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

CalculatedEntry _entry({required DateTime scheduledTime}) {
  return CalculatedEntry(
    scheduleId: 'schedule-1',
    scheduleName: 'Morning Routine',
    medicationName: 'Test Medication',
    scheduledTime: scheduledTime,
    entryValue: 1,
    entryUnit: 'tablet',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  group('EntryCard goldens', () {
    testWidgets('pending (active)', (tester) async {
      final entry = _entry(scheduledTime: DateTime(2026, 1, 26, 9));

      await tester.pumpWidget(
        _wrapForGolden(
          EntryCard(
            entry: entry,
            medicationName: 'Test Medication',
            strengthOrConcentrationLabel: '25 mg tablet',
            entryMetrics: '1 tablet',
            onTap: () {},
            isActive: true,
            compact: false,
            showActions: true,
            statusOverride: EntryStatus.pending,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/entry_card_pending.png'),
      );
    });

    testWidgets('taken (active)', (tester) async {
      final entry = _entry(scheduledTime: DateTime(2026, 1, 26, 9));

      await tester.pumpWidget(
        _wrapForGolden(
          EntryCard(
            entry: entry,
            medicationName: 'Test Medication',
            strengthOrConcentrationLabel: '25 mg tablet',
            entryMetrics: '1 tablet',
            onTap: () {},
            isActive: true,
            compact: false,
            showActions: true,
            statusOverride: EntryStatus.logged,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/entry_card_taken.png'),
      );
    });

    testWidgets('overdue (active)', (tester) async {
      final entry = _entry(scheduledTime: DateTime(2026, 1, 26, 9));

      await tester.pumpWidget(
        _wrapForGolden(
          EntryCard(
            entry: entry,
            medicationName: 'Test Medication',
            strengthOrConcentrationLabel: '25 mg tablet',
            entryMetrics: '1 tablet',
            onTap: () {},
            isActive: true,
            compact: false,
            showActions: true,
            statusOverride: EntryStatus.overdue,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/entry_card_missed.png'),
      );
    });

    testWidgets('disabled (inactive schedule)', (tester) async {
      final entry = _entry(scheduledTime: DateTime(2026, 1, 26, 9));

      await tester.pumpWidget(
        _wrapForGolden(
          EntryCard(
            entry: entry,
            medicationName: 'Test Medication',
            strengthOrConcentrationLabel: '25 mg tablet',
            entryMetrics: '1 tablet',
            onTap: () {},
            isActive: false,
            compact: false,
            showActions: true,
            statusOverride: EntryStatus.pending,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/entry_card_disabled.png'),
      );
    });

    testWidgets('compact (pending)', (tester) async {
      final entry = _entry(scheduledTime: DateTime(2026, 1, 26, 9));

      await tester.pumpWidget(
        _wrapForGolden(
          EntryCard(
            entry: entry,
            medicationName: 'Test Medication',
            strengthOrConcentrationLabel: '25 mg tablet',
            entryMetrics: '1 tablet',
            onTap: () {},
            isActive: true,
            compact: true,
            showActions: true,
            statusOverride: EntryStatus.pending,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/entry_card_compact_pending.png'),
      );
    });

    testWidgets('compact (long metrics)', (tester) async {
      final entry = _entry(scheduledTime: DateTime(2026, 1, 26, 9));

      await tester.pumpWidget(
        _wrapForGolden(
          EntryCard(
            entry: entry,
            medicationName: 'Very Long Medication Name That Should Ellipsize',
            strengthOrConcentrationLabel: '250 mcg/mL',
            entryMetrics: '0.75 mL (75 units) • 1.25 mg equiv',
            onTap: () {},
            isActive: true,
            compact: true,
            showActions: true,
            statusOverride: EntryStatus.pending,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/entry_card_compact_long.png'),
      );
    });

    testWidgets('compact pending - compact width with large text', (
      tester,
    ) async {
      final entry = _entry(scheduledTime: DateTime(2026, 1, 26, 9));

      await tester.pumpWidget(
        _wrapForGoldenConstrained(
          EntryCard(
            entry: entry,
            medicationName: 'Very Long Medication Name That Should Ellipsize',
            strengthOrConcentrationLabel: '250 mcg/mL',
            entryMetrics: '0.75 mL (75 units) • 1.25 mg equiv',
            onTap: () {},
            isActive: true,
            compact: true,
            showActions: true,
            statusOverride: EntryStatus.pending,
          ),
          width: 320,
          textScaleFactor: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/entry_card_compact_pending_compact_large_text.png',
        ),
      );
    });
  });
}
