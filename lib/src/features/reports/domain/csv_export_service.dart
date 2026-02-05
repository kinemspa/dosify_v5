import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

class CsvExportService {
  const CsvExportService();

  String escape(String value) {
    final needsQuotes = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;

    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String medicationsToCsv(Iterable<Medication> meds) {
    final items = meds.toList(growable: false)
      ..sort(
        (a, b) => a.name.toLowerCase() == b.name.toLowerCase()
            ? a.id.compareTo(b.id)
            : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    final header = [
      'id',
      'name',
      'form',
      'manufacturer',
      'strengthValue',
      'strengthUnit',
      'stockValue',
      'stockUnit',
      'createdAtUtc',
      'updatedAtUtc',
    ].join(',');

    final rows = items.map((m) {
      return [
        escape(m.id),
        escape(m.name),
        escape(m.form.name),
        escape(m.manufacturer ?? ''),
        escape(m.strengthValue.toString()),
        escape(m.strengthUnit.name),
        escape(m.stockValue.toString()),
        escape(m.stockUnit.name),
        escape(m.createdAt.toUtc().toIso8601String()),
        escape(m.updatedAt.toUtc().toIso8601String()),
      ].join(',');
    }).join('\n');

    return '$header\n$rows\n';
  }

  String schedulesToCsv(Iterable<Schedule> schedules) {
    final items = schedules.toList(growable: false)
      ..sort(
        (a, b) => a.name.toLowerCase() == b.name.toLowerCase()
            ? a.id.compareTo(b.id)
            : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    final header = [
      'id',
      'name',
      'medicationId',
      'medicationName',
      'active',
      'startAtUtc',
      'endAtUtc',
      'doseValue',
      'doseUnit',
      'daysOfWeek',
      'timesOfDay',
      'createdAtUtc',
    ].join(',');

    final rows = items.map((s) {
      return [
        escape(s.id),
        escape(s.name),
        escape(s.medicationId ?? ''),
        escape(s.medicationName),
        escape(s.active.toString()),
        escape(s.startAt?.toUtc().toIso8601String() ?? ''),
        escape(s.endAt?.toUtc().toIso8601String() ?? ''),
        escape(s.doseValue.toString()),
        escape(s.doseUnit),
        escape(s.daysOfWeek.join('|')),
        escape((s.timesOfDay ?? const <int>[]).join('|')),
        escape(s.createdAt.toUtc().toIso8601String()),
      ].join(',');
    }).join('\n');

    return '$header\n$rows\n';
  }

  String doseLogsToCsv(
    Iterable<DoseLog> logs, {
    UtcTimeRange? range,
  }) {
    final filtered = logs.where((l) => range == null || range.contains(l.actionTime));
    final items = filtered.toList(growable: false)
      ..sort(
        (a, b) => a.actionTime == b.actionTime
            ? a.id.compareTo(b.id)
            : b.actionTime.compareTo(a.actionTime),
      );

    final header = [
      'id',
      'medicationName',
      'scheduleName',
      'scheduledTimeUtc',
      'actionTimeUtc',
      'action',
      'doseValue',
      'doseUnit',
      'actualDoseValue',
      'actualDoseUnit',
      'notes',
    ].join(',');

    final rows = items.map((l) {
      return [
        escape(l.id),
        escape(l.medicationName),
        escape(l.scheduleName),
        escape(l.scheduledTime.toUtc().toIso8601String()),
        escape(l.actionTime.toUtc().toIso8601String()),
        escape(l.action.name),
        escape(l.doseValue.toString()),
        escape(l.doseUnit),
        escape(l.actualDoseValue?.toString() ?? ''),
        escape(l.actualDoseUnit ?? ''),
        escape(l.notes ?? ''),
      ].join(',');
    }).join('\n');

    return '$header\n$rows\n';
  }

  String inventoryLogsToCsv(
    Iterable<InventoryLog> logs, {
    UtcTimeRange? range,
  }) {
    final filtered = logs.where((l) => range == null || range.contains(l.timestamp));
    final items = filtered.toList(growable: false)
      ..sort(
        (a, b) => a.timestamp == b.timestamp
            ? a.id.compareTo(b.id)
            : b.timestamp.compareTo(a.timestamp),
      );

    final header = [
      'id',
      'medicationId',
      'medicationName',
      'timestampUtc',
      'changeType',
      'previousStock',
      'newStock',
      'changeAmount',
      'notes',
    ].join(',');

    final rows = items.map((l) {
      return [
        escape(l.id),
        escape(l.medicationId),
        escape(l.medicationName),
        escape(l.timestamp.toUtc().toIso8601String()),
        escape(l.changeType.name),
        escape(l.previousStock.toString()),
        escape(l.newStock.toString()),
        escape(l.changeAmount.toString()),
        escape(l.notes ?? ''),
      ].join(',');
    }).join('\n');

    return '$header\n$rows\n';
  }
}
