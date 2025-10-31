// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class MedicationDetailPage extends StatelessWidget {
  const MedicationDetailPage({super.key, this.medicationId, this.initial});
  final String? medicationId;
  final Medication? initial;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Medication>('medications');
    final med =
        initial ?? (medicationId != null ? box.get(medicationId) : null);

    if (med == null) {
      return const Scaffold(
        appBar: GradientAppBar(title: 'Medication', forceBackButton: true),
        body: Center(child: Text('Medication not found')),
      );
    }

    final cs = Theme.of(context).colorScheme;

    Widget detailRow(String label, String? value) {
      if (value == null || value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: fieldLabelStyle(context)?.copyWith(color: cs.primary),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: bodyTextStyle(
                context,
              )?.copyWith(color: cs.onSurface, height: kLineHeightNormal),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: med.name,
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () {
              final route = switch (med.form) {
                MedicationForm.tablet => '/medications/edit/tablet/${med.id}',
                MedicationForm.capsule => '/medications/edit/capsule/${med.id}',
                MedicationForm.prefilledSyringe =>
                  '/medications/edit/injection/pfs/${med.id}',
                MedicationForm.singleDoseVial =>
                  '/medications/edit/injection/single/${med.id}',
                MedicationForm.multiDoseVial =>
                  '/medications/edit/injection/multi/${med.id}',
              };
              context.push(route);
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () async {
              final ok =
                  await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete medication?'),
                      content: Text(
                        'Delete "${med.name}"? This will cancel and DELETE any schedules linked to this medication.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (!ok) return;

              // Cancel notifications and DELETE related schedules (fundamental rule)
              final schedulesBox = Hive.box<Schedule>('schedules');
              final related = schedulesBox.values
                  .where((s) => s.medicationId == med.id)
                  .toList(growable: false);
              var removed = 0;
              for (final s in related) {
                await ScheduleScheduler.cancelFor(s.id);
                await schedulesBox.delete(s.id);
                removed++;
              }

              await box.delete(med.id);
              if (context.mounted) {
                context.go('/medications');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Deleted "${med.name}" — removed $removed linked schedule(s)',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card
          _buildSummaryCard(context, med),
          const SizedBox(height: 16),

          // Form-specific content
          ..._buildFormSpecificSections(context, med, detailRow),

          const SizedBox(height: 80), // Space for FAB if needed
        ],
      ),
    );
  }
}

// Helper functions
String _formLabel(MedicationForm form) => switch (form) {
      MedicationForm.tablet => 'Tablet',
      MedicationForm.capsule => 'Capsule',
      MedicationForm.prefilledSyringe => 'Pre-Filled Syringe',
      MedicationForm.singleDoseVial => 'Single Dose Vial',
      MedicationForm.multiDoseVial => 'Multi Dose Vial',
    };

String _unitLabel(Unit u) => switch (u) {
      Unit.mcg => 'mcg',
      Unit.mg => 'mg',
      Unit.g => 'g',
      Unit.units => 'units',
      Unit.mcgPerMl => 'mcg/mL',
      Unit.mgPerMl => 'mg/mL',
      Unit.gPerMl => 'g/mL',
      Unit.unitsPerMl => 'units/mL',
    };

String _stockUnitLabel(StockUnit u) => switch (u) {
  StockUnit.tablets => 'tablets',
  StockUnit.capsules => 'capsules',
  StockUnit.preFilledSyringes => 'syringes',
  StockUnit.singleDoseVials => 'vials',
  StockUnit.multiDoseVials => 'vials',
  StockUnit.mcg => 'mcg',
  StockUnit.mg => 'mg',
  StockUnit.g => 'g',
};

// Modern section widget with icon
Widget _modernSection(
  BuildContext context,
  String title,
  IconData icon,
  List<Widget> children,
) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  // Filter out empty widgets
  final visibleChildren =
      children.where((w) => w is! SizedBox || w.key != null).toList();
  if (visibleChildren.isEmpty) return const SizedBox.shrink();

  return Container(
    decoration: softWhiteCardDecoration(context),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(title, style: sectionTitleStyle(context)),
            ],
          ),
          const SizedBox(height: 16),
          ...visibleChildren,
        ],
      ),
    ),
  );
}

