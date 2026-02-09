@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/schedule_list_card.dart';

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

Schedule _testSchedule() {
  return Schedule(
    id: 's1',
    name: 'Very Long Schedule Name That Should Ellipsize',
    medicationName: 'Very Long Medication Name That Should Ellipsize',
    doseValue: 1,
    doseUnit: 'tablet',
    minutesOfDay: 9 * 60,
    daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
    active: false,
    pausedUntil: null,
    medicationId: 'm1',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScheduleListCard goldens', () {
    testWidgets('dense - compact width with large text', (tester) async {
      await tester.pumpWidget(
        _wrapForGolden(
          ScheduleListCard(schedule: _testSchedule(), dense: true),
          width: 320,
          textScaleFactor: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/schedule_list_card_dense_compact_large_text.png',
        ),
      );
    });
  });
}
