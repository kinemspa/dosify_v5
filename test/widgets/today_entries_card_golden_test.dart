@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_log.dart';
import 'package:dosifi_v5/src/widgets/cards/today_entries_card.dart';

ThemeData _goldenTheme() {
  const primarySeed = kDetailHeaderGradientStart;
  const secondarySeed = kEntryStatusSnoozedOrange;

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

Widget _wrapForGolden(
  Widget child, {
  double width = 380,
  double? textScaleFactor,
}) {
  return ProviderScope(
    child: MaterialApp(
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
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive for tests
    await Hive.initFlutter();
    
    // Register adapters if needed
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MedicationAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ScheduleAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(EntryLogAdapter());
    }

    // Open boxes
    await Hive.openBox<Medication>('medications');
    await Hive.openBox<Schedule>('schedules');
    await Hive.openBox<EntryLog>('entry_logs');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('TodayEntriesCard goldens', () {
    testWidgets('collapsed state - standard width', (tester) async {
      await tester.pumpWidget(
        _wrapForGolden(
          const TodayEntriesCard(
            scope: TodayEntriesScope.all(),
            isExpanded: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/today_entries_card_collapsed.png'),
      );
    });

    testWidgets('collapsed state - compact width with large text',
        (tester) async {
      await tester.pumpWidget(
        _wrapForGolden(
          const TodayEntriesCard(
            scope: TodayEntriesScope.all(),
            isExpanded: false,
            reserveReorderHandleGutterWhenCollapsed: true,
          ),
          width: 320,
          textScaleFactor: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/today_entries_card_collapsed_compact_large_text.png',
        ),
      );
    });

    testWidgets('collapsed with reorder handle gutter', (tester) async {
      await tester.pumpWidget(
        _wrapForGolden(
          const TodayEntriesCard(
            scope: TodayEntriesScope.all(),
            isExpanded: false,
            reserveReorderHandleGutterWhenCollapsed: true,
          ),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/today_entries_card_collapsed_with_gutter.png',
        ),
      );
    });
  });
}