Widget _buildSummaryCard(BuildContext context, Medication med) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  return Container(
    decoration: BoxDecoration(
      color: cs.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: cs.primary.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.onPrimaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _formIcon(med.form),
                color: cs.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formLabel(med.form),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.85),
                    ),
                  ),
                  if (med.manufacturer != null) ...{
                    const SizedBox(height: 2),
                    Text(
                      med.manufacturer!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  },
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _summaryChip(
              context,
              Icons.inventory_2,
              '${_formatNumber(med.stockValue)} ${_stockUnitLabel(med.stockUnit)}',
            ),
            if (med.strengthValue > 0)
              _summaryChip(
                context,
                Icons.science,
                '${_formatNumber(med.strengthValue)} ${_unitLabel(med.strengthUnit)}',
              ),
            if (med.volumePerDose != null && med.volumePerDose! > 0)
              _summaryChip(
                context,
                Icons.water_drop,
                '${_formatNumber(med.volumePerDose!)} ${med.volumeUnit?.name ?? "ml"}',
              ),
            if (med.expiry != null)
              _summaryChip(
                context,
                Icons.calendar_today,
                'Exp: ${DateFormat('MMM d, y').format(med.expiry!)}',
                warning: _isExpiringSoon(med.expiry!),
              ),
            if (med.requiresRefrigeration)
              _summaryChip(context, Icons.ac_unit, 'Refrigerate'),
            if (med.lowStockEnabled)
              _summaryChip(
                context,
                Icons.warning_amber,
                'Alert at ${_formatNumber(med.lowStockThreshold ?? 0)}',
                warning: med.stockValue <= (med.lowStockThreshold ?? 0),
              ),
          ],
        ),
      ],
    ),
  );
}

Widget _summaryChip(
  BuildContext context,
  IconData icon,
  String label, {
  bool warning = false,
}) {
  final cs = Theme.of(context).colorScheme;
  final bgColor = warning
      ? cs.errorContainer.withValues(alpha: 0.3)
      : cs.onPrimaryContainer.withValues(alpha: 0.1);
  final fgColor =
      warning ? cs.error : cs.onPrimaryContainer.withValues(alpha: 0.85);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fgColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    ),
  );
}

List<Widget> _buildFormSpecificSections(
  BuildContext context,
  Medication med,
  Widget Function(String, String?) detailRow,
) {
  switch (med.form) {
    case MedicationForm.tablet:
    case MedicationForm.capsule:
      return _buildOralMedicationSections(context, med, detailRow);
    case MedicationForm.prefilledSyringe:
      return _buildPrefilledSyringeSections(context, med, detailRow);
    case MedicationForm.singleDoseVial:
      return _buildSingleDoseVialSections(context, med, detailRow);
    case MedicationForm.multiDoseVial:
      return _buildMultiDoseVialSections(context, med, detailRow);
  }
}

List<Widget> _buildOralMedicationSections(
  BuildContext context,
  Medication med,
  Widget Function(String, String?) detailRow,
) {
  return [
    _modernSection(context, 'Medication Details', Icons.medication_outlined, [
      detailRow('Form', _formLabel(med.form)),
      detailRow('Manufacturer', med.manufacturer),
      detailRow('Batch Number', med.batchNumber),
      detailRow('Description', med.description),
    ]),
    const SizedBox(height: 12),
    _modernSection(context, 'Strength', Icons.science_outlined, [
      detailRow(
        'Active Ingredient',
        '${_formatNumber(med.strengthValue)} ${_unitLabel(med.strengthUnit)}',
      ),
    ]),
    const SizedBox(height: 12),
    _modernSection(context, 'Inventory', Icons.inventory_2_outlined, [
      detailRow(
        'Current Stock',
        '${_formatNumber(med.stockValue)} ${_stockUnitLabel(med.stockUnit)}',
      ),
      if (med.initialStockValue != null)
        detailRow(
          'Initial Stock',
          '${_formatNumber(med.initialStockValue!)} ${_stockUnitLabel(med.stockUnit)}',
        ),
      detailRow(
        'Low Stock Alert',
        med.lowStockEnabled
            ? 'Enabled at ${_formatNumber(med.lowStockThreshold ?? 0)} ${_stockUnitLabel(med.stockUnit)}'
            : 'Disabled',
      ),
    ]),
    const SizedBox(height: 12),
    _modernSection(context, 'Storage', Icons.kitchen_outlined, [
      if (med.expiry != null)
        detailRow('Expiry Date', DateFormat('MMMM d, y').format(med.expiry!)),
      detailRow('Storage Location', med.storageLocation),
      if (med.requiresRefrigeration)
        detailRow('Refrigeration', 'Required (2-8°C)'),
      detailRow('Storage Instructions', med.storageInstructions),
    ]),
    if (med.notes != null && med.notes!.isNotEmpty) ...{
      const SizedBox(height: 12),
      _modernSection(context, 'Notes', Icons.notes_outlined, [
        detailRow('Additional Notes', med.notes),
      ]),
    },
  ];
}

