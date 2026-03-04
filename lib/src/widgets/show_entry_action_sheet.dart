import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:skedux/src/core/notifications/low_stock_notifier.dart';
import 'package:skedux/src/core/utils/datetime_formatter.dart';
import 'package:skedux/src/core/notifications/notification_service.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:skedux/src/features/schedules/data/entry_log_repository.dart';
import 'package:skedux/src/features/schedules/data/schedule_scheduler.dart';
import 'package:skedux/src/features/schedules/domain/calculated_entry.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/entry_log_ids.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/features/schedules/domain/schedule_entry_metrics.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';
import 'package:skedux/src/widgets/entry_action_sheet.dart';

Future<void> showEntryActionSheetFromModels(
  BuildContext context, {
  required CalculatedEntry entry,
  required Schedule schedule,
  required Medication medication,
  EntryStatus? initialStatus,
}) {
  Future<void> cancelNotificationForEntry() async {
    try {
      await NotificationService.cancel(
        ScheduleScheduler.entryNotificationIdFor(
          entry.scheduleId,
          entry.scheduledTime,
        ),
      );
      for (final overdueId in ScheduleScheduler.overdueNotificationIdsFor(
        entry.scheduleId,
        entry.scheduledTime,
      )) {
        await NotificationService.cancel(overdueId);
      }
      // Cancel the Android group summary so "Upcoming entries" clears from the
      // notification tray when the user acts on a entry from a notification.
      await NotificationService.cancel(
        ScheduleScheduler.entrySummaryNotificationIdFor(
          entry.scheduledTime.toLocal(),
        ),
      );
    } catch (_) {
      // Best-effort cancellation only.
    }
  }

  return EntryActionSheet.show(
    context,
    entry: entry,
    initialStatus: initialStatus,
    onMarkLogged: (request) async {
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
        actionTime: request.actionTime,
        entryValue: entry.entryValue,
        entryUnit: entry.entryUnit,
        action: EntryAction.logged,
        actualEntryValue: request.actualEntryValue,
        actualEntryUnit: request.actualEntryUnit,
        notes: request.notes?.isEmpty ?? true ? null : request.notes,
      );

      final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
      await repo.upsertOccurrence(log);
      await cancelNotificationForEntry();

      final medBox = Hive.box<Medication>('medications');
      final currentMed = medBox.get(medication.id);
      if (currentMed != null) {
        final effectiveEntryValue = request.actualEntryValue ?? entry.entryValue;
        final effectiveEntryUnit = request.actualEntryUnit ?? entry.entryUnit;
        final delta = MedicationStockAdjustment.tryCalculateStockDelta(
          medication: currentMed,
          schedule: schedule,
          entryValue: effectiveEntryValue,
          entryUnit: effectiveEntryUnit,
          preferEntryValue: request.actualEntryValue != null,
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
        showAppSnackBar(context, 'Entry marked as taken');
      }
    },
    onSnooze: (request) async {
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
        actionTime: request.actionTime,
        entryValue: entry.entryValue,
        entryUnit: entry.entryUnit,
        action: EntryAction.snoozed,
        actualEntryValue: request.actualEntryValue,
        actualEntryUnit: request.actualEntryUnit,
        notes: request.notes?.isEmpty ?? true ? null : request.notes,
      );

      final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
      await repo.upsertOccurrence(log);

      // Reschedule a reminder at the snooze-until time (best-effort).
      await cancelNotificationForEntry();
      final when = request.actionTime;
      if (when.isAfter(DateTime.now())) {
        final metrics = ScheduleEntryMetrics.format(schedule);
        final time = DateTimeFormatter.formatTime(context, when);
        final body = '$metrics | Snoozed until $time';
        await NotificationService.scheduleAtAlarmClock(
          ScheduleScheduler.entryNotificationIdFor(
            entry.scheduleId,
            entry.scheduledTime,
          ),
          when,
          title: medication.name,
          body: body,
          payload:
              'entry:${entry.scheduleId}:${entry.scheduledTime.millisecondsSinceEpoch}',
          actions: NotificationService.upcomingEntryActions,
          expandedLines: <String>[metrics, 'Snoozed until $time'],
        );
      }

      if (context.mounted) {
        final now = DateTime.now();
        final sameDay =
            request.actionTime.year == now.year &&
            request.actionTime.month == now.month &&
            request.actionTime.day == now.day;
        final time = DateTimeFormatter.formatTime(context, request.actionTime);
        final label = sameDay
            ? 'Entry snoozed until $time'
            : 'Entry snoozed until ${MaterialLocalizations.of(context).formatMediumDate(request.actionTime)} | $time';
        showAppSnackBar(context, label);
      }
    },
    onSkip: (request) async {
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
        actionTime: request.actionTime,
        entryValue: entry.entryValue,
        entryUnit: entry.entryUnit,
        action: EntryAction.skipped,
        actualEntryValue: request.actualEntryValue,
        actualEntryUnit: request.actualEntryUnit,
        notes: request.notes?.isEmpty ?? true ? null : request.notes,
      );

      final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
      await repo.upsertOccurrence(log);
      await cancelNotificationForEntry();

      if (context.mounted) {
        showAppSnackBar(context, 'Entry skipped');
      }
    },
    onDelete: (request) async {
      final logBox = Hive.box<EntryLog>('entry_logs');
      final baseId = EntryLogIds.occurrenceId(
        scheduleId: entry.scheduleId,
        scheduledTime: entry.scheduledTime,
      );
      final existingLog =
          logBox.get(baseId) ??
          logBox.get(EntryLogIds.legacySnoozeIdFromBase(baseId));

      if (existingLog != null && existingLog.action == EntryAction.logged) {
        final medBox = Hive.box<Medication>('medications');
        final currentMed = medBox.get(medication.id);
        if (currentMed != null) {
          final oldValue = existingLog.actualEntryValue ?? existingLog.entryValue;
          final oldUnit = existingLog.actualEntryUnit ?? existingLog.entryUnit;
          final delta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: currentMed,
            schedule: schedule,
            entryValue: oldValue,
            entryUnit: oldUnit,
            preferEntryValue: existingLog.actualEntryValue != null,
          );
          if (delta != null) {
            await medBox.put(
              currentMed.id,
              MedicationStockAdjustment.restore(
                medication: currentMed,
                delta: delta,
              ),
            );
          }
        }
      }

      final repo = EntryLogRepository(logBox);
      await repo.deleteOccurrence(
        scheduleId: entry.scheduleId,
        scheduledTime: entry.scheduledTime,
      );
      await cancelNotificationForEntry();

      if (context.mounted) {
        showAppSnackBar(context, 'Entry log deleted');
      }
    },
  );
}
