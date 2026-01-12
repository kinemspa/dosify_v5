import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/notifications/low_stock_notifier.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
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
      final weekday = dose.scheduledTime.weekday;
      final minutes = dose.scheduledTime.hour * 60 + dose.scheduledTime.minute;
      final notificationId = ScheduleScheduler.slotIdFor(
        dose.scheduleId,
        weekday: weekday,
        minutes: minutes,
        occurrence: 0,
      );
      await NotificationService.cancel(notificationId);
    } catch (_) {
      // Best-effort cancellation only.
    }
  }

  return DoseActionSheet.show(
    context,
    dose: dose,
    initialStatus: initialStatus,
    onMarkTaken: (request) async {
      final logId =
          '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
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
        action: DoseAction.taken,
        actualDoseValue: request.actualDoseValue,
        actualDoseUnit: request.actualDoseUnit,
        notes: request.notes?.isEmpty ?? true ? null : request.notes,
      );

      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsert(log);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dose marked as taken')));
      }
    },
    onSnooze: (request) async {
      final logId =
          '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}_snooze';
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
      await repo.upsert(log);

      if (context.mounted) {
        final now = DateTime.now();
        final sameDay =
            request.actionTime.year == now.year &&
            request.actionTime.month == now.month &&
            request.actionTime.day == now.day;
        final time = TimeOfDay.fromDateTime(request.actionTime).format(context);
        final label = sameDay
            ? 'Dose snoozed until $time'
            : 'Dose snoozed until ${MaterialLocalizations.of(context).formatMediumDate(request.actionTime)} • $time';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(label)));
      }
    },
    onSkip: (request) async {
      final logId =
          '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
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
      await repo.upsert(log);
      await cancelNotificationForDose();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dose skipped')));
      }
    },
    onDelete: (request) async {
      final logBox = Hive.box<DoseLog>('dose_logs');
      final idToDelete =
          dose.existingLog?.id ??
          '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
      final existingLog = logBox.get(idToDelete);

      if (existingLog != null && existingLog.action == DoseAction.taken) {
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
      await repo.delete(idToDelete);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dose log deleted')));
      }
    },
  );
}
