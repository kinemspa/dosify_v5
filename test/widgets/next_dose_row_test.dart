import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/widgets/next_dose_row.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

void main() {
  testWidgets('NextDoseRow does not overflow at small width', (
    WidgetTester tester,
  ) async {
    final schedule = Schedule(
      id: 's1',
      name: 'Very long schedule name that should not matter',
      medicationName: 'Med',
      doseValue: 1.0,
      doseUnit: 'tab',
      minutesOfDay: 8 * 60,
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
      active: true,
    );

    final nextDose = DateTime.now().add(const Duration(days: 7, hours: 3));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: NextDoseRow(
                schedule: schedule,
                nextDose: nextDose,
                dense: true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('NextDoseRow shows secondary paused line without overflow', (
    WidgetTester tester,
  ) async {
    final schedule = Schedule(
      id: 's2',
      name: 'Paused schedule',
      medicationName: 'Med',
      doseValue: 1.0,
      doseUnit: 'tab',
      minutesOfDay: 8 * 60,
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
      active: false,
      pausedUntil: DateTime.now().add(const Duration(days: 2, hours: 5)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: NextDoseRow(
                schedule: schedule,
                nextDose: DateTime.now().add(const Duration(days: 1)),
                dense: true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Next dose'), findsOneWidget);
    expect(find.textContaining('Paused until'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
