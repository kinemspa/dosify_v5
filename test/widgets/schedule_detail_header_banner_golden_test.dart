@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/schedule_detail_header_banner.dart';

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

Widget _wrapForGolden(
  Widget child, {
  double width = 400,
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
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

Schedule _createTestSchedule({
  bool active = true,
  bool? pausedUntil,
  DateTime? endAt,
  String name = 'Morning Dose',
}) {
  return Schedule(
    id: 'test-schedule-1',
    name: name,
    medicationName: 'Test Medication',
    doseValue: 1.0,
    doseUnit: 'tablet',
    minutesOfDay: 540, // 9:00 AM
    daysOfWeek: const [1, 2, 3, 4, 5], // Mon-Fri
    medicationId: 'test-med-1',
    active: active,
    pausedUntil: pausedUntil != null
        ? DateTime.now().add(const Duration(days: 2))
        : null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScheduleDetailHeaderBanner goldens', () {
    testWidgets('active schedule with next dose - standard width',
        (tester) async {
      final schedule = _createTestSchedule(active: true);
      final nextDose = DateTime.now().add(const Duration(hours: 2));

      await tester.pumpWidget(
        _wrapForGolden(
          ScheduleDetailHeaderBanner(
            schedule: schedule,
            nextDose: nextDose,
            title: 'Morning Dose',
            onPauseResumePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/schedule_detail_header_banner_active.png',
        ),
      );
    });

    testWidgets('paused schedule - compact width with large text',
        (tester) async {
      final schedule = _createTestSchedule(
        active: true,
        pausedUntil: true,
      );
      final nextDose = DateTime.now().add(const Duration(days: 3));

      await tester.pumpWidget(
        _wrapForGolden(
          ScheduleDetailHeaderBanner(
            schedule: schedule,
            nextDose: nextDose,
            title: 'Paused Schedule',
            onPauseResumePressed: () {},
          ),
          width: 320,
          textScaleFactor: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/schedule_detail_header_banner_paused_compact_large_text.png',
        ),
      );
    });

    testWidgets('inactive schedule - no next dose', (tester) async {
      final schedule = _createTestSchedule(active: false);

      await tester.pumpWidget(
        _wrapForGolden(
          ScheduleDetailHeaderBanner(
            schedule: schedule,
            nextDose: null,
            title: 'Inactive Schedule',
            onPauseResumePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/schedule_detail_header_banner_inactive.png',
        ),
      );
    });

    testWidgets('completed schedule - compact width', (tester) async {
      final schedule = _createTestSchedule(
        active: false,
        name: 'Completed Schedule',
      );

      await tester.pumpWidget(
        _wrapForGolden(
          ScheduleDetailHeaderBanner(
            schedule: schedule,
            nextDose: null,
            title: 'Completed Schedule',
            onPauseResumePressed: () {},
          ),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/schedule_detail_header_banner_completed_compact.png',
        ),
      );
    });

    testWidgets('long medication name - text wrapping', (tester) async {
      final schedule = _createTestSchedule(
        active: true,
        name: 'Very Long Medication Name That Should Wrap or Ellipsize',
      );
      final nextDose = DateTime.now().add(const Duration(hours: 4));

      await tester.pumpWidget(
        _wrapForGolden(
          ScheduleDetailHeaderBanner(
            schedule: schedule,
            nextDose: nextDose,
            title: 'Very Long Medication Name That Should Wrap or Ellipsize',
            onPauseResumePressed: () {},
          ),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/schedule_detail_header_banner_long_title.png',
        ),
      );
    });
  });
}
