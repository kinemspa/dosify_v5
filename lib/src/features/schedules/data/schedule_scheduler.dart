// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

class ScheduleScheduler {
  /// Maximum alarms we'll use across ALL schedules to stay well under Android's 500 limit.
  /// Leaves room for other apps and system alarms.
  static const int _maxGlobalAlarms = 400;

  /// Minimum days to schedule ahead for each schedule (ensures near-term coverage).
  static const int _minDaysPerSchedule = 3;

  /// Maximum days to schedule ahead when budget allows.
  static const int _maxDaysPerSchedule = 7;

  /// Estimates how many alarms would be needed for a schedule over N days.
  static int _estimateAlarmCount(Schedule s, int days) {
    final timesPerDay = (s.timesOfDay ?? [s.minutesOfDay]).length;
    if (s.hasCycle) {
      final cycleLength = s.cycleEveryNDays!.clamp(1, 365);
      final occurrencesInPeriod = (days / cycleLength).ceil();
      return occurrencesInPeriod * timesPerDay;
    } else {
      // Weekly pattern - count matching days in period
      final daysOfWeek = s.daysOfWeek;
      var matchingDays = 0;
      for (var i = 0; i < days; i++) {
        final weekday = (DateTime.now().weekday + i - 1) % 7 + 1;
        if (daysOfWeek.contains(weekday)) matchingDays++;
      }
      return matchingDays * timesPerDay;
    }
  }

  /// Calculates how many days to schedule for this schedule based on global budget.
  static Future<int> _calculateScheduleDays(Schedule s) async {
    final box = Hive.box<Schedule>('schedules');
    final allActive = box.values.where((sch) => sch.active).toList();

    // Calculate total alarms needed if we schedule _minDaysPerSchedule for all
    var totalNeeded = 0;
    for (final schedule in allActive) {
      totalNeeded += _estimateAlarmCount(schedule, _minDaysPerSchedule);
    }

    print(
      '[ScheduleScheduler] Active schedules: ${allActive.length}, '
      'Min alarms needed: $totalNeeded / $_maxGlobalAlarms',
    );

    if (totalNeeded > _maxGlobalAlarms) {
      // Critical: Can't even schedule minimum. Return minimum anyway and warn.
      print(
        '[ScheduleScheduler] WARNING: Too many schedules! '
        'Exceeding alarm budget. Some notifications may be missed.',
      );
      return _minDaysPerSchedule;
    }

    // We have budget. Try to schedule more days.
    final remainingBudget = _maxGlobalAlarms - totalNeeded;
    final additionalDays =
        remainingBudget ~/ (allActive.length * 2); // Conservative estimate
    final targetDays = (_minDaysPerSchedule + additionalDays).clamp(
      _minDaysPerSchedule,
      _maxDaysPerSchedule,
    );

    print(
      '[ScheduleScheduler] Scheduling $targetDays days ahead for "${s.name}"',
    );

    return targetDays;
  }

