import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:skedux/src/app/app_navigator.dart';
import 'package:skedux/src/core/notifications/low_stock_notifier.dart';
import 'package:skedux/src/core/notifications/notification_service.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:skedux/src/features/schedules/data/entry_log_repository.dart';
import 'package:skedux/src/features/schedules/data/schedule_scheduler.dart';
import 'package:skedux/src/features/schedules/domain/calculated_entry.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/entry_log_ids.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';
import 'package:skedux/src/widgets/show_entry_action_sheet.dart';

class NotificationDeepLinkHandler {
  const NotificationDeepLinkHandler._();

  static NotificationResponse? _pending;

  static void handle(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctx = rootNavigatorKey.currentState?.overlay?.context;
      if (ctx == null) {
        _pending = response;
        return;
      }
      await _handleWithContext(ctx, response);
    });
  }

  static void flushPendingIfAny() {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    handle(pending);
  }

  static Future<void> _handleWithContext(
    BuildContext context,
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) return;

    // Best-effort: clear the tapped/acted notification so entry reminders do not
    // accumulate in the tray across days.
    final id = response.id;
    if (id != null) {
      try {
        await NotificationService.cancel(id);
      } catch (_) {
        // Best-effort only.
      }
    }

    if (payload.startsWith('low_stock:')) {
      final id = payload.substring('low_stock:'.length);
      if (id.isEmpty) return;
      context.go('/medications/$id');
      return;
    }

    if (payload.startsWith('supply_low_stock:')) {
      // Navigate to the Supplies page so the user can see and act on
      // the low-stock supply.
      context.go('/supplies');
      return;
    }

    if (payload.startsWith('entry:')) {
      final rest = payload.substring('entry:'.length);
      final parts = rest.split(':');
      if (parts.length != 2) return;
      final scheduleId = parts[0];
      final whenMs = int.tryParse(parts[1]);
      if (scheduleId.isEmpty || whenMs == null) return;

      await _openEntryActionSheet(
        context,
        scheduleId: scheduleId,
        scheduledTime: DateTime.fromMillisecondsSinceEpoch(whenMs),
        actionId: response.actionId,
      );
      return;
    }

    if (payload.startsWith('entry_group:')) {
      final groupKey = payload.substring('entry_group:'.length);
      if (groupKey.isEmpty) return;
      await _openEntryGroupPicker(context, groupKey: groupKey);
      return;
    }
  }

  static EntryStatus? _initialStatusForActionId(String? actionId) {
    switch (actionId) {
      case 'log':
        return EntryStatus.logged;
      case 'snooze':
        return EntryStatus.snoozed;
      case 'skip':
        return EntryStatus.skipped;
    }
    return null;
  }

  static EntryLog? _findExistingLog(
    Box<EntryLog> logBox, {
    required String scheduleId,
    required DateTime scheduledTime,
  }) {
    final baseId = EntryLogIds.occurrenceId(
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
    );
    return logBox.get(baseId) ?? logBox.get(EntryLogIds.legacySnoozeIdFromBase(baseId));
  }

  static Future<void> _openEntryActionSheet(
    BuildContext context, {
    required String scheduleId,
    required DateTime scheduledTime,
    required String? actionId,
  }) async {
    final scheduleBox = Hive.box<Schedule>('schedules');
    final schedule = scheduleBox.get(scheduleId);
    if (schedule == null) {
      context.go('/schedules');
      return;
    }

    final medBox = Hive.box<Medication>('medications');
    final medication = medBox.get(schedule.medicationId);
    if (medication == null) {
      context.go('/medications');
      return;
    }

    final logBox = Hive.box<EntryLog>('entry_logs');
    final existingLog = _findExistingLog(
      logBox,
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
    );

    final entry = CalculatedEntry(
      scheduleId: schedule.id,
      scheduleName: schedule.name,
      medicationName: medication.name,
      scheduledTime: scheduledTime,
      entryValue: schedule.entryValue,
      entryUnit: schedule.entryUnit,
      existingLog: existingLog,
    );

    // Quick-log: when the user taps "Log" on the notification and the entry
    // hasn't already been logged, write the log directly without opening the
    // action sheet.  Snooze/Skip still open the sheet so the user can choose
    // a time / confirm they want to skip.
    if (actionId == 'log' &&
        (existingLog == null || existingLog.action != EntryAction.logged)) {
      await _directLogEntry(
        context,
        schedule: schedule,
        medication: medication,
        entry: entry,
      );
      return;
    }

    final initialStatus = _initialStatusForActionId(actionId);

    // Ensure we are in the right tab first so bottom-nav is consistent.
    context.go('/');

    await showEntryActionSheetFromModels(
      context,
      entry: entry,
      schedule: schedule,
      medication: medication,
      initialStatus: initialStatus,
    );
  }

  /// Writes an entry log directly without showing the action sheet.
  ///
  /// Called when the user taps the "Log" button on a notification and the
  /// entry has not already been recorded.  Handles stock deduction and
  /// notification cancellation identically to the normal sheet save path.
  static Future<void> _directLogEntry(
    BuildContext context, {
    required Schedule schedule,
    required Medication medication,
    required CalculatedEntry entry,
  }) async {
    try {
      final logId = EntryLogIds.occurrenceId(
        scheduleId: entry.scheduleId,
        scheduledTime: entry.scheduledTime,
      );
      final log = EntryLog(
        id: logId,
        scheduleId: entry.scheduleId,
        scheduleName: entry.scheduleName,
        medicationId: medication.id,
        medicationName: medication.name,
        scheduledTime: entry.scheduledTime,
        actionTime: DateTime.now(),
        entryValue: entry.entryValue,
        entryUnit: entry.entryUnit,
        action: EntryAction.logged,
      );

      final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
      await repo.upsertOccurrence(log);

      // Cancel notification for this occurrence.
      try {
        await NotificationService.cancel(
          ScheduleScheduler.entryNotificationIdFor(
            entry.scheduleId,
            entry.scheduledTime,
          ),
        );
        for (final id in ScheduleScheduler.overdueNotificationIdsFor(
          entry.scheduleId,
          entry.scheduledTime,
        )) {
          await NotificationService.cancel(id);
        }
        await NotificationService.cancel(
          ScheduleScheduler.entrySummaryNotificationIdFor(
            entry.scheduledTime.toLocal(),
          ),
        );
      } catch (_) {}

      // Deduct stock.
      final medBox = Hive.box<Medication>('medications');
      final currentMed = medBox.get(medication.id);
      if (currentMed != null) {
        final delta = MedicationStockAdjustment.tryCalculateStockDelta(
          medication: currentMed,
          schedule: schedule,
          entryValue: entry.entryValue,
          entryUnit: entry.entryUnit,
          preferEntryValue: false,
        );
        if (delta != null) {
          final updated = MedicationStockAdjustment.deduct(
            medication: currentMed,
            delta: delta,
          );
          await medBox.put(currentMed.id, updated);
          await LowStockNotifier.handleStockChange(
            before: currentMed,
            after: updated,
          );
        }
      }

      if (context.mounted) {
        showAppSnackBar(context, '${medication.name} — entry logged');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Quick log failed: $e');
      }
    }
  }

  static DateTime? _parseGroupKeyToLocalDateTime(String groupKey) {
    // Expected: upcoming_entry|yyyymmdd|hhmm
    final parts = groupKey.split('|');
    if (parts.length != 3) return null;
    if (parts[0] != 'upcoming_entry') return null;

    final ymd = parts[1];
    final hm = parts[2];
    if (ymd.length != 8 || hm.length != 4) return null;

    final year = int.tryParse(ymd.substring(0, 4));
    final month = int.tryParse(ymd.substring(4, 6));
    final day = int.tryParse(ymd.substring(6, 8));
    final hour = int.tryParse(hm.substring(0, 2));
    final minute = int.tryParse(hm.substring(2, 4));
    if ([year, month, day, hour, minute].any((v) => v == null)) return null;

    return DateTime(year!, month!, day!, hour!, minute!);
  }

  static bool _scheduleMatchesLocalMinute(Schedule schedule, DateTime localDt) {
    if (!schedule.isActive) return false;

    // Cycle schedules
    if (schedule.hasCycle && schedule.cycleEveryNDays != null) {
      final n = schedule.cycleEveryNDays!.clamp(1, 365);
      final anchor = schedule.cycleAnchorDate ?? DateTime.now();
      final anchorDate = DateTime(anchor.year, anchor.month, anchor.day);
      final targetDate = DateTime(localDt.year, localDt.month, localDt.day);
      final diff = targetDate.difference(anchorDate).inDays;
      if (diff < 0 || diff % n != 0) return false;

      final times = schedule.timesOfDay ?? [schedule.minutesOfDay];
      final minutes = localDt.hour * 60 + localDt.minute;
      return times.contains(minutes);
    }

    // Monthly schedules
    if (schedule.hasDaysOfMonth) {
      // Keep it simple: match only the explicit day and local minute.
      final days = schedule.daysOfMonth ?? const <int>[];
      if (!days.contains(localDt.day)) return false;
      final times = schedule.timesOfDay ?? [schedule.minutesOfDay];
      final minutes = localDt.hour * 60 + localDt.minute;
      return times.contains(minutes);
    }

    // Weekly schedules
    if (schedule.hasUtc) {
      final utc = localDt.toUtc();
      final daysUtc = schedule.daysOfWeekUtc ?? const <int>[];
      final timesUtc =
          schedule.timesOfDayUtc ??
          [schedule.minutesOfDayUtc ?? schedule.minutesOfDay];
      final utcMinutes = utc.hour * 60 + utc.minute;
      return daysUtc.contains(utc.weekday) && timesUtc.contains(utcMinutes);
    }

    final daysLocal = schedule.daysOfWeek;
    final timesLocal = schedule.timesOfDay ?? [schedule.minutesOfDay];
    final minutesLocal = localDt.hour * 60 + localDt.minute;
    return daysLocal.contains(localDt.weekday) &&
        timesLocal.contains(minutesLocal);
  }

  static Future<void> _openEntryGroupPicker(
    BuildContext context, {
    required String groupKey,
  }) async {
    final dt = _parseGroupKeyToLocalDateTime(groupKey);
    if (dt == null) return;

    final scheduleBox = Hive.box<Schedule>('schedules');
    final medBox = Hive.box<Medication>('medications');
    final logBox = Hive.box<EntryLog>('entry_logs');

    final entries =
        <({CalculatedEntry entry, Schedule schedule, Medication med})>[];

    for (final schedule in scheduleBox.values) {
      if (!_scheduleMatchesLocalMinute(schedule, dt)) continue;
      final medication = medBox.get(schedule.medicationId);
      if (medication == null) continue;

      final existingLog = _findExistingLog(
        logBox,
        scheduleId: schedule.id,
        scheduledTime: dt,
      );

      entries.add((
        entry: CalculatedEntry(
          scheduleId: schedule.id,
          scheduleName: schedule.name,
          medicationName: medication.name,
          scheduledTime: dt,
          entryValue: schedule.entryValue,
          entryUnit: schedule.entryUnit,
          existingLog: existingLog,
        ),
        schedule: schedule,
        med: medication,
      ));
    }

    if (entries.isEmpty) {
      context.go('/schedules');
      return;
    }

    // Ensure we are in the right tab first so bottom-nav is consistent.
    context.go('/');

    if (entries.length == 1) {
      final e = entries.single;
      await showEntryActionSheetFromModels(
        context,
        entry: e.entry,
        schedule: e.schedule,
        medication: e.med,
      );
      return;
    }

    entries.sort((a, b) {
      final byTime = a.entry.scheduledTime.compareTo(b.entry.scheduledTime);
      if (byTime != 0) return byTime;
      return a.entry.scheduleName.compareTo(b.entry.scheduleName);
    });

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Upcoming entries'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = entries[index];
                return ListTile(
                  title: Text(e.entry.scheduleName),
                  subtitle: Text(e.med.name),
                  onTap: () async {
                    Navigator.of(dialogContext).pop();
                    await showEntryActionSheetFromModels(
                      context,
                      entry: e.entry,
                      schedule: e.schedule,
                      medication: e.med,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
