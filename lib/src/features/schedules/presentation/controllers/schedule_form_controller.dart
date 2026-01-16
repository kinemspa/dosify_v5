import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_mode.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart'; // For DoseUnit/Mode enums

part 'schedule_form_controller.freezed.dart';

@freezed
class ScheduleFormState with _$ScheduleFormState {
  const factory ScheduleFormState({
    required ScheduleMode mode,
    DateTime? endDate,
    @Default(true) bool noEnd,
    @Default('') String name,
    @Default('') String medicationName,
    String? medicationId,
    @Default(0) double doseValue,
    @Default('mg') String doseUnit,
    @Default([TimeOfDay(hour: 9, minute: 0)]) List<TimeOfDay> times,
    @Default({1, 2, 3, 4, 5, 6, 7}) Set<int> days,
    @Default({}) Set<int> daysOfMonth,
    @Default(true) bool active,
    @Default(false) bool useCycle,
    @Default(5) int daysOn,
    @Default(2) int daysOff,
    @Default(2) int cycleN,
    required DateTime cycleAnchor,
    @Default(true) bool nameAuto,
    Medication? selectedMed,
    required DateTime startDate,
    SyringeType? selectedSyringeType,
    @Default(false) bool showMedSelector,
    // Loading/Error state
    @Default(false) bool isSaving,
    String? error,
  }) = _ScheduleFormState;
}

