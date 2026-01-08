// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/widgets/calendar/dose_calendar_widget.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_header.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';
import 'package:dosifi_v5/src/widgets/dose_card.dart';
import 'package:dosifi_v5/src/widgets/up_next_dose_card.dart';
import 'package:dosifi_v5/src/widgets/schedule_status_chip.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _cancelNotificationForDose(CalculatedDose dose) async {
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

  Future<void> _showDoseActionSheet(
    BuildContext context, {
    required CalculatedDose dose,
    required Schedule schedule,
    required Medication medication,
    DoseStatus? initialStatus,
  }) {
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
        await _cancelNotificationForDose(dose);

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
            await medBox.put(
              currentMed.id,
              MedicationStockAdjustment.deduct(
                medication: currentMed,
                delta: delta,
              ),
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
          final time = TimeOfDay.fromDateTime(
            request.actionTime,
          ).format(context);
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
        await _cancelNotificationForDose(dose);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Dose skipped')));
        }
      },
      onDelete: (request) async {
        final logId =
            '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
        final snoozeId = '${logId}_snooze';

        final logBox = Hive.box<DoseLog>('dose_logs');
        final repo = DoseLogRepository(logBox);

        final existingLog = logBox.get(logId);
        if (existingLog != null && existingLog.action == DoseAction.taken) {
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(medication.id);
          if (currentMed != null) {
            final oldValue =
                existingLog.actualDoseValue ?? existingLog.doseValue;
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

        await repo.delete(logId);
        await repo.delete(snoozeId);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Dose log deleted')));
        }
      },
    );
  }

  ({
    CalculatedDose? dose,
    Schedule? schedule,
    Medication? medication,
    String? strengthLabel,
    String? metrics,
  })
  _resolveUpNext(
    Iterable<Schedule> schedules,
    Box<Medication> meds,
    Box<DoseLog> logs,
  ) {
    final now = DateTime.now();

    DateTime? bestTime;
    Schedule? bestSchedule;
    Medication? bestMedication;

    for (final schedule in schedules) {
      if (!schedule.isActive) continue;
      final medId = schedule.medicationId;
      if (medId == null) continue;
      final med = meds.get(medId);
      if (med == null) continue;

      final next = ScheduleOccurrenceService.nextOccurrence(
        schedule,
        from: now,
      );
      if (next == null) continue;

      if (bestTime == null || next.isBefore(bestTime)) {
        bestTime = next;
        bestSchedule = schedule;
        bestMedication = med;
      }
    }

    if (bestTime == null || bestSchedule == null || bestMedication == null) {
      return (
        dose: null,
        schedule: null,
        medication: null,
        strengthLabel: null,
        metrics: null,
      );
    }

    final baseId = '${bestSchedule.id}_${bestTime.millisecondsSinceEpoch}';
    final existingLog = logs.get(baseId) ?? logs.get('${baseId}_snooze');
    final dose = CalculatedDose(
      scheduleId: bestSchedule.id,
      scheduleName: bestSchedule.name,
      medicationName: bestMedication.name,
      scheduledTime: bestTime,
      doseValue: bestSchedule.doseValue,
      doseUnit: bestSchedule.doseUnit,
      existingLog: existingLog,
    );

    final strengthLabel = MedicationDisplayHelpers.strengthOrConcentrationLabel(
      bestMedication,
    );
    final metrics = MedicationDisplayHelpers.doseMetricsSummary(
      bestMedication,
      doseTabletQuarters: bestSchedule.doseTabletQuarters,
      doseCapsules: bestSchedule.doseCapsules,
      doseSyringes: bestSchedule.doseSyringes,
      doseVials: bestSchedule.doseVials,
      doseMassMcg: bestSchedule.doseMassMcg?.toDouble(),
      doseVolumeMicroliter: bestSchedule.doseVolumeMicroliter?.toDouble(),
      syringeUnits: bestSchedule.doseIU?.toDouble(),
    );

    return (
      dose: dose,
      schedule: bestSchedule,
      medication: bestMedication,
      strengthLabel: strengthLabel,
      metrics: metrics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Dosifi v5'),
      // Logo moved to body header to avoid duplicate appBar
      body: Padding(
        padding: kPagePaddingNoBottom,
        child: ListView(
          children: [
            Text('Dosifi', style: cardTitleStyle(context)),
            const SizedBox(height: kSpacingXS),
            Text(
              'Upcoming doses, schedules, and calendar',
              style: helperTextStyle(context),
            ),
            const SizedBox(height: kSpacingL),
            ValueListenableBuilder(
              valueListenable: Hive.box<Schedule>('schedules').listenable(),
              builder: (context, Box<Schedule> scheduleBox, _) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box<Medication>(
                    'medications',
                  ).listenable(),
                  builder: (context, Box<Medication> medBox, _) {
                    return ValueListenableBuilder(
                      valueListenable: Hive.box<DoseLog>(
                        'dose_logs',
                      ).listenable(),
                      builder: (context, Box<DoseLog> logBox, _) {
                        final result = _resolveUpNext(
                          scheduleBox.values,
                          medBox,
                          logBox,
                        );

                        return UpNextDoseCard(
                          dose: result.dose,
                          medicationName: result.medication?.name,
                          strengthOrConcentrationLabel: result.strengthLabel,
                          doseMetrics: result.metrics,
                          onDoseTap: (CalculatedDose dose) {
                            final schedule = result.schedule;
                            final medication = result.medication;
                            if (schedule == null || medication == null) return;
                            _showDoseActionSheet(
                              context,
                              dose: dose,
                              schedule: schedule,
                              medication: medication,
                            );
                          },
                          onQuickAction: (status) {
                            final schedule = result.schedule;
                            final medication = result.medication;
                            final resolvedDose = result.dose;
                            if (schedule == null || medication == null) return;
                            if (resolvedDose == null) return;
                            _showDoseActionSheet(
                              context,
                              dose: resolvedDose,
                              schedule: schedule,
                              medication: medication,
                              initialStatus: status,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: kSpacingL),
            ValueListenableBuilder(
              valueListenable: Hive.box<Schedule>('schedules').listenable(),
              builder: (context, Box<Schedule> scheduleBox, _) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box<Medication>(
                    'medications',
                  ).listenable(),
                  builder: (context, Box<Medication> medBox, _) {
                    return ValueListenableBuilder(
                      valueListenable: Hive.box<DoseLog>(
                        'dose_logs',
                      ).listenable(),
                      builder: (context, Box<DoseLog> logBox, _) {
                        final activeSchedules = scheduleBox.values
                            .where((s) => s.isActive && s.medicationId != null)
                            .toList();

                        activeSchedules.sort((a, b) {
                          final an =
                              ScheduleOccurrenceService.nextOccurrence(a) ??
                              DateTime(9999);
                          final bn =
                              ScheduleOccurrenceService.nextOccurrence(b) ??
                              DateTime(9999);
                          return an.compareTo(bn);
                        });

                        final visible = activeSchedules.take(3).toList();

                        return SectionFormCard(
                          neutral: true,
                          title: 'Schedules',
                          children: [
                            if (visible.isEmpty)
                              Text(
                                'No active schedules',
                                style: mutedTextStyle(context),
                              )
                            else
                              for (final schedule in visible) ...[
                                Builder(
                                  builder: (context) {
                                    final medId = schedule.medicationId;
                                    if (medId == null) {
                                      return const SizedBox.shrink();
                                    }

                                    final med = medBox.get(medId);
                                    if (med == null) {
                                      return const SizedBox.shrink();
                                    }

                                    final next =
                                        ScheduleOccurrenceService.nextOccurrence(
                                          schedule,
                                        );
                                    if (next == null) {
                                      return const SizedBox.shrink();
                                    }

                                    final strengthLabel =
                                        MedicationDisplayHelpers.strengthOrConcentrationLabel(
                                          med,
                                        );
                                    final metrics =
                                        MedicationDisplayHelpers.doseMetricsSummary(
                                          med,
                                          doseTabletQuarters:
                                              schedule.doseTabletQuarters,
                                          doseCapsules: schedule.doseCapsules,
                                          doseSyringes: schedule.doseSyringes,
                                          doseVials: schedule.doseVials,
                                          doseMassMcg: schedule.doseMassMcg
                                              ?.toDouble(),
                                          doseVolumeMicroliter: schedule
                                              .doseVolumeMicroliter
                                              ?.toDouble(),
                                          syringeUnits: schedule.doseIU
                                              ?.toDouble(),
                                        );

                                    final baseId =
                                        '${schedule.id}_${next.millisecondsSinceEpoch}';
                                    final existingLog =
                                        logBox.get(baseId) ??
                                        logBox.get('${baseId}_snooze');
                                    final dose = CalculatedDose(
                                      scheduleId: schedule.id,
                                      scheduleName: schedule.name,
                                      medicationName: med.name,
                                      scheduledTime: next,
                                      doseValue: schedule.doseValue,
                                      doseUnit: schedule.doseUnit,
                                      existingLog: existingLog,
                                    );

                                    return DoseCard(
                                      dose: dose,
                                      medicationName: med.name,
                                      strengthOrConcentrationLabel:
                                          strengthLabel,
                                      doseMetrics: metrics,
                                      isActive: schedule.isActive,
                                      titleTrailing: ScheduleStatusChip(
                                        schedule: schedule,
                                      ),
                                      onTap: () => context.push(
                                        '/schedules/detail/${schedule.id}',
                                      ),
                                      onQuickAction: (status) =>
                                          _showDoseActionSheet(
                                            context,
                                            dose: dose,
                                            schedule: schedule,
                                            medication: med,
                                            initialStatus: status,
                                          ),
                                      onPrimaryAction: () =>
                                          _showDoseActionSheet(
                                            context,
                                            dose: dose,
                                            schedule: schedule,
                                            medication: med,
                                          ),
                                    );
                                  },
                                ),
                                const SizedBox(height: kSpacingS),
                              ],
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: kSpacingL),
            SectionFormCard(
              neutral: true,
              title: 'Calendar',
              children: [
                SizedBox(
                  height: kHomeMiniCalendarHeight,
                  child: const DoseCalendarWidget(
                    variant: CalendarVariant.mini,
                    defaultView: CalendarView.day,
                    showSelectedDayPanel: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpacingXL),
            Wrap(
              spacing: kSpacingM,
              runSpacing: kSpacingM,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/medications'),
                  icon: const Icon(Icons.medication),
                  label: const Text('Medications'),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/schedules'),
                  icon: const Icon(Icons.schedule),
                  label: const Text('Schedules'),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/calendar'),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Calendar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
