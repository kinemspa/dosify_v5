import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_mode.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_calculator.dart'; // For EntryUnit/Mode enums

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
    @Default(0) double entryValue,
    @Default('mg') String entryUnit,
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
        endDate: initial.endAt,
        noEnd: initial.endAt == null,
        name: initial.name,
        medicationName: initial.medicationName,
        medicationId: initial.medicationId,
        entryValue: initial.entryValue,
        entryUnit: initial.entryUnit,
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
        startDate: initial.startAt ?? DateTime.now(),
        selectedMed: initial.medicationId != null
            ? Hive.box<Medication>('medications').get(initial.medicationId)
            : null,
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
    String newUnit = state.entryUnit;
    double newValue = state.entryValue;

    switch (med.form) {
      case MedicationForm.tablet:
        newUnit = 'tablets';
        if (state.entryValue == 0) newValue = 1;
      case MedicationForm.capsule:
        newUnit = 'capsules';
        if (state.entryValue == 0) newValue = 1;
      case MedicationForm.prefilledSyringe:
        newUnit = 'syringes';
        if (state.entryValue == 0) newValue = 1;
      case MedicationForm.singleDoseVial:
        newUnit = 'vials';
        if (state.entryValue == 0) newValue = 1;
      case MedicationForm.multiDoseVial:
        final u = med.strengthUnit;
        if (u == Unit.unitsPerMl) {
          newUnit = 'IU';
        } else {
          newUnit = 'mg';
        }
        if (state.entryValue == 0) {
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

    state = state.copyWith(entryUnit: newUnit, entryValue: newValue);
    _maybeAutoName();
  }

  void updateEntry(double value, String unit) {
    state = state.copyWith(entryValue: value, entryUnit: unit);
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
    final entry = state.entryValue;
    final unit = state.entryUnit;
    if (med.isEmpty || entry == 0 || unit.isEmpty) return;

    // Simple formatting
    final entryStr = entry == entry.roundToDouble()
        ? entry.toStringAsFixed(0)
        : entry.toStringAsFixed(2);
    state = state.copyWith(name: '$med — $entryStr $unit');
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

      // Compute typed entry normalized fields
      int? entryUnitCode;
      int? entryMassMcg;
      int? entryVolumeMicroliter;
      int? entryTabletQuarters;
      int? entryCapsules;
      int? entrySyringes;
      int? entryVials;
      int? entryIU;
      int? displayUnitCode;
      int? inputModeCode;

      final med = state.selectedMed;
      final entryVal = state.entryValue;
      final unitStr = state.entryUnit.trim().toLowerCase();

      if (med != null && entryVal > 0 && unitStr.isNotEmpty) {
        switch (med.form) {
          case MedicationForm.tablet:
            if (unitStr == 'tablets') {
              entryTabletQuarters = (entryVal * 4).round();
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
              entryMassMcg = (perTabMcg * entryTabletQuarters / 4.0).round();
              entryUnitCode = EntryUnit.tablets.index;
              displayUnitCode = EntryUnit.tablets.index;
              inputModeCode = EntryInputMode.tablets.index;
            } else {
              // mass → compute tablets equivalence
              final desiredMcg = switch (unitStr) {
                'mcg' => entryVal,
                'mg' => entryVal * 1000,
                'g' => entryVal * 1e6,
                _ => entryVal,
              };
              entryMassMcg = desiredMcg.round();
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
              entryTabletQuarters = ((desiredMcg / perTabMcg) * 4).round();
              entryUnitCode = switch (unitStr) {
                'mcg' => EntryUnit.mcg.index,
                'mg' => EntryUnit.mg.index,
                'g' => EntryUnit.g.index,
                _ => EntryUnit.mg.index,
              };
              displayUnitCode = entryUnitCode;
              inputModeCode = EntryInputMode.mass.index;
            }
          case MedicationForm.capsule:
            if (unitStr == 'capsules') {
              entryCapsules = entryVal.round();
              final perCapMcg = switch (med.strengthUnit) {
                Unit.mcg => med.strengthValue,
                Unit.mg => med.strengthValue * 1000,
                Unit.g => med.strengthValue * 1e6,
                Unit.units => med.strengthValue,
                _ => med.strengthValue,
              };
              entryMassMcg = (perCapMcg * entryCapsules).round();
              entryUnitCode = EntryUnit.capsules.index;
              displayUnitCode = EntryUnit.capsules.index;
              inputModeCode = EntryInputMode.capsules.index;
            } else {
              final desiredMcg = switch (unitStr) {
                'mcg' => entryVal,
                'mg' => entryVal * 1000,
                'g' => entryVal * 1e6,
                _ => entryVal,
              };
              entryMassMcg = desiredMcg.round();
              final perCapMcg = switch (med.strengthUnit) {
                Unit.mcg => med.strengthValue,
                Unit.mg => med.strengthValue * 1000,
                Unit.g => med.strengthValue * 1e6,
                Unit.units => med.strengthValue,
                _ => med.strengthValue,
              };
              entryCapsules = (desiredMcg / perCapMcg).round();
              entryUnitCode = switch (unitStr) {
                'mcg' => EntryUnit.mcg.index,
                'mg' => EntryUnit.mg.index,
                'g' => EntryUnit.g.index,
                _ => EntryUnit.mg.index,
              };
              displayUnitCode = entryUnitCode;
              inputModeCode = EntryInputMode.mass.index;
            }
          case MedicationForm.prefilledSyringe:
            entrySyringes = entryVal.round();
            entryUnitCode = EntryUnit.syringes.index;
            displayUnitCode = EntryUnit.syringes.index;
            inputModeCode = EntryInputMode.count.index;
          case MedicationForm.singleDoseVial:
            entryVials = entryVal.round();
            entryUnitCode = EntryUnit.vials.index;
            displayUnitCode = EntryUnit.vials.index;
            inputModeCode = EntryInputMode.count.index;
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
              final ml = entryVal;
              entryVolumeMicroliter = (ml * 1000).round();
              if (mgPerMl != null) entryMassMcg = (ml * mgPerMl * 1000).round();
              if (iuPerMl != null) entryIU = (ml * iuPerMl).round();
              entryUnitCode = EntryUnit.ml.index;
              displayUnitCode = EntryUnit.ml.index;
              inputModeCode = EntryInputMode.volume.index;
            } else if (unitStr == 'iu' || unitStr == 'units') {
              if (iuPerMl != null) {
                final ml = entryVal / iuPerMl;
                entryIU = entryVal.round();
                entryVolumeMicroliter = (ml * 1000).round();
                entryUnitCode = EntryUnit.iu.index;
                displayUnitCode = EntryUnit.iu.index;
                inputModeCode = EntryInputMode.iuUnits.index;
              }
            } else {
              // mg/mcg/g
              if (mgPerMl != null) {
                final desiredMg = switch (unitStr) {
                  'mg' => entryVal,
                  'mcg' => entryVal / 1000.0,
                  'g' => entryVal * 1000.0,
                  _ => entryVal,
                };
                final ml = desiredMg / mgPerMl;
                entryMassMcg = (desiredMg * 1000).round();
                entryVolumeMicroliter = (ml * 1000).round();
                entryUnitCode = switch (unitStr) {
                  'mcg' => EntryUnit.mcg.index,
                  'mg' => EntryUnit.mg.index,
                  'g' => EntryUnit.g.index,
                  _ => EntryUnit.mg.index,
                };
                displayUnitCode = entryUnitCode;
                inputModeCode = EntryInputMode.mass.index;
              }
            }
        }
      }

      final s = Schedule(
        id: id,
        name: state.name.trim(),
        medicationName: state.medicationName.trim(),
        entryValue: state.entryValue,
        entryUnit: state.entryUnit.trim(),
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
        entryUnitCode: entryUnitCode,
        entryMassMcg: entryMassMcg,
        entryVolumeMicroliter: entryVolumeMicroliter,
        entryTabletQuarters: entryTabletQuarters,
        entryCapsules: entryCapsules,
        entrySyringes: entrySyringes,
        entryVials: entryVials,
        entryIU: entryIU,
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
