import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:dosifi_v5/src/app/app_navigator.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/show_dose_action_sheet.dart';

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

    // Best-effort: clear the tapped/acted notification so dose reminders do not
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

    if (payload.startsWith('dose:')) {
      final rest = payload.substring('dose:'.length);
      final parts = rest.split(':');
      if (parts.length != 2) return;
      final scheduleId = parts[0];
      final whenMs = int.tryParse(parts[1]);
      if (scheduleId.isEmpty || whenMs == null) return;

      await _openDoseActionSheet(
        context,
        scheduleId: scheduleId,
        scheduledTime: DateTime.fromMillisecondsSinceEpoch(whenMs),
        actionId: response.actionId,
      );
      return;
    }

    if (payload.startsWith('dose_group:')) {
      final groupKey = payload.substring('dose_group:'.length);
      if (groupKey.isEmpty) return;
      await _openDoseGroupPicker(context, groupKey: groupKey);
      return;
    }
  }

  static DoseStatus? _initialStatusForActionId(String? actionId) {
    switch (actionId) {
      case 'take':
        return DoseStatus.taken;
      case 'snooze':
        return DoseStatus.snoozed;
      case 'skip':
        return DoseStatus.skipped;
    }
    return null;
  }

  static DoseLog? _findExistingLog(
    Box<DoseLog> logBox, {
    required String scheduleId,
    required DateTime scheduledTime,
  }) {
    final baseId = '${scheduleId}_${scheduledTime.millisecondsSinceEpoch}';
    return logBox.get(baseId) ?? logBox.get('${baseId}_snooze');
  }

  static Future<void> _openDoseActionSheet(
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

    final logBox = Hive.box<DoseLog>('dose_logs');
    final existingLog = _findExistingLog(
      logBox,
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
    );

    final dose = CalculatedDose(
      scheduleId: schedule.id,
      scheduleName: schedule.name,
      medicationName: medication.name,
      scheduledTime: scheduledTime,
      doseValue: schedule.doseValue,
      doseUnit: schedule.doseUnit,
      existingLog: existingLog,
    );

    final initialStatus = _initialStatusForActionId(actionId);

    // Ensure we are in the right tab first so bottom-nav is consistent.
    context.go('/');

    await showDoseActionSheetFromModels(
      context,
      dose: dose,
      schedule: schedule,
      medication: medication,
      initialStatus: initialStatus,
    );
  }

  static DateTime? _parseGroupKeyToLocalDateTime(String groupKey) {
    // Expected: upcoming_dose|yyyymmdd|hhmm
    final parts = groupKey.split('|');
    if (parts.length != 3) return null;
    if (parts[0] != 'upcoming_dose') return null;

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

  static Future<void> _openDoseGroupPicker(
    BuildContext context, {
    required String groupKey,
  }) async {
    final dt = _parseGroupKeyToLocalDateTime(groupKey);
    if (dt == null) return;

    final scheduleBox = Hive.box<Schedule>('schedules');
    final medBox = Hive.box<Medication>('medications');
    final logBox = Hive.box<DoseLog>('dose_logs');

    final entries =
        <({CalculatedDose dose, Schedule schedule, Medication med})>[];

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
        dose: CalculatedDose(
          scheduleId: schedule.id,
          scheduleName: schedule.name,
          medicationName: medication.name,
          scheduledTime: dt,
          doseValue: schedule.doseValue,
          doseUnit: schedule.doseUnit,
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
      await showDoseActionSheetFromModels(
        context,
        dose: e.dose,
        schedule: e.schedule,
        medication: e.med,
      );
      return;
    }

    entries.sort((a, b) {
      final byTime = a.dose.scheduledTime.compareTo(b.dose.scheduledTime);
      if (byTime != 0) return byTime;
      return a.dose.scheduleName.compareTo(b.dose.scheduleName);
    });

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Upcoming doses'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = entries[index];
                return ListTile(
                  title: Text(e.dose.scheduleName),
                  subtitle: Text(e.med.name),
                  onTap: () async {
                    Navigator.of(dialogContext).pop();
                    await showDoseActionSheetFromModels(
                      context,
                      dose: e.dose,
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
