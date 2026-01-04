// Package imports:
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

/// Schedules notifications for registered [Schedule] entries and exposes helpers
/// for deterministic stable slot ID generation used across the app.
class ScheduleScheduler {
  static const String _lastStartupRescheduleMsKey =
      'schedule_scheduler.last_startup_reschedule_ms';

  static Future<void> _resumePausedSchedulesIfDue() async {
    final box = Hive.box<Schedule>('schedules');
    final now = DateTime.now();
    final due = box.values
        .where(
          (s) =>
              !s.active &&
              s.pausedUntil != null &&
              !s.pausedUntil!.isAfter(now),
        )
        .toList();

    for (final s in due) {
      final updated = s.copyWith(active: true, pausedUntil: null);
      await box.put(s.id, updated);
    }
  }

  static bool _withinBounds(Schedule s, DateTime dt) {
    final startAt = s.startAt;
    if (startAt != null && dt.isBefore(startAt)) return false;
    final endAt = s.endAt;
    if (endAt != null && dt.isAfter(endAt)) return false;
    return true;
  }

  /// Maximum alarms we'll use across ALL schedules to stay well under Android's 500 limit.
  static const int _maxGlobalAlarms = 400;

  /// Minimum days to schedule ahead for each schedule (ensures near-term coverage).
  static const int _minDaysPerSchedule = 3;

  /// Maximum days to schedule ahead when budget allows.
  static const int _maxDaysPerSchedule = 7;

  /// Public API: deterministic stable scheduling slot id used by UI and scheduler
  /// to refer to a single scheduled notification occurrence.
  static int slotIdFor(
    String scheduleId, {
    required int weekday,
    required int minutes,
    int occurrence = 0,
  }) {
    final key = '$scheduleId|w:$weekday|m:$minutes|o:$occurrence';
    return _stableHash31(key);
  }

  /// Public API: legacy id for day-based notification cancellation (safe within 32-bit)
  static int idForDay(String scheduleId, int weekday) {
    final key = '$scheduleId|d:$weekday';
    return _stableHash31(key);
  }

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

    if (totalNeeded > _maxGlobalAlarms) {
      // Critical: Can't even schedule minimum. Return minimum anyway and warn.
      print(
        '[ScheduleScheduler] WARNING: Too many schedules! Exceeding alarm budget.',
      );
      return _minDaysPerSchedule;
    }

