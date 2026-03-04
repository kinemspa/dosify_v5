@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/widgets/calendar/calendar_header.dart';
import 'package:skedux/src/widgets/calendar/entry_calendar_widget.dart';

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

Widget _wrapForGolden(Widget child) {
	return MaterialApp(
		theme: _goldenTheme(),
		home: Scaffold(
			body: Center(
				child: RepaintBoundary(
					key: const ValueKey<String>('golden'),
					child: SizedBox(
						width: 320,
						height: 720,
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

void main() {
	TestWidgetsFlutterBinding.ensureInitialized();

	Directory? hiveDir;

	setUpAll(() async {
		Intl.defaultLocale = 'en_US';

		hiveDir = await Directory.systemTemp.createTemp('dosifi_hive_calendar_');
		Hive.init(hiveDir!.path);

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
		if (!Hive.isAdapterRegistered(EntryLogAdapter().typeId)) {
			Hive.registerAdapter(EntryLogAdapter());
		}
		if (!Hive.isAdapterRegistered(EntryActionAdapter().typeId)) {
			Hive.registerAdapter(EntryActionAdapter());
		}

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

	group('EntryCalendarWidget goldens (compact)', () {
		testWidgets('month view', (tester) async {
			await tester.binding.setSurfaceSize(const Size(320, 720));
			addTearDown(() => tester.binding.setSurfaceSize(null));

			await tester.pumpWidget(
				_wrapForGolden(
					EntryCalendarWidget(
						variant: CalendarVariant.full,
						defaultView: CalendarView.month,
						startDate: DateTime(2026, 2, 1),
						showSelectedDayPanel: false,
						showUpNextCard: false,
						requireHourSelectionInDayView: false,
						embedInParentCard: true,
					),
				),
			);

			await tester.pumpAndSettle();

			await expectLater(
				find.byKey(const ValueKey<String>('golden')),
				matchesGoldenFile('goldens/entry_calendar_month_compact.png'),
			);
		});

		testWidgets('week view', (tester) async {
			await tester.binding.setSurfaceSize(const Size(320, 720));
			addTearDown(() => tester.binding.setSurfaceSize(null));

			await tester.pumpWidget(
				_wrapForGolden(
					EntryCalendarWidget(
						variant: CalendarVariant.full,
						defaultView: CalendarView.week,
						startDate: DateTime(2026, 2, 1),
						showSelectedDayPanel: false,
						showUpNextCard: false,
						requireHourSelectionInDayView: false,
						embedInParentCard: true,
					),
				),
			);

			await tester.pumpAndSettle();

			await expectLater(
				find.byKey(const ValueKey<String>('golden')),
				matchesGoldenFile('goldens/entry_calendar_week_compact.png'),
			);
		});
	});
}