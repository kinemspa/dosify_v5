@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/widgets/cards/today_entries_card.dart';

void _registerHiveAdaptersIfNeeded() {
  if (!Hive.isAdapterRegistered(UnitAdapter().typeId)) {
    Hive.registerAdapter(UnitAdapter());
  }
  if (!Hive.isAdapterRegistered(StockUnitAdapter().typeId)) {
    Hive.registerAdapter(StockUnitAdapter());
  }
  if (!Hive.isAdapterRegistered(MedicationFormAdapter().typeId)) {
    Hive.registerAdapter(MedicationFormAdapter());
  }
  if (!Hive.isAdapterRegistered(VolumeUnitAdapter().typeId)) {
    Hive.registerAdapter(VolumeUnitAdapter());
  }
  if (!Hive.isAdapterRegistered(MedicationAdapter().typeId)) {
    Hive.registerAdapter(MedicationAdapter());
  }
  if (!Hive.isAdapterRegistered(ScheduleAdapter().typeId)) {
    Hive.registerAdapter(ScheduleAdapter());
  }
  if (!Hive.isAdapterRegistered(EntryActionAdapter().typeId)) {
    Hive.registerAdapter(EntryActionAdapter());
  }
  if (!Hive.isAdapterRegistered(EntryLogAdapter().typeId)) {
    Hive.registerAdapter(EntryLogAdapter());
  }
}

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

  Directory? hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp('skedux_hive_today_');
    Hive.init(hiveDir!.path);
    _registerHiveAdaptersIfNeeded();

    await Hive.openBox<Medication>('medications');
    await Hive.openBox<Schedule>('schedules');
    await Hive.openBox<EntryLog>('entry_logs');
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir != null && hiveDir!.existsSync()) {
      hiveDir!.deleteSync(recursive: true);
    }
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
