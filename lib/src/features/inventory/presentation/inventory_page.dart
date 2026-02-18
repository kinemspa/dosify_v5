// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/id.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/medication_stock_service.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _tableExpanded = false;

  @override
  Widget build(BuildContext context) {
    final medsBox = Hive.box<Medication>('medications');
    final schedulesBox = Hive.box<Schedule>('schedules');
    final doseLogsBox = Hive.box<DoseLog>('dose_logs');

    return Scaffold(
      appBar: const GradientAppBar(title: 'Inventory', forceBackButton: true),
      body: ValueListenableBuilder<Box<Medication>>(
        valueListenable: medsBox.listenable(),
        builder: (context, meds, _) {
          return ValueListenableBuilder<Box<Schedule>>(
            valueListenable: schedulesBox.listenable(),
            builder: (context, schedules, __) {
              return ValueListenableBuilder<Box<DoseLog>>(
                valueListenable: doseLogsBox.listenable(),
                builder: (context, doseLogs, ___) {
                  final medItems = meds.values.toList(growable: false)
                    ..sort(
                      (a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                    );
                  final scheduleItems = schedules.values.toList(
                    growable: false,
                  );
                  final doseLogItems = doseLogs.values.toList(growable: false);

                  final medLow = medItems
                      .where(MedicationStockService.isLowStock)
                      .length;
                  final medOut = medItems
                      .where((m) => m.stockValue <= 0)
                      .length;

                  final takenDoses = doseLogItems
                      .where((d) => d.action == DoseAction.taken)
                      .length;

                  return ListView(
                    padding: const EdgeInsets.all(kSpacingL),
                    children: [
                      SectionFormCard(
                        title: 'Medications',
                        neutral: true,
                        children: [
                          buildDetailInfoRow(
                            context,
                            label: 'Total',
                            value: medItems.length.toString(),
                          ),
                          buildDetailInfoRow(
                            context,
                            label: 'Low stock',
                            value: medLow.toString(),
                            warning: medLow > 0,
                          ),
                          buildDetailInfoRow(
                            context,
                            label: 'Out of stock',
                            value: medOut.toString(),
                            warning: medOut > 0,
                          ),
                          buildDetailInfoRow(
                            context,
                            label: 'Used (taken doses)',
                            value: takenDoses.toString(),
                          ),
                          buildHelperText(
                            context,
                            'Overview of medication stock, expiry, and projected days remaining based on linked schedules.',
                          ),
                          const SizedBox(height: kSpacingS),
                          if (medItems.isEmpty)
                            Text(
                              'No medications',
                              style: mutedTextStyle(context),
                            )
                          else
                            Column(
                              children: [
                                for (int i = 0; i < medItems.length; i++) ...[
                                  _MedicationInventoryRow(
                                    medication: medItems[i],
                                    schedules: scheduleItems,
                                  ),
                                  if (i != medItems.length - 1)
                                    Divider(
                                      height: kSpacingS,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withValues(alpha: kOpacityVeryLow),
                                    ),
                                ],
                              ],
                            ),
                          const SizedBox(height: kSpacingS),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: () => context.go('/medications'),
                              child: const Text('View Medications'),
                            ),
                          ),
                        ],
                      ),
                      sectionSpacing,
                      CollapsibleSectionFormCard(
                        title: 'Inventory table',
                        neutral: true,
                        isExpanded: _tableExpanded,
                        onExpandedChanged: (v) {
                          setState(() => _tableExpanded = v);
                        },
                        children: [
                          buildHelperText(
                            context,
                            'A compact table view of stock, expiry, and projected days remaining for all medications.',
                          ),
                          const SizedBox(height: kSpacingS),
                          if (medItems.isEmpty)
                            Text(
                              'No medications',
                              style: mutedTextStyle(context),
                            )
                          else
                            _MedicationInventoryTable(
                              medications: medItems,
                              schedules: scheduleItems,
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

class _MedicationInventoryTable extends StatelessWidget {
  const _MedicationInventoryTable({
    required this.medications,
    required this.schedules,
  });

  final List<Medication> medications;
  final List<Schedule> schedules;

  List<Schedule> _linkedSchedules(Medication medication) {
    return schedules
        .where(
          (s) =>
              (s.medicationId != null && s.medicationId == medication.id) ||
              (s.medicationId == null && s.medicationName == medication.name),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                'Medication',
                style: hintLabelTextStyle(
                  context,
                  color: cs.onSurfaceVariant,
                )?.copyWith(fontWeight: kFontWeightSemiBold),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                'Remaining',
                textAlign: TextAlign.end,
                style: hintLabelTextStyle(
                  context,
                  color: cs.onSurfaceVariant,
                )?.copyWith(fontWeight: kFontWeightSemiBold),
              ),
            ),
            const SizedBox(width: kSpacingS),
            Expanded(
              flex: 2,
              child: Text(
                'Days',
                textAlign: TextAlign.end,
                style: hintLabelTextStyle(
                  context,
                  color: cs.onSurfaceVariant,
                )?.copyWith(fontWeight: kFontWeightSemiBold),
              ),
            ),
            const SizedBox(width: kSpacingS),
            Expanded(
              flex: 3,
              child: Text(
                'Expiry',
                textAlign: TextAlign.end,
                style: hintLabelTextStyle(
                  context,
                  color: cs.onSurfaceVariant,
                )?.copyWith(fontWeight: kFontWeightSemiBold),
              ),
            ),
            const SizedBox(width: kSpacingXS),
            SizedBox(
              width: kStepperButtonSize,
              child: Text(
                '',
                style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: kSpacingS),
        for (int i = 0; i < medications.length; i++) ...[
          _MedicationInventoryTableRow(
            medication: medications[i],
            linkedSchedules: _linkedSchedules(medications[i]),
          ),
          if (i != medications.length - 1)
            Divider(
              height: kSpacingS,
              color: cs.outlineVariant.withValues(alpha: kOpacityVeryLow),
            ),
        ],
      ],
    );
  }
}

class _MedicationInventoryTableRow extends StatelessWidget {
  const _MedicationInventoryTableRow({
    required this.medication,
    required this.linkedSchedules,
  });

  final Medication medication;
  final List<Schedule> linkedSchedules;

  String _formatShortDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatShortDate(date);
  }

  String _formatExpiryCell(BuildContext context) {
    final active = medication.reconstitutedVialExpiry;
    final sealed = medication.backupVialsExpiry ?? medication.expiry;

    if (medication.form == MedicationForm.multiDoseVial) {
      final parts = <String>[];
      if (active != null) parts.add('A: ${_formatShortDate(context, active)}');
      if (sealed != null) parts.add('S: ${_formatShortDate(context, sealed)}');
      if (parts.isEmpty) return '—';
      return parts.join('\n');
    }

    if (medication.expiry == null) return '—';
    return _formatShortDate(context, medication.expiry!);
  }

  Color _expiryColor(BuildContext context) {
    final active = medication.reconstitutedVialExpiry;
    final sealed = medication.backupVialsExpiry ?? medication.expiry;

    if (medication.form == MedicationForm.multiDoseVial) {
      final colors = <Color>[];
      if (active != null) {
        colors.add(
          expiryStatusColor(
            context,
            createdAt: medication.reconstitutedAt ?? medication.createdAt,
            expiry: active,
          ),
        );
      }
      if (sealed != null) {
        colors.add(
          expiryStatusColor(
            context,
            createdAt: medication.createdAt,
            expiry: sealed,
          ),
        );
      }
      if (colors.isEmpty) {
        return Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh);
      }
      if (colors.any((c) => c == Theme.of(context).colorScheme.error)) {
        return Theme.of(context).colorScheme.error;
      }
      if (colors.any((c) => c == Theme.of(context).colorScheme.secondary)) {
        return Theme.of(context).colorScheme.secondary;
      }
      return colors.first;
    }

    final exp = medication.expiry;
    if (exp == null) {
      return Theme.of(
        context,
      ).colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh);
    }
    return expiryStatusColor(
      context,
      createdAt: medication.createdAt,
      expiry: exp,
    );
  }

  DateTime? _runOutDateFromDaysRemaining(double? daysRemaining) {
    if (daysRemaining == null ||
        daysRemaining.isNaN ||
        daysRemaining.isInfinite ||
        daysRemaining <= 0) {
      return null;
    }
    final hours = (daysRemaining * 24).round();
    return DateTime.now().add(Duration(hours: hours));
  }

  Future<void> _showAddStockDialog(BuildContext context) async {
    final controller = TextEditingController(text: '1');
    final isMdv = medication.form == MedicationForm.multiDoseVial;

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final cs = theme.colorScheme;
        return AlertDialog(
          titleTextStyle: cardTitleStyle(
            dialogContext,
          )?.copyWith(color: cs.primary),
          contentTextStyle: bodyTextStyle(dialogContext),
          title: Text(isMdv ? 'Restock Sealed Vials' : 'Refill Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMdv
                    ? 'Add sealed vials to your reserve stock.'
                    : 'Add units to your current stock.',
                style: helperTextStyle(dialogContext),
              ),
              const SizedBox(height: kSpacingM),
              Field36(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                    signed: false,
                  ),
                  decoration: buildFieldDecoration(
                    dialogContext,
                    label: 'Amount',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(controller.text.trim()) ?? 0;
                Navigator.of(dialogContext).pop(v);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (result == null || result <= 0) return;

    final medsBox = Hive.box<Medication>('medications');
    final inventoryLogBox = Hive.box<InventoryLog>('inventory_logs');
    final now = DateTime.now();

    final bool isMultiDoseVial =
        medication.form == MedicationForm.multiDoseVial;
    if (isMultiDoseVial) {
      final prev = medication.stockValue;
      final next = prev + result;
      medsBox.put(medication.id, medication.copyWith(stockValue: next));

      final id = IdGen.newId(prefix: 'inv_restock');
      inventoryLogBox.put(
        id,
        InventoryLog(
          id: id,
          medicationId: medication.id,
          medicationName: medication.name,
          changeType: InventoryChangeType.vialRestocked,
          previousStock: prev,
          newStock: next,
          changeAmount: result,
          notes: 'Added ${result.toInt()} sealed vials',
          timestamp: now,
        ),
      );
      return;
    }

    final prev = medication.stockValue;
    final next = (prev + result).clamp(0.0, double.infinity);
    medsBox.put(medication.id, medication.copyWith(stockValue: next));
    final id = IdGen.newId(prefix: 'inv_refill');
    inventoryLogBox.put(
      id,
      InventoryLog(
        id: id,
        medicationId: medication.id,
        medicationName: medication.name,
        changeType: InventoryChangeType.refillAdd,
        previousStock: prev,
        newStock: next,
        changeAmount: result,
        notes: 'Refill from Inventory page',
        timestamp: now,
      ),
    );
  }

  Future<void> _showSetStockDialog(BuildContext context) async {
    final isMdv = medication.form == MedicationForm.multiDoseVial;
    final controller = TextEditingController(
      text: isMdv
          ? ((medication.activeVialVolume ?? medication.containerVolumeMl ?? 0)
                .toStringAsFixed(1))
          : medication.stockValue.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final cs = theme.colorScheme;

        final title = isMdv ? 'Set Active Vial Volume' : 'Set Stock';
        final helper = isMdv
            ? 'Set the current active vial volume (mL).'
            : 'Set the current stock amount.';

        return AlertDialog(
          titleTextStyle: cardTitleStyle(
            dialogContext,
          )?.copyWith(color: cs.primary),
          contentTextStyle: bodyTextStyle(dialogContext),
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(helper, style: helperTextStyle(dialogContext)),
              const SizedBox(height: kSpacingM),
              Field36(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  decoration: buildFieldDecoration(
                    dialogContext,
                    label: isMdv ? 'mL' : 'Stock',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(controller.text.trim());
                Navigator.of(dialogContext).pop(v);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (result == null) return;

    final medsBox = Hive.box<Medication>('medications');
    final inventoryLogBox = Hive.box<InventoryLog>('inventory_logs');
    final now = DateTime.now();

    if (isMdv) {
      final max = medication.containerVolumeMl;
      final prev =
          medication.activeVialVolume ?? medication.containerVolumeMl ?? 0;
      final next = (max != null && max > 0)
          ? result.clamp(0.0, max)
          : result.clamp(0.0, double.infinity);
      medsBox.put(medication.id, medication.copyWith(activeVialVolume: next));
      final id = IdGen.newId(prefix: 'inv_adjust');
      inventoryLogBox.put(
        id,
        InventoryLog(
          id: id,
          medicationId: medication.id,
          medicationName: medication.name,
          changeType: InventoryChangeType.manualAdjustment,
          previousStock: prev,
          newStock: next,
          changeAmount: next - prev,
          notes: 'Active vial set from Inventory page',
          timestamp: now,
        ),
      );
      return;
    }

    final prev = medication.stockValue;
    final next = result.clamp(0.0, double.infinity);
    medsBox.put(medication.id, medication.copyWith(stockValue: next));
    final id = IdGen.newId(prefix: 'inv_adjust');
    inventoryLogBox.put(
      id,
      InventoryLog(
        id: id,
        medicationId: medication.id,
        medicationName: medication.name,
        changeType: InventoryChangeType.manualAdjustment,
        previousStock: prev,
        newStock: next,
        changeAmount: next - prev,
        notes: 'Stock set from Inventory page',
        timestamp: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stockInfo = MedicationDisplayHelpers.calculateStock(medication);
    final daysRemaining = MedicationStockService.calculateDaysRemaining(
      medication,
      linkedSchedules,
    );

    final isMdv = medication.form == MedicationForm.multiDoseVial;
    final sealedCount = isMdv ? medication.stockValue.floor() : null;

    final stockColor = stockStatusColorFromPercentage(
      context,
      percentage: stockInfo.percentage,
    );
    final daysLabel = daysRemaining == null
        ? '—'
        : daysRemaining.isNaN
        ? '—'
        : daysRemaining.isInfinite
        ? '—'
        : daysRemaining < 1
        ? '<1'
        : daysRemaining.floor().toString();

    final runOutDate = _runOutDateFromDaysRemaining(daysRemaining);
    final runOutLabel = runOutDate == null
        ? ''
        : '\n${_formatShortDate(context, runOutDate)}';

    final daysWarning = daysRemaining != null && daysRemaining <= 7;
    final daysColor = daysWarning
        ? cs.error
        : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: bodyTextStyle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: kSpacingXXS),
                Text(
                  MedicationDisplayHelpers.formLabel(medication.form),
                  style: microHelperTextStyle(context)?.copyWith(
                    color: cs.onSurfaceVariant.withValues(
                      alpha: kOpacityMediumHigh,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              isMdv && sealedCount != null
                  ? '${stockInfo.label}\n$sealedCount sealed'
                  : stockInfo.label,
              textAlign: TextAlign.end,
              style: helperTextStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightSemiBold, color: stockColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: kSpacingS),
          Expanded(
            flex: 2,
            child: Text(
              '$daysLabel$runOutLabel',
              textAlign: TextAlign.end,
              style: helperTextStyle(
                context,
                color: daysColor,
              )?.copyWith(fontWeight: kFontWeightSemiBold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: kSpacingS),
          Expanded(
            flex: 3,
            child: Text(
              _formatExpiryCell(context),
              textAlign: TextAlign.end,
              style: helperTextStyle(
                context,
                color: _expiryColor(context),
              )?.copyWith(fontWeight: kFontWeightSemiBold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: kSpacingXS),
          SizedBox(
            width: kStepperButtonSize,
            height: kStepperButtonSize,
            child: PopupMenuButton<String>(
              tooltip: 'Actions',
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.more_vert,
                size: kIconSizeSmall,
                color: cs.onSurfaceVariant.withValues(
                  alpha: kOpacityMediumHigh,
                ),
              ),
              onSelected: (value) async {
                switch (value) {
                  case 'refill':
                    await _showAddStockDialog(context);
                    break;
                  case 'set':
                    await _showSetStockDialog(context);
                    break;
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];
                items.add(
                  PopupMenuItem(
                    value: 'refill',
                    child: Text(isMdv ? 'Restock sealed vials' : 'Refill'),
                  ),
                );
                items.add(
                  PopupMenuItem(
                    value: 'set',
                    child: Text(isMdv ? 'Set active vial' : 'Set stock'),
                  ),
                );
                return items;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationInventoryRow extends StatelessWidget {
  const _MedicationInventoryRow({
    required this.medication,
    required this.schedules,
  });

  final Medication medication;
  final List<Schedule> schedules;

  List<Schedule> _linkedSchedules() {
    return schedules
        .where(
          (s) =>
              (s.medicationId != null && s.medicationId == medication.id) ||
              (s.medicationId == null && s.medicationName == medication.name),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = MedicationStockService.calculateStockRatio(medication);
    final percentage = (ratio * 100).clamp(0.0, 100.0);

    final stockInfo = MedicationDisplayHelpers.calculateStock(medication);
    final linked = _linkedSchedules();
    final daysRemaining = MedicationStockService.calculateDaysRemaining(
      medication,
      linked,
    );

    final isMdv = medication.form == MedicationForm.multiDoseVial;
    final sealedCount = isMdv ? medication.stockValue.floor() : null;

    final daysLabel = daysRemaining == null
        ? '—'
        : daysRemaining.isNaN
        ? '—'
        : daysRemaining.isInfinite
        ? '—'
        : daysRemaining < 1
        ? '<1 day'
        : '${daysRemaining.floor()} days';

    final daysWarning = daysRemaining != null && daysRemaining <= 7;
    final daysColor = daysWarning
        ? cs.error
        : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: MiniStockGauge(
              percentage: percentage,
              color: cs.primary,
              size: 44,
            ),
          ),
          const SizedBox(width: kSpacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: cardTitleStyle(
                    context,
                  )?.copyWith(fontWeight: kFontWeightSemiBold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: kSpacingXS),
                Text(
                  '${MedicationDisplayHelpers.formLabel(medication.form)} • ${stockInfo.label}'
                  '${isMdv && sealedCount != null ? ' • $sealedCount sealed' : ''}',
                  style: helperTextStyle(context)?.copyWith(
                    fontWeight: kFontWeightSemiBold,
                    color: stockStatusColorFromPercentage(
                      context,
                      percentage: stockInfo.percentage,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: kSpacingS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Days left',
                style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: kSpacingXS),
              Text(
                daysLabel,
                style: helperTextStyle(
                  context,
                  color: daysColor,
                )?.copyWith(fontWeight: kFontWeightSemiBold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
