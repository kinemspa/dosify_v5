import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

class TestDataSeedService {
  static const String _prefsKey = 'test_data_seeded_v1';

  static const String _medIdTablet = 'test_med_tablet';
  static const String _medIdCapsule = 'test_med_capsule';
  static const String _medIdPfs = 'test_med_prefilled_syringe';
  static const String _medIdSdv = 'test_med_single_dose_vial';
  static const String _medIdMdv = 'test_med_multi_dose_vial';

  static const String _schedulePrefix = 'test_sched_';

  static Future<bool> isSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> setSeeded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  static Future<void> seed() async {
    final meds = Hive.box<Medication>('medications');
    final schedules = Hive.box<Schedule>('schedules');

    // Idempotency: if any of our test meds exist, treat as seeded.
    final already =
        meds.containsKey(_medIdTablet) ||
        meds.containsKey(_medIdCapsule) ||
        meds.containsKey(_medIdPfs) ||
        meds.containsKey(_medIdSdv) ||
        meds.containsKey(_medIdMdv);

    if (already) {
      await setSeeded(true);
      return;
    }

    final now = DateTime.now();

    final tablet = Medication(
      id: _medIdTablet,
      form: MedicationForm.tablet,
      name: 'Test Tablet',
      strengthValue: 50,
      strengthUnit: Unit.mg,
      stockValue: 30,
      stockUnit: StockUnit.tablets,
      description: 'Sample tablet medication for UI testing.',
    );

    final capsule = Medication(
      id: _medIdCapsule,
      form: MedicationForm.capsule,
      name: 'Test Capsule',
      strengthValue: 25,
      strengthUnit: Unit.mg,
      stockValue: 20,
      stockUnit: StockUnit.capsules,
      description: 'Sample capsule medication for UI testing.',
    );

    final pfs = Medication(
      id: _medIdPfs,
      form: MedicationForm.prefilledSyringe,
      name: 'Test Prefilled Syringe',
      strengthValue: 5,
      strengthUnit: Unit.mgPerMl,
      stockValue: 10,
      stockUnit: StockUnit.preFilledSyringes,
      volumePerDose: 0.5,
      volumeUnit: VolumeUnit.ml,
      description: 'Sample prefilled syringe for UI testing.',
    );

    final sdv = Medication(
      id: _medIdSdv,
      form: MedicationForm.singleDoseVial,
      name: 'Test Single Dose Vial',
      strengthValue: 1,
      strengthUnit: Unit.mg,
      stockValue: 8,
      stockUnit: StockUnit.singleDoseVials,
      description: 'Sample single-dose vial for UI testing.',
    );

    final mdv = Medication(
      id: _medIdMdv,
      form: MedicationForm.multiDoseVial,
      name: 'Test Multi Dose Vial',
      strengthValue: 10,
      strengthUnit: Unit.mgPerMl,
      stockValue: 2,
      stockUnit: StockUnit.multiDoseVials,
      containerVolumeMl: 10,
      activeVialVolume: 10,
      diluentName: 'Test Diluent',
      description: 'Sample multi-dose vial for UI testing.',
    );

    await meds.putAll({
      tablet.id: tablet,
      capsule.id: capsule,
      pfs.id: pfs,
      sdv.id: sdv,
      mdv.id: mdv,
    });

    final s1 = Schedule(
      id: '${_schedulePrefix}tablet_daily',
      name: '1 Tablet',
      medicationName: tablet.name,
      medicationId: tablet.id,
      doseValue: 1,
      doseUnit: 'tablets',
      minutesOfDay: 9 * 60,
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
      timesOfDay: const [9 * 60],
      startAt: now,
    );

    final s2 = Schedule(
      id: '${_schedulePrefix}capsule_weekly',
      name: '1 Capsule',
      medicationName: capsule.name,
      medicationId: capsule.id,
      doseValue: 1,
      doseUnit: 'capsules',
      minutesOfDay: 8 * 60,
      daysOfWeek: const [1, 3, 5],
      timesOfDay: const [8 * 60, 20 * 60],
      startAt: now,
    );

    final s3 = Schedule(
      id: '${_schedulePrefix}pfs_cycle',
      name: 'Injection (every 2 days)',
      medicationName: pfs.name,
      medicationId: pfs.id,
      doseValue: 1,
      doseUnit: 'syringes',
      minutesOfDay: 7 * 60 + 30,
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
      timesOfDay: const [7 * 60 + 30],
      cycleEveryNDays: 2,
      cycleAnchorDate: DateTime(now.year, now.month, now.day),
      startAt: now,
    );

    final s4 = Schedule(
      id: '${_schedulePrefix}sdv_monthly_31',
      name: 'Monthly (31st)',
      medicationName: sdv.name,
      medicationId: sdv.id,
      doseValue: 1,
      doseUnit: 'vials',
      minutesOfDay: 9 * 60,
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
      timesOfDay: const [9 * 60],
      daysOfMonth: const [31],
      monthlyMissingDayBehaviorCode: MonthlyMissingDayBehavior.lastDay.index,
      startAt: now,
    );

    final s5 = Schedule(
      id: '${_schedulePrefix}mdv_weekly',
      name: 'MDV (weekly)',
      medicationName: mdv.name,
      medicationId: mdv.id,
      doseValue: 0.25,
      doseUnit: 'ml',
      minutesOfDay: 10 * 60,
      daysOfWeek: const [2],
      timesOfDay: const [10 * 60],
      startAt: now,
    );

    await schedules.putAll({
      s1.id: s1,
      s2.id: s2,
      s3.id: s3,
      s4.id: s4,
      s5.id: s5,
    });

    await setSeeded(true);
  }

  static Future<void> clear() async {
    final meds = Hive.box<Medication>('medications');
    final schedules = Hive.box<Schedule>('schedules');

    final scheduleIds = schedules.keys
        .cast<String>()
        .where((id) => id.startsWith(_schedulePrefix))
        .toList(growable: false);

    for (final id in scheduleIds) {
      await schedules.delete(id);
    }

    await meds.delete(_medIdTablet);
    await meds.delete(_medIdCapsule);
    await meds.delete(_medIdPfs);
    await meds.delete(_medIdSdv);
    await meds.delete(_medIdMdv);

    await setSeeded(false);
  }
}
