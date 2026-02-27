import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/reports/domain/csv_export_service.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

void main() {
  const csv = CsvExportService();

  test('CSV escape quotes values with commas/quotes/newlines', () {
    expect(csv.escape('plain'), equals('plain'));
    expect(csv.escape('a,b'), equals('"a,b"'));
    expect(csv.escape('a"b'), equals('"a""b"'));
    expect(csv.escape('a\nb'), equals('"a\nb"'));
    expect(csv.escape('a\rb'), equals('"a\rb"'));
  });

  test('Medications CSV is stably ordered by name then id', () {
    final m1 = Medication(
      id: 'b',
      form: MedicationForm.tablet,
      name: 'Zeta',
      strengthValue: 1,
      strengthUnit: Unit.mg,
      stockValue: 1,
      stockUnit: StockUnit.tablets,
    );
    final m2 = Medication(
      id: 'a',
      form: MedicationForm.tablet,
      name: 'Alpha',
      strengthValue: 1,
      strengthUnit: Unit.mg,
      stockValue: 1,
      stockUnit: StockUnit.tablets,
    );

    final out = csv.medicationsToCsv([m1, m2]);
    final lines = out.trim().split('\n');
    // header + 2 rows
    expect(lines.length, equals(3));
    expect(lines[1].startsWith('a,Alpha,'), isTrue);
    expect(lines[2].startsWith('b,Zeta,'), isTrue);
  });

  test('Dose logs CSV is stably ordered by actionTime desc then id', () {
    final t0 = DateTime.utc(2026, 1, 1, 12);
    final t1 = DateTime.utc(2026, 1, 2, 12);

    final l1 = DoseLog(
      id: 'b',
      scheduleId: 's',
      scheduleName: 'Sched',
      medicationId: 'm',
      medicationName: 'Med',
      scheduledTime: t0,
      actionTime: t0,
      doseValue: 1,
      doseUnit: 'mg',
      action: DoseAction.logged,
    );
    final l2 = DoseLog(
      id: 'a',
      scheduleId: 's',
      scheduleName: 'Sched',
      medicationId: 'm',
      medicationName: 'Med',
      scheduledTime: t1,
      actionTime: t1,
      doseValue: 1,
      doseUnit: 'mg',
      action: DoseAction.logged,
    );

    final out = csv.doseLogsToCsv([l1, l2]);
    final lines = out.trim().split('\n');
    expect(lines.length, equals(3));
    // Newest first
    expect(lines[1].startsWith('a,'), isTrue);
    expect(lines[2].startsWith('b,'), isTrue);
  });

  test('Inventory logs CSV supports time range filtering', () {
    final t0 = DateTime.utc(2026, 1, 1, 12);
    final t1 = DateTime.utc(2026, 1, 2, 12);

    final i1 = InventoryLog(
      id: 'old',
      medicationId: 'm',
      medicationName: 'Med',
      changeType: InventoryChangeType.manualAdjustment,
      previousStock: 0,
      newStock: 1,
      changeAmount: 1,
      timestamp: t0,
    );
    final i2 = InventoryLog(
      id: 'new',
      medicationId: 'm',
      medicationName: 'Med',
      changeType: InventoryChangeType.manualAdjustment,
      previousStock: 1,
      newStock: 2,
      changeAmount: 1,
      timestamp: t1,
    );

    final range = UtcTimeRange(
      startInclusiveUtc: DateTime.utc(2026, 1, 2, 0),
      endExclusiveUtc: DateTime.utc(2026, 1, 3, 0),
    );

    final out = csv.inventoryLogsToCsv([i1, i2], range: range);
    final lines = out.trim().split('\n');
    expect(lines.length, equals(2));
    expect(lines[1].startsWith('new,'), isTrue);
  });

  test('Schedules CSV is stably ordered by name then id', () {
    final s1 = Schedule(
      id: 'b',
      name: 'Zeta',
      medicationName: 'Med',
      doseValue: 1,
      doseUnit: 'mg',
      minutesOfDay: 60,
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
    );
    final s2 = Schedule(
      id: 'a',
      name: 'Alpha',
      medicationName: 'Med',
      doseValue: 1,
      doseUnit: 'mg',
      minutesOfDay: 60,
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
    );

    final out = csv.schedulesToCsv([s1, s2]);
    final lines = out.trim().split('\n');
    expect(lines.length, equals(3));
    expect(lines[1].startsWith('a,Alpha,'), isTrue);
    expect(lines[2].startsWith('b,Zeta,'), isTrue);
  });

  test('ReportTimeRange presets create UTC time ranges', () {
    const r = ReportTimeRange(ReportTimeRangePreset.last7Days);
    final now = DateTime.utc(2026, 1, 8, 0);
    final range = r.toUtcTimeRange(nowUtc: now)!;
    expect(range.endExclusiveUtc, equals(now));
    expect(range.startInclusiveUtc, equals(DateTime.utc(2026, 1, 1, 0)));
  });
}