    // Otherwise scale up to fit within the budget up to _maxDaysPerSchedule
    var budgetLeft = _maxGlobalAlarms - totalNeeded;
    var additionalDays = 0; // per-schedule additional days
    // Keep scaling additional days until budget runs out or we hit cap
    while (additionalDays < (_maxDaysPerSchedule - _minDaysPerSchedule)) {
      // Count the incremental cost of adding 1 day across all schedules
      var incremental = 0;
      for (final schedule in allActive) {
        incremental += _estimateAlarmCount(schedule, 1);
      }
      if (incremental <= budgetLeft) {
        budgetLeft -= incremental;
        additionalDays++;
      } else {
        break;
      }
    }
    return (_minDaysPerSchedule + additionalDays).clamp(
      _minDaysPerSchedule,
      _maxDaysPerSchedule,
    );
  }

  /// Schedules upcoming alarms for the given schedule (best-effort)
  static Future<void> scheduleFor(Schedule s) async {
    if (!s.active) return;
    final title = s.name;
    final body = '${s.medicationName} • ${s.doseValue} ${s.doseUnit}';

    // Calculate how many days we can afford to schedule for this schedule
    final daysToSchedule = await _calculateScheduleDays(s);

    // If cycle is enabled, schedule next occurrences based on anchor
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
          if (!dt.isAfter(now)) continue;
          if (!_withinBounds(s, dt)) continue;
          final id = slotIdFor(
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

    // Otherwise weekly pattern with optional UTC handling
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
            if (dtLocal.isAfter(now) && _withinBounds(s, dtLocal)) {
              final id = slotIdFor(
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
        if (daysLocal.contains(date.weekday)) {
          for (final mLocal in timesLocal) {
            final dt = DateTime(
              date.year,
              date.month,
              date.day,
              mLocal ~/ 60,
              mLocal % 60,
            );
            if (dt.isAfter(now) && _withinBounds(s, dt)) {
              final id = slotIdFor(
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

  /// Cancel scheduled notifications for a schedule (best-effort)
  static Future<void> cancelFor(
    String scheduleId, {
    Iterable<int>? days,
  }) async {
    final box = Hive.box<Schedule>('schedules');
    final existing = box.get(scheduleId); // may be null for brand-new schedules
    if (existing != null) {
      if (existing.hasCycle) {
        final n = existing.cycleEveryNDays!.clamp(1, 365);
        final anchor = existing.cycleAnchorDate ?? DateTime.now();
        final times = existing.timesOfDay ?? [existing.minutesOfDay];
        var day = DateTime(anchor.year, anchor.month, anchor.day);
        for (var i = 0; i < 20; i++) {
          for (final minutes in times) {
            final dt = DateTime(
              day.year,
              day.month,
              day.day,
              minutes ~/ 60,
              minutes % 60,
            );
            final id = slotIdFor(
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
        final useUtc = existing.hasUtc;
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final timesLocal = existing.timesOfDay ?? [existing.minutesOfDay];
        final timesUtc =
            existing.timesOfDayUtc ??
            [existing.minutesOfDayUtc ?? existing.minutesOfDay];
        final daysLocal = existing.daysOfWeek;
        final daysUtc = existing.daysOfWeekUtc ?? const <int>[];
        for (var dayOffset = 0; dayOffset < 20; dayOffset++) {
          final date = start.add(Duration(days: dayOffset));
          if (useUtc) {
            final utcWeekday = date.toUtc().weekday;
            if (daysUtc.contains(utcWeekday)) {
              for (final mUtc in timesUtc) {
                final id = slotIdFor(
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
                final id = slotIdFor(
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
    final ds = days ?? List<int>.generate(7, (i) => i + 1);
    for (final d in ds) {
      final base = idForDay(scheduleId, d);
      await NotificationService.cancel(base);
    }
  }

  /// Reschedules all active schedules by canceling then re-scheduling.
  static Future<void> rescheduleAllActive() async {
    final box = Hive.box<Schedule>('schedules');
    for (final s in box.values) {
      if (s.active) {
        await cancelFor(s.id, days: s.daysOfWeek);
        await scheduleFor(s);
      }
    }
  }

  /// Startup-friendly reschedule that avoids doing heavy cancel/recreate work
  /// every single launch.
  static Future<void> rescheduleAllActiveIfStale({
    Duration minInterval = const Duration(hours: 12),
  }) async {
    // First, ensure any schedules whose pause window has passed are resumed.
    // This is done regardless of notification permission so the UI reflects
    // the correct state.
    await _resumePausedSchedulesIfDue();

    final schedulesBox = Hive.box<Schedule>('schedules');
    final activeCount = schedulesBox.values.where((s) => s.active).length;
    if (activeCount == 0) return;

    // Avoid any work if notifications can't be shown anyway.
    final enabled = await NotificationService.areNotificationsEnabled();
    if (!enabled) return;

    final permissionGranted = await NotificationService.isPermissionGranted();
    if (!permissionGranted) return;

    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastStartupRescheduleMsKey) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (lastMs > 0 && (nowMs - lastMs) < minInterval.inMilliseconds) {
      return;
    }

    await rescheduleAllActive();
    await prefs.setInt(_lastStartupRescheduleMsKey, nowMs);
  }

  /// Internal: stable hash 31-bit positive int (suitable for notification IDs)
  static int _stableHash31(String input) {
    // FNV-1a 32-bit hash then mask to 31 bits to ensure positive signed int range.
    const int fnvOffset = 2166136261;
    const int fnvPrime = 16777619;
    var hash = fnvOffset;
    for (var i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}

// Package imports:
