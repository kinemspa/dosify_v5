// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
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

  @override
  Widget build(BuildContext context) {
    final medsBox = Hive.box<Medication>('medications');
    final schedulesBox = Hive.box<Schedule>('schedules');
    final doseLogsBox = Hive.box<DoseLog>('dose_logs');

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
                  final medItems = meds.values.toList(growable: false);
                  final scheduleItems = schedules.values.toList(growable: false);
                  final logItems = doseLogs.values.toList(growable: false)
                    ..sort((a, b) => b.actionTime.compareTo(a.actionTime));

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
                            'Copy your dose history as CSV for spreadsheets or backups.',
                          ),
                          const SizedBox(height: kSpacingS),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: logItems.isEmpty
                                  ? null
                                  : () async {
                                      final csv = _doseLogsToCsv(logItems);
                                      await Clipboard.setData(
                                        ClipboardData(text: csv),
                                      );
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Dose log CSV copied to clipboard',
                                          ),
                                        ),
                                      );
                                    },
                              child: const Text('Copy Dose Logs CSV'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
