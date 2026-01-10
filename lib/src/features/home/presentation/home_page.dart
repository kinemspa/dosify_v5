// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_reports_widget.dart';
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
import 'package:dosifi_v5/src/widgets/schedule_status_chip.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  List<
    ({
      CalculatedDose dose,
      Schedule schedule,
      Medication medication,
      String strengthLabel,
      String metrics,
    })
  >
  _resolveTodayDoses(
    Iterable<Schedule> schedules,
    Box<Medication> meds,
    Box<DoseLog> logs,
  ) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    final items =
        <
          ({
            CalculatedDose dose,
            Schedule schedule,
            Medication medication,
            String strengthLabel,
            String metrics,
          })
        >[];

    for (final schedule in schedules) {
      if (!schedule.isActive) continue;
      final medId = schedule.medicationId;
      if (medId == null) continue;
      final med = meds.get(medId);
      if (med == null) continue;

      final times = ScheduleOccurrenceService.occurrencesInRange(
        schedule,
        start,
        end,
      );

      if (times.isEmpty) continue;

      final strengthLabel =
          MedicationDisplayHelpers.strengthOrConcentrationLabel(med);
      final metrics = MedicationDisplayHelpers.doseMetricsSummary(
        med,
        doseTabletQuarters: schedule.doseTabletQuarters,
        doseCapsules: schedule.doseCapsules,
        doseSyringes: schedule.doseSyringes,
        doseVials: schedule.doseVials,
        doseMassMcg: schedule.doseMassMcg?.toDouble(),
        doseVolumeMicroliter: schedule.doseVolumeMicroliter?.toDouble(),
        syringeUnits: schedule.doseIU?.toDouble(),
      );

      for (final dt in times) {
        final baseId = '${schedule.id}_${dt.millisecondsSinceEpoch}';
        final existingLog = logs.get(baseId) ?? logs.get('${baseId}_snooze');
        final dose = CalculatedDose(
          scheduleId: schedule.id,
          scheduleName: schedule.name,
          medicationName: med.name,
          scheduledTime: dt,
          doseValue: schedule.doseValue,
          doseUnit: schedule.doseUnit,
          existingLog: existingLog,
        );

        items.add((
          dose: dose,
          schedule: schedule,
          medication: med,
          strengthLabel: strengthLabel,
          metrics: metrics,
        ));
      }
    }

    items.sort((a, b) => a.dose.scheduledTime.compareTo(b.dose.scheduledTime));
    return items;
  }

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

}

class _HomePageState extends State<HomePage> {
  static const _kCardToday = 'today';
  static const _kCardSchedules = 'schedules';
  static const _kCardReports = 'reports';
  static const _kCardCalendar = 'calendar';

  late final List<String> _cardOrder;
  Set<String>? _reportIncludedMedicationIds;

  @override
  void initState() {
    super.initState();
    _cardOrder = <String>[
      _kCardToday,
      _kCardSchedules,
      _kCardReports,
      _kCardCalendar,
    ];
    unawaited(_restoreCardOrder());
  }

  String _prefsKeyCardOrder() => 'home_card_order';

