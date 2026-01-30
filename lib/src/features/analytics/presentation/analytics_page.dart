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
import 'package:dosifi_v5/src/features/reports/domain/csv_export_service.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/report_time_range_selector_row.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _csv = const CsvExportService();
  ReportTimeRangePreset _rangePreset = ReportTimeRangePreset.allTime;

  @override
  Widget build(BuildContext context) {
    final medsBox = Hive.box<Medication>('medications');
    final schedulesBox = Hive.box<Schedule>('schedules');
    final doseLogsBox = Hive.box<DoseLog>('dose_logs');
    final inventoryLogsBox = Hive.box<InventoryLog>('inventory_logs');

    final range = ReportTimeRange(_rangePreset).toUtcTimeRange();

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
                      final allLogItems =
                          doseLogs.values.toList(growable: false);
                      final allInventoryItems =
                          inventoryLogs.values.toList(growable: false);

                      final logItems = (range == null
                              ? allLogItems
                              : allLogItems
                                  .where((l) => range.contains(l.actionTime))
                                  .toList(growable: false))
                        ..sort((a, b) => b.actionTime.compareTo(a.actionTime));
                      final inventoryItems = (range == null
                              ? allInventoryItems
                              : allInventoryItems
                                  .where((l) => range.contains(l.timestamp))
                                  .toList(growable: false))
                        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

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
                          ReportTimeRangeSelectorRow(
                            value: _rangePreset,
                            onChanged: (next) {
                              setState(() => _rangePreset = next);
                            },
                          ),
                          const SizedBox(height: kSpacingS),
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
                            'Copy your data as CSV for spreadsheets or backups. Dose/Inventory exports follow the selected time range.',
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
                                        final csv = _csv.medicationsToCsv(
                                          medItems,
                                        );
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
                                        final csv = _csv.schedulesToCsv(
                                          scheduleItems,
                                        );
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
                                        final csv = _csv.doseLogsToCsv(
                                          logItems,
                                          range: range,
                                        );
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
                                        final csv = _csv.inventoryLogsToCsv(
                                          inventoryItems,
                                          range: range,
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
                            rangePreset: _rangePreset,
                            onRangePresetChanged: (next) {
                              setState(() => _rangePreset = next);
                            },
                            showTimeRangeControl: false,
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
