import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skedux/src/widgets/next_entry_row.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';

void main() {
  testWidgets('NextEntryRow does not overflow at small width', (
    WidgetTester tester,
  ) async {
    final schedule = Schedule(
      id: 's1',
      name: 'Very long schedule name that should not matter',
      medicationName: 'Med',
      entryValue: 1.0,
      entryUnit: 'tab',
      minutesOfDay: 8 * 60,
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
      active: true,
    );

    final nextEntry = DateTime.now().add(const Duration(days: 7, hours: 3));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: NextEntryRow(
                schedule: schedule,
                nextEntry: nextEntry,
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

  testWidgets('NextEntryRow shows secondary paused line without overflow', (
    WidgetTester tester,
  ) async {
    final schedule = Schedule(
      id: 's2',
      name: 'Paused schedule',
      medicationName: 'Med',
      entryValue: 1.0,
      entryUnit: 'tab',
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
              child: NextEntryRow(
                schedule: schedule,
                nextEntry: DateTime.now().add(const Duration(days: 1)),
                dense: true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Next entry'), findsOneWidget);
    expect(find.textContaining('Paused until'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
