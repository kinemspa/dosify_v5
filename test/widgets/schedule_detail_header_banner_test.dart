import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/schedule_detail_header_banner.dart';

ThemeData _testTheme() {
  const primarySeed = kDetailHeaderGradientStart;
  final scheme = ColorScheme.fromSeed(
    seedColor: primarySeed,
  ).copyWith(primary: primarySeed);

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}

Widget _wrapCompact(Widget child) {
  return MaterialApp(
    theme: _testTheme(),
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 320),
          child: Padding(
            padding: const EdgeInsets.all(kSpacingM),
            child: child,
          ),
        ),
      ),
    ),
  );
}

Future<List<FlutterErrorDetails>> _captureFlutterErrors(
  Future<void> Function() action,
) async {
  final errors = <FlutterErrorDetails>[];
  final oldHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details);
  };

  try {
    await action();
  } finally {
    FlutterError.onError = oldHandler;
  }
  return errors;
}

bool _isOverflowError(FlutterErrorDetails details) {
  final message = details.exceptionAsString();
  return message.contains('A RenderFlex overflowed') ||
      message.contains('overflowed by');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  testWidgets('ScheduleDetailHeaderBanner does not overflow at compact width', (
    WidgetTester tester,
  ) async {
    final schedule = Schedule(
      id: 's1',
      name: 'Very Long Schedule Name That Should Ellipsize Safely',
      medicationName: 'Medication Name That Is Also Quite Long',
      doseValue: 0.75,
      doseUnit: 'mL',
      minutesOfDay: 8 * 60 + 30,
      daysOfWeek: const [1, 3, 5],
    );

    final nextDose = DateTime.now().add(const Duration(hours: 2));

    final errors = await _captureFlutterErrors(() async {
      await tester.pumpWidget(
        _wrapCompact(
          ScheduleDetailHeaderBanner(
            schedule: schedule,
            nextDose: nextDose,
            title: schedule.name,
            onPauseResumePressed: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
    });

    final overflowErrors = errors.where(_isOverflowError);
    expect(overflowErrors, isEmpty);

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
  });

  testWidgets('ScheduleDetailHeaderBanner shows Resume when paused', (
    WidgetTester tester,
  ) async {
    final schedule = Schedule(
      id: 's2',
      name: 'Paused Schedule',
      medicationName: 'Test Medication',
      doseValue: 1,
      doseUnit: 'tablet',
      minutesOfDay: 9 * 60,
      daysOfWeek: const [2, 4, 6],
      active: false,
      pausedUntil: DateTime.now().add(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      _wrapCompact(
        ScheduleDetailHeaderBanner(
          schedule: schedule,
          nextDose: null,
          title: schedule.name,
          onPauseResumePressed: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
  });
}