  Future<void> _restoreCardOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKeyCardOrder());
    if (stored == null || stored.isEmpty) return;

    final allowed = <String>{
      _kCardToday,
      _kCardSchedules,
      _kCardReports,
      _kCardCalendar,
    };
    final filtered = stored.where(allowed.contains).toList();
    for (final id in allowed) {
      if (!filtered.contains(id)) filtered.add(id);
    }

    if (!mounted) return;
    setState(() {
      _cardOrder
        ..clear()
        ..addAll(filtered);
    });
  }

  Future<void> _persistCardOrder(List<String> orderedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKeyCardOrder(), orderedIds);
  }

  Widget _buildHomeCards(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final todayCard = ValueListenableBuilder(
      valueListenable: Hive.box<Schedule>('schedules').listenable(),
      builder: (context, Box<Schedule> scheduleBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<Medication>('medications').listenable(),
          builder: (context, Box<Medication> medBox, _) {
            return ValueListenableBuilder(
              valueListenable: Hive.box<DoseLog>('dose_logs').listenable(),
              builder: (context, Box<DoseLog> logBox, _) {
                final items = widget._resolveTodayDoses(
                  scheduleBox.values,
                  medBox,
                  logBox,
                );

                return SectionFormCard(
                  neutral: true,
                  title: 'Today',
                  children: [
                    if (items.isEmpty)
                      Text('No doses today', style: mutedTextStyle(context))
                    else
                      for (final item in items) ...[
                        DoseCard(
                          dose: item.dose,
                          medicationName: item.medication.name,
                          strengthOrConcentrationLabel: item.strengthLabel,
                          doseMetrics: item.metrics,
                          isActive: item.schedule.isActive,
                          onTap: () => widget._showDoseActionSheet(
                            context,
                            dose: item.dose,
                            schedule: item.schedule,
                            medication: item.medication,
                          ),
                          onQuickAction: (status) => widget._showDoseActionSheet(
                            context,
                            dose: item.dose,
                            schedule: item.schedule,
                            medication: item.medication,
                            initialStatus: status,
                          ),
                          onPrimaryAction: () => widget._showDoseActionSheet(
                            context,
                            dose: item.dose,
                            schedule: item.schedule,
                            medication: item.medication,
                          ),
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
    );

    final schedulesCard = ValueListenableBuilder(
      valueListenable: Hive.box<Schedule>('schedules').listenable(),
      builder: (context, Box<Schedule> scheduleBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<Medication>('medications').listenable(),
          builder: (context, Box<Medication> medBox, _) {
            return ValueListenableBuilder(
              valueListenable: Hive.box<DoseLog>('dose_logs').listenable(),
              builder: (context, Box<DoseLog> logBox, _) {
                final schedules = scheduleBox.values
                    .where((s) => s.medicationId != null)
                    .toList();

                schedules.sort((a, b) {
                  final an = ScheduleOccurrenceService.nextOccurrence(a) ??
                      DateTime(9999);
                  final bn = ScheduleOccurrenceService.nextOccurrence(b) ??
                      DateTime(9999);
                  return an.compareTo(bn);
                });

                return SectionFormCard(
                  neutral: true,
                  title: 'Schedules',
                  children: [
                    if (schedules.isEmpty)
                      Text('No schedules', style: mutedTextStyle(context))
                    else
                      for (final schedule in schedules) ...[
                        Builder(
                          builder: (context) {
                            final medId = schedule.medicationId;
                            if (medId == null) return const SizedBox.shrink();

                            final med = medBox.get(medId);
                            if (med == null) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      schedule.name,
                                      style: mutedTextStyle(context),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: kSpacingS),
                                  ScheduleStatusChip(
                                    schedule: schedule,
                                    dense: true,
                                  ),
                                ],
                              );
                            }

                            final next = ScheduleOccurrenceService.nextOccurrence(
                              schedule,
                            );
                            if (next == null) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          schedule.name,
                                          style: bodyTextStyle(context),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: kSpacingXXS),
                                        Text(
                                          'No upcoming dose',
                                          style: mutedTextStyle(context),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: kSpacingS),
                                  ScheduleStatusChip(
                                    schedule: schedule,
                                    dense: true,
                                  ),
                                ],
                              );
                            }

                            final strengthLabel =
                                MedicationDisplayHelpers
                                    .strengthOrConcentrationLabel(med);
                            final metrics = MedicationDisplayHelpers
                                .doseMetricsSummary(
                              med,
                              doseTabletQuarters: schedule.doseTabletQuarters,
                              doseCapsules: schedule.doseCapsules,
                              doseSyringes: schedule.doseSyringes,
                              doseVials: schedule.doseVials,
                              doseMassMcg: schedule.doseMassMcg?.toDouble(),
                              doseVolumeMicroliter:
                                  schedule.doseVolumeMicroliter?.toDouble(),
                              syringeUnits: schedule.doseIU?.toDouble(),
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
                              strengthOrConcentrationLabel: strengthLabel,
                              doseMetrics: metrics,
                              isActive: schedule.isActive,
                              showActions: schedule.isActive,
                              titleTrailing: ScheduleStatusChip(
                                schedule: schedule,
                                dense: true,
                              ),
                              onTap: () => context.pushNamed(
                                'scheduleDetail',
                                pathParameters: {'id': schedule.id},
                              ),
                              onQuickAction: schedule.isActive
                                  ? (status) => widget._showDoseActionSheet(
                                        context,
                                        dose: dose,
                                        schedule: schedule,
                                        medication: med,
                                        initialStatus: status,
                                      )
                                  : null,
                              onPrimaryAction: () => widget._showDoseActionSheet(
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
    );

    final calendarCard = SectionFormCard(
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
    );

    final reportsCard = ValueListenableBuilder(
      valueListenable: Hive.box<Medication>('medications').listenable(),
      builder: (context, Box<Medication> medBox, _) {
        final meds = medBox.values.toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (_reportIncludedMedicationIds == null) {
          _reportIncludedMedicationIds = meds.map((m) => m.id).toSet();
        } else {
          final currentIds = meds.map((m) => m.id).toSet();
          _reportIncludedMedicationIds =
              _reportIncludedMedicationIds!.intersection(currentIds);
          if (_reportIncludedMedicationIds!.isEmpty && currentIds.isNotEmpty) {
            _reportIncludedMedicationIds = currentIds;
          }
        }

        final included = _reportIncludedMedicationIds!;

        return SectionFormCard(
          neutral: true,
          title: 'Reports',
          children: [
            if (meds.isEmpty)
              Text('No medications', style: mutedTextStyle(context))
            else ...[
              Wrap(
                spacing: kSpacingS,
                runSpacing: kSpacingS,
                children: [
                  for (final med in meds)
                    PrimaryChoiceChip(
                      label: Text(med.name),
                      selected: included.contains(med.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            included.add(med.id);
                          } else {
                            included.remove(med.id);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: kSpacingM),
              if (included.isEmpty)
                Text(
                  'No medications selected',
                  style: mutedTextStyle(context),
                )
              else
                for (final med in meds)
                  if (included.contains(med.id)) ...[
                    MedicationReportsWidget(medication: med),
                    const SizedBox(height: kSpacingM),
                  ],
            ],
          ],
        );
      },
    );

    final cards = <String, Widget>{
      _kCardToday: todayCard,
      _kCardSchedules: schedulesCard,
      _kCardReports: reportsCard,
      _kCardCalendar: calendarCard,
    };

    final orderedIds = _cardOrder.where(cards.containsKey).toList();
    for (final id in cards.keys) {
      if (!orderedIds.contains(id)) orderedIds.add(id);
    }

    final children = <Widget>[
      for (final entry in orderedIds.asMap().entries)
        Padding(
          key: ValueKey<String>('home_card_${entry.value}'),
          padding: EdgeInsets.only(
            bottom: entry.key == orderedIds.length - 1 ? 0 : kSpacingL,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              cards[entry.value]!,
              Positioned(
                left: kSpacingS,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ReorderableDelayedDragStartListener(
                    index: entry.key,
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: kIconSizeMedium,
                      color: cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    ];

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final moved = orderedIds.removeAt(oldIndex);
          orderedIds.insert(newIndex, moved);
          _cardOrder
            ..clear()
            ..addAll(orderedIds);
        });
        unawaited(_persistCardOrder(orderedIds));
      },
      children: children,
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
            _buildHomeCards(context),
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
