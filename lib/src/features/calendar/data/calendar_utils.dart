import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../schedules/domain/schedule.dart';
import 'calendar_event.dart';

class CalendarUtils {
  static List<CalendarEvent> eventsForMonth(
    DateTime monthLocal,
    Box<Schedule> box,
  ) {
    // monthLocal is any date in the month (local)
    final year = monthLocal.year;
    final month = monthLocal.month;
    final firstLocal = DateTime(year, month, 1);
    final lastLocal = DateTime(year, month + 1, 0);
    return _eventsForRange(firstLocal, lastLocal, box);
  }

  static List<CalendarEvent> eventsForWeek(
    DateTime weekStartLocal,
    Box<Schedule> box,
  ) {
    final start = DateTime(
      weekStartLocal.year,
      weekStartLocal.month,
      weekStartLocal.day,
    );
    final end = start.add(const Duration(days: 6));
    return _eventsForRange(start, end, box);
  }

  static List<CalendarEvent> eventsForDay(
    DateTime dayLocal,
    Box<Schedule> box,
  ) {
    final start = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final end = start;
    return _eventsForRange(start, end, box);
  }

  static List<CalendarEvent> _eventsForRange(
    DateTime startLocal,
    DateTime endLocal,
    Box<Schedule> box,
  ) {
    final List<CalendarEvent> out = [];
    final schedules = box.values.where((s) => s.active).toList(growable: false);

    for (
      DateTime d = startLocal;
      !d.isAfter(endLocal);
      d = d.add(const Duration(days: 1))
    ) {
      final dUtcMidnight = DateTime(d.year, d.month, d.day).toUtc();
      final utcWeekday = dUtcMidnight.weekday; // 1..7 UTC weekday
      for (final s in schedules) {
        int minutesUtc;
        List<int> daysUtc;
        if (s.hasUtc) {
          minutesUtc = s.minutesOfDayUtc!;
          daysUtc = s.daysOfWeekUtc!;
        } else {
          // Legacy fields in local. Convert local schedule to UTC-based weekday/time for this day.
          minutesUtc = _toUtcMinutesForLocalDay(s.minutesOfDay, d);
          final localWeekday = d.weekday;
          daysUtc = [_localWeekdayToUtcWeekday(localWeekday, s.minutesOfDay)];
        }
        if (daysUtc.contains(utcWeekday)) {
          final hUtc = minutesUtc ~/ 60;
          final mUtc = minutesUtc % 60;
          final eventUtc = DateTime.utc(
            dUtcMidnight.year,
            dUtcMidnight.month,
            dUtcMidnight.day,
            hUtc,
            mUtc,
          );
          final whenLocal = eventUtc.toLocal();
          out.add(
            CalendarEvent(
              scheduleId: s.id,
              title: _titleFor(s),
              when: whenLocal,
            ),
          );
        }
      }
    }
    out.sort((a, b) => a.when.compareTo(b.when));
    return out;
  }

  static String _titleFor(Schedule s) {
    final unit = s.doseUnit;
    final v = NumberFormat('0.##').format(s.doseValue);
    return '${s.name} — $v $unit';
  }

  static int _toUtcMinutesForLocalDay(int localMinutes, DateTime localDay) {
    final local = DateTime(
      localDay.year,
      localDay.month,
      localDay.day,
      localMinutes ~/ 60,
      localMinutes % 60,
    );
    final utc = local.toUtc();
    return utc.hour * 60 + utc.minute;
  }

  static int _localWeekdayToUtcWeekday(int localWeekday, int localMinutes) {
    // Determine UTC weekday for an event that occurs at localMinutes on a day with localWeekday
    final now = DateTime.now();
    final sampleLocal = DateTime(
      now.year,
      now.month,
      now.day + ((localWeekday - now.weekday) % 7),
      localMinutes ~/ 60,
      localMinutes % 60,
    );
    return sampleLocal.toUtc().weekday;
  }
}