class ScheduleFormController
    extends AutoDisposeFamilyNotifier<ScheduleFormState, Schedule?> {
  @override
  ScheduleFormState build(Schedule? initial) {
    if (initial != null) {
      final times = initial.timesOfDay ?? [initial.minutesOfDay];
      final useCycle = initial.cycleEveryNDays != null;

      // Parse cycle days if possible
      int dOn = 5;
      int dOff = 2;
      if (useCycle) {
        final n = initial.cycleEveryNDays ?? 2;
        dOn = n ~/ 2;
        dOff = n - (n ~/ 2);
      }

      final mode = useCycle
          ? ScheduleMode.daysOnOff
          : (initial.daysOfMonth != null && initial.daysOfMonth!.isNotEmpty
                ? ScheduleMode.daysOfMonth
                : (initial.daysOfWeek.length == 7
                      ? ScheduleMode.everyDay
                      : ScheduleMode.daysOfWeek));

      return ScheduleFormState(
        mode: mode,
        endDate:
            null, // TODO: Add endDate to Schedule model if needed, currently not in model?
        noEnd:
            true, // Assuming no end date in model for now based on previous code
        name: initial.name,
        medicationName: initial.medicationName,
        medicationId: initial.medicationId,
        doseValue: initial.doseValue,
        doseUnit: initial.doseUnit,
        times: times
            .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60))
            .toList(),
        days: initial.daysOfWeek.toSet(),
        daysOfMonth: initial.daysOfMonth?.toSet() ?? {},
        active: initial.active,
        useCycle: useCycle,
        daysOn: dOn,
        daysOff: dOff,
        cycleN: initial.cycleEveryNDays ?? 2,
        cycleAnchor: initial.cycleAnchorDate ?? DateTime.now(),
        nameAuto: false, // Existing schedule name considered manual
        startDate: DateTime.now(), // TODO: Add startDate to Schedule model?
        // selectedMed: null, // We need to fetch this? Or pass it in?
        // For now, we might not have the full Medication object unless we fetch it.
        // The original code didn't load the medication object in initState,
        // it just set the name/id. But _selectedMed is needed for logic.
        // We might need to load it asynchronously.
      );
    }

    return ScheduleFormState(
      mode: ScheduleMode.everyDay,
      cycleAnchor: DateTime.now(),
      startDate: DateTime.now(),
    );
  }

  void setMode(ScheduleMode mode) {
    state = state.copyWith(mode: mode);
    // Logic from original _mode listener
    if (mode == ScheduleMode.everyDay) {
      state = state.copyWith(
        days: {1, 2, 3, 4, 5, 6, 7},
        useCycle: false,
        daysOfMonth: {},
      );
    } else if (mode == ScheduleMode.daysOfWeek) {
      state = state.copyWith(useCycle: false, daysOfMonth: {});
      if (state.days.isEmpty) {
        state = state.copyWith(days: {1, 2, 3, 4, 5});
      }
    } else if (mode == ScheduleMode.daysOnOff) {
      state = state.copyWith(useCycle: true, daysOfMonth: {});
    } else if (mode == ScheduleMode.daysOfMonth) {
      state = state.copyWith(useCycle: false);
      if (state.daysOfMonth.isEmpty) {
        state = state.copyWith(daysOfMonth: {1});
      }
    }
  }

  void setMedication(Medication med) {
    state = state.copyWith(
      selectedMed: med,
      medicationId: med.id,
      medicationName: med.name,
      showMedSelector: false,
    );

    // Set defaults
    String newUnit = state.doseUnit;
    double newValue = state.doseValue;

    switch (med.form) {
      case MedicationForm.tablet:
        newUnit = 'tablets';
        if (state.doseValue == 0) newValue = 1;
      case MedicationForm.capsule:
        newUnit = 'capsules';
        if (state.doseValue == 0) newValue = 1;
      case MedicationForm.prefilledSyringe:
        newUnit = 'syringes';
        if (state.doseValue == 0) newValue = 1;
      case MedicationForm.singleDoseVial:
        newUnit = 'vials';
        if (state.doseValue == 0) newValue = 1;
      case MedicationForm.multiDoseVial:
        final u = med.strengthUnit;
        if (u == Unit.unitsPerMl) {
          newUnit = 'IU';
        } else {
          newUnit = 'mg';
        }
        if (state.doseValue == 0) {
          if (u == Unit.mcgPerMl) {
            newValue = med.strengthValue;
            newUnit = 'mcg';
          } else if (u == Unit.mgPerMl) {
            newValue = med.strengthValue;
            newUnit = 'mg';
          } else if (u == Unit.gPerMl) {
            newValue = med.strengthValue;
            newUnit = 'g';
          } else if (u == Unit.unitsPerMl) {
            newValue = med.strengthValue;
            newUnit = 'IU';
          } else {
            newValue = 1;
          }
        }
    }

    state = state.copyWith(doseUnit: newUnit, doseValue: newValue);
    _maybeAutoName();
  }

  void updateDose(double value, String unit) {
    state = state.copyWith(doseValue: value, doseUnit: unit);
    _maybeAutoName();
  }

  void setName(String name) {
    state = state.copyWith(name: name);
    if (state.nameAuto && name.isNotEmpty) {
      state = state.copyWith(nameAuto: false);
    }
  }

  void _maybeAutoName() {
    if (!state.nameAuto) return;
    final med = state.medicationName;
    final dose = state.doseValue;
    final unit = state.doseUnit;
    if (med.isEmpty || dose == 0 || unit.isEmpty) return;

    // Simple formatting
    final doseStr = dose == dose.roundToDouble()
        ? dose.toStringAsFixed(0)
        : dose.toStringAsFixed(2);
    state = state.copyWith(name: '$med — $doseStr $unit');
  }

  void addTime(TimeOfDay time) {
    state = state.copyWith(times: [...state.times, time]);
  }

  void removeTime(int index) {
    if (index >= 0 && index < state.times.length) {
      final newTimes = [...state.times];
      newTimes.removeAt(index);
      state = state.copyWith(times: newTimes);
    }
  }

  void updateTime(int index, TimeOfDay time) {
    if (index >= 0 && index < state.times.length) {
      final newTimes = [...state.times];
      newTimes[index] = time;
      state = state.copyWith(times: newTimes);
    }
  }

  void toggleDay(int day) {
    final newDays = {...state.days};
    if (newDays.contains(day)) {
      newDays.remove(day);
    } else {
      newDays.add(day);
    }
    state = state.copyWith(days: newDays);
  }

  void toggleDayOfMonth(int day) {
    final newDays = {...state.daysOfMonth};
    if (newDays.contains(day)) {
      newDays.remove(day);
    } else {
      newDays.add(day);
    }
    state = state.copyWith(daysOfMonth: newDays);
  }

  void setStartDate(DateTime date) {
    state = state.copyWith(startDate: date);
  }

  void setEndDate(DateTime? date) {
    state = state.copyWith(endDate: date, noEnd: date == null);
  }

  void setNoEnd(bool value) {
    state = state.copyWith(noEnd: value, endDate: value ? null : state.endDate);
  }

  void setDaysOn(int days) {
    state = state.copyWith(daysOn: days);
  }

  void setDaysOff(int days) {
    state = state.copyWith(daysOff: days);
  }

  void setSyringeType(SyringeType? type) {
    state = state.copyWith(selectedSyringeType: type);
  }

  void toggleMedSelector() {
    state = state.copyWith(showMedSelector: !state.showMedSelector);
  }

  void setActive(bool active) {
    state = state.copyWith(active: active);
  }

  Future<void> save(Schedule? initialSchedule) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final id =
          initialSchedule?.id ??
          DateTime.now().microsecondsSinceEpoch.toString();
      final minutesList = state.times
          .map((t) => t.hour * 60 + t.minute)
          .toList();

      // Compute UTC fields
      final now = DateTime.now();
      int computeUtcMinutes(int localMinutes) {
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

      List<int> computeUtcDays(Set<int> localDays, int localMinutes) {
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

      final minutesUtc = computeUtcMinutes(minutesList.first);
      final timesUtc = minutesList.map(computeUtcMinutes).toList();
      final daysUtc = computeUtcDays(state.days, minutesList.first);

      // Compute typed dose normalized fields
      int? doseUnitCode;
      int? doseMassMcg;
      int? doseVolumeMicroliter;
      int? doseTabletQuarters;
      int? doseCapsules;
      int? doseSyringes;
      int? doseVials;
      int? doseIU;
      int? displayUnitCode;
      int? inputModeCode;

      final med = state.selectedMed;
      final doseVal = state.doseValue;
      final unitStr = state.doseUnit.trim().toLowerCase();

      if (med != null && doseVal > 0 && unitStr.isNotEmpty) {
        switch (med.form) {
          case MedicationForm.tablet:
            if (unitStr == 'tablets') {
              doseTabletQuarters = (doseVal * 4).round();
              // convert to mass using med.strength
              final perTabMcg = switch (med.strengthUnit) {
                Unit.mcg => med.strengthValue,
                Unit.mg => med.strengthValue * 1000,
                Unit.g => med.strengthValue * 1e6,
                Unit.units => med.strengthValue,
                Unit.mcgPerMl => med.strengthValue,
                Unit.mgPerMl => med.strengthValue * 1000,
                Unit.gPerMl => med.strengthValue * 1e6,
                Unit.unitsPerMl => med.strengthValue,
              };
              doseMassMcg = (perTabMcg * doseTabletQuarters / 4.0).round();
              doseUnitCode = DoseUnit.tablets.index;
              displayUnitCode = DoseUnit.tablets.index;
              inputModeCode = DoseInputMode.tablets.index;
            } else {
              // mass → compute tablets equivalence
              final desiredMcg = switch (unitStr) {
                'mcg' => doseVal,
                'mg' => doseVal * 1000,
                'g' => doseVal * 1e6,
                _ => doseVal,
              };
              doseMassMcg = desiredMcg.round();
              final perTabMcg = switch (med.strengthUnit) {
                Unit.mcg => med.strengthValue,
                Unit.mg => med.strengthValue * 1000,
                Unit.g => med.strengthValue * 1e6,
                Unit.units => med.strengthValue,
                Unit.mcgPerMl => med.strengthValue,
                Unit.mgPerMl => med.strengthValue * 1000,
                Unit.gPerMl => med.strengthValue * 1e6,
                Unit.unitsPerMl => med.strengthValue,
              };
              doseTabletQuarters = ((desiredMcg / perTabMcg) * 4).round();
              doseUnitCode = switch (unitStr) {
                'mcg' => DoseUnit.mcg.index,
                'mg' => DoseUnit.mg.index,
                'g' => DoseUnit.g.index,
                _ => DoseUnit.mg.index,
              };
              displayUnitCode = doseUnitCode;
              inputModeCode = DoseInputMode.mass.index;
            }
          case MedicationForm.capsule:
            if (unitStr == 'capsules') {
              doseCapsules = doseVal.round();
              final perCapMcg = switch (med.strengthUnit) {
                Unit.mcg => med.strengthValue,
                Unit.mg => med.strengthValue * 1000,
                Unit.g => med.strengthValue * 1e6,
                Unit.units => med.strengthValue,
                _ => med.strengthValue,
              };
              doseMassMcg = (perCapMcg * doseCapsules).round();
              doseUnitCode = DoseUnit.capsules.index;
              displayUnitCode = DoseUnit.capsules.index;
              inputModeCode = DoseInputMode.capsules.index;
            } else {
              final desiredMcg = switch (unitStr) {
                'mcg' => doseVal,
                'mg' => doseVal * 1000,
                'g' => doseVal * 1e6,
                _ => doseVal,
              };
              doseMassMcg = desiredMcg.round();
              final perCapMcg = switch (med.strengthUnit) {
                Unit.mcg => med.strengthValue,
                Unit.mg => med.strengthValue * 1000,
                Unit.g => med.strengthValue * 1e6,
                Unit.units => med.strengthValue,
                _ => med.strengthValue,
              };
              doseCapsules = (desiredMcg / perCapMcg).round();
              doseUnitCode = switch (unitStr) {
                'mcg' => DoseUnit.mcg.index,
                'mg' => DoseUnit.mg.index,
                'g' => DoseUnit.g.index,
                _ => DoseUnit.mg.index,
              };
              displayUnitCode = doseUnitCode;
              inputModeCode = DoseInputMode.mass.index;
            }
          case MedicationForm.prefilledSyringe:
            doseSyringes = doseVal.round();
            doseUnitCode = DoseUnit.syringes.index;
            displayUnitCode = DoseUnit.syringes.index;
            inputModeCode = DoseInputMode.count.index;
          case MedicationForm.singleDoseVial:
            doseVials = doseVal.round();
            doseUnitCode = DoseUnit.vials.index;
            displayUnitCode = DoseUnit.vials.index;
            inputModeCode = DoseInputMode.count.index;
          case MedicationForm.multiDoseVial:
            // Allow mg/mcg/g, IU/units or mL
            double? mgPerMl;
            double? iuPerMl;
            switch (med.strengthUnit) {
              case Unit.mgPerMl:
                mgPerMl = med.perMlValue ?? med.strengthValue;
              case Unit.mcgPerMl:
                mgPerMl = (med.perMlValue ?? med.strengthValue) / 1000.0;
              case Unit.gPerMl:
                mgPerMl = (med.perMlValue ?? med.strengthValue) * 1000.0;
              case Unit.unitsPerMl:
                iuPerMl = med.perMlValue ?? med.strengthValue;
              default:
                break;
            }
            if (unitStr == 'ml') {
              final ml = doseVal;
              doseVolumeMicroliter = (ml * 1000).round();
              if (mgPerMl != null) doseMassMcg = (ml * mgPerMl * 1000).round();
              if (iuPerMl != null) doseIU = (ml * iuPerMl).round();
              doseUnitCode = DoseUnit.ml.index;
              displayUnitCode = DoseUnit.ml.index;
              inputModeCode = DoseInputMode.volume.index;
            } else if (unitStr == 'iu' || unitStr == 'units') {
              if (iuPerMl != null) {
                final ml = doseVal / iuPerMl;
                doseIU = doseVal.round();
                doseVolumeMicroliter = (ml * 1000).round();
                doseUnitCode = DoseUnit.iu.index;
                displayUnitCode = DoseUnit.iu.index;
                inputModeCode = DoseInputMode.iuUnits.index;
              }
            } else {
              // mg/mcg/g
              if (mgPerMl != null) {
                final desiredMg = switch (unitStr) {
                  'mg' => doseVal,
                  'mcg' => doseVal / 1000.0,
                  'g' => doseVal * 1000.0,
                  _ => doseVal,
                };
                final ml = desiredMg / mgPerMl;
                doseMassMcg = (desiredMg * 1000).round();
                doseVolumeMicroliter = (ml * 1000).round();
                doseUnitCode = switch (unitStr) {
                  'mcg' => DoseUnit.mcg.index,
                  'mg' => DoseUnit.mg.index,
                  'g' => DoseUnit.g.index,
                  _ => DoseUnit.mg.index,
                };
                displayUnitCode = doseUnitCode;
                inputModeCode = DoseInputMode.mass.index;
              }
            }
        }
      }

      final s = Schedule(
        id: id,
        name: state.name.trim(),
        medicationName: state.medicationName.trim(),
        doseValue: state.doseValue,
        doseUnit: state.doseUnit.trim(),
        minutesOfDay: minutesList.first,
        daysOfWeek: state.days.toList()..sort(),
        minutesOfDayUtc: minutesUtc,
        daysOfWeekUtc: daysUtc,
        medicationId: state.medicationId,
        active: state.active,
        timesOfDay: minutesList,
        timesOfDayUtc: timesUtc,
        cycleEveryNDays: state.useCycle ? state.cycleN : null,
        cycleAnchorDate: state.useCycle
            ? DateTime(
                state.cycleAnchor.year,
                state.cycleAnchor.month,
                state.cycleAnchor.day,
              )
            : null,
        daysOfMonth: state.daysOfMonth.isNotEmpty
            ? (state.daysOfMonth.toList()..sort())
            : null,
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
        startAt: () {
          final now = DateTime.now();
          final selectedDay = DateTime(
            state.startDate.year,
            state.startDate.month,
            state.startDate.day,
          );
          final today = DateTime(now.year, now.month, now.day);
          if (selectedDay.isAtSameMomentAs(today)) return now;
          return selectedDay;
        }(),
        endAt: state.noEnd || state.endDate == null
            ? null
            : DateTime(
                state.endDate!.year,
                state.endDate!.month,
                state.endDate!.day,
                23,
                59,
                59,
                999,
              ),
      );

      final box = Hive.box<Schedule>('schedules');

      // Cancel existing notifications for this schedule id (handles edits)
      await ScheduleScheduler.cancelFor(id);
      await box.put(id, s);

      // Schedule notifications if active
      if (s.isActive) {
        await ScheduleScheduler.scheduleFor(s);
      }

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      rethrow;
    }
  }
}

final scheduleFormProvider =
    AutoDisposeNotifierProviderFamily<
      ScheduleFormController,
      ScheduleFormState,
      Schedule?
    >(ScheduleFormController.new);