  static int _stableHash32(String s) {
    // Deterministic 32-bit FNV-1a hash
    const fnvOffset = 0x811C9DC5;
    const fnvPrime = 0x01000193;
    var hash = fnvOffset;
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
  static int _slotId(
    String scheduleId, {
    required int weekday,
    required int minutes,
    int occurrence = 0,
  }) {
    final key = '$scheduleId|w:$weekday|m:$minutes|o:$occurrence';
    return _stableHash32(key);
  }

  // Public wrapper for generating slot ids; used by UI and other helpers.
  static int slotIdFor(
    String scheduleId, {
    required int weekday,
    required int minutes,
    int occurrence = 0,
  }) {
    return _slotId(
      scheduleId,
      weekday: weekday,
      minutes: minutes,
      occurrence: occurrence,
    );
  }

  static Future<void> scheduleFor(Schedule s) async {
    if (!s.active) return;
    final title = s.name;
    final body = '${s.medicationName} • ${s.doseValue} ${s.doseUnit}';

    // Calculate how many days we can afford to schedule for this schedule
    final daysToSchedule = await _calculateScheduleDays(s);

    // If cycle is enabled, schedule next N occurrences based on anchor
    if (s.hasCycle) {
      final n = s.cycleEveryNDays!.clamp(1, 365);
      final anchor = s.cycleAnchorDate ?? DateTime.now();
      final times = s.timesOfDay ?? [s.minutesOfDay];
      final now = DateTime.now();
      var day = DateTime(anchor.year, anchor.month, anchor.day);
      // Advance to today or next cycle day
      while (day.isBefore(DateTime(now.year, now.month, now.day))) {
        day = day.add(Duration(days: n));
      }

      // Schedule for calculated number of occurrences
      final occurrences = (daysToSchedule / n).ceil().clamp(1, 14);
      for (var i = 0; i < occurrences; i++) {
        for (final minutes in times) {
          final dt = DateTime(
            day.year,
            day.month,
            day.day,
            minutes ~/ 60,
            minutes % 60,
          );
          final id = _slotId(
            s.id,
            weekday: dt.weekday,
            minutes: minutes,
            occurrence: i,
          );
          await NotificationService.scheduleAtAlarmClock(
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
    // Schedule one-shot alarms for the next N days (dynamically calculated).
    final useUtc = s.hasUtc;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final timesLocal = s.timesOfDay ?? [s.minutesOfDay];
    final timesUtc = s.timesOfDayUtc ?? [s.minutesOfDayUtc ?? s.minutesOfDay];
    final daysLocal = s.daysOfWeek;
    final daysUtc = s.daysOfWeekUtc ?? const <int>[];

    for (var dayOffset = 0; dayOffset < daysToSchedule; dayOffset++) {
      final date = start.add(Duration(days: dayOffset));
      if (useUtc) {
        // Check UTC weekday against daysOfWeekUtc using the UTC date
        final utcWeekday = date.toUtc().weekday; // 1..7
        if (daysUtc.contains(utcWeekday)) {
          for (final mUtc in timesUtc) {
            final dtUtc = DateTime.utc(
              date.year,
              date.month,
              date.day,
              mUtc ~/ 60,
              mUtc % 60,
            );
            final dtLocal = dtUtc.toLocal();
            if (dtLocal.isAfter(now)) {
              final id = _slotId(
                s.id,
                weekday: date.weekday,
                minutes: mUtc,
                occurrence: dayOffset,
              );
              await NotificationService.scheduleAtAlarmClock(
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
            final dt = DateTime(
              date.year,
              date.month,
              date.day,
              mLocal ~/ 60,
              mLocal % 60,
            );
            if (dt.isAfter(now)) {
              final id = _slotId(
                s.id,
                weekday: date.weekday,
                minutes: mLocal,
                occurrence: dayOffset,
              );
              await NotificationService.scheduleAtAlarmClock(
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

  static Future<void> cancelFor(
    String scheduleId, {
    Iterable<int>? days,
  }) async {
    // Best-effort cancel that supports both legacy and new ID schemes without exceeding 32-bit range.
    final box = Hive.box<Schedule>('schedules');
    final existing = box.get(scheduleId); // may be null for brand-new schedules

    // 1) New scheme: cancel _slotId-based notifications for known days/times
    if (existing != null) {
      if (existing.hasCycle) {
        final n = existing.cycleEveryNDays!.clamp(1, 365);
        final anchor = existing.cycleAnchorDate ?? DateTime.now();
        final times = existing.timesOfDay ?? [existing.minutesOfDay];
        var day = DateTime(anchor.year, anchor.month, anchor.day);
        // Cancel up to max possible occurrences (conservative)
        for (var i = 0; i < 20; i++) {
          for (final minutes in times) {
            final dt = DateTime(
              day.year,
              day.month,
              day.day,
              minutes ~/ 60,
              minutes % 60,
            );
            final id = _slotId(
              existing.id,
              weekday: dt.weekday,
              minutes: minutes,
              occurrence: i,
            );
            await NotificationService.cancel(id);
          }
          day = day.add(Duration(days: n));
        }
      } else {
        // Cancel next ~60 days of one-shot weekly occurrences
        final useUtc = existing.hasUtc;
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final timesLocal = existing.timesOfDay ?? [existing.minutesOfDay];
        final timesUtc =
            existing.timesOfDayUtc ??
            [existing.minutesOfDayUtc ?? existing.minutesOfDay];
        final daysLocal = existing.daysOfWeek;
        final daysUtc = existing.daysOfWeekUtc ?? const <int>[];
        // Cancel up to max possible days (conservative)
        for (var dayOffset = 0; dayOffset < 20; dayOffset++) {
          final date = start.add(Duration(days: dayOffset));
          if (useUtc) {
            final utcWeekday = date.toUtc().weekday;
            if (daysUtc.contains(utcWeekday)) {
              for (final mUtc in timesUtc) {
                final id = _slotId(
                  existing.id,
                  weekday: date.weekday,
                  minutes: mUtc,
                  occurrence: dayOffset,
                );
                await NotificationService.cancel(id);
              }
            }
          } else {
            if (daysLocal.contains(date.weekday)) {
              for (final mLocal in timesLocal) {
                final id = _slotId(
                  existing.id,
                  weekday: date.weekday,
                  minutes: mLocal,
                  occurrence: dayOffset,
                );
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

  /// Reschedules all active schedules. Called on app startup.
  /// This keeps the 14-day notification window filled.
  /// Safe to call repeatedly - will cancel and reschedule to ensure consistency.
  static Future<void> rescheduleAllActive() async {
    final box = Hive.box<Schedule>('schedules');
    for (final s in box.values) {
      if (s.active) {
        // Cancel existing notifications and reschedule fresh
        await cancelFor(s.id, days: s.daysOfWeek);
        await scheduleFor(s);
      }
    }
  }
}
