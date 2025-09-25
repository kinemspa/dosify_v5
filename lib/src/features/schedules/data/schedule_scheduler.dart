import 'package:hive_flutter/hive_flutter.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/schedule.dart';

class ScheduleScheduler {
  static int _stableHash32(String s) {
    // Deterministic 32-bit FNV-1a hash
    const int fnvOffset = 0x811C9DC5;
    const int fnvPrime = 0x01000193;
    int hash = fnvOffset;
    for (final codeUnit in s.codeUnits) {
      hash ^= codeUnit & 0xFF;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF; // ensure positive 31-bit
  }

  static int _baseId(String scheduleId) {
    // Legacy base id retained for backwards compatibility with older IDs
    final h = _stableHash32(scheduleId) % 100000000; // up to 8 digits
    return h;
  }

  static int idForDay(String scheduleId, int weekday) {
    return _baseId(scheduleId) * 10 + weekday; // legacy day-based id
  }

  // New: stable 31-bit id for a specific slot combining scheduleId, weekday, minutes and optional occurrence
  static int _slotId(String scheduleId, {required int weekday, required int minutes, int occurrence = 0}) {
    final key = '$scheduleId|w:$weekday|m:$minutes|o:$occurrence';
    return _stableHash32(key);
  }

  static (int weekdayLocal, int minutesLocal) _utcToLocalSlot(int utcWeekday, int minutesOfDayUtc) {
    final nowUtc = tz.TZDateTime.now(tz.getLocation('UTC'));
    final hour = minutesOfDayUtc ~/ 60;
    final minute = minutesOfDayUtc % 60;
    var scheduledUtc = tz.TZDateTime(tz.getLocation('UTC'), nowUtc.year, nowUtc.month, nowUtc.day, hour, minute);
    final daysUntil = (utcWeekday - scheduledUtc.weekday) % 7;
    scheduledUtc = scheduledUtc.add(Duration(days: daysUntil));
    final local = tz.TZDateTime.from(scheduledUtc, tz.local);
    return (local.weekday, local.hour * 60 + local.minute);
  }

  static Future<void> scheduleFor(Schedule s) async {
    if (!s.active) return;
    final title = s.name;
    final body = '${s.medicationName} • ${s.doseValue} ${s.doseUnit}';

    // If cycle is enabled, schedule next N days occurrences based on anchor
    if (s.hasCycle) {
      final n = s.cycleEveryNDays!.clamp(1, 365);
      final anchor = s.cycleAnchorDate ?? DateTime.now();
      final times = (s.timesOfDay ?? [s.minutesOfDay]);
      // Schedule for the next ~30 occurrences
      final now = DateTime.now();
      var day = DateTime(anchor.year, anchor.month, anchor.day);
      // Advance to today or next cycle day
      while (day.isBefore(DateTime(now.year, now.month, now.day))) {
        day = day.add(Duration(days: n));
      }
      for (int i = 0; i < 30; i++) {
        for (final minutes in times) {
          final dt = DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
          final id = _slotId(s.id, weekday: dt.weekday, minutes: minutes, occurrence: i);
          await NotificationService.scheduleAt(
            id,
            dt,
            title: title,
            body: body,
          );
        }
        day = day.add(Duration(days: n));
      }
      return;
    }

    // Otherwise weekly pattern, supporting multiple times per day
    // Instead of weekly repeating alarms (which can be unreliable on some devices),
    // schedule one-shot alarms for the next 60 days.
    final useUtc = s.hasUtc;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final timesLocal = (s.timesOfDay ?? [s.minutesOfDay]);
    final timesUtc = (s.timesOfDayUtc ?? [s.minutesOfDayUtc ?? s.minutesOfDay]);
    final daysLocal = s.daysOfWeek;
    final daysUtc = s.daysOfWeekUtc ?? const <int>[];

    for (int dayOffset = 0; dayOffset < 60; dayOffset++) {
      final date = start.add(Duration(days: dayOffset));
      if (useUtc) {
        // Check UTC weekday against daysOfWeekUtc using the UTC date
        final utcWeekday = date.toUtc().weekday; // 1..7
        if (daysUtc.contains(utcWeekday)) {
          for (final mUtc in timesUtc) {
            final dtUtc = DateTime.utc(date.year, date.month, date.day, mUtc ~/ 60, mUtc % 60);
            final dtLocal = dtUtc.toLocal();
            if (dtLocal.isAfter(now)) {
              final id = _slotId(s.id, weekday: date.weekday, minutes: mUtc, occurrence: dayOffset);
              await NotificationService.scheduleAt(
                id,
                dtLocal,
                title: title,
                body: body,
              );
            }
          }
        }
      } else {
        // Local weekly pattern
        if (daysLocal.contains(date.weekday)) {
          for (final mLocal in timesLocal) {
            final dt = DateTime(date.year, date.month, date.day, mLocal ~/ 60, mLocal % 60);
            if (dt.isAfter(now)) {
              final id = _slotId(s.id, weekday: date.weekday, minutes: mLocal, occurrence: dayOffset);
              await NotificationService.scheduleAt(
                id,
                dt,
                title: title,
                body: body,
              );
            }
          }
        }
      }
    }
  }

  static Future<void> cancelFor(String scheduleId, {Iterable<int>? days}) async {
    // Best-effort cancel that supports both legacy and new ID schemes without exceeding 32-bit range.
    final box = Hive.box<Schedule>('schedules');
    final existing = box.get(scheduleId); // may be null for brand-new schedules

    // 1) New scheme: cancel _slotId-based notifications for known days/times
    if (existing != null) {
      if (existing.hasCycle) {
        final n = existing.cycleEveryNDays!.clamp(1, 365);
        final anchor = existing.cycleAnchorDate ?? DateTime.now();
        final times = (existing.timesOfDay ?? [existing.minutesOfDay]);
        var day = DateTime(anchor.year, anchor.month, anchor.day);
        // cancel ~30 occurrences ahead
        for (int i = 0; i < 30; i++) {
          for (final minutes in times) {
            final dt = DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
            final id = _slotId(existing.id, weekday: dt.weekday, minutes: minutes, occurrence: i);
            await NotificationService.cancel(id);
          }
          day = day.add(Duration(days: n));
        }
      } else {
        // Cancel next ~60 days of one-shot weekly occurrences
        final useUtc = existing.hasUtc;
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final timesLocal = (existing.timesOfDay ?? [existing.minutesOfDay]);
        final timesUtc = (existing.timesOfDayUtc ?? [existing.minutesOfDayUtc ?? existing.minutesOfDay]);
        final daysLocal = existing.daysOfWeek;
        final daysUtc = existing.daysOfWeekUtc ?? const <int>[];
        for (int dayOffset = 0; dayOffset < 60; dayOffset++) {
          final date = start.add(Duration(days: dayOffset));
          if (useUtc) {
            final utcWeekday = date.toUtc().weekday;
            if (daysUtc.contains(utcWeekday)) {
              for (final mUtc in timesUtc) {
                final id = _slotId(existing.id, weekday: date.weekday, minutes: mUtc, occurrence: dayOffset);
                await NotificationService.cancel(id);
              }
            }
          } else {
            if (daysLocal.contains(date.weekday)) {
              for (final mLocal in timesLocal) {
                final id = _slotId(existing.id, weekday: date.weekday, minutes: mLocal, occurrence: dayOffset);
                await NotificationService.cancel(id);
              }
            }
          }
        }
      }
    }

    // 2) Legacy scheme: cancel day-based ids (safe within 32-bit). Avoid base*100+minutes pattern (overflow risk).
    final ds = days ?? List<int>.generate(7, (i) => i + 1);
    for (final d in ds) {
      final base = idForDay(scheduleId, d);
      await NotificationService.cancel(base);
    }
  }

  static Future<void> rescheduleAllActive() async {
    final box = Hive.box<Schedule>('schedules');
    for (final s in box.values) {
      if (s.active) {
        await scheduleFor(s);
      }
    }
  }
}
