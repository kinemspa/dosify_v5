// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/supplies/domain/stock_movement.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';
import 'package:dosifi_v5/src/features/medications/domain/saved_reconstitution_calculation.dart';
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
  ReportTimeRangePreset _rangePreset = ReportTimeRangePreset.last30Days;

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<void> _copyExport(String text, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppSnackBar(context, successMessage);
  }

  static String _formLabel(MedicationForm form) => switch (form) {
    MedicationForm.tablet => 'Tablets',
    MedicationForm.capsule => 'Capsules',
    MedicationForm.prefilledSyringe => 'Pre-filled Syringes',
    MedicationForm.singleDoseVial => 'Single-dose Vials',
    MedicationForm.multiDoseVial => 'Multi-dose Vials',
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
            'No dose activity in selected range.',
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
    List<DoseLog> logItems,
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
      if (log.action != DoseAction.logged) continue;
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
            'No logged doses in selected range.',
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
                  '${day.month}/${day.day}\n${rod.toY.toInt()} doses',
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

  /// Horizontal metric bars for top-N medications.
  Widget _buildTopMedsChart(
    BuildContext context,
    List<MapEntry<String, int>> topActivity,
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
    final maxVal = topActivity.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color:
                              cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            kBorderRadiusChipTight,
                          ),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: maxVal == 0
                            ? 0
                            : (entry.value / maxVal).clamp(0.0, 1.0),
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(
                              kBorderRadiusChipTight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: kSpacingS),
                SizedBox(
                  width: 28,
                  child: Text(
                    entry.value.toString(),
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
    required VoidCallback? onCsv,
    required VoidCallback? onHtml,
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
            MenuItemButton(
              leadingIcon: const Icon(Icons.table_chart_outlined),
              onPressed: enabled ? onCsv : null,
              child: const Text('Copy CSV'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.code_outlined),
              onPressed: enabled ? onHtml : null,
              child: const Text('Copy HTML'),
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
    final doseLogsBox = Hive.box<DoseLog>('dose_logs');
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
                          doseLogs.values.toList(growable: false);
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

                      final logged = logItems
                          .where((l) => l.action == DoseAction.logged)
                          .length;
                      final skipped = logItems
                          .where((l) => l.action == DoseAction.skipped)
                          .length;
                      final snoozed = logItems
                          .where((l) => l.action == DoseAction.snoozed)
                          .length;
                      final totalDoseActions = logged + skipped + snoozed;
                      final adherencePercent = totalDoseActions == 0
                          ? 0
                          : ((logged / totalDoseActions) * 100).round();

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
                            (l) =>
                                l.changeType == InventoryChangeType.expired,
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
                      final topActivity =
                          activityByMedication.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));

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
                      final lowStockCount = medItems.where((m) {
                        if (!m.lowStockEnabled) return false;
                        return m.stockValue <=
                            (m.lowStockThreshold ??
                                m.lowStockVialsThresholdCount ??
                                0);
                      }).length;
                      final expiringCount = medItems.where((m) {
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
                        'Dose logs,${logItems.length}',
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
                          // ── 1. Overview ─────────────────────────────────────
                          SectionFormCard(
                            title: 'Overview',
                            neutral: true,
                            children: [
                              ReportTimeRangeSelectorRow(
                                value: _rangePreset,
                                onChanged: (next) =>
                                    setState(() => _rangePreset = next),
                              ),
                              const SizedBox(height: kSpacingM),
                              // 4-stat grid
                              Row(
                                children: [
                                  _statTile(
                                    context,
                                    icon: Icons.medication_outlined,
                                    label: 'Medications',
                                    value: medItems.length.toString(),
                                  ),
                                  const SizedBox(width: kSpacingS),
                                  _statTile(
                                    context,
                                    icon: Icons.schedule_outlined,
                                    label: 'Schedules',
                                    value: scheduleItems.length.toString(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: kSpacingS),
                              Row(
                                children: [
                                  _statTile(
                                    context,
                                    icon: Icons.check_circle_outline,
                                    label: 'Dose logs',
                                    value: logItems.length.toString(),
                                  ),
                                  const SizedBox(width: kSpacingS),
                                  _statTile(
                                    context,
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Stock logs',
                                    value: inventoryItems.length.toString(),
                                  ),
                                ],
                              ),
                              if (typeBreakdown.isNotEmpty) ...[
                                const SizedBox(height: kSpacingM),
                                buildHelperText(
                                  context,
                                  'Medications by type',
                                ),
                                const SizedBox(height: kSpacingXS),
                                Wrap(
                                  spacing: kSpacingS,
                                  runSpacing: kSpacingXS,
                                  children: [
                                    for (final form in MedicationForm.values)
                                      if ((typeBreakdown[form] ?? 0) > 0)
                                        _chip(
                                          context,
                                          '${_formLabel(form)}: ${typeBreakdown[form]}',
                                        ),
                                  ],
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
                            title: 'Daily Dose Activity',
                            neutral: true,
                            children: [
                              buildHelperText(
                                context,
                                'Logged doses per day — last $trendDays days.',
                              ),
                              const SizedBox(height: kSpacingM),
                              _buildDailyTrendChart(
                                context,
                                allLogItems, // use all logs so trend is bounded to trendDays window
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
                              buildHelperText(
                                context,
                                'Top ${topActivity.take(8).length} medications by dose actions in selected range.',
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
                              buildHelperText(
                                context,
                                'Export data as CSV or HTML. Dose & inventory exports use the selected time range.',
                              ),
                              const SizedBox(height: kSpacingM),
                              _exportButton(
                                context,
                                label: 'Summary',
                                icon: Icons.summarize_outlined,
                                enabled: true,
                                onCsv: () => _copyExport(
                                  summaryCsv,
                                  'Summary CSV copied',
                                ),
                                onHtml: () async {
                                  final html = _csv.csvToHtmlDocument(
                                    title: 'Analytics Summary',
                                    csv: summaryCsv,
                                  );
                                  await _copyExport(html, 'Summary HTML copied');
                                },
                              ),
                              const Divider(height: kSpacingL),
                              _exportButton(
                                context,
                                label: 'Medications',
                                icon: Icons.medication_outlined,
                                enabled: medItems.isNotEmpty,
                                onCsv: () async {
                                  final csv =
                                      _csv.medicationsToCsv(medItems);
                                  await _copyExport(csv, 'Medications CSV copied');
                                },
                                onHtml: () async {
                                  final csv =
                                      _csv.medicationsToCsv(medItems);
                                  final html = _csv.csvToHtmlDocument(
                                    title: 'Medications',
                                    csv: csv,
                                  );
                                  await _copyExport(
                                    html,
                                    'Medications HTML copied',
                                  );
                                },
                              ),
                              const Divider(height: kSpacingL),
                              _exportButton(
                                context,
                                label: 'Schedules',
                                icon: Icons.schedule_outlined,
                                enabled: scheduleItems.isNotEmpty,
                                onCsv: () async {
                                  final csv =
                                      _csv.schedulesToCsv(scheduleItems);
                                  await _copyExport(csv, 'Schedules CSV copied');
                                },
                                onHtml: () async {
                                  final csv =
                                      _csv.schedulesToCsv(scheduleItems);
                                  final html = _csv.csvToHtmlDocument(
                                    title: 'Schedules',
                                    csv: csv,
                                  );
                                  await _copyExport(
                                    html,
                                    'Schedules HTML copied',
                                  );
                                },
                              ),
                              const Divider(height: kSpacingL),
                              _exportButton(
                                context,
                                label: 'Dose Logs',
                                icon: Icons.history_outlined,
                                enabled: logItems.isNotEmpty,
                                onCsv: () async {
                                  final csv = _csv.doseLogsToCsv(
                                    logItems,
                                    range: range,
                                  );
                                  await _copyExport(csv, 'Dose Logs CSV copied');
                                },
                                onHtml: () async {
                                  final csv = _csv.doseLogsToCsv(
                                    logItems,
                                    range: range,
                                  );
                                  final html = _csv.csvToHtmlDocument(
                                    title: 'Dose Logs',
                                    csv: csv,
                                  );
                                  await _copyExport(
                                    html,
                                    'Dose Logs HTML copied',
                                  );
                                },
                              ),
                              const Divider(height: kSpacingL),
                              _exportButton(
                                context,
                                label: 'Inventory Logs',
                                icon: Icons.inventory_2_outlined,
                                enabled: inventoryItems.isNotEmpty,
                                onCsv: () async {
                                  final csv = _csv.inventoryLogsToCsv(
                                    inventoryItems,
                                    range: range,
                                  );
                                  await _copyExport(
                                    csv,
                                    'Inventory Logs CSV copied',
                                  );
                                },
                                onHtml: () async {
                                  final csv = _csv.inventoryLogsToCsv(
                                    inventoryItems,
                                    range: range,
                                  );
                                  final html = _csv.csvToHtmlDocument(
                                    title: 'Inventory Logs',
                                    csv: csv,
                                  );
                                  await _copyExport(
                                    html,
                                    'Inventory Logs HTML copied',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: kIconSizeSmall,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: kSpacingXS),
                Expanded(
                  child: Text(
                    label,
                    style: helperTextStyle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpacingXS),
            Text(
              value,
              style: bodyTextStyle(context)?.copyWith(
                fontWeight: kFontWeightSemiBold,
                fontSize: kFontSizeLarge,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingS,
        vertical: kSpacingXS,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(kBorderRadiusChip),
      ),
      child: Text(label, style: helperTextStyle(context)),
    );
  }
}