List<Widget> _buildPrefilledSyringeSections(
  BuildContext context,
  Medication med,
  Widget Function(String, String?) detailRow,
) {
  return [
    _modernSection(context, 'Medication Details', Icons.vaccines, [
      detailRow('Form', _formLabel(med.form)),
      detailRow('Manufacturer', med.manufacturer),
      detailRow('Batch Number', med.batchNumber),
      detailRow('Description', med.description),
    ]),
    const SizedBox(height: 12),
    _modernSection(context, 'Concentration & Volume', Icons.science_outlined, [
      detailRow(
        'Concentration',
        '${_formatNumber(med.strengthValue)} ${_unitLabel(med.strengthUnit)}',
      ),
      if (med.volumePerDose != null && med.volumePerDose! > 0)
        detailRow(
          'Volume per Syringe',
          '${_formatNumber(med.volumePerDose!)} ${med.volumeUnit?.name ?? "ml"}',
        ),
    ]),
    const SizedBox(height: 12),
    _modernSection(context, 'Inventory', Icons.inventory_2_outlined, [
      detailRow(
        'Current Stock',
        '${_formatNumber(med.stockValue)} ${_stockUnitLabel(med.stockUnit)}',
      ),
      if (med.initialStockValue != null)
        detailRow(
          'Initial Stock',
          '${_formatNumber(med.initialStockValue!)} ${_stockUnitLabel(med.stockUnit)}',
        ),
      detailRow(
        'Low Stock Alert',
        med.lowStockEnabled
            ? 'Enabled at ${_formatNumber(med.lowStockThreshold ?? 0)} ${_stockUnitLabel(med.stockUnit)}'
            : 'Disabled',
      ),
    ]),
    const SizedBox(height: 12),
    _modernSection(context, 'Storage', Icons.kitchen_outlined, [
      if (med.expiry != null)
        detailRow('Expiry Date', DateFormat('MMMM d, y').format(med.expiry!)),
      detailRow('Storage Location', med.storageLocation),
      if (med.requiresRefrigeration)
        detailRow('Refrigeration', 'Required (2-8°C)'),
      detailRow('Storage Instructions', med.storageInstructions),
    ]),
    if (med.notes != null && med.notes!.isNotEmpty) ...{
      const SizedBox(height: 12),
      _modernSection(context, 'Notes', Icons.notes_outlined, [
        detailRow('Additional Notes', med.notes),
      ]),
    },
  ];
}

List<Widget> _buildSingleDoseVialSections(
  BuildContext context,
  Medication med,
  Widget Function(String, String?) detailRow,
) {
  return [
    _modernSection(context, 'Medication Details', Icons.science_outlined, [
      detailRow('Form', _formLabel(med.form)),
      detailRow('Manufacturer', med.manufacturer),
      detailRow('Batch Number', med.batchNumber),
      detailRow('Description', med.description),
    ]),
    const SizedBox(height: 12),
    _modernSection(context, 'Concentration', Icons.water_drop_outlined, [
      detailRow(
        'Strength',
        '${_formatNumber(med.strengthValue)} ${_unitLabel(med.strengthUnit)}',
      ),
      if (med.containerVolumeMl != null && med.containerVolumeMl! > 0)
        detailRow('Vial Volume', '${_formatNumber(med.containerVolumeMl!)} mL'),
    ]),
    const SizedBox(height: 12),
    _modernSection(context, 'Inventory', Icons.inventory_2_outlined, [
      detailRow(
        'Current Stock',
        '${_formatNumber(med.stockValue)} ${_stockUnitLabel(med.stockUnit)}',
      ),
      if (med.initialStockValue != null)
        detailRow(
          'Initial Stock',
          '${_formatNumber(med.initialStockValue!)} ${_stockUnitLabel(med.stockUnit)}',
        ),
      detailRow(
        'Low Stock Alert',
        med.lowStockEnabled
            ? 'Enabled at ${_formatNumber(med.lowStockThreshold ?? 0)} ${_stockUnitLabel(med.stockUnit)}'
            : 'Disabled',
      ),
    ]),
    const SizedBox(height: 12),
    _modernSection(context, 'Storage', Icons.kitchen_outlined, [
      if (med.expiry != null)
        detailRow('Expiry Date', DateFormat('MMMM d, y').format(med.expiry!)),
      detailRow('Storage Location', med.storageLocation),
      if (med.requiresRefrigeration)
        detailRow('Refrigeration', 'Required (2-8°C)'),
      detailRow('Storage Instructions', med.storageInstructions),
    ]),
    if (med.notes != null && med.notes!.isNotEmpty) ...{
      const SizedBox(height: 12),
      _modernSection(context, 'Notes', Icons.notes_outlined, [
        detailRow('Additional Notes', med.notes),
      ]),
    },
  ];
}

