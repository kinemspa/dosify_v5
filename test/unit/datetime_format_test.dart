// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/core/utils/datetime_format_settings.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';

void main() {
  group('DateTimeFormatSettings', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('default values are system formats', () {
      expect(DateTimeFormatSettings.value.value.timeFormat, TimeFormat.system);
      expect(DateTimeFormatSettings.value.value.dateFormat, DateFormat.system);
    });

    test('loads saved time format preference', () async {
      SharedPreferences.setMockInitialValues({
        'datetime_format.time_format_v1': TimeFormat.hour24.index,
      });

      await DateTimeFormatSettings.load();

      expect(
        DateTimeFormatSettings.value.value.timeFormat,
        TimeFormat.hour24,
      );
    });

    test('loads saved date format preference', () async {
      SharedPreferences.setMockInitialValues({
        'datetime_format.date_format_v1': DateFormat.ymd.index,
      });

      await DateTimeFormatSettings.load();

      expect(
        DateTimeFormatSettings.value.value.dateFormat,
        DateFormat.ymd,
      );
    });

    test('setTimeFormat updates value and persists', () async {
      await DateTimeFormatSettings.setTimeFormat(TimeFormat.hour12);

      expect(
        DateTimeFormatSettings.value.value.timeFormat,
        TimeFormat.hour12,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt('datetime_format.time_format_v1'),
        TimeFormat.hour12.index,
      );
    });

    test('setDateFormat updates value and persists', () async {
      await DateTimeFormatSettings.setDateFormat(DateFormat.dmy);

      expect(
        DateTimeFormatSettings.value.value.dateFormat,
        DateFormat.dmy,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt('datetime_format.date_format_v1'),
        DateFormat.dmy.index,
      );
    });

    test('handles invalid stored values gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'datetime_format.time_format_v1': 999,
        'datetime_format.date_format_v1': -1,
      });

      await DateTimeFormatSettings.load();

      // Should fall back to system defaults
      expect(
        DateTimeFormatSettings.value.value.timeFormat,
        TimeFormat.system,
      );
      expect(
        DateTimeFormatSettings.value.value.dateFormat,
        DateFormat.system,
      );
    });
  });

  group('DateTimeFormatter', () {
    late DateTime testDateTime;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // January 15, 2024, 3:45 PM
      testDateTime = DateTime(2024, 1, 15, 15, 45);
    });

    testWidgets('formatTime with 12-hour format', (tester) async {
      await DateTimeFormatSettings.setTimeFormat(TimeFormat.hour12);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final formatted =
                  DateTimeFormatter.formatTime(context, testDateTime);
              return Text(formatted);
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('3:45 PM'), findsOneWidget);
    });

    testWidgets('formatTime with 24-hour format', (tester) async {
      await DateTimeFormatSettings.setTimeFormat(TimeFormat.hour24);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final formatted =
                  DateTimeFormatter.formatTime(context, testDateTime);
              return Text(formatted);
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('15:45'), findsOneWidget);
    });

    test('formatDate with MDY format', () async {
      await DateTimeFormatSettings.setDateFormat(DateFormat.mdy);
      final formatted = DateTimeFormatter.formatDate(testDateTime);
      expect(formatted, '01/15/2024');
    });

    test('formatDate with DMY format', () async {
      await DateTimeFormatSettings.setDateFormat(DateFormat.dmy);
      final formatted = DateTimeFormatter.formatDate(testDateTime);
      expect(formatted, '15/01/2024');
    });

    test('formatDate with YMD format', () async {
      await DateTimeFormatSettings.setDateFormat(DateFormat.ymd);
      final formatted = DateTimeFormatter.formatDate(testDateTime);
      expect(formatted, '2024-01-15');
    });

    test('formatDateShort with MDY format', () async {
      await DateTimeFormatSettings.setDateFormat(DateFormat.mdy);
      final formatted = DateTimeFormatter.formatDateShort(testDateTime);
      expect(formatted, '01/15');
    });

    test('formatDateShort with DMY format', () async {
      await DateTimeFormatSettings.setDateFormat(DateFormat.dmy);
      final formatted = DateTimeFormatter.formatDateShort(testDateTime);
      expect(formatted, '15/01');
    });

    test('formatDay returns day number', () {
      final formatted = DateTimeFormatter.formatDay(testDateTime);
      expect(formatted, '15');
    });

    test('formatMonthAbbr returns uppercase month', () {
      final formatted = DateTimeFormatter.formatMonthAbbr(testDateTime);
      expect(formatted, 'JAN');
    });

    test('formatMonthName returns full month name', () {
      final formatted = DateTimeFormatter.formatMonthName(testDateTime);
      expect(formatted, 'January');
    });

    test('formatYear returns year', () {
      final formatted = DateTimeFormatter.formatYear(testDateTime);
      expect(formatted, '2024');
    });

    test('formatDateLong returns long format', () {
      final formatted = DateTimeFormatter.formatDateLong(testDateTime);
      expect(formatted, 'January 15, 2024');
    });

    testWidgets('formatDateTime combines date and time', (tester) async {
      await DateTimeFormatSettings.setDateFormat(DateFormat.mdy);
      await DateTimeFormatSettings.setTimeFormat(TimeFormat.hour12);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final formatted =
                  DateTimeFormatter.formatDateTime(context, testDateTime);
              return Text(formatted);
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('01/15/2024 3:45 PM'), findsOneWidget);
    });

    test('formatters work across different locales', () async {
      // Test with a date that could be ambiguous (e.g., 3/4/2024)
      final ambiguousDate = DateTime(2024, 3, 4);

      await DateTimeFormatSettings.setDateFormat(DateFormat.mdy);
      expect(DateTimeFormatter.formatDate(ambiguousDate), '03/04/2024');

      await DateTimeFormatSettings.setDateFormat(DateFormat.dmy);
      expect(DateTimeFormatter.formatDate(ambiguousDate), '04/03/2024');

      await DateTimeFormatSettings.setDateFormat(DateFormat.ymd);
      expect(DateTimeFormatter.formatDate(ambiguousDate), '2024-03-04');
    });

    test('formatters handle DST transitions', () async {
      // Test date during DST transition (US: March 10, 2024, 2:00 AM -> 3:00 AM)
      // This tests that formatting is stable across DST boundaries
      await DateTimeFormatSettings.setTimeFormat(TimeFormat.hour12);

      // Before DST (2:30 AM on March 10, 2024)
      final beforeDst = DateTime(2024, 3, 10, 2, 30);
      // After DST (3:30 AM on March 10, 2024)
      final afterDst = DateTime(2024, 3, 10, 3, 30);

      // Both should format correctly regardless of DST
      expect(DateTimeFormatter.formatDay(beforeDst), '10');
      expect(DateTimeFormatter.formatDay(afterDst), '10');
      expect(DateTimeFormatter.formatMonthAbbr(beforeDst), 'MAR');
      expect(DateTimeFormatter.formatMonthAbbr(afterDst), 'MAR');
    });

    test('formatters are consistent for same moment across formats', () async {
      // Same moment should format consistently
      final moment = DateTime(2024, 12, 31, 23, 59);

      // Test all date formats produce valid output for same moment
      await DateTimeFormatSettings.setDateFormat(DateFormat.mdy);
      final mdy = DateTimeFormatter.formatDate(moment);

      await DateTimeFormatSettings.setDateFormat(DateFormat.dmy);
      final dmy = DateTimeFormatter.formatDate(moment);

      await DateTimeFormatSettings.setDateFormat(DateFormat.ymd);
      final ymd = DateTimeFormatter.formatDate(moment);

      // Different formats, but all should contain same date components
      expect(mdy, contains('2024'));
      expect(mdy, contains('12'));
      expect(mdy, contains('31'));

      expect(dmy, contains('2024'));
      expect(dmy, contains('12'));
      expect(dmy, contains('31'));

      expect(ymd, contains('2024'));
      expect(ymd, contains('12'));
      expect(ymd, contains('31'));
    });
  });
}
