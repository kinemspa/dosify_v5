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
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
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

  Future<void> _copyExport(String text, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppSnackBar(context, successMessage);
  }

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
                        ..sort(
                          (a, b) => a.name.toLowerCase().compareTo(
                            b.name.toLowerCase(),
                          ),
                        );
                      final scheduleItems =
                          schedules.values.toList(growable: false)..sort(
                            (a, b) => a.name.toLowerCase().compareTo(
                              b.name.toLowerCase(),
                            ),
                          );
                      final allLogItems = doseLogs.values.toList(
                        growable: false,
                      );
                      final allInventoryItems = inventoryLogs.values.toList(
                        growable: false,
                      );

                      final logItems =
                          (range == null
                                ? allLogItems
                                : allLogItems
                                      .where(
                                        (l) => range.contains(l.actionTime),
                                      )
                                      .toList(growable: false))
                            ..sort(
                              (a, b) => b.actionTime.compareTo(a.actionTime),
                            );
                      final inventoryItems =
                          (range == null
                                ? allInventoryItems
                                : allInventoryItems
                                      .where((l) => range.contains(l.timestamp))
                                      .toList(growable: false))
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
                      final totalDoseActions = taken + skipped + snoozed;
                      final adherencePercent = totalDoseActions == 0
                          ? 0
                          : ((taken / totalDoseActions) * 100).round();

                      final stockRefills = inventoryItems
                          .where(
                            (l) =>
                                l.changeType == InventoryChangeType.refillAdd ||
                                l.changeType ==
                                    InventoryChangeType.refillToMax ||
                                l.changeType ==
                                    InventoryChangeType.vialRestocked,
                          )
                          .length;
                      final stockUsage = inventoryItems
                          .where(
                            (l) =>
                                l.changeType ==
                                    InventoryChangeType.doseDeducted ||
                                l.changeType == InventoryChangeType.adHocDose,
                          )
                          .length;
                      final stockAdjustments = inventoryItems
                          .where(
                            (l) =>
                                l.changeType ==
                                InventoryChangeType.manualAdjustment,
                          )
                          .length;
                      final stockExpired = inventoryItems
                          .where(
                            (l) => l.changeType == InventoryChangeType.expired,
                          )
                          .length;

                      final activityByMedication = <String, int>{};
                      for (final log in logItems) {
                        activityByMedication.update(
                          log.medicationName,
                          (value) => value + 1,
                          ifAbsent: () => 1,
                        );
                      }
                      final topActivity = activityByMedication.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      final summaryCsv = [
                        'report,value',
                        'Medications,${medItems.length}',
                        'Schedules,${scheduleItems.length}',
                        'Dose logs,${logItems.length}',
                        'Inventory logs,${inventoryItems.length}',
                        'Taken,${taken}',
                        'Skipped,${skipped}',
                        'Snoozed,${snoozed}',
                        'Adherence %,${adherencePercent}',
                        'Stock refills,${stockRefills}',
                        'Stock usage events,${stockUsage}',
                        'Stock adjustments,${stockAdjustments}',
                        'Expired removals,${stockExpired}',
                        'Total medicine activity,${logItems.length + inventoryItems.length}',
                      ].join('\n');

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
                                            await _copyExport(
                                              csv,
                                              'Medications CSV copied to clipboard',
                                            );
                                          },
                                    child: const Text('Copy Medications CSV'),
                                  ),
                                  FilledButton(
                                    onPressed: medItems.isEmpty
                                        ? null
                                        : () async {
                                            final csv = _csv.medicationsToCsv(
                                              medItems,
                                            );
                                            final html = _csv.csvToHtmlDocument(
                                              title: 'Medications Report',
                                              csv: csv,
                                            );
                                            await _copyExport(
                                              html,
                                              'Medications HTML copied to clipboard',
                                            );
                                          },
                                    child: const Text('Copy Medications HTML'),
                                  ),
                                  FilledButton(
                                    onPressed: scheduleItems.isEmpty
                                        ? null
                                        : () async {
                                            final csv = _csv.schedulesToCsv(
                                              scheduleItems,
                                            );
                                            await _copyExport(
                                              csv,
                                              'Schedules CSV copied to clipboard',
                                            );
                                          },
                                    child: const Text('Copy Schedules CSV'),
                                  ),
                                  FilledButton(
                                    onPressed: scheduleItems.isEmpty
                                        ? null
                                        : () async {
                                            final csv = _csv.schedulesToCsv(
                                              scheduleItems,
                                            );
                                            final html = _csv.csvToHtmlDocument(
                                              title: 'Schedules Report',
                                              csv: csv,
                                            );
                                            await _copyExport(
                                              html,
                                              'Schedules HTML copied to clipboard',
                                            );
                                          },
                                    child: const Text('Copy Schedules HTML'),
                                  ),
                                  FilledButton(
                                    onPressed: logItems.isEmpty
                                        ? null
                                        : () async {
                                            final csv = _csv.doseLogsToCsv(
                                              logItems,
                                              range: range,
                                            );
                                            await _copyExport(
                                              csv,
                                              'Dose logs CSV copied to clipboard',
                                            );
                                          },
                                    child: const Text('Copy Dose Logs CSV'),
                                  ),
                                  FilledButton(
                                    onPressed: logItems.isEmpty
                                        ? null
                                        : () async {
                                            final csv = _csv.doseLogsToCsv(
                                              logItems,
                                              range: range,
                                            );
                                            final html = _csv.csvToHtmlDocument(
                                              title: 'Dose Logs Report',
                                              csv: csv,
                                            );
                                            await _copyExport(
                                              html,
                                              'Dose logs HTML copied to clipboard',
                                            );
                                          },
                                    child: const Text('Copy Dose Logs HTML'),
                                  ),
                                  FilledButton(
                                    onPressed: inventoryItems.isEmpty
                                        ? null
                                        : () async {
                                            final csv = _csv.inventoryLogsToCsv(
                                              inventoryItems,
                                              range: range,
                                            );
                                            await _copyExport(
                                              csv,
                                              'Inventory logs CSV copied to clipboard',
                                            );
                                          },
                                    child: const Text(
                                      'Copy Inventory Logs CSV',
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: inventoryItems.isEmpty
                                        ? null
                                        : () async {
                                            final csv = _csv.inventoryLogsToCsv(
                                              inventoryItems,
                                              range: range,
                                            );
                                            final html = _csv.csvToHtmlDocument(
                                              title: 'Inventory Logs Report',
                                              csv: csv,
                                            );
                                            await _copyExport(
                                              html,
                                              'Inventory logs HTML copied to clipboard',
                                            );
                                          },
                                    child: const Text(
                                      'Copy Inventory Logs HTML',
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () async {
                                      await _copyExport(
                                        summaryCsv,
                                        'Analytics summary CSV copied to clipboard',
                                      );
                                    },
                                    child: const Text('Copy Summary CSV'),
                                  ),
                                  FilledButton(
                                    onPressed: () async {
                                      final html = _csv.csvToHtmlDocument(
                                        title: 'Analytics Summary Report',
                                        csv: summaryCsv,
                                      );
                                      await _copyExport(
                                        html,
                                        'Analytics summary HTML copied to clipboard',
                                      );
                                    },
                                    child: const Text('Copy Summary HTML'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          sectionSpacing,
                          SectionFormCard(
                            title: 'Dose Status Report',
                            neutral: true,
                            children: [
                              buildDetailInfoRow(
                                context,
                                label: 'Taken doses',
                                value: taken.toString(),
                              ),
                              buildDetailInfoRow(
                                context,
                                label: 'Skipped doses',
                                value: skipped.toString(),
                              ),
                              buildDetailInfoRow(
                                context,
                                label: 'Snoozed doses',
                                value: snoozed.toString(),
                              ),
                            ],
                          ),
                          sectionSpacing,
                          SectionFormCard(
                            title: 'Adherence Report',
                            neutral: true,
                            children: [
                              buildDetailInfoRow(
                                context,
                                label: 'Total dose actions',
                                value: totalDoseActions.toString(),
                              ),
                              buildDetailInfoRow(
                                context,
                                label: 'Adherence',
                                value: '$adherencePercent%',
                              ),
                            ],
                          ),
                          sectionSpacing,
                          SectionFormCard(
                            title: 'Stock Activity Report',
                            neutral: true,
                            children: [
                              buildDetailInfoRow(
                                context,
                                label: 'Refill events',
                                value: stockRefills.toString(),
                              ),
                              buildDetailInfoRow(
                                context,
                                label: 'Usage events',
                                value: stockUsage.toString(),
                              ),
                              buildDetailInfoRow(
                                context,
                                label: 'Manual adjustments',
                                value: stockAdjustments.toString(),
                              ),
                              buildDetailInfoRow(
                                context,
                                label: 'Expired removals',
                                value: stockExpired.toString(),
                              ),
                            ],
                          ),
                          sectionSpacing,
                          SectionFormCard(
                            title: 'Total Medicine Activity Report',
                            neutral: true,
                            children: [
                              buildDetailInfoRow(
                                context,
                                label: 'Dose + stock activities',
                                value:
                                    '${logItems.length + inventoryItems.length}',
                              ),
                              if (topActivity.isEmpty)
                                buildDetailInfoRow(
                                  context,
                                  label: 'Top medication activity',
                                  value: 'No activity in selected range',
                                )
                              else
                                for (final entry in topActivity.take(5))
                                  buildDetailInfoRow(
                                    context,
                                    label: entry.key,
                                    value: entry.value.toString(),
                                  ),
                            ],
                          ),
                          if (medItems.isNotEmpty) ...[
                            sectionSpacing,
                            SectionFormCard(
                              title: 'Activity by medication',
                              neutral: true,
                              children: [
                                buildHelperText(
                                  context,
                                  'Activity history grouped by medication.',
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
