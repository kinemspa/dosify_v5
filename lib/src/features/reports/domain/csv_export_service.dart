import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/inventory_log.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/reports/domain/report_time_range.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';

class CsvExportService {
  const CsvExportService();

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i += 1;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    values.add(buffer.toString());
    return values;
  }

  String csvToHtmlDocument({required String title, required String csv}) {
    final lines = csv
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      return '<!doctype html><html><head><meta charset="utf-8"><title>${_escapeHtml(title)}</title></head><body><h1>${_escapeHtml(title)}</h1><p>No data</p></body></html>';
    }

    final header = _parseCsvLine(lines.first);
    final rows = lines.skip(1).map(_parseCsvLine).toList(growable: false);

    final headerHtml = header.map((h) => '<th>${_escapeHtml(h)}</th>').join();
    final rowHtml = rows
        .map(
          (row) =>
              '<tr>${row.map((c) => '<td>${_escapeHtml(c)}</td>').join()}</tr>',
        )
        .join();

    return '''
  <!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>${_escapeHtml(title)}</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 16px; }
      h1 { margin-bottom: 12px; }
      table { border-collapse: collapse; width: 100%; }
      th, td { border: 1px solid #d0d7de; padding: 8px; text-align: left; }
      th { background: #f6f8fa; }
      tr:nth-child(even) td { background: #fbfcfd; }
    </style>
  </head>
  <body>
    <h1>${_escapeHtml(title)}</h1>
    <table>
      <thead><tr>$headerHtml</tr></thead>
      <tbody>$rowHtml</tbody>
    </table>
  </body>
</html>''';
  }

  // ── plain-text helpers ──────────────────────────────────────────────────

  /// Local datetime as dd/MM/yyyy HH:mm.
  String _fmtDate(DateTime dt) {
    final l = dt.toLocal();
    final d = l.day.toString().padLeft(2, '0');
    final mo = l.month.toString().padLeft(2, '0');
    final h = l.hour.toString().padLeft(2, '0');
    final mi = l.minute.toString().padLeft(2, '0');
    return '$d/$mo/${l.year} $h:$mi';
  }

  /// Medication form → plain English label.
  static String _formLabel(MedicationForm form) => switch (form) {
    MedicationForm.tablet => 'Tablet',
    MedicationForm.capsule => 'Capsule',
    MedicationForm.prefilledSyringe => 'Pre-filled Syringe',
    MedicationForm.singleDoseVial => 'Single-Dose Vial',
    MedicationForm.multiDoseVial => 'Multi-Dose Vial',
  };

  /// Entry action enum name → plain English.
  static String _actionLabel(String name) => switch (name) {
    'logged' => 'Logged',
    'snoozed' => 'Snoozed',
    'skipped' => 'Skipped',
    'missed' => 'Missed',
    _ => '${name[0].toUpperCase()}${name.substring(1)}',
  };

  /// Inventory change type → plain English.
  static String _changeTypeLabel(InventoryChangeType t) => switch (t) {
    InventoryChangeType.refillAdd => 'Stock Added',
    InventoryChangeType.refillToMax => 'Refilled to Max',
    InventoryChangeType.entryDeducted => 'Entry Deducted',
    InventoryChangeType.adHocEntry => 'Ad-hoc Entry',
    InventoryChangeType.manualAdjustment => 'Manual Adjustment',
    InventoryChangeType.vialOpened => 'Vial Opened',
    InventoryChangeType.vialRestocked => 'Sealed Vials Restocked',
    InventoryChangeType.expired => 'Expired Removed',
  };

  /// Minutes-from-midnight integer → HH:MM.
  static String _fmtMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Day-of-week numbers (1=Mon … 7=Sun) → abbreviated names.
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static String _fmtDays(Iterable<int> days) =>
      days.map((d) => _dayNames[(d - 1).clamp(0, 6)]).join(', ');

  // ── CSV methods ────────────────────────────────────────────────────────────

  String escape(String value) {
    final needsQuotes =
        value.contains(',') ||
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
      'ID',
      'Name',
      'Medication Type',
      'Manufacturer',
      'Strength',
      'Strength Unit',
      'Stock',
      'Stock Unit',
      'Created',
      'Updated',
    ].join(',');

    final rows = items
        .map((m) {
          return [
            escape(m.id),
            escape(m.name),
            escape(_formLabel(m.form)),
            escape(m.manufacturer ?? ''),
            escape(m.strengthValue.toString()),
            escape(m.strengthUnit.name),
            escape(m.stockValue.toString()),
            escape(m.stockUnit.name),
            escape(_fmtDate(m.createdAt)),
            escape(_fmtDate(m.updatedAt)),
          ].join(',');
        })
        .join('\n');

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
      'ID',
      'Name',
      'Medication ID',
      'Medication',
      'Active',
      'Start Date',
      'End Date',
      'Amount',
      'Unit',
      'Days of Week',
      'Times of Day',
      'Created',
    ].join(',');

    final rows = items
        .map((s) {
          return [
            escape(s.id),
            escape(s.name),
            escape(s.medicationId ?? ''),
            escape(s.medicationName),
            escape(s.active ? 'Yes' : 'No'),
            escape(s.startAt != null ? _fmtDate(s.startAt!) : ''),
            escape(s.endAt != null ? _fmtDate(s.endAt!) : ''),
            escape(s.entryValue.toString()),
            escape(s.entryUnit),
            escape(_fmtDays(s.daysOfWeek)),
            escape((s.timesOfDay ?? const <int>[]).map(_fmtMinutes).join(', ')),
            escape(_fmtDate(s.createdAt)),
          ].join(',');
        })
        .join('\n');

    return '$header\n$rows\n';
  }

  String entryLogsToCsv(Iterable<EntryLog> logs, {UtcTimeRange? range}) {
    final filtered = logs.where(
      (l) => range == null || range.contains(l.actionTime),
    );
    final items = filtered.toList(growable: false)
      ..sort(
        (a, b) => a.actionTime == b.actionTime
            ? a.id.compareTo(b.id)
            : b.actionTime.compareTo(a.actionTime),
      );

    final header = [
      'ID',
      'Medication',
      'Schedule',
      'Scheduled Time',
      'Action Time',
      'Action',
      'Amount',
      'Unit',
      'Actual Amount',
      'Actual Unit',
      'Notes',
    ].join(',');

    final rows = items
        .map((l) {
          return [
            escape(l.id),
            escape(l.medicationName),
            escape(l.scheduleName),
            escape(_fmtDate(l.scheduledTime)),
            escape(_fmtDate(l.actionTime)),
            escape(_actionLabel(l.action.name)),
            escape(l.entryValue.toString()),
            escape(l.entryUnit),
            escape(l.actualEntryValue?.toString() ?? ''),
            escape(l.actualEntryUnit ?? ''),
            escape(l.notes ?? ''),
          ].join(',');
        })
        .join('\n');

    return '$header\n$rows\n';
  }

  String inventoryLogsToCsv(
    Iterable<InventoryLog> logs, {
    UtcTimeRange? range,
  }) {
    final filtered = logs.where(
      (l) => range == null || range.contains(l.timestamp),
    );
    final items = filtered.toList(growable: false)
      ..sort(
        (a, b) => a.timestamp == b.timestamp
            ? a.id.compareTo(b.id)
            : b.timestamp.compareTo(a.timestamp),
      );

    final header = [
      'ID',
      'Medication ID',
      'Medication',
      'Date & Time',
      'Change Type',
      'Previous Stock',
      'New Stock',
      'Change Amount',
      'Notes',
    ].join(',');

    final rows = items
        .map((l) {
          return [
            escape(l.id),
            escape(l.medicationId),
            escape(l.medicationName),
            escape(_fmtDate(l.timestamp)),
            escape(_changeTypeLabel(l.changeType)),
            escape(l.previousStock.toString()),
            escape(l.newStock.toString()),
            escape(l.changeAmount.toString()),
            escape(l.notes ?? ''),
          ].join(',');
        })
        .join('\n');

    return '$header\n$rows\n';
  }
}
