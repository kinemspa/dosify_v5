// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_reports_widget.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  String _csvEscape(String value) {
    final needsQuotes = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _doseLogsToCsv(List<DoseLog> logs) {
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

    final rows = logs.map((l) {
      return [
        _csvEscape(l.id),
        _csvEscape(l.medicationName),
        _csvEscape(l.scheduleName),
        _csvEscape(l.scheduledTime.toUtc().toIso8601String()),
        _csvEscape(l.actionTime.toUtc().toIso8601String()),
        _csvEscape(l.action.name),
        _csvEscape(l.doseValue.toString()),
        _csvEscape(l.doseUnit),
        _csvEscape(l.actualDoseValue?.toString() ?? ''),
        _csvEscape(l.actualDoseUnit ?? ''),
        _csvEscape(l.notes ?? ''),
      ].join(',');
    }).join('\n');

    return '$header\n$rows\n';
  }

  String _inventoryLogsToCsv(List<InventoryLog> logs) {
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

    final rows = logs.map((l) {
      return [
        _csvEscape(l.id),
        _csvEscape(l.medicationId),
        _csvEscape(l.medicationName),
        _csvEscape(l.timestamp.toUtc().toIso8601String()),
        _csvEscape(l.changeType.name),
        _csvEscape(l.previousStock.toString()),
        _csvEscape(l.newStock.toString()),
        _csvEscape(l.changeAmount.toString()),
        _csvEscape(l.notes ?? ''),
      ].join(',');
    }).join('\n');

    return '$header\n$rows\n';
  }

  String _medicationsToCsv(List<Medication> meds) {
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

    final rows = meds.map((m) {
      return [
        _csvEscape(m.id),
        _csvEscape(m.name),
        _csvEscape(m.form.name),
        _csvEscape(m.manufacturer ?? ''),
        _csvEscape(m.strengthValue.toString()),
        _csvEscape(m.strengthUnit.name),
        _csvEscape(m.stockValue.toString()),
        _csvEscape(m.stockUnit.name),
        _csvEscape(m.createdAt.toUtc().toIso8601String()),
        _csvEscape(m.updatedAt.toUtc().toIso8601String()),
      ].join(',');
    }).join('\n');

    return '$header\n$rows\n';
  }

  String _schedulesToCsv(List<Schedule> schedules) {
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

    final rows = schedules.map((s) {
      return [
        _csvEscape(s.id),
        _csvEscape(s.name),
        _csvEscape(s.medicationId ?? ''),
        _csvEscape(s.medicationName),
        _csvEscape(s.active.toString()),
        _csvEscape(s.startAt?.toUtc().toIso8601String() ?? ''),
        _csvEscape(s.endAt?.toUtc().toIso8601String() ?? ''),
        _csvEscape(s.doseValue.toString()),
        _csvEscape(s.doseUnit),
        _csvEscape(s.daysOfWeek.join('|')),
        _csvEscape((s.timesOfDay ?? const <int>[]).join('|')),
        _csvEscape(s.createdAt.toUtc().toIso8601String()),
      ].join(',');
    }).join('\n');

    return '$header\n$rows\n';
  }

  @override
  Widget build(BuildContext context) {
    final medsBox = Hive.box<Medication>('medications');
    final schedulesBox = Hive.box<Schedule>('schedules');
    final doseLogsBox = Hive.box<DoseLog>('dose_logs');
    final inventoryLogsBox = Hive.box<InventoryLog>('inventory_logs');

    return Scaffold(
      appBar: const GradientAppBar(title: 'Analytics', forceBackButton: true),
      body: ValueListenableBuilder<Box<Medication>>(
        valueListenable: medsBox.listenable(),
        builder: (context, meds, _) {
          return ValueListenableBuilder<Box<Schedule>>(
            valueListenable: schedulesBox.listenable(),
            builder: (context, schedules, __) {
              return ValueListenableBuilder<Box<DoseLog>>(
                valueListenable: doseLogsBox.listenable(),
                builder: (context, doseLogs, ___) {
                  return ValueListenableBuilder<Box<InventoryLog>>(
                    valueListenable: inventoryLogsBox.listenable(),
                    builder: (context, inventoryLogs, ____) {
                      final medItems = meds.values.toList(growable: false)
                        ..sort((a, b) => a.name
                            .toLowerCase()
                            .compareTo(b.name.toLowerCase()));
                      final scheduleItems = schedules.values.toList(
                        growable: false,
                      )..sort((a, b) => a.name
                          .toLowerCase()
                          .compareTo(b.name.toLowerCase()));
                      final logItems = doseLogs.values.toList(growable: false)
                        ..sort((a, b) => b.actionTime.compareTo(a.actionTime));
                      final inventoryItems =
                          inventoryLogs.values.toList(growable: false)
                            ..sort(
                              (a, b) => b.timestamp.compareTo(a.timestamp),
                            );

                      final taken = logItems
                        .where((l) => l.action == DoseAction.taken)
                        .length;
                      final skipped = logItems
                        .where((l) => l.action == DoseAction.skipped)
                        .length;
                      final snoozed = logItems
                        .where((l) => l.action == DoseAction.snoozed)
                        .length;

                      return ListView(
                        padding: const EdgeInsets.all(kSpacingL),
                        children: [
                      SectionFormCard(
                        title: 'Overview',
                        neutral: true,
                        children: [
                          buildDetailInfoRow(
                            context,
                            label: 'Medications',
                            value: medItems.length.toString(),
                          ),
                          buildDetailInfoRow(
                            context,
                            label: 'Schedules',
                            value: scheduleItems.length.toString(),
                          ),
                          buildDetailInfoRow(
                            context,
                            label: 'Dose logs',
                            value: logItems.length.toString(),
                          ),
                          buildDetailInfoRow(
                            context,
                            label: 'Inventory logs',
                            value: inventoryItems.length.toString(),
                          ),
                          buildDetailInfoRow(
                            context,
                            label: 'Taken',
                            value: taken.toString(),
                          ),
                          buildDetailInfoRow(
                            context,
                            label: 'Skipped',
                            value: skipped.toString(),
                          ),
                          buildDetailInfoRow(
                            context,
                            label: 'Snoozed',
                            value: snoozed.toString(),
                          ),
                        ],
                      ),
                      sectionSpacing,
                      SectionFormCard(
                        title: 'Export',
                        neutral: true,
                        children: [
                          buildHelperText(
                            context,
                            'Copy your data as CSV for spreadsheets or backups.',
                          ),
                          const SizedBox(height: kSpacingS),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: kSpacingS,
                            runSpacing: kSpacingS,
                            children: [
                              FilledButton(
                                onPressed: medItems.isEmpty
                                    ? null
                                    : () async {
                                        final csv = _medicationsToCsv(medItems);
                                        await Clipboard.setData(
                                          ClipboardData(text: csv),
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Medications CSV copied to clipboard',
                                            ),
                                          ),
                                        );
                                      },
                                child: const Text('Copy Medications CSV'),
                              ),
                              FilledButton(
                                onPressed: scheduleItems.isEmpty
                                    ? null
                                    : () async {
                                        final csv =
                                            _schedulesToCsv(scheduleItems);
                                        await Clipboard.setData(
                                          ClipboardData(text: csv),
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Schedules CSV copied to clipboard',
                                            ),
                                          ),
                                        );
                                      },
                                child: const Text('Copy Schedules CSV'),
                              ),
                              FilledButton(
                                onPressed: logItems.isEmpty
                                    ? null
                                    : () async {
                                        final csv = _doseLogsToCsv(logItems);
                                        await Clipboard.setData(
                                          ClipboardData(text: csv),
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Dose logs CSV copied to clipboard',
                                            ),
                                          ),
                                        );
                                      },
                                child: const Text('Copy Dose Logs CSV'),
                              ),
                              FilledButton(
                                onPressed: inventoryItems.isEmpty
                                    ? null
                                    : () async {
                                        final csv = _inventoryLogsToCsv(
                                          inventoryItems,
                                        );
                                        await Clipboard.setData(
                                          ClipboardData(text: csv),
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Inventory logs CSV copied to clipboard',
                                            ),
                                          ),
                                        );
                                      },
                                child: const Text('Copy Inventory Logs CSV'),
                              ),
                            ],
                          )
                        ],
                      ),
                      if (medItems.isNotEmpty) ...[
                        sectionSpacing,
                        SectionFormCard(
                          title: 'Reports',
                          neutral: true,
                          children: [
                            buildHelperText(
                              context,
                              'This section reuses the same Reports widgets from Medication Details, grouped by medication.',
                            ),
                          ],
                        ),
                        const SizedBox(height: kSpacingS),
                        for (final med in medItems) ...[
                          MedicationReportsWidget(
                            medication: med,
                            isExpanded: false,
                          ),
                          const SizedBox(height: kSpacingL),
                        ],
                      ],
                    ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
