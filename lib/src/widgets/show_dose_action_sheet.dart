import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/notifications/low_stock_notifier.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log_ids.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_dose_metrics.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';

Future<void> showDoseActionSheetFromModels(
  BuildContext context, {
  required CalculatedDose dose,
  required Schedule schedule,
  required Medication medication,
  DoseStatus? initialStatus,
}) {
  Future<void> cancelNotificationForDose() async {
    try {
      await NotificationService.cancel(
        ScheduleScheduler.doseNotificationIdFor(
          dose.scheduleId,
          dose.scheduledTime,
        ),
      );
      for (final overdueId in ScheduleScheduler.overdueNotificationIdsFor(
        dose.scheduleId,
        dose.scheduledTime,
      )) {
        await NotificationService.cancel(overdueId);
      }
      // Cancel the Android group summary so "Upcoming doses" clears from the
      // notification tray when the user acts on a dose from a notification.
      await NotificationService.cancel(
        ScheduleScheduler.doseSummaryNotificationIdFor(
          dose.scheduledTime.toLocal(),
        ),
      );
    } catch (_) {
      // Best-effort cancellation only.
    }
  }

  return DoseActionSheet.show(
    context,
    dose: dose,
    initialStatus: initialStatus,
    onMarkLogged: (request) async {
      final logId = DoseLogIds.occurrenceId(
        scheduleId: dose.scheduleId,
        scheduledTime: dose.scheduledTime,
      );
      final log = DoseLog(
        id: logId,
        scheduleId: dose.scheduleId,
        scheduleName: dose.scheduleName,
        medicationId: medication.id,
        medicationName: medication.name,
        scheduledTime: dose.scheduledTime,
        actionTime: request.actionTime,
        doseValue: dose.doseValue,
        doseUnit: dose.doseUnit,
        action: DoseAction.logged,
        actualDoseValue: request.actualDoseValue,
        actualDoseUnit: request.actualDoseUnit,
        notes: request.notes?.isEmpty ?? true ? null : request.notes,
      );

      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsertOccurrence(log);
      await cancelNotificationForDose();

      final medBox = Hive.box<Medication>('medications');
      final currentMed = medBox.get(medication.id);
      if (currentMed != null) {
        final effectiveDoseValue = request.actualDoseValue ?? dose.doseValue;
        final effectiveDoseUnit = request.actualDoseUnit ?? dose.doseUnit;
        final delta = MedicationStockAdjustment.tryCalculateStockDelta(
          medication: currentMed,
          schedule: schedule,
          doseValue: effectiveDoseValue,
          doseUnit: effectiveDoseUnit,
          preferDoseValue: request.actualDoseValue != null,
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
        showAppSnackBar(context, 'Dose marked as taken');
      }
    },
    onSnooze: (request) async {
      final logId = DoseLogIds.occurrenceId(
        scheduleId: dose.scheduleId,
        scheduledTime: dose.scheduledTime,
      );
      final log = DoseLog(
        id: logId,
        scheduleId: dose.scheduleId,
        scheduleName: dose.scheduleName,
        medicationId: medication.id,
        medicationName: medication.name,
        scheduledTime: dose.scheduledTime,
        actionTime: request.actionTime,
        doseValue: dose.doseValue,
        doseUnit: dose.doseUnit,
        action: DoseAction.snoozed,
        actualDoseValue: request.actualDoseValue,
        actualDoseUnit: request.actualDoseUnit,
        notes: request.notes?.isEmpty ?? true ? null : request.notes,
      );

      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsertOccurrence(log);

      // Reschedule a reminder at the snooze-until time (best-effort).
      await cancelNotificationForDose();
      final when = request.actionTime;
      if (when.isAfter(DateTime.now())) {
        final metrics = ScheduleDoseMetrics.format(schedule);
        final time = DateTimeFormatter.formatTime(context, when);
        final body = '$metrics | Snoozed until $time';
        await NotificationService.scheduleAtAlarmClock(
          ScheduleScheduler.doseNotificationIdFor(
            dose.scheduleId,
            dose.scheduledTime,
          ),
          when,
          title: medication.name,
          body: body,
          payload:
              'dose:${dose.scheduleId}:${dose.scheduledTime.millisecondsSinceEpoch}',
          actions: NotificationService.upcomingDoseActions,
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
            ? 'Dose snoozed until $time'
            : 'Dose snoozed until ${MaterialLocalizations.of(context).formatMediumDate(request.actionTime)} | $time';
        showAppSnackBar(context, label);
      }
    },
    onSkip: (request) async {
      final logId = DoseLogIds.occurrenceId(
        scheduleId: dose.scheduleId,
        scheduledTime: dose.scheduledTime,
      );
      final log = DoseLog(
        id: logId,
        scheduleId: dose.scheduleId,
        scheduleName: dose.scheduleName,
        medicationId: medication.id,
        medicationName: medication.name,
        scheduledTime: dose.scheduledTime,
        actionTime: request.actionTime,
        doseValue: dose.doseValue,
        doseUnit: dose.doseUnit,
        action: DoseAction.skipped,
        actualDoseValue: request.actualDoseValue,
        actualDoseUnit: request.actualDoseUnit,
        notes: request.notes?.isEmpty ?? true ? null : request.notes,
      );

      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsertOccurrence(log);
      await cancelNotificationForDose();

      if (context.mounted) {
        showAppSnackBar(context, 'Dose skipped');
      }
    },
    onDelete: (request) async {
      final logBox = Hive.box<DoseLog>('dose_logs');
      final baseId = DoseLogIds.occurrenceId(
        scheduleId: dose.scheduleId,
        scheduledTime: dose.scheduledTime,
      );
      final existingLog =
          logBox.get(baseId) ??
          logBox.get(DoseLogIds.legacySnoozeIdFromBase(baseId));

      if (existingLog != null && existingLog.action == DoseAction.logged) {
        final medBox = Hive.box<Medication>('medications');
        final currentMed = medBox.get(medication.id);
        if (currentMed != null) {
          final oldValue = existingLog.actualDoseValue ?? existingLog.doseValue;
          final oldUnit = existingLog.actualDoseUnit ?? existingLog.doseUnit;
          final delta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: currentMed,
            schedule: schedule,
            doseValue: oldValue,
            doseUnit: oldUnit,
            preferDoseValue: existingLog.actualDoseValue != null,
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

      final repo = DoseLogRepository(logBox);
      await repo.deleteOccurrence(
        scheduleId: dose.scheduleId,
        scheduledTime: dose.scheduledTime,
      );
      await cancelNotificationForDose();

      if (context.mounted) {
        showAppSnackBar(context, 'Dose log deleted');
      }
    },
  );
}