List<Widget> _buildMultiDoseVialSections(
  BuildContext context,
  Medication med,
  Widget Function(String, String?) detailRow,
) {
  return [
    _modernSection(context, 'Medication Details', Icons.science_outlined, [
      detailRow('Form', _formLabel(med.form)),
      detailRow('Manufacturer', med.manufacturer),
      detailRow('Batch Number', med.batchNumber),
      detailRow('Description', med.description),
    ]),
    const SizedBox(height: 12),
    _modernSection(context, 'Active Vial', Icons.science_outlined, [
      if (med.reconstitutedAt != null)
        detailRow(
          'Reconstituted',
          DateFormat('MMMM d, y HH:mm').format(med.reconstitutedAt!),
        ),
      if (med.reconstitutedVialExpiry != null)
        detailRow(
          'Expires',
          DateFormat('MMMM d, y HH:mm').format(med.reconstitutedVialExpiry!),
        ),
      if (med.containerVolumeMl != null && med.containerVolumeMl! > 0)
        detailRow(
          'Total Volume',
          '${_formatNumber(med.containerVolumeMl!)} mL',
        ),
      if (med.activeVialLowStockMl != null)
        detailRow(
          'Low Stock Alert',
          'At ${_formatNumber(med.activeVialLowStockMl!)} mL',
        ),
      detailRow('Batch Number', med.activeVialBatchNumber),
      detailRow('Storage Location', med.activeVialStorageLocation),
      if (med.activeVialRequiresRefrigeration)
        detailRow('Refrigeration', 'Required'),
      if (med.activeVialRequiresFreezer) detailRow('Storage', 'Freezer'),
      if (med.activeVialLightSensitive)
        detailRow('Light Sensitivity', 'Protect from light'),
    ]),
    const SizedBox(height: 12),
    _modernSection(context, 'Backup Stock', Icons.inventory_2_outlined, [
      detailRow(
        'Backup Vials',
        '${_formatNumber(med.stockValue)} ${_stockUnitLabel(med.stockUnit)}',
      ),
      if (med.lowStockVialsThresholdCount != null)
        detailRow(
          'Low Stock Alert',
          'At ${_formatNumber(med.lowStockVialsThresholdCount!)} vials',
        ),
      if (med.backupVialsExpiry != null)
        detailRow(
          'Expiry',
          DateFormat('MMMM d, y').format(med.backupVialsExpiry!),
        ),
      detailRow('Batch Number', med.backupVialsBatchNumber),
      detailRow('Storage Location', med.backupVialsStorageLocation),
      if (med.backupVialsRequiresRefrigeration)
        detailRow('Refrigeration', 'Required'),
      if (med.backupVialsRequiresFreezer) detailRow('Storage', 'Freezer'),
      if (med.backupVialsLightSensitive)
        detailRow('Light Sensitivity', 'Protect from light'),
    ]),
    if (med.notes != null && med.notes!.isNotEmpty) ...{
      const SizedBox(height: 12),
      _modernSection(context, 'Notes', Icons.notes_outlined, [
        detailRow('Additional Notes', med.notes),
      ]),
    },
  ];
}

IconData _formIcon(MedicationForm form) => switch (form) {
      MedicationForm.tablet => Icons.medication,
      MedicationForm.capsule => Icons.medication_liquid,
      MedicationForm.prefilledSyringe => Icons.vaccines,
      MedicationForm.singleDoseVial => Icons.science,
      MedicationForm.multiDoseVial => Icons.science,
    };

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}

bool _isExpiringSoon(DateTime expiry) {
  final now = DateTime.now();
  final daysUntilExpiry = expiry.difference(now).inDays;
  return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
}
