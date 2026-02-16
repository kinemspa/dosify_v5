// Flutter imports:
import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log_ids.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/pages/add_schedule_wizard_page.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_status_ui.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/schedule_detail_header_banner.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/cards/today_doses_card.dart';
import 'package:dosifi_v5/src/widgets/cards/activity_card.dart';
import 'package:dosifi_v5/src/widgets/cards/calendar_card.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/widgets/schedule_pause_dialog.dart';
import 'package:dosifi_v5/src/widgets/unified_status_badge.dart';
import 'package:dosifi_v5/src/widgets/unified_tinted_card_surface.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class ScheduleDetailPage extends StatefulWidget {
  const ScheduleDetailPage({required this.scheduleId, super.key});
  final String scheduleId;

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late final DoseLogRepository _doseLogRepo;

  bool _isScheduleDetailsExpanded = true;
  bool _isTodayExpanded = true;
  bool _isActivityExpanded = true;
  bool _isCalendarExpanded = true;

  ReportTimeRangePreset _activityRangePreset = ReportTimeRangePreset.allTime;

  @override
  void initState() {
    super.initState();
    _doseLogRepo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
  }

  int _computeUtcMinutes(int localMinutes, DateTime now) {
    final localToday = DateTime(
      now.year,
      now.month,
      now.day,
      localMinutes ~/ 60,
      localMinutes % 60,
    );
    final utc = localToday.toUtc();
    return utc.hour * 60 + utc.minute;
  }

  List<int> _computeUtcDays(
    Set<int> localDays,
    int localMinutes,
    DateTime now,
  ) {
    final utcDays = <int>[];
    for (final d in localDays) {
      final delta = (d - now.weekday) % 7;
      final candidate = DateTime(
        now.year,
        now.month,
        now.day + delta,
        localMinutes ~/ 60,
        localMinutes % 60,
      );
      final utc = candidate.toUtc();
      utcDays.add(utc.weekday);
    }
    utcDays.sort();
    return utcDays;
  }

  Future<void> _upsertSchedule(
    BuildContext context,
    Schedule updated, {
    String? successMessage,
  }) async {
    try {
      final scheduleBox = Hive.box<Schedule>('schedules');

      await ScheduleScheduler.cancelFor(updated.id);
      await scheduleBox.put(updated.id, updated);

      if (updated.isActive) {
        await ScheduleScheduler.scheduleFor(updated);
      }

      if (!mounted) return;
      if (successMessage != null && successMessage.trim().isNotEmpty) {
        showAppSnackBar(context, successMessage);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Failed to update schedule: $e');
    }
  }

  Future<void> _editScheduleName(BuildContext context, Schedule s) async {
    final controller = TextEditingController(text: s.name);
    final next = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          titleTextStyle: dialogTitleTextStyle(dialogContext),
          contentTextStyle: dialogContentTextStyle(dialogContext),
          title: const Text('Schedule Name'),
          content: TextField(
            controller: controller,
            style: bodyTextStyle(dialogContext),
            textCapitalization: kTextCapitalizationDefault,
            decoration: buildFieldDecoration(dialogContext, hint: 'Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) return;
                Navigator.of(dialogContext).pop(trimmed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    final trimmed = next?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    if (trimmed == s.name) return;

    await _upsertSchedule(
      context,
      s.copyWithDetails(name: trimmed),
      successMessage: 'Schedule name updated',
    );
  }

  Future<void> _editScheduleDose(BuildContext context, Schedule s) async {
    final controller = TextEditingController(text: _formatNumber(s.doseValue));
    final originalUnit = s.doseUnit.trim().isEmpty ? 'mg' : s.doseUnit;
    final units = <String>[
      'mcg',
      'mg',
      'g',
      'mL',
      'IU',
      'units',
      'tablets',
      'capsules',
      'syringes',
      'vials',
    ];

    final normalizedOriginalUnit = units.firstWhere(
      (u) => u.toLowerCase() == originalUnit.toLowerCase(),
      orElse: () => originalUnit,
    );

    final result = await showDialog<Map<String, Object?>>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        var selectedUnit = normalizedOriginalUnit;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              titleTextStyle: dialogTitleTextStyle(dialogContext),
              contentTextStyle: dialogContentTextStyle(dialogContext),
              title: const Text('Dose'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Value', style: helperTextStyle(dialogContext)),
                  const SizedBox(height: kSpacingS),
                  TextField(
                    controller: controller,
                    style: bodyTextStyle(dialogContext),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: buildFieldDecoration(dialogContext, hint: '0'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kSpacingM),
                  Text('Unit', style: helperTextStyle(dialogContext)),
                  const SizedBox(height: kSpacingS),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: buildFieldDecoration(dialogContext),
                    items: units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() => selectedUnit = v);
                    },
                  ),
                  const SizedBox(height: kSpacingS),
                  Text(
                    'Tip: for tablets/capsules, enter a count (e.g. 1, 0.5, 2).',
                    style: helperTextStyle(dialogContext),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final v = double.tryParse(controller.text.trim());
                    if (v == null || v <= 0) return;
                    Navigator.of(
                      dialogContext,
                    ).pop(<String, Object?>{'value': v, 'unit': selectedUnit});
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (result == null) return;

    final value = result['value'] as double?;
    final unit = (result['unit'] as String?)?.trim();
    if (value == null || unit == null || unit.isEmpty) return;
    if (value == s.doseValue &&
        unit.toLowerCase() == s.doseUnit.toLowerCase()) {
      return;
    }

    int? doseMassMcg;
    int? doseVolumeMicroliter;
    int? doseTabletQuarters;
    int? doseCapsules;
    int? doseSyringes;
    int? doseVials;
    int? doseIU;
    int? doseUnitCode;
    int? displayUnitCode;
    int? inputModeCode;

    final unitLower = unit.toLowerCase();
    if (unitLower == 'mcg' || unitLower == 'mg' || unitLower == 'g') {
      final mcg = switch (unitLower) {
        'mcg' => value,
        'mg' => value * 1000,
        'g' => value * 1000000,
        _ => value,
      };
      doseMassMcg = mcg.round();
      doseUnitCode = switch (unitLower) {
        'mcg' => DoseUnit.mcg.index,
        'mg' => DoseUnit.mg.index,
        'g' => DoseUnit.g.index,
        _ => null,
      };
      displayUnitCode = doseUnitCode;
      inputModeCode = DoseInputMode.mass.index;
    } else if (unitLower == 'ml' || unitLower == 'mL'.toLowerCase()) {
      doseVolumeMicroliter = (value * 1000).round();
      doseUnitCode = DoseUnit.ml.index;
      displayUnitCode = doseUnitCode;
      inputModeCode = DoseInputMode.volume.index;
    } else if (unitLower == 'iu' || unitLower == 'units') {
      doseIU = value.round();
      doseUnitCode = DoseUnit.iu.index;
      displayUnitCode = doseUnitCode;
      inputModeCode = DoseInputMode.iuUnits.index;
    } else if (unitLower == 'tablets') {
      doseTabletQuarters = (value * 4).round();
      doseUnitCode = DoseUnit.tablets.index;
      displayUnitCode = doseUnitCode;
      inputModeCode = DoseInputMode.tablets.index;
    } else if (unitLower == 'capsules') {
      doseCapsules = value.round();
      doseUnitCode = DoseUnit.capsules.index;
      displayUnitCode = doseUnitCode;
      inputModeCode = DoseInputMode.capsules.index;
    } else if (unitLower == 'syringes') {
      doseSyringes = value.round();
      doseUnitCode = DoseUnit.syringes.index;
      displayUnitCode = doseUnitCode;
      inputModeCode = DoseInputMode.count.index;
    } else if (unitLower == 'vials') {
      doseVials = value.round();
      doseUnitCode = DoseUnit.vials.index;
      displayUnitCode = doseUnitCode;
      inputModeCode = DoseInputMode.count.index;
    }

    await _upsertSchedule(
      context,
      s.copyWithDetails(
        doseValue: value,
        doseUnit: unit,
        doseUnitCode: doseUnitCode,
        doseMassMcg: doseMassMcg,
        doseVolumeMicroliter: doseVolumeMicroliter,
        doseTabletQuarters: doseTabletQuarters,
        doseCapsules: doseCapsules,
        doseSyringes: doseSyringes,
        doseVials: doseVials,
        doseIU: doseIU,
        displayUnitCode: displayUnitCode,
        inputModeCode: inputModeCode,
      ),
      successMessage: 'Dose updated',
    );
  }

  Future<void> _editScheduleTimes(BuildContext context, Schedule s) async {
    final initial = ScheduleOccurrenceService.normalizedTimesOfDay(s).toList()
      ..sort();
    final result = await showDialog<List<int>>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        var times = initial.toList();

        Future<void> addTime() async {
          final picked = await showTimePicker(
            context: dialogContext,
            initialTime: times.isEmpty
                ? const TimeOfDay(hour: 8, minute: 0)
                : TimeOfDay(hour: times.last ~/ 60, minute: times.last % 60),
          );
          if (picked == null) return;
          final minutes = picked.hour * 60 + picked.minute;
          if (times.contains(minutes)) return;
          times = (times..add(minutes))..sort();
        }

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final formatted = times
                .map(
                  (m) => DateTimeFormatter.formatTime(
                    dialogContext,
                    DateTime(0, 1, 1, m ~/ 60, m % 60),
                  ),
                )
                .toList();

            return AlertDialog(
              titleTextStyle: dialogTitleTextStyle(dialogContext),
              contentTextStyle: dialogContentTextStyle(dialogContext),
              title: const Text('Times'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (formatted.isEmpty)
                    Text('No times set', style: helperTextStyle(dialogContext))
                  else
                    ...List.generate(formatted.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: kSpacingS),
                        child: Row(
                          children: [
                            Expanded(child: Text(formatted[i])),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setDialogState(() {
                                  times.removeAt(i);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: kSpacingS),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await addTime();
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.add, size: kIconSizeSmall),
                    label: const Text('Add time'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (times.isEmpty) return;
                    Navigator.of(dialogContext).pop(times);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result.isEmpty) return;
    final nextTimes = result.toList()..sort();
    final nextMinutes = nextTimes.first;
    final nextTimesField = nextTimes.length > 1 ? nextTimes : null;

    final now = DateTime.now();
    final minutesUtc = _computeUtcMinutes(nextMinutes, now);
    final timesUtc = nextTimes.map((m) => _computeUtcMinutes(m, now)).toList();
    final daysUtc = _computeUtcDays(s.daysOfWeek.toSet(), nextMinutes, now);

    await _upsertSchedule(
      context,
      s.copyWithDetails(
        minutesOfDay: nextMinutes,
        timesOfDay: nextTimesField,
        minutesOfDayUtc: minutesUtc,
        timesOfDayUtc: timesUtc,
        daysOfWeekUtc: daysUtc,
      ),
      successMessage: 'Times updated',
    );
  }

  Future<void> _editScheduleType(BuildContext context, Schedule s) async {
    final initialMode = s.hasDaysOfMonth
        ? _ScheduleEditMode.daysOfMonth
        : (s.hasCycle ? _ScheduleEditMode.cycle : _ScheduleEditMode.daysOfWeek);
    final initialDays = s.daysOfWeek.toSet();
    final initialCycleN = s.cycleEveryNDays ?? 2;
    final initialAnchor = s.cycleAnchorDate ?? DateTime.now();
    final initialDom = (s.daysOfMonth ?? const <int>[]).toSet();
    final initialMissing = s.monthlyMissingDayBehavior;

    final result = await showDialog<_ScheduleTypeEditResult>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        var mode = initialMode;
        var days = initialDays.toSet();
        var cycleN = initialCycleN;
        var anchor = DateTime(
          initialAnchor.year,
          initialAnchor.month,
          initialAnchor.day,
        );
        var daysOfMonth = initialDom.toSet();
        var missing = initialMissing;

        final cycleCtrl = TextEditingController(text: cycleN.toString());

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickAnchor() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: anchor,
                firstDate: DateTime.now().subtract(
                  const Duration(days: 365 * 5),
                ),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (picked == null) return;
              anchor = DateTime(picked.year, picked.month, picked.day);
            }

            return AlertDialog(
              titleTextStyle: dialogTitleTextStyle(dialogContext),
              contentTextStyle: dialogContentTextStyle(dialogContext),
              title: const Text('Type'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RadioListTile<_ScheduleEditMode>(
                      value: _ScheduleEditMode.daysOfWeek,
                      groupValue: mode,
                      title: const Text('Days of week / Daily'),
                      onChanged: (v) => setDialogState(() => mode = v!),
                    ),
                    RadioListTile<_ScheduleEditMode>(
                      value: _ScheduleEditMode.cycle,
                      groupValue: mode,
                      title: const Text('Every N days'),
                      onChanged: (v) => setDialogState(() => mode = v!),
                    ),
                    RadioListTile<_ScheduleEditMode>(
                      value: _ScheduleEditMode.daysOfMonth,
                      groupValue: mode,
                      title: const Text('Days of month'),
                      onChanged: (v) => setDialogState(() => mode = v!),
                    ),
                    const SizedBox(height: kSpacingS),
                    if (mode == _ScheduleEditMode.daysOfWeek) ...[
                      Text('Days', style: helperTextStyle(dialogContext)),
                      const SizedBox(height: kSpacingS),
                      Wrap(
                        spacing: kSpacingS,
                        runSpacing: kSpacingS,
                        children:
                            const <int, String>{
                              1: 'Mon',
                              2: 'Tue',
                              3: 'Wed',
                              4: 'Thu',
                              5: 'Fri',
                              6: 'Sat',
                              7: 'Sun',
                            }.entries.map((e) {
                              return FilterChip(
                                label: Text(e.value),
                                selected: days.contains(e.key),
                                onSelected: (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      days.add(e.key);
                                    } else {
                                      days.remove(e.key);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: kSpacingS),
                      OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            days = {1, 2, 3, 4, 5, 6, 7};
                          });
                        },
                        child: const Text('Set to daily'),
                      ),
                    ],
                    if (mode == _ScheduleEditMode.cycle) ...[
                      Text('Every', style: helperTextStyle(dialogContext)),
                      const SizedBox(height: kSpacingS),
                      StepperRow36(
                        controller: cycleCtrl,
                        fixedFieldWidth: 120,
                        decoration: buildFieldDecoration(
                          dialogContext,
                          hint: 'Days',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onDec: () {
                          final v = int.tryParse(cycleCtrl.text) ?? cycleN;
                          final next = (v - 1).clamp(1, 365);
                          cycleCtrl.text = next.toString();
                          setDialogState(() => cycleN = next);
                        },
                        onInc: () {
                          final v = int.tryParse(cycleCtrl.text) ?? cycleN;
                          final next = (v + 1).clamp(1, 365);
                          cycleCtrl.text = next.toString();
                          setDialogState(() => cycleN = next);
                        },
                        onChanged: (v) {
                          final parsed = int.tryParse(v);
                          if (parsed == null) return;
                          setDialogState(() => cycleN = parsed.clamp(1, 365));
                        },
                      ),
                      const SizedBox(height: kSpacingM),
                      Text(
                        'Anchor date',
                        style: helperTextStyle(dialogContext),
                      ),
                      const SizedBox(height: kSpacingS),
                      DateButton36(
                        label: DateFormat('EEE, MMM d, y').format(anchor),
                        onPressed: () async {
                          await pickAnchor();
                          setDialogState(() {});
                        },
                      ),
                    ],
                    if (mode == _ScheduleEditMode.daysOfMonth) ...[
                      Text('Days', style: helperTextStyle(dialogContext)),
                      const SizedBox(height: kSpacingS),
                      Wrap(
                        spacing: kSpacingS,
                        runSpacing: kSpacingS,
                        children: List.generate(31, (i) {
                          final day = i + 1;
                          return FilterChip(
                            label: Text(day.toString()),
                            selected: daysOfMonth.contains(day),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  daysOfMonth.add(day);
                                } else {
                                  daysOfMonth.remove(day);
                                }
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: kSpacingM),
                      Text(
                        'If a selected day does not exist in a month',
                        style: helperTextStyle(dialogContext),
                      ),
                      const SizedBox(height: kSpacingS),
                      DropdownButtonFormField<MonthlyMissingDayBehavior>(
                        value: missing,
                        decoration: buildFieldDecoration(dialogContext),
                        items: MonthlyMissingDayBehavior.values
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(
                                  b == MonthlyMissingDayBehavior.skip
                                      ? 'Skip'
                                      : 'Move to last day',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setDialogState(() => missing = v);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cycleCtrl.dispose();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (mode == _ScheduleEditMode.daysOfWeek && days.isEmpty) {
                      return;
                    }
                    if (mode == _ScheduleEditMode.daysOfMonth &&
                        daysOfMonth.isEmpty) {
                      return;
                    }
                    cycleCtrl.dispose();
                    Navigator.of(dialogContext).pop(
                      _ScheduleTypeEditResult(
                        mode: mode,
                        daysOfWeek: days.toList()..sort(),
                        cycleEvery: cycleN,
                        cycleAnchor: anchor,
                        daysOfMonth: daysOfMonth.toList()..sort(),
                        missingDayBehavior: missing,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final now = DateTime.now();
    final firstLocalMinutes = ScheduleOccurrenceService.normalizedTimesOfDay(
      s,
    ).first;
    final minutesUtc = _computeUtcMinutes(firstLocalMinutes, now);
    final timesUtc = ScheduleOccurrenceService.normalizedTimesOfDay(
      s,
    ).map((m) => _computeUtcMinutes(m, now)).toList();

    switch (result.mode) {
      case _ScheduleEditMode.daysOfWeek:
        final days = result.daysOfWeek.toList()..sort();
        final daysUtc = _computeUtcDays(days.toSet(), firstLocalMinutes, now);
        await _upsertSchedule(
          context,
          s.copyWithDetails(
            daysOfWeek: days,
            cycleEveryNDays: null,
            cycleAnchorDate: null,
            daysOfMonth: null,
            monthlyMissingDayBehaviorCode: null,
            minutesOfDayUtc: minutesUtc,
            timesOfDayUtc: timesUtc,
            daysOfWeekUtc: daysUtc,
          ),
          successMessage: 'Type updated',
        );
        return;
      case _ScheduleEditMode.cycle:
        await _upsertSchedule(
          context,
          s.copyWithDetails(
            cycleEveryNDays: result.cycleEvery,
            cycleAnchorDate: DateTime(
              result.cycleAnchor.year,
              result.cycleAnchor.month,
              result.cycleAnchor.day,
            ),
            daysOfMonth: null,
            monthlyMissingDayBehaviorCode: null,
          ),
          successMessage: 'Type updated',
        );
        return;
      case _ScheduleEditMode.daysOfMonth:
        await _upsertSchedule(
          context,
          s.copyWithDetails(
            daysOfMonth: result.daysOfMonth,
            monthlyMissingDayBehaviorCode: result.missingDayBehavior.index,
            cycleEveryNDays: null,
            cycleAnchorDate: null,
          ),
          successMessage: 'Type updated',
        );
        return;
    }
  }

  Future<void> _editScheduleStart(BuildContext context, Schedule s) async {
    final picked = await showDialog<_DateEditResult>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        final current = s.startAt;
        final currentLabel = current == null
            ? 'Not set'
            : DateFormat('EEE, MMM d, y').format(current);

        return AlertDialog(
          titleTextStyle: dialogTitleTextStyle(dialogContext),
          contentTextStyle: dialogContentTextStyle(dialogContext),
          title: const Text('Start'),
          content: Text('Current: $currentLabel'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(const _DateEditResult.cancel()),
              child: const Text('Cancel'),
            ),
            if (current != null)
              TextButton(
                onPressed: () => Navigator.of(
                  dialogContext,
                ).pop(const _DateEditResult.clear()),
                child: const Text('Clear'),
              ),
            FilledButton(
              onPressed: () async {
                final initialDate = current ?? DateTime.now();
                final d = await showDatePicker(
                  context: dialogContext,
                  initialDate: DateTime(
                    initialDate.year,
                    initialDate.month,
                    initialDate.day,
                  ),
                  firstDate: DateTime.now().subtract(
                    const Duration(days: 365 * 5),
                  ),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (d == null) return;
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(_DateEditResult.set(d));
              },
              child: const Text('Set date'),
            ),
          ],
        );
      },
    );

    if (picked == null || picked.action == _DateEditAction.cancel) return;
    if (picked.action == _DateEditAction.clear) {
      if (s.startAt == null) return;
      await _upsertSchedule(
        context,
        s.copyWithDetails(startAt: null),
        successMessage: 'Start cleared',
      );
      return;
    }

    final date = picked.date;
    if (date == null) return;

    final now = DateTime.now();
    final selectedDay = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final nextStart = selectedDay.isAtSameMomentAs(today)
        ? now
        : DateTime(date.year, date.month, date.day);

    if (s.startAt != null && s.startAt!.isAtSameMomentAs(nextStart)) return;
    await _upsertSchedule(
      context,
      s.copyWithDetails(startAt: nextStart),
      successMessage: 'Start updated',
    );
  }

  Future<void> _editScheduleEnd(BuildContext context, Schedule s) async {
    final picked = await showDialog<_DateEditResult>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        final current = s.endAt;
        final currentLabel = current == null
            ? 'Not set'
            : DateFormat('EEE, MMM d, y').format(current);

        return AlertDialog(
          titleTextStyle: dialogTitleTextStyle(dialogContext),
          contentTextStyle: dialogContentTextStyle(dialogContext),
          title: const Text('End'),
          content: Text('Current: $currentLabel'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(const _DateEditResult.cancel()),
              child: const Text('Cancel'),
            ),
            if (current != null)
              TextButton(
                onPressed: () => Navigator.of(
                  dialogContext,
                ).pop(const _DateEditResult.clear()),
                child: const Text('Clear'),
              ),
            FilledButton(
              onPressed: () async {
                final initialDate = current ?? DateTime.now();
                final d = await showDatePicker(
                  context: dialogContext,
                  initialDate: DateTime(
                    initialDate.year,
                    initialDate.month,
                    initialDate.day,
                  ),
                  firstDate: DateTime.now().subtract(
                    const Duration(days: 365 * 5),
                  ),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (d == null) return;
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(_DateEditResult.set(d));
              },
              child: const Text('Set date'),
            ),
          ],
        );
      },
    );

    if (picked == null || picked.action == _DateEditAction.cancel) return;
    if (picked.action == _DateEditAction.clear) {
      if (s.endAt == null) return;
      await _upsertSchedule(
        context,
        s.copyWithDetails(endAt: null),
        successMessage: 'End cleared',
      );
      return;
    }

    final date = picked.date;
    if (date == null) return;

    final nextEnd = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    if (s.endAt != null && s.endAt!.isAtSameMomentAs(nextEnd)) return;

    await _upsertSchedule(
      context,
      s.copyWithDetails(endAt: nextEnd),
      successMessage: 'End updated',
    );
  }

  Future<void> _openEditScheduleDialog(Schedule schedule) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kBorderRadiusLarge),
        ),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: AddScheduleWizardPage(initial: schedule),
        );
      },
    );
  }

  String _mergedTitle(Schedule s) {
    final med = s.medicationName.trim();
    final name = s.name.trim();

    if (med.isEmpty) return name;
    if (name.isEmpty) return med;

    final nameLower = name.toLowerCase();
    final medLower = med.toLowerCase();
    if (nameLower.startsWith(medLower)) return name;

    return '$med - $name';
  }

  /// Check if there's already a log for this scheduled time
  DoseLog? _getExistingLog(DateTime scheduledTime) {
    final logs = _doseLogRepo.getByScheduleId(widget.scheduleId);
    final scheduledUtc = scheduledTime.toUtc();

    return logs.cast<DoseLog?>().firstWhere(
      (log) =>
          log!.scheduledTime.year == scheduledUtc.year &&
          log.scheduledTime.month == scheduledUtc.month &&
          log.scheduledTime.day == scheduledUtc.day &&
          log.scheduledTime.hour == scheduledUtc.hour &&
          log.scheduledTime.minute == scheduledUtc.minute,
      orElse: () => null,
    );
  }

  /// Show dialog to record dose with notes and injection site
  Future<void> _showRecordDoseDialog({
    required Schedule schedule,
    required DateTime scheduledTime,
    required DoseAction action,
    DoseLog? existingLog,
  }) async {
    final notesController = TextEditingController(text: existingLog?.notes);
    String? injectionSite = existingLog?.notes?.contains('Site:') == true
        ? existingLog!.notes!.split('Site:').last.trim()
        : null;

    final isInjection =
        schedule.medicationName.toLowerCase().contains('injection') ||
        schedule.doseUnit.toLowerCase().contains('syringe') ||
        schedule.doseUnit.toLowerCase().contains('vial');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DoseRecordDialog(
        action: action,
        existingLog: existingLog,
        isInjection: isInjection,
        notesController: notesController,
        initialInjectionSite: injectionSite,
      ),
    );

    if (result == null) return;

    if (result['delete'] == true && existingLog != null) {
      await _doseLogRepo.delete(existingLog.id);
      if (!mounted) return;
      showAppSnackBar(context, 'Dose log removed');
      setState(() {});
      return;
    }

    final notes = result['notes'] as String?;
    final site = result['injectionSite'] as String?;
    final combinedNotes = [
      if (notes?.isNotEmpty == true) notes,
      if (site?.isNotEmpty == true) 'Site: $site',
    ].join('\n');

    final log = DoseLog(
      id:
          existingLog?.id ??
          DoseLogIds.occurrenceId(
            scheduleId: schedule.id,
            scheduledTime: scheduledTime,
          ),
      scheduleId: schedule.id,
      scheduleName: schedule.name,
      medicationId: schedule.medicationId ?? '',
      medicationName: schedule.medicationName,
      scheduledTime: scheduledTime.toUtc(),
      doseValue: schedule.doseValue,
      doseUnit: schedule.doseUnit,
      action: action,
      notes: combinedNotes.isEmpty ? null : combinedNotes,
    );

    await _doseLogRepo.upsert(log);

    if (!mounted) return;

    final actionText = action == DoseAction.taken
        ? 'taken'
        : action == DoseAction.skipped
        ? 'skipped'
        : 'snoozed for 15 minutes';

    showAppSnackBar(context, 'Dose $actionText');

    setState(() {});
  }

  // Helper methods for dose action UI
  Color _getActionColor(BuildContext context, DoseAction action) {
    final cs = Theme.of(context).colorScheme;
    return switch (action) {
      DoseAction.taken => cs.primary,
      DoseAction.snoozed => cs.tertiary,
      DoseAction.skipped => cs.error,
    };
  }

  IconData _getActionIcon(DoseAction action) {
    return switch (action) {
      DoseAction.taken => Icons.check_circle,
      DoseAction.snoozed => Icons.snooze,
      DoseAction.skipped => Icons.cancel,
    };
  }

  String _getActionLabel(DoseAction action) {
    return switch (action) {
      DoseAction.taken => 'Taken',
      DoseAction.snoozed => 'Snoozed',
      DoseAction.skipped => 'Skipped',
    };
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Schedule>('schedules');
    final schedule = box.get(widget.scheduleId);

    if (schedule == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: kEmptyStateIconSize,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: kSpacingL),
              Text('Schedule not found', style: sectionTitleStyle(context)),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Schedule> box, _) {
        try {
          final s = box.get(widget.scheduleId) ?? schedule;
          final nextDose = _nextOccurrence(s);
          final mergedTitle = _mergedTitle(s);

          final medsBox = Hive.box<Medication>('medications');
          final medId = s.medicationId;
          final med = medId == null || medId.isEmpty
              ? null
              : medsBox.get(medId);

          return DetailPageScaffold(
            title: 'Schedule Details',
            expandedHeight: kDetailHeaderExpandedHeightCompact,
            onEdit: () => _openEditScheduleDialog(s),
            onDelete: () => _confirmDelete(context, s),
            showEditInMenu: false,
            showDeleteInMenu: false,
            statsBannerContent: ScheduleDetailHeaderBanner(
              schedule: s,
              nextDose: nextDose,
              title: mergedTitle,
              medication: med,
              onPauseResumePressed: () => _promptPauseFromHeader(context, s),
            ),
            sections: _buildSections(context, s, nextDose),
          );
        } catch (e) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(kSpacingXXL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: kEmptyStateIconSize,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: kSpacingM),
                      Text(
                        'Unable to open schedule details',
                        style: sectionTitleStyle(context),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: kSpacingM),
                      FilledButton(
                        onPressed: () => context.pop(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _promptPauseFromHeader(BuildContext context, Schedule s) async {
    final choice = await showSchedulePauseDialog(context, schedule: s);
    if (choice == null) return;

    switch (choice) {
      case SchedulePauseDialogChoice.resume:
        await _setScheduleStatus(context, s, active: true, pausedUntil: null);
        return;
      case SchedulePauseDialogChoice.pauseIndefinitely:
        await _setScheduleStatus(context, s, active: false, pausedUntil: null);
        return;
      case SchedulePauseDialogChoice.pauseUntilDate:
        final nowDate = DateUtils.dateOnly(DateTime.now());
        final picked = await showDatePicker(
          context: context,
          initialDate: nowDate.add(const Duration(days: 1)),
          firstDate: nowDate,
          lastDate: nowDate.add(const Duration(days: 365 * 10)),
        );
        if (picked == null) return;
        final endOfDay = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
          999,
        );
        await _setScheduleStatus(
          context,
          s,
          active: false,
          pausedUntil: endOfDay,
        );
        return;
    }
  }

  String _getTimeUntil(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.inMinutes < 60) {
      return 'in ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'in ${diff.inHours}h';
    } else {
      return 'in ${diff.inDays}d';
    }
  }

  String _formatDateTime(BuildContext context, DateTime dt) {
    return '${DateFormat('EEE, MMM d, y').format(dt)} • ${DateTimeFormatter.formatTime(context, dt)}';
  }

  List<Widget> _buildSections(
    BuildContext context,
    Schedule s,
    DateTime? nextDose,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: kSpacingS),
        child: TodayDosesCard(
          scope: TodayDosesScope.schedule(s.id),
          isExpanded: _isTodayExpanded,
          onExpandedChanged: (expanded) {
            if (!mounted) return;
            setState(() => _isTodayExpanded = expanded);
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: kSpacingS),
        child: CalendarCard(
          scope: CalendarCardScope.schedule(s.id),
          isExpanded: _isCalendarExpanded,
          onExpandedChanged: (expanded) {
            if (!mounted) return;
            setState(() => _isCalendarExpanded = expanded);
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: kSpacingS),
        child: ValueListenableBuilder(
          valueListenable: Hive.box<Medication>('medications').listenable(),
          builder: (context, Box<Medication> medBox, _) {
            final medId = s.medicationId;
            final med = medId == null || medId.isEmpty
                ? null
                : medBox.get(medId);

            final meds = med == null ? <Medication>[] : <Medication>[med];
            final included = med == null ? <String>{} : <String>{med.id};

            return ActivityCard(
              medications: meds,
              includedMedicationIds: included,
              rangePreset: _activityRangePreset,
              onRangePresetChanged: (next) {
                if (!mounted) return;
                setState(() => _activityRangePreset = next);
              },
              isExpanded: _isActivityExpanded,
              onExpandedChanged: (expanded) {
                if (!mounted) return;
                setState(() => _isActivityExpanded = expanded);
              },
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: kSpacingS),
        child: CollapsibleSectionFormCard(
          neutral: true,
          title: 'Schedule Details',
          titleStyle: reviewCardTitleStyle(context),
          isExpanded: _isScheduleDetailsExpanded,
          onExpandedChanged: (expanded) {
            if (!mounted) return;
            setState(() => _isScheduleDetailsExpanded = expanded);
          },
          children: _buildScheduleDetailsCardChildren(context, s),
        ),
      ),
    ];
  }

  List<Widget> _buildScheduleDetailsCardChildren(
    BuildContext context,
    Schedule s,
  ) {
    final cs = Theme.of(context).colorScheme;
    final startAtLabel = s.startAt == null
        ? 'Not set'
        : _formatDateTime(context, s.startAt!);
    final endAtLabel = s.endAt == null
        ? 'Not set'
        : _formatDateTime(context, s.endAt!);

    return [
      buildDetailInfoRow(
        context,
        label: 'Name',
        value: s.name.trim().isEmpty ? '—' : s.name,
        onTap: () => _editScheduleName(context, s),
      ),
      buildDetailInfoRow(
        context,
        label: 'Dose',
        value: _getDoseDisplay(s),
        onTap: () => _editScheduleDose(context, s),
      ),
      buildDetailInfoRow(
        context,
        label: 'Type',
        value: _scheduleTypeText(s),
        onTap: () => _editScheduleType(context, s),
        maxLines: 2,
      ),
      buildDetailInfoRow(
        context,
        label: 'Times',
        value: _timesText(context, s),
        onTap: () => _editScheduleTimes(context, s),
        maxLines: 2,
      ),
      buildDetailInfoRow(
        context,
        label: 'Start',
        value: startAtLabel,
        onTap: () => _editScheduleStart(context, s),
        maxLines: 2,
      ),
      buildDetailInfoRow(
        context,
        label: 'End',
        value: endAtLabel,
        onTap: () => _editScheduleEnd(context, s),
        maxLines: 2,
      ),
      const SizedBox(height: kSpacingL),
      Center(
        child: TextButton.icon(
          onPressed: () => _confirmDelete(context, s),
          icon: Icon(Icons.delete_outline, color: cs.error),
          label: Text(
            'Delete Schedule',
            style: helperTextStyle(context, color: cs.error),
          ),
        ),
      ),
    ];
  }

  Future<void> _setScheduleStatus(
    BuildContext context,
    Schedule s, {
    required bool active,
    required DateTime? pausedUntil,
  }) async {
    if (s.active == active && s.pausedUntil == pausedUntil) return;

    try {
      final scheduleBox = Hive.box<Schedule>('schedules');
      final updated = s.copyWith(active: active, pausedUntil: pausedUntil);

      // Update UI state fast, and do notification cancel/schedule work
      // in the background (best-effort) so we don't block the screen.
      await scheduleBox.put(s.id, updated);
      unawaited(
        Future<void>(() async {
          try {
            await ScheduleScheduler.cancelFor(s.id);
            if (updated.isActive) {
              await ScheduleScheduler.scheduleFor(updated);
            }
          } catch (_) {
            // Best-effort only.
          }
        }),
      );

      if (!mounted) return;
      showAppSnackBar(
        context,
        'Schedule set to ${scheduleStatusLabel(updated)}',
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Failed to update schedule status: $e');
    }
  }

  // ignore: unused_element
  Widget _buildNextDoseSection(
    BuildContext context,
    Schedule s,
    DateTime nextDose,
  ) {
    final existingLog = _getExistingLog(nextDose);
    final isTaken = existingLog?.action == DoseAction.taken;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingS),
      child: SectionFormCard(
        neutral: true,
        title: 'Next Dose',
        children: [
          buildDetailInfoRow(
            context,
            label: 'When',
            value:
                '${DateFormat('EEE, MMM d').format(nextDose)} • ${DateTimeFormatter.formatTime(context, nextDose)}',
            maxLines: 2,
          ),
          buildDetailInfoRow(
            context,
            label: 'Time until',
            value: _getTimeUntil(nextDose),
          ),
          if (existingLog != null)
            buildDetailInfoRow(
              context,
              label: 'Recorded',
              value:
                  '${_getActionLabel(existingLog.action)} at ${DateTimeFormatter.formatTime(context, existingLog.actionTime)}',
              highlighted: true,
            ),
          const SizedBox(height: kSpacingS),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showRecordDoseDialog(
                      schedule: s,
                      scheduledTime: nextDose,
                      action: DoseAction.taken,
                      existingLog: existingLog,
                    );
                  },
                  icon: Icon(
                    existingLog != null ? Icons.edit : Icons.check,
                    size: kIconSizeSmall,
                  ),
                  label: Text(existingLog != null ? 'Edit' : 'Take'),
                ),
              ),
              if (!isTaken) ...[
                const SizedBox(width: kSpacingS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showRecordDoseDialog(
                        schedule: s,
                        scheduledTime: nextDose,
                        action: DoseAction.snoozed,
                        existingLog: existingLog,
                      );
                    },
                    icon: Icon(Icons.snooze, size: kIconSizeSmall),
                    label: const Text('Snooze'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface.withValues(
                        alpha: kOpacityMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: kSpacingS),
                OutlinedButton(
                  onPressed: () {
                    _showRecordDoseDialog(
                      schedule: s,
                      scheduledTime: nextDose,
                      action: DoseAction.skipped,
                      existingLog: existingLog,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurface.withValues(
                      alpha: kOpacityMedium,
                    ),
                  ),
                  child: Icon(Icons.close, size: kIconSizeSmall),
                ),
              ],
            ],
          ),
          if (existingLog != null) ...[
            const SizedBox(height: kSpacingS),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getActionIcon(existingLog.action),
                  size: kIconSizeSmall,
                  color: _getActionColor(context, existingLog.action),
                ),
                const SizedBox(width: kSpacingXS),
                Text(
                  _getActionLabel(existingLog.action),
                  style: helperTextStyle(context)?.copyWith(
                    color: _getActionColor(context, existingLog.action),
                    fontWeight: kFontWeightSemiBold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Unified dose timeline showing past (with logs), today, and future doses
  // ignore: unused_element
  Widget _buildDoseTimeline(BuildContext context, Schedule s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get 7 days: 3 past + today + 3 future
    final days = List.generate(7, (i) => today.add(Duration(days: i - 3)));

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingS),
      child: SectionFormCard(
        neutral: true,
        title: 'Dose Timeline',
        children: [
          // Scrollable timeline
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isPast = date.isBefore(today);
                final hasDoses = _hasDosesOnDate(date, s);

                return _buildTimelineDay(
                  context,
                  s,
                  date,
                  isToday: isToday,
                  isPast: isPast,
                  hasDoses: hasDoses,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDay(
    BuildContext context,
    Schedule s,
    DateTime date, {
    required bool isToday,
    required bool isPast,
    required bool hasDoses,
  }) {
    if (!hasDoses) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

    final doses = _getDosesForDate(date, s);

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            children: [
              if (isToday)
                UnifiedStatusBadge(
                  label: 'TODAY',
                  icon: Icons.today_rounded,
                  color: cs.primary,
                  dense: true,
                ),
              if (isToday) const SizedBox(width: kSpacingS),
              Text(
                DateFormat('EEE, MMM d').format(date),
                style: bodyTextStyle(context)?.copyWith(
                  fontWeight: kFontWeightBold,
                  color: isToday ? cs.primary : cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingS),
          // Doses for this day
          ...doses.map((dt) {
            final existingLog = _getExistingLog(dt);
            return _buildTimelineDoseCard(
              context,
              s,
              dt,
              existingLog: existingLog,
              isPast: isPast,
              isToday: isToday,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineDoseCard(
    BuildContext context,
    Schedule s,
    DateTime dt, {
    DoseLog? existingLog,
    required bool isPast,
    required bool isToday,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isTaken = existingLog?.action == DoseAction.taken;
    final hasLog = existingLog != null;
    final accentColor = hasLog
        ? _getActionColor(context, existingLog.action)
        : (isToday ? cs.primary : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingS),
      child: UnifiedTintedCardSurface(
        accentColor: accentColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasLog ? _getActionIcon(existingLog.action) : Icons.schedule,
                  size: kIconSizeSmall,
                  color: hasLog
                      ? _getActionColor(context, existingLog.action)
                      : (isToday ? cs.primary : cs.onSurfaceVariant),
                ),
                const SizedBox(width: kSpacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateTimeFormatter.formatTime(context, dt),
                        style: cardTitleStyle(
                          context,
                        )?.copyWith(color: cs.onSurface),
                      ),
                      Text(
                        _getDoseDisplay(s),
                        style: helperTextStyle(
                          context,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasLog)
                  UnifiedStatusBadge(
                    label: _getActionLabel(existingLog.action).toUpperCase(),
                    icon: _getActionIcon(existingLog.action),
                    color: _getActionColor(context, existingLog.action),
                    dense: true,
                  ),
              ],
            ),

            // Show notes and injection site if logged
            if (hasLog && existingLog.notes != null) ...[
              const SizedBox(height: kSpacingS),
              () {
                final notes = existingLog.notes!.trim();
                final hasInjectionSite = notes.contains('Site:');
                String displayNotes = notes;
                String? injectionSite;

                if (hasInjectionSite) {
                  final parts = notes.split('Site:');
                  displayNotes = parts[0].trim();
                  injectionSite = parts.length > 1 ? parts[1].trim() : null;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (displayNotes.isNotEmpty)
                      Text(
                        displayNotes,
                        style: helperTextStyle(
                          context,
                          color: cs.onSurfaceVariant,
                        )?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    if (injectionSite != null) ...[
                      const SizedBox(height: kSpacingXS),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: kIconSizeXXSmall,
                            color: cs.primary,
                          ),
                          const SizedBox(width: kSpacingXS),
                          Text(
                            injectionSite,
                            style: helperTextStyle(
                              context,
                              color: cs.primary,
                            )?.copyWith(fontWeight: kFontWeightSemiBold),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              }(),
            ],

            // Action buttons for future or today's doses
            if (!isPast || isToday) ...[
              const SizedBox(height: kSpacingS),
              Row(
                children: [
                  if (!isTaken) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.taken,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.check, size: kIconSizeXSmall),
                        label: Text(
                          existingLog != null ? 'Edit' : 'Take',
                          style: microHelperTextStyle(
                            context,
                          )?.copyWith(fontWeight: kFontWeightSemiBold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: kDenseButtonContentPadding,
                        ),
                      ),
                    ),
                    const SizedBox(width: kSpacingXS),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.snoozed,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.snooze, size: kIconSizeXSmall),
                        label: Text(
                          'Snooze',
                          style: microHelperTextStyle(
                            context,
                          )?.copyWith(fontWeight: kFontWeightSemiBold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: kDenseButtonContentPadding,
                        ),
                      ),
                    ),
                    const SizedBox(width: kSpacingXS),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.skipped,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.close, size: kIconSizeXSmall),
                        label: Text(
                          'Skip',
                          style: microHelperTextStyle(
                            context,
                          )?.copyWith(fontWeight: kFontWeightSemiBold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: kDenseButtonContentPadding,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.taken,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.edit, size: kIconSizeXSmall),
                        label: Text(
                          'Edit',
                          style: microHelperTextStyle(
                            context,
                          )?.copyWith(fontWeight: kFontWeightSemiBold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: kDenseButtonContentPadding,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDoseDisplay(Schedule s) {
    String trimZerosNumber(double value, {int decimals = 3}) {
      final fixed = value.toStringAsFixed(decimals);
      return fixed
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }

    String formatMass(int mcg) {
      if (mcg == 0) return '0 mcg';
      if (mcg.abs() >= 1000000) {
        final g = mcg / 1000000.0;
        return '${trimZerosNumber(g, decimals: 3)} g';
      }
      if (mcg.abs() >= 1000) {
        final mg = mcg / 1000.0;
        return '${trimZerosNumber(mg, decimals: 3)} mg';
      }
      return '$mcg mcg';
    }

    String formatVolume(int microliter) {
      final ml = microliter / 1000.0;
      return '${trimZerosNumber(ml, decimals: 3)} mL';
    }

    String formatCount(double count, String singular) {
      final label = (count == 1) ? singular : '${singular}s';
      return '${trimZerosNumber(count, decimals: 3)} $label';
    }

    String? countPart;
    if (s.doseTabletQuarters != null) {
      final q = s.doseTabletQuarters!;
      final count = q / 4.0;
      String amount;
      if (q == 1) {
        amount = '1/4';
      } else if (q == 2) {
        amount = '1/2';
      } else if (q == 3) {
        amount = '3/4';
      } else if (q % 4 == 0) {
        amount = (q ~/ 4).toString();
      } else {
        amount = trimZerosNumber(count, decimals: 3);
      }

      final label = (count == 1) ? 'tablet' : 'tablets';
      countPart = '$amount $label';
    } else if (s.doseCapsules != null) {
      final count = s.doseCapsules!.toDouble();
      countPart = formatCount(count, 'capsule');
    } else if (s.doseSyringes != null) {
      final count = s.doseSyringes!.toDouble();
      countPart = formatCount(count, 'syringe');
    } else if (s.doseVials != null) {
      final count = s.doseVials!.toDouble();
      countPart = formatCount(count, 'vial');
    }

    final parts = <String>[];
    if (countPart != null && countPart.isNotEmpty) {
      parts.add(countPart);
    }

    if (s.doseMassMcg != null) {
      parts.add(formatMass(s.doseMassMcg!));
    }

    if (s.doseVolumeMicroliter != null) {
      parts.add(formatVolume(s.doseVolumeMicroliter!));
    }

    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }

    // Fallback (legacy)
    return '${_formatNumber(s.doseValue)} ${s.doseUnit}'.trim();
  }

  bool _hasDosesOnDate(DateTime date, Schedule s) {
    final onDay = s.hasCycle && s.cycleEveryNDays != null
        ? (() {
            final anchor = s.cycleAnchorDate ?? DateTime.now();
            final a = DateTime(anchor.year, anchor.month, anchor.day);
            final d0 = DateTime(date.year, date.month, date.day);
            final diff = d0.difference(a).inDays;
            return diff >= 0 && diff % s.cycleEveryNDays! == 0;
          })()
        : s.daysOfWeek.contains(date.weekday);
    return onDay;
  }

  List<DateTime> _getDosesForDate(DateTime date, Schedule s) {
    final doses = <DateTime>[];
    final onDay = _hasDosesOnDate(date, s);

    if (onDay) {
      final times = ScheduleOccurrenceService.normalizedTimesOfDay(s);
      for (final minutes in times) {
        final dt = DateTime(
          date.year,
          date.month,
          date.day,
          minutes ~/ 60,
          minutes % 60,
        );
        doses.add(dt);
      }
    }
    return doses;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _scheduleTypeText(Schedule schedule) {
    if (schedule.daysOfMonth?.isNotEmpty == true) return 'Days of month';
    if (schedule.hasCycle && schedule.cycleEveryNDays != null) {
      final n = schedule.cycleEveryNDays!;
      return 'Every $n day${n == 1 ? '' : 's'}';
    }
    final ds = schedule.daysOfWeek.toList();
    if (ds.length == 7) return 'Daily';
    return 'Days of week';
  }

  String _timesText(BuildContext context, Schedule schedule) {
    final ts = ScheduleOccurrenceService.normalizedTimesOfDay(schedule);
    return ts
        .map(
          (m) => DateTimeFormatter.formatTime(
            context,
            DateTime(0, 1, 1, m ~/ 60, m % 60),
          ),
        )
        .join('\n');
  }

  DateTime? _nextOccurrence(Schedule s) {
    return ScheduleOccurrenceService.nextOccurrence(s);
  }

  Future<void> _confirmDelete(BuildContext context, Schedule schedule) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            final cs = Theme.of(context).colorScheme;
            return AlertDialog(
              titleTextStyle: dialogTitleTextStyle(context),
              contentTextStyle: dialogContentTextStyle(context),
              title: const Text('Delete schedule?'),
              content: Text(
                'Delete "${schedule.name}"? This will cancel its notifications.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok || !context.mounted) return;

    await ScheduleScheduler.cancelFor(schedule.id);
    await Hive.box<Schedule>('schedules').delete(schedule.id);
    if (context.mounted) {
      showAppSnackBar(context, 'Deleted "${schedule.name}"');
      context.pop();
    }
  }
}

enum _ScheduleEditMode { daysOfWeek, cycle, daysOfMonth }

class _ScheduleTypeEditResult {
  _ScheduleTypeEditResult({
    required this.mode,
    required this.daysOfWeek,
    required this.cycleEvery,
    required this.cycleAnchor,
    required this.daysOfMonth,
    required this.missingDayBehavior,
  });

  final _ScheduleEditMode mode;
  final List<int> daysOfWeek;
  final int cycleEvery;
  final DateTime cycleAnchor;
  final List<int> daysOfMonth;
  final MonthlyMissingDayBehavior missingDayBehavior;
}

enum _DateEditAction { cancel, clear, set }

class _DateEditResult {
  const _DateEditResult._(this.action, this.date);

  const _DateEditResult.cancel() : this._(_DateEditAction.cancel, null);
  const _DateEditResult.clear() : this._(_DateEditAction.clear, null);
  const _DateEditResult.set(DateTime date) : this._(_DateEditAction.set, date);

  final _DateEditAction action;
  final DateTime? date;
}

/// Dialog for recording a dose with notes and optional injection site
class _DoseRecordDialog extends StatefulWidget {
  final DoseAction action;
  final DoseLog? existingLog;
  final bool isInjection;
  final TextEditingController notesController;
  final String? initialInjectionSite;

  const _DoseRecordDialog({
    required this.action,
    required this.existingLog,
    required this.isInjection,
    required this.notesController,
    this.initialInjectionSite,
  });

  @override
  State<_DoseRecordDialog> createState() => _DoseRecordDialogState();
}

class _DoseRecordDialogState extends State<_DoseRecordDialog> {
  late final TextEditingController _injectionSiteController;

  @override
  void initState() {
    super.initState();
    _injectionSiteController = TextEditingController(
      text: widget.initialInjectionSite,
    );
  }

  @override
  void dispose() {
    _injectionSiteController.dispose();
    super.dispose();
  }

  String get _actionLabel {
    return switch (widget.action) {
      DoseAction.taken => 'Take Dose',
      DoseAction.snoozed => 'Snooze Dose',
      DoseAction.skipped => 'Skip Dose',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      titleTextStyle: dialogTitleTextStyle(context),
      contentTextStyle: dialogContentTextStyle(context),
      title: Text(widget.existingLog != null ? 'Edit Dose' : _actionLabel),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notes field
            TextFormField(
              controller: widget.notesController,
              decoration: buildFieldDecoration(
                context,
                label: 'Notes (optional)',
                hint: 'Add any notes about this dose...',
              ),
              maxLines: 3,
              textCapitalization: kTextCapitalizationDefault,
            ),

            // Injection site field (only for injections)
            if (widget.isInjection) ...[
              const SizedBox(height: kSpacingM),
              TextFormField(
                controller: _injectionSiteController,
                decoration: buildFieldDecoration(
                  context,
                  label: 'Injection Site (optional)',
                  hint: 'e.g., Left arm, Right thigh...',
                ),
                textCapitalization: kTextCapitalizationDefault,
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Delete button (if editing existing log)
        if (widget.existingLog != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop({'delete': true}),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Delete'),
          ),

        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        // Save button
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            'notes': widget.notesController.text.trim(),
            'injectionSite': _injectionSiteController.text.trim(),
            'delete': false,
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
