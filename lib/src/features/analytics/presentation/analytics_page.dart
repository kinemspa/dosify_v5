// Dart imports:
import 'dart:io';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Project imports:
import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/inventory_log.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/supplies/domain/stock_movement.dart';
import 'package:skedux/src/features/supplies/domain/supply.dart';
import 'package:skedux/src/features/medications/domain/saved_reconstitution_calculation.dart';
import 'package:skedux/src/features/reports/domain/csv_export_service.dart';
import 'package:skedux/src/features/reports/domain/pdf_export_service.dart';
import 'package:skedux/src/features/reports/domain/report_time_range.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';
import 'package:skedux/src/widgets/app_header.dart';
import 'package:skedux/src/widgets/detail_page_scaffold.dart';
import 'package:skedux/src/widgets/report_time_range_selector_row.dart';
import 'package:skedux/src/widgets/no_medications_banner.dart';
import 'package:skedux/src/widgets/unified_form.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _csv = const CsvExportService();
  final _pdf = const PdfExportService();
  ReportTimeRangePreset _rangePreset = ReportTimeRangePreset.last30Days;
  Set<MedicationForm> _filterForms = MedicationForm.values.toSet();

  /// Medication ID filter for exports. Empty = include all.
  Set<String> _exportMedFilter = {};
  /// Display filters — affect all analytics cards, not just export.
  Set<String> _filterMedIds = {};
  Set<String> _filterScheduleIds = {};
  bool _filtersExpanded = true;

  Future<void> _showExportFilterSheet(
    BuildContext context,
    List<Medication> meds,
  ) async {
    var draft = Set<String>.from(_exportMedFilter);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSS) {
            final allSelected = draft.isEmpty;
            final bottomPad = MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).padding.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomPad),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.55,
                maxChildSize: 0.9,
                builder: (ctx2, scrollCtrl) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSpacingM,
                        vertical: kSpacingS,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Export Medication Filter',
                            style: sectionTitleStyle(context),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setSS(() => draft = {}),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        children: [
                          CheckboxListTile(
                            title: const Text('All medications'),
                            value: allSelected,
                            onChanged: (v) {
                              if (v == true) setSS(() => draft = {});
                            },
                          ),
                          const Divider(height: 1),
                          for (final med in meds)
                            CheckboxListTile(
                              title: Text(med.name),
                              value:
                                  !allSelected && draft.contains(med.id),
                              onChanged: (v) {
                                setSS(() {
                                  if (v == true) {
                                    draft = {...draft, med.id};
                                  } else {
                                    draft = draft
                                        .where((id) => id != med.id)
                                        .toSet();
                                    if (draft.isEmpty) draft = {};
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(kSpacingM),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(sheetCtx).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: kSpacingS),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() => _exportMedFilter = draft);
                                Navigator.of(sheetCtx).pop();
                              },
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<void> _shareExport(
    String content,
    String filename,
    String subject,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], subject: subject);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Export failed: $e');
    }
  }

  Future<void> _sharePdfExport(
    Future<Uint8List> Function() buildPdf,
    String filename,
    String subject,
  ) async {
    try {
      final bytes = await buildPdf();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: subject,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'PDF export failed: $e');
    }
  }

  static String _formLabel(MedicationForm form) => switch (form) {
    MedicationForm.tablet => 'Tablets',
    MedicationForm.capsule => 'Capsules',
    MedicationForm.prefilledSyringe => 'Pre-filled Syringes',
    MedicationForm.singleDoseVial => 'Single-Dose Vials',
    MedicationForm.multiDoseVial => 'Multi-Dose Vials',
  };

  // ── chart helpers ──────────────────────────────────────────────────────────

  /// Builds an adherence donut (PieChart) with a centre-text label.
  Widget _buildAdherenceDonut(
    BuildContext context, {
    required int logged,
    required int skipped,
    required int snoozed,
    required int adherencePercent,
  }) {
    final cs = Theme.of(context).colorScheme;
    final total = logged + skipped + snoozed;
    if (total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: kSpacingXL),
          child: Text(
            'No activity in selected range.',
            style: helperTextStyle(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        value: logged.toDouble(),
        color: cs.primary,
        title: '',
        radius: 28,
      ),
      if (skipped > 0)
        PieChartSectionData(
          value: skipped.toDouble(),
          color: cs.error,
          title: '',
          radius: 22,
        ),
      if (snoozed > 0)
        PieChartSectionData(
          value: snoozed.toDouble(),
          color: cs.tertiary,
          title: '',
          radius: 22,
        ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 52,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                  borderData: FlBorderData(show: false),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$adherencePercent%',
                    style: bodyTextStyle(context)?.copyWith(
                      fontSize: kFontSizeXLarge,
                      fontWeight: kFontWeightBold,
                      color: cs.primary,
                    ),
                  ),
                  Text(
                    'adherence',
                    style: helperTextStyle(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: kSpacingM),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(context, cs.primary, 'Logged ($logged)'),
            if (skipped > 0) ...[
              const SizedBox(width: kSpacingL),
              _legend(context, cs.error, 'Skipped ($skipped)'),
            ],
            if (snoozed > 0) ...[
              const SizedBox(width: kSpacingL),
              _legend(context, cs.tertiary, 'Snoozed ($snoozed)'),
            ],
          ],
        ),
      ],
    );
  }

  Widget _legend(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: kSpacingM,
          height: kSpacingM,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(kBorderRadiusChipTight),
          ),
        ),
        const SizedBox(width: kSpacingXS),
        Text(label, style: helperTextStyle(context)),
      ],
    );
  }

  /// BarChart with one bar per day for the last [days] days.
  Widget _buildDailyTrendChart(
    BuildContext context,
    List<EntryLog> logItems,
    int days,
  ) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now().toLocal();
    final startDay = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final countByDay = <int, int>{};
    for (var i = 0; i < days; i++) {
      countByDay[i] = 0;
    }
    for (final log in logItems) {
      if (log.action != EntryAction.logged) continue;
      final local = log.actionTime.toLocal();
      final dayOffset = DateTime(local.year, local.month, local.day)
          .difference(startDay)
          .inDays;
      if (dayOffset >= 0 && dayOffset < days) {
        countByDay[dayOffset] = (countByDay[dayOffset] ?? 0) + 1;
      }
    }

    final maxY = countByDay.values.fold<int>(1, (m, v) => v > m ? v : m);

    // Show a label every N days to avoid crowding
    final labelEvery = days <= 14 ? 2 : days <= 30 ? 5 : 10;

    final barGroups = List.generate(days, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (countByDay[i] ?? 0).toDouble(),
            color: cs.primary,
            width: days <= 14 ? 10 : days <= 30 ? 6 : 4,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(kBorderRadiusChipTight),
            ),
          ),
        ],
      );
    });

    if (countByDay.values.every((v) => v == 0)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: kSpacingXL),
          child: Text(
            'No entries in selected range.',
            style: helperTextStyle(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY.toDouble() + 1,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  if (value != value.roundToDouble()) return const SizedBox();
                  return Text(
                    value.toInt().toString(),
                    style: helperTextStyle(context)?.copyWith(
                      fontSize: kFontSizeHint,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i % labelEvery != 0) return const SizedBox();
                  final day = startDay.add(Duration(days: i));
                  final label = '${day.month}/${day.day}';
                  return Padding(
                    padding: const EdgeInsets.only(top: kSpacingXS),
                    child: Text(
                      label,
                      style: helperTextStyle(context)?.copyWith(
                        fontSize: kFontSizeHint,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  cs.surfaceContainerHigh,
              getTooltipItem: (group, _, rod, __) {
                final day = startDay.add(Duration(days: group.x));
                return BarTooltipItem(
                  '${day.month}/${day.day}\n${rod.toY.toInt()} entries',
                  (helperTextStyle(context) ?? const TextStyle()).copyWith(
                    color: cs.onSurface,
                    fontSize: kFontSizeSmall,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Horizontal stacked-bar chart showing per-action-type counts per medication.
  Widget _buildTopMedsChart(
    BuildContext context,
    List<MapEntry<String, Map<String, int>>> topActivity,
  ) {
    final cs = Theme.of(context).colorScheme;
    if (topActivity.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: kSpacingXL),
          child: Text(
            'No activity in selected range.',
            style: helperTextStyle(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Determine the max total across all medications for proportional scaling
    final maxTotal = topActivity
        .map((e) => e.value.values.fold(0, (s, v) => s + v))
        .fold(0, (a, b) => a > b ? a : b);
    if (maxTotal == 0) return const SizedBox.shrink();

    const actionOrder = ['Logged', 'Skipped', 'Snoozed', 'Refilled'];

    Color actionColor(String action) => switch (action) {
      'Logged' => cs.primary,
      'Skipped' => cs.error,
      'Snoozed' => cs.tertiary,
      'Refilled' => cs.secondary,
      _ => cs.outline,
    };

    // Only show legend items for action types present in the data
    final presentActions = actionOrder
        .where((a) => topActivity.any((e) => (e.value[a] ?? 0) > 0))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Wrap(
          spacing: kSpacingM,
          runSpacing: kSpacingXS,
          children: [
            for (final action in presentActions)
              _legend(context, actionColor(action), action),
          ],
        ),
        const SizedBox(height: kSpacingM),
        // One row per medication
        for (final entry in topActivity)
          Padding(
            padding: const EdgeInsets.only(bottom: kSpacingS),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    entry.key,
                    style: helperTextStyle(context),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: kSpacingS),
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(kBorderRadiusChipTight),
                    child: SizedBox(
                      height: 20,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final totalWidth = constraints.maxWidth;
                          final counts = entry.value;
                          return Stack(
                            children: [
                              Container(
                                color: cs.surfaceContainerHighest,
                                width: totalWidth,
                              ),
                              Row(
                                children: [
                                  for (final action in actionOrder)
                                    if ((counts[action] ?? 0) > 0)
                                      Container(
                                        width: ((counts[action]! / maxTotal) *
                                                totalWidth)
                                            .clamp(0.0, totalWidth),
                                        height: 20,
                                        color: actionColor(action),
                                      ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: kSpacingS),
                SizedBox(
                  width: 28,
                  child: Text(
                    entry.value.values.fold(0, (s, v) => s + v).toString(),
                    style: helperTextStyle(context),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── export helpers ─────────────────────────────────────────────────────────

  Widget _exportButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool enabled,
    VoidCallback? onShareCsv,
    VoidCallback? onSharePdf,
  }) {
    return Row(
      children: [
        Icon(icon, size: kIconSizeSmall, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: kSpacingS),
        Expanded(
          child: Text(label, style: bodyTextStyle(context)),
        ),
        MenuAnchor(
          menuChildren: [
            if (onShareCsv != null)
              MenuItemButton(
                leadingIcon: const Icon(Icons.share_outlined),
                onPressed: enabled ? onShareCsv : null,
                child: const Text('Share CSV'),
              ),
            if (onSharePdf != null)
              MenuItemButton(
                leadingIcon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: enabled ? onSharePdf : null,
                child: const Text('Share PDF'),
              ),
          ],
          builder: (ctx, controller, _) => OutlinedButton.icon(
            onPressed: enabled
                ? () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  }
                : null,
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Export'),
          ),
        ),
      ],
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final medsBox = Hive.box<Medication>('medications');
    final schedulesBox = Hive.box<Schedule>('schedules');
    final entryLogsBox = Hive.box<EntryLog>('entry_logs');
    final inventoryLogsBox = Hive.box<InventoryLog>('inventory_logs');
    final suppliesBox = Hive.box<Supply>('supplies');
    final stockMovementsBox = Hive.box<StockMovement>('stock_movements');

    final range = ReportTimeRange(_rangePreset).toUtcTimeRange();
    // For daily trend chart: how many days to show
    final trendDays = switch (_rangePreset) {
      ReportTimeRangePreset.allTime => 30,
      ReportTimeRangePreset.last7Days => 7,
      ReportTimeRangePreset.last30Days => 30,
      ReportTimeRangePreset.last90Days => 90,
      ReportTimeRangePreset.last365Days => 90, // cap at 90 bars for readability
    };

    return Scaffold(
      appBar: const GradientAppBar(title: 'Analytics', forceBackButton: true),
      body: Column(
        children: [
          const NoMedicationsBanner(),
          Expanded(
            child: ValueListenableBuilder<Box<Medication>>(
        valueListenable: medsBox.listenable(),
        builder: (context, meds, _) {
          return ValueListenableBuilder<Box<Schedule>>(
            valueListenable: schedulesBox.listenable(),
            builder: (context, schedules, __) {
              return ValueListenableBuilder<Box<EntryLog>>(
                valueListenable: entryLogsBox.listenable(),
                builder: (context, entryLogs, ___) {
                  return ValueListenableBuilder<Box<InventoryLog>>(
                    valueListenable: inventoryLogsBox.listenable(),
                    builder: (context, inventoryLogs, ____) {
                      // ── data ───────────────────────────────────────────────
                      final medItems = meds.values.toList(growable: false)
                        ..sort(
                          (a, b) => a.name.toLowerCase().compareTo(
                            b.name.toLowerCase(),
                          ),
                        );
                      final scheduleItems =
                          schedules.values.toList(growable: false);
                      final allLogItems =
                          entryLogs.values.toList(growable: false);
                      final allInventoryItems =
                          inventoryLogs.values.toList(growable: false);

                      final logItems = (range == null
                              ? allLogItems
                              : allLogItems
                                  .where((l) => range.contains(l.actionTime))
                                  .toList(growable: false))
                        ..sort(
                          (a, b) => b.actionTime.compareTo(a.actionTime),
                        );
                      final inventoryItems = (range == null
                              ? allInventoryItems
                              : allInventoryItems
                                  .where(
                                    (l) => range.contains(l.timestamp),
                                  )
                                  .toList(growable: false))
                        ..sort(
                          (a, b) => b.timestamp.compareTo(a.timestamp),
                        );

                      // ── Apply display filters (form + med + schedule) ──────
                      final displayMedIds = <String>{
                        for (final m in medItems)
                          if (_filterForms.contains(m.form) &&
                              (_filterMedIds.isEmpty ||
                                  _filterMedIds.contains(m.id)))
                            m.id,
                      };
                      final displayScheduleIds = <String>{
                        for (final s in scheduleItems)
                          if (s.medicationId != null &&
                              displayMedIds.contains(s.medicationId) &&
                              (_filterScheduleIds.isEmpty ||
                                  _filterScheduleIds.contains(s.id)))
                            s.id,
                      };
                      final displayMedItems = medItems
                          .where((m) => displayMedIds.contains(m.id))
                          .toList(growable: false);
                      final displayScheduleItems = scheduleItems
                          .where(
                            (s) =>
                                s.medicationId != null &&
                                displayMedIds.contains(s.medicationId),
                          )
                          .toList(growable: false);
                      final displayLogItems = logItems
                          .where(
                            (l) =>
                                displayMedIds.contains(l.medicationId) &&
                                (_filterScheduleIds.isEmpty ||
                                    displayScheduleIds
                                        .contains(l.scheduleId)),
                          )
                          .toList(growable: false);
                      final displayInventoryItems = inventoryItems
                          .where(
                            (l) => displayMedIds.contains(l.medicationId),
                          )
                          .toList(growable: false);
                      final hasActiveFilters =
                          _filterForms.length <
                              MedicationForm.values.length ||
                          _filterMedIds.isNotEmpty ||
                          _filterScheduleIds.isNotEmpty;

                      final logged = displayLogItems
                          .where((l) => l.action == EntryAction.logged)
                          .length;
                      final skipped = displayLogItems
                          .where((l) => l.action == EntryAction.skipped)
                          .length;
                      final snoozed = displayLogItems
                          .where((l) => l.action == EntryAction.snoozed)
                          .length;
                      final totalEntryActions = logged + skipped + snoozed;
                      final adherencePercent = totalEntryActions == 0
                          ? 0
                          : ((logged / totalEntryActions) * 100).round();

                      final stockRefills = displayInventoryItems
                          .where(
                            (l) =>
                                l.changeType == InventoryChangeType.refillAdd ||
                                l.changeType ==
                                    InventoryChangeType.refillToMax ||
                                l.changeType ==
                                    InventoryChangeType.vialRestocked,
                          )
                          .length;
                      final stockUsage = displayInventoryItems
                          .where(
                            (l) =>
                                l.changeType ==
                                    InventoryChangeType.entryDeducted ||
                                l.changeType == InventoryChangeType.adHocEntry,
                          )
                          .length;
                      final stockAdjustments = displayInventoryItems
                          .where(
                            (l) =>
                                l.changeType ==
                                InventoryChangeType.manualAdjustment,
                          )
                          .length;
                      final stockExpired = displayInventoryItems
                          .where(
                            (l) =>
                                l.changeType == InventoryChangeType.expired,
                          )
                          .length;

                      // Per-medication per-action-type activity breakdown
                      final activityByMedication = <String, Map<String, int>>{};
                      for (final log in displayLogItems) {
                        final label = switch (log.action) {
                          EntryAction.logged => 'Logged',
                          EntryAction.skipped => 'Skipped',
                          EntryAction.snoozed => 'Snoozed',
                        };
                        activityByMedication.putIfAbsent(
                          log.medicationName, () => {});
                        activityByMedication[log.medicationName]!.update(
                          label, (v) => v + 1, ifAbsent: () => 1);
                      }
                      // Include refill events from inventory logs
                      for (final inv in displayInventoryItems) {
                        final isRefill =
                            inv.changeType == InventoryChangeType.refillAdd ||
                            inv.changeType == InventoryChangeType.refillToMax ||
                            inv.changeType == InventoryChangeType.vialRestocked;
                        if (!isRefill) continue;
                        activityByMedication.putIfAbsent(
                          inv.medicationName, () => {});
                        activityByMedication[inv.medicationName]!.update(
                          'Refilled', (v) => v + 1, ifAbsent: () => 1);
                      }
                      final topActivity = activityByMedication.entries.toList()
                        ..sort((a, b) =>
                            b.value.values.fold(0, (s, v) => s + v)
                                .compareTo(
                                    a.value.values.fold(0, (s, v) => s + v)));

                      // Export-filtered lists (applies the medication ID filter)
                      final exportMeds = _exportMedFilter.isEmpty
                          ? medItems
                          : medItems
                              .where((m) => _exportMedFilter.contains(m.id))
                              .toList(growable: false);
                      final exportSchedules = _exportMedFilter.isEmpty
                          ? scheduleItems
                          : scheduleItems
                              .where(
                                (s) =>
                                    s.medicationId != null &&
                                    _exportMedFilter.contains(s.medicationId),
                              )
                              .toList(growable: false);
                      final exportLogs = _exportMedFilter.isEmpty
                          ? logItems
                          : logItems
                              .where(
                                (l) =>
                                    _exportMedFilter.contains(l.medicationId),
                              )
                              .toList(growable: false);
                      final exportInventory = _exportMedFilter.isEmpty
                          ? inventoryItems
                          : inventoryItems
                              .where(
                                (l) =>
                                    _exportMedFilter.contains(l.medicationId),
                              )
                              .toList(growable: false);

                      // Medication type breakdown
                      final typeBreakdown = <MedicationForm, int>{};
                      for (final m in medItems) {
                        typeBreakdown.update(
                          m.form,
                          (v) => v + 1,
                          ifAbsent: () => 1,
                        );
                      }

                      // Inventory health
                      final now = DateTime.now().toUtc();
                      final in30Days = now.add(const Duration(days: 30));
                      final lowStockCount = displayMedItems.where((m) {
                        if (!m.lowStockEnabled) return false;
                        return m.stockValue <=
                            (m.lowStockThreshold ??
                                m.lowStockVialsThresholdCount ??
                                0);
                      }).length;
                      final expiringCount = displayMedItems.where((m) {
                        final dates = [
                          m.expiry,
                          m.backupVialsExpiry,
                          m.reconstitutedVialExpiry,
                        ];
                        return dates.any(
                          (d) =>
                              d != null &&
                              !d.isBefore(now) &&
                              d.isBefore(in30Days),
                        );
                      }).length;
                      final savedReconCount =
                          Hive.box<SavedReconstitutionCalculation>(
                        SavedReconstitutionRepository.boxName,
                      ).length;

                      // Supply health
                      final allSupplies =
                          suppliesBox.values.toList(growable: false);
                      final allMovements =
                          stockMovementsBox.values.toList(growable: false);
                      int lowSuppliesCount = 0;
                      int expiringSuppliesCount = 0;
                      for (final supply in allSupplies) {
                        if (supply.reorderThreshold != null) {
                          final currentStock = allMovements
                              .where((m) => m.supplyId == supply.id)
                              .fold<double>(0.0, (sum, m) => sum + m.delta);
                          if (currentStock <= supply.reorderThreshold!) {
                            lowSuppliesCount++;
                          }
                        }
                        if (supply.expiry != null &&
                            !supply.expiry!.isBefore(now) &&
                            supply.expiry!.isBefore(in30Days)) {
                          expiringSuppliesCount++;
                        }
                      }

                      // CSV strings (for export only)
                      final summaryCsv = [
                        'report,value',
                        'Medications,${medItems.length}',
                        'Schedules,${scheduleItems.length}',
                        'Activity log,${logItems.length}',
                        'Inventory logs,${inventoryItems.length}',
                        'Logged,$logged',
                        'Skipped,$skipped',
                        'Snoozed,$snoozed',
                        'Adherence %,$adherencePercent',
                        'Stock refills,$stockRefills',
                        'Stock usage events,$stockUsage',
                        'Stock adjustments,$stockAdjustments',
                        'Expired removals,$stockExpired',
                      ].join('\n');

                      // ── layout ─────────────────────────────────────────────
                      return ListView(
                        padding: kPagePadding,
                        children: [
                          // ── 0. Filters ──────────────────────────────────────
                          CollapsibleSectionFormCard(
                            title: hasActiveFilters
                                ? 'Filters (active)'
                                : 'Filters',
                            neutral: true,
                            isExpanded: _filtersExpanded,
                            onExpandedChanged: (v) =>
                                setState(() => _filtersExpanded = v),
                            trailing: hasActiveFilters
                                ? IconButton(
                                    tooltip: 'Clear all filters',
                                    icon: const Icon(Icons.filter_list_off),
                                    constraints: kTightIconButtonConstraints,
                                    padding: kNoPadding,
                                    onPressed: () => setState(() {
                                      _filterForms =
                                          MedicationForm.values.toSet();
                                      _filterMedIds = {};
                                      _filterScheduleIds = {};
                                    }),
                                  )
                                : null,
                            children: [
                              // ── Date range (centered) ──────────────────────
                              Center(
                                child: ReportTimeRangeSelectorRow(
                                  value: _rangePreset,
                                  onChanged: (next) =>
                                      setState(() => _rangePreset = next),
                                ),
                              ),
                              // ── Medication type ────────────────────────────
                              if (typeBreakdown.isNotEmpty) ...[
                                const SizedBox(height: kSpacingS),
                                _filterRow(
                                  context,
                                  label: 'Type',
                                  chips: [
                                    for (final form in MedicationForm.values)
                                      if ((typeBreakdown[form] ?? 0) > 0)
                                        _filterChip(
                                          context,
                                          label:
                                              '${_formLabel(form)} (${typeBreakdown[form]})',
                                          selected:
                                              _filterForms.contains(form),
                                          onTap: () => setState(() {
                                            if (_filterForms.contains(form)) {
                                              if (_filterForms.length > 1) {
                                                _filterForms.remove(form);
                                              } else {
                                                _filterForms = MedicationForm
                                                    .values
                                                    .toSet();
                                              }
                                            } else {
                                              _filterForms.add(form);
                                            }
                                            _filterMedIds = {};
                                            _filterScheduleIds = {};
                                          }),
                                        ),
                                  ],
                                ),
                              ],
                              // ── Specific medication ────────────────────────
                              if (medItems.isNotEmpty) ...[
                                const SizedBox(height: kSpacingXS),
                                _filterRow(
                                  context,
                                  label: 'Med',
                                  chips: [
                                    _filterChip(
                                      context,
                                      label: 'All',
                                      selected: _filterMedIds.isEmpty,
                                      onTap: () => setState(() {
                                        _filterMedIds = {};
                                        _filterScheduleIds = {};
                                      }),
                                    ),
                                    for (final m in medItems)
                                      if (_filterForms.contains(m.form))
                                        _filterChip(
                                          context,
                                          label: m.name,
                                          selected:
                                              _filterMedIds.contains(m.id),
                                          onTap: () => setState(() {
                                            if (_filterMedIds.contains(m.id)) {
                                              _filterMedIds = _filterMedIds
                                                  .where((id) => id != m.id)
                                                  .toSet();
                                            } else {
                                              _filterMedIds = {
                                                ..._filterMedIds,
                                                m.id,
                                              };
                                            }
                                            _filterScheduleIds = {};
                                          }),
                                        ),
                                  ],
                                ),
                              ],
                              // ── Specific schedule ──────────────────────────
                              if (scheduleItems.isNotEmpty) ...[
                                const SizedBox(height: kSpacingXS),
                                _filterRow(
                                  context,
                                  label: 'Schedule',
                                  chips: [
                                    _filterChip(
                                      context,
                                      label: 'All',
                                      selected: _filterScheduleIds.isEmpty,
                                      onTap: () => setState(
                                        () => _filterScheduleIds = {},
                                      ),
                                    ),
                                    for (final s in scheduleItems)
                                      if (s.medicationId != null &&
                                          displayMedIds
                                              .contains(s.medicationId))
                                        _filterChip(
                                          context,
                                          label: s.name,
                                          selected:
                                              _filterScheduleIds.contains(s.id),
                                          onTap: () => setState(() {
                                            if (_filterScheduleIds
                                                .contains(s.id)) {
                                              _filterScheduleIds =
                                                  _filterScheduleIds
                                                      .where(
                                                        (id) => id != s.id,
                                                      )
                                                      .toSet();
                                            } else {
                                              _filterScheduleIds = {
                                                ..._filterScheduleIds,
                                                s.id,
                                              };
                                            }
                                          }),
                                        ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          sectionSpacing,

                          // ── 1. Overview ─────────────────────────────────────
                          SectionFormCard(
                            title: 'Overview',
                            neutral: true,
                            children: [
                              Row(
                                children: [
                                  _statTile(
                                    context,
                                    icon: Icons.medication_outlined,
                                    label: hasActiveFilters
                                        ? 'Filtered Meds'
                                        : 'Medications',
                                    value: displayMedItems.length.toString(),
                                  ),
                                  const SizedBox(width: kSpacingS),
                                  _statTile(
                                    context,
                                    icon: Icons.schedule_outlined,
                                    label: 'Schedules',
                                    value:
                                        displayScheduleItems.length.toString(),
                                    valueColor:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: kSpacingS),
                              Row(
                                children: [
                                  _statTile(
                                    context,
                                    icon: Icons.check_circle_outline,
                                    label: 'Activity log',
                                    value: displayLogItems.length.toString(),
                                    valueColor:
                                        Theme.of(context).colorScheme.tertiary,
                                  ),
                                  const SizedBox(width: kSpacingS),
                                  _statTile(
                                    context,
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Stock logs',
                                    value:
                                        displayInventoryItems.length.toString(),
                                    valueColor:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ],
                              ),
                              if (totalEntryActions > 0) ...[
                                const SizedBox(height: kSpacingS),
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        adherencePercent >= 80
                                            ? Icons.check_circle_outline
                                            : adherencePercent >= 50
                                                ? Icons.remove_circle_outline
                                                : Icons.cancel_outlined,
                                        size: kIconSizeSmall,
                                        color: adherencePercent >= 80
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : adherencePercent >= 50
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .error,
                                      ),
                                      const SizedBox(width: kSpacingXS),
                                      Text(
                                        'Adherence: $adherencePercent%',
                                        style: helperTextStyle(
                                          context,
                                        )?.copyWith(
                                          fontWeight: kFontWeightSemiBold,
                                          color: adherencePercent >= 80
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : adherencePercent >= 50
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          sectionSpacing,

                          // ── 2. Adherence donut ───────────────────────────────
                          SectionFormCard(
                            title: 'Adherence',
                            neutral: true,
                            children: [
                              _buildAdherenceDonut(
                                context,
                                logged: logged,
                                skipped: skipped,
                                snoozed: snoozed,
                                adherencePercent: adherencePercent,
                              ),
                            ],
                          ),
                          sectionSpacing,

                          // ── 3. Daily trend bar chart ─────────────────────────
                          SectionFormCard(
                            title: 'Daily Entry Activity',
                            neutral: true,
                            children: [
                              Center(
                                child: buildHelperText(
                                  context,
                                  'Entries per day — last $trendDays days.',
                                ),
                              ),
                              const SizedBox(height: kSpacingM),
                              _buildDailyTrendChart(
                                context,
                                displayLogItems,
                                trendDays,
                              ),
                            ],
                          ),
                          sectionSpacing,

                          // ── 4. Top medications ───────────────────────────────
                          SectionFormCard(
                            title: 'Activity by Medication',
                            neutral: true,
                            children: [
                              Center(
                                child: buildHelperText(
                                  context,
                                  'Top ${topActivity.take(8).length} medications by activity in selected range.',
                                ),
                              ),
                              const SizedBox(height: kSpacingM),
                              _buildTopMedsChart(
                                context,
                                topActivity.take(8).toList(),
                              ),
                            ],
                          ),
                          sectionSpacing,

                          // ── 5. Inventory health ──────────────────────────────
                          SectionFormCard(
                            title: 'Inventory Health',
                            neutral: true,
                            children: [
                              Row(
                                children: [
                                  _statTile(
                                    context,
                                    icon: Icons.warning_amber_outlined,
                                    label: 'Low stock',
                                    value: lowStockCount == 0
                                        ? '—'
                                        : lowStockCount.toString(),
                                    valueColor: lowStockCount > 0
                                        ? Theme.of(context).colorScheme.error
                                        : null,
                                  ),
                                  const SizedBox(width: kSpacingS),
                                  _statTile(
                                    context,
                                    icon: Icons.hourglass_bottom_outlined,
                                    label: 'Expiring ≤30d',
                                    value: expiringCount == 0
                                        ? '—'
                                        : expiringCount.toString(),
                                    valueColor: expiringCount > 0
                                        ? Theme.of(context).colorScheme.tertiary
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: kSpacingS),
                              Row(
                                children: [
                                  _statTile(
                                    context,
                                    icon: Icons.refresh_outlined,
                                    label: 'Refill events',
                                    value: stockRefills.toString(),
                                  ),
                                  const SizedBox(width: kSpacingS),
                                  _statTile(
                                    context,
                                    icon: Icons.remove_circle_outline,
                                    label: 'Usage events',
                                    value: stockUsage.toString(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: kSpacingS),
                              Row(
                                children: [
                                  _statTile(
                                    context,
                                    icon: Icons.tune_outlined,
                                    label: 'Adjustments',
                                    value: stockAdjustments.toString(),
                                  ),
                                  const SizedBox(width: kSpacingS),
                                  _statTile(
                                    context,
                                    icon: Icons.delete_outline,
                                    label: 'Expired',
                                    value: stockExpired.toString(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: kSpacingS),
                              buildDetailInfoRow(
                                context,
                                label: 'Saved reconstitutions',
                                value: savedReconCount.toString(),
                              ),
                              if (allSupplies.isNotEmpty) ...[                                const SizedBox(height: kSpacingS),
                                const Divider(height: 1),
                                const SizedBox(height: kSpacingS),
                                buildDetailInfoRow(
                                  context,
                                  label: 'Supplies tracked',
                                  value: allSupplies.length.toString(),
                                ),
                                buildDetailInfoRow(
                                  context,
                                  label: 'Low-stock supplies',
                                  value: lowSuppliesCount == 0
                                      ? '—'
                                      : lowSuppliesCount.toString(),
                                  warning: lowSuppliesCount > 0,
                                ),
                                buildDetailInfoRow(
                                  context,
                                  label: 'Supplies expiring ≤30d',
                                  value: expiringSuppliesCount == 0
                                      ? '—'
                                      : expiringSuppliesCount.toString(),
                                  highlighted: expiringSuppliesCount > 0,
                                ),
                              ],
                            ],
                          ),
                          sectionSpacing,

                          // ── 6. Export ────────────────────────────────────────
                          SectionFormCard(
                            title: 'Export',
                            neutral: true,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: buildHelperText(
                                      context,
                                      _exportMedFilter.isEmpty
                                          ? 'Exporting all medications. Activity & inventory use the selected time range.'
                                          : '${_exportMedFilter.length} medication${_exportMedFilter.length == 1 ? '' : 's'} selected. Activity & inventory use the selected time range.',
                                    ),
                                  ),
                                  TextButton.icon(
                                    icon: Icon(
                                      _exportMedFilter.isEmpty
                                          ? Icons.filter_list
                                          : Icons.filter_list_off,
                                      size: kIconSizeSmall,
                                    ),
                                    label: Text(
                                      _exportMedFilter.isEmpty ? 'Filter' : 'Filtered',
                                    ),
                                    onPressed: () => _showExportFilterSheet(
                                      context,
                                      medItems,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: kSpacingS),
                              _exportButton(
                                context,
                                label: 'Summary',
                                icon: Icons.summarize_outlined,
                                enabled: true,
                                onShareCsv: () => _shareExport(
                                  summaryCsv,
                                  'skedux_summary.csv',
                                  'Skedux Analytics Summary',
                                ),
                                onSharePdf: () => _sharePdfExport(
                                  () => _pdf.buildTablePdf(
                                    title: 'Analytics Summary',
                                    csv: summaryCsv,
                                  ),
                                  'skedux_summary.pdf',
                                  'Skedux Analytics Summary',
                                ),
                              ),
                              const Divider(height: kSpacingL),
                              _exportButton(
                                context,
                                label: 'Medications',
                                icon: Icons.medication_outlined,
                                enabled: exportMeds.isNotEmpty,
                                onShareCsv: () async {
                                  final csv = _csv.medicationsToCsv(exportMeds);
                                  await _shareExport(
                                    csv,
                                    'skedux_medications.csv',
                                    'Skedux Medications',
                                  );
                                },
                                onSharePdf: () async {
                                  final csv = _csv.medicationsToCsv(exportMeds);
                                  await _sharePdfExport(
                                    () => _pdf.buildTablePdf(
                                      title: 'Medications',
                                      csv: csv,
                                      excludeColumns: const {'id'},
                                    ),
                                    'skedux_medications.pdf',
                                    'Skedux Medications',
                                  );
                                },
                              ),
                              const Divider(height: kSpacingL),
                              _exportButton(
                                context,
                                label: 'Schedules',
                                icon: Icons.schedule_outlined,
                                enabled: exportSchedules.isNotEmpty,
                                onShareCsv: () async {
                                  final csv = _csv.schedulesToCsv(exportSchedules);
                                  await _shareExport(
                                    csv,
                                    'skedux_schedules.csv',
                                    'Skedux Schedules',
                                  );
                                },
                                onSharePdf: () async {
                                  final csv = _csv.schedulesToCsv(exportSchedules);
                                  await _sharePdfExport(
                                    () => _pdf.buildTablePdf(
                                      title: 'Schedules',
                                      csv: csv,
                                      landscape: true,
                                    ),
                                    'skedux_schedules.pdf',
                                    'Skedux Schedules',
                                  );
                                },
                              ),
                              const Divider(height: kSpacingL),
                              _exportButton(
                                context,
                                label: 'Activity Log',
                                icon: Icons.history_outlined,
                                enabled: exportLogs.isNotEmpty,
                                onShareCsv: () async {
                                  final csv = _csv.entryLogsToCsv(
                                    exportLogs,
                                    range: range,
                                  );
                                  await _shareExport(
                                    csv,
                                    'skedux_activity_log.csv',
                                    'Skedux Activity Log',
                                  );
                                },
                                onSharePdf: () async {
                                  final csv = _csv.entryLogsToCsv(
                                    exportLogs,
                                    range: range,
                                  );
                                  await _sharePdfExport(
                                    () => _pdf.buildTablePdf(
                                      title: 'Activity Log',
                                      csv: csv,
                                      landscape: true,
                                    ),
                                    'skedux_activity_log.pdf',
                                    'Skedux Activity Log',
                                  );
                                },
                              ),
                              const Divider(height: kSpacingL),
                              _exportButton(
                                context,
                                label: 'Inventory Logs',
                                icon: Icons.inventory_2_outlined,
                                enabled: exportInventory.isNotEmpty,
                                onShareCsv: () async {
                                  final csv = _csv.inventoryLogsToCsv(
                                    exportInventory,
                                    range: range,
                                  );
                                  await _shareExport(
                                    csv,
                                    'skedux_inventory_logs.csv',
                                    'Skedux Inventory Logs',
                                  );
                                },
                                onSharePdf: () async {
                                  final csv = _csv.inventoryLogsToCsv(
                                    exportInventory,
                                    range: range,
                                  );
                                  await _sharePdfExport(
                                    () => _pdf.buildTablePdf(
                                      title: 'Inventory Logs',
                                      csv: csv,
                                      landscape: true,
                                    ),
                                    'skedux_inventory_logs.pdf',
                                    'Skedux Inventory Logs',
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: kPageBottomPadding),
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
          ),
        ],
      ),
    );
  }

  // ── small reusable sub-widgets ─────────────────────────────────────────────

  Widget _statTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingM,
          vertical: kSpacingS,
        ),
        decoration: buildStandardCardDecoration(context: context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: kIconSizeLarge,
              color: valueColor ?? cs.primary,
            ),
            const SizedBox(height: kSpacingXS),
            Text(
              label,
              style: helperTextStyle(context),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: kSpacingXS),
            Text(
              value,
              style: bodyTextStyle(context)?.copyWith(
                fontWeight: kFontWeightBold,
                fontSize: kFontSizeXLarge,
                color: valueColor ?? cs.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Renders a labelled horizontal-scrolling chip row for the filter card.
  ///
  /// [label] is a fixed-width left column; [chips] scroll horizontally so the
  /// card height stays fixed regardless of the number of items.
  Widget _filterRow(
    BuildContext context, {
    required String label,
    required List<Widget> chips,
  }) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = microHelperTextStyle(context)?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: kFontWeightSemiBold,
    );
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < chips.length; i++) ...[
                  chips[i],
                  if (i < chips.length - 1) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusChip),
      child: AnimatedContainer(
        duration: kAnimationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(kBorderRadiusChip),
          border: Border.all(
            color: selected
                ? cs.primary
                : cs.outline.withValues(alpha: 0.3),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: microHelperTextStyle(context)?.copyWith(
            color: selected ? cs.onPrimaryContainer : null,
            fontWeight: selected ? kFontWeightSemiBold : null,
          ),
        ),
      ),
    );
  }
}
