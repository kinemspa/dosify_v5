import 'package:flutter_test/flutter_test.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';

void main() {
  test('MDV: decrement active vial without touching stock', () {
    final med = Medication(
      id: 'm1',
      form: MedicationForm.multiDoseVial,
      name: 'Test MDV',
      strengthValue: 1.0,
      strengthUnit: Unit.mgPerMl,
      stockValue: 2.0,
      stockUnit: StockUnit.multiDoseVials,
      containerVolumeMl: 10.0,
      activeVialVolume: 3.0,
    );

    final s = Schedule(
      id: 's1',
      name: 'dose1',
      medicationName: med.name,
      doseValue: 1.0,
      doseUnit: 'mL',
      minutesOfDay: 60,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      doseVolumeMicroliter: 2000, // 2 mL
    );

    final updated = applyDoseTakenUpdate(med, s)!;
    expect(updated.activeVialVolume, closeTo(1.0, 0.0001));
    expect(updated.stockValue, equals(2.0));
  });

  test('MDV: overflow opens new vial and decrements backup', () {
    final med = Medication(
      id: 'm2',
      form: MedicationForm.multiDoseVial,
      name: 'Test MDV 2',
      strengthValue: 1.0,
      strengthUnit: Unit.mgPerMl,
      stockValue: 2.0,
      stockUnit: StockUnit.multiDoseVials,
      containerVolumeMl: 10.0,
      activeVialVolume: 3.0,
    );

    final s = Schedule(
      id: 's2',
      name: 'dose2',
      medicationName: med.name,
      doseValue: 1.0,
      doseUnit: 'mL',
      minutesOfDay: 60,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      doseVolumeMicroliter: 4000, // 4 mL
    );

    final updated = applyDoseTakenUpdate(med, s)!;
    // new active = 10 + (3 - 4) = 9
    expect(updated.activeVialVolume, closeTo(9.0, 0.001));
    expect(updated.stockValue, equals(1.0));
  });

  test('Tablets decrement by quarters', () {
    final med = Medication(
      id: 'm3',
      form: MedicationForm.tablet,
      name: 'Test Tabs',
      strengthValue: 10.0,
      strengthUnit: Unit.mg,
      stockValue: 10.0,
      stockUnit: StockUnit.tablets,
    );

    final s = Schedule(
      id: 's3',
      name: 'dose3',
      medicationName: med.name,
      doseValue: 1.0,
      doseUnit: 'tab',
      minutesOfDay: 60,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      doseTabletQuarters: 4,
    );

    final updated = applyDoseTakenUpdate(med, s)!;
    expect(updated.stockValue, equals(9.0));
  });
}
