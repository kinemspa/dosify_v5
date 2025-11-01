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

    Widget detailRow(String label, String? value) {
      if (value == null || value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: fieldLabelStyle(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: bodyTextStyle(context),
              ),
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
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Medication> box, _) {
          final updatedMed = box.get(med.id) ?? med;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Compact info header
              _buildInfoHeader(context, updatedMed),
              const SizedBox(height: 16),
              
              // Form-specific content
              ..._buildFormSpecificSections(context, updatedMed, detailRow),
              
              const SizedBox(height: 80),
            ],
          );
        },
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

// Section card matching app's large card styling
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
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: cs.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: sectionTitleStyle(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...visibleChildren,
      ],
    ),
  );
}

// Dark high-contrast header inspired by reconstitution calculator
Widget _buildInfoHeader(BuildContext context, Medication med) {
  final theme = Theme.of(context);
  
  return Container(
    decoration: BoxDecoration(
      color: kReconBackgroundDark,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        // Title area
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _formIcon(med.form),
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: kFontWeightBold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _formLabel(med.form),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: kFontWeightBold,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Divider
        Divider(
          color: Colors.white.withValues(alpha: 0.15),
          height: 1,
        ),
        // Info rows
        _editableInfoRow(
          context,
          med,
          Icons.business_outlined,
          'Manufacturer',
          med.manufacturer ?? 'Not set',
          'manufacturer',
          darkTheme: true,
        ),
        _editableInfoRow(
          context,
          med,
          Icons.science_outlined,
          'Strength',
          '${_formatNumber(med.strengthValue)} ${_unitLabel(med.strengthUnit)}',
          'strength',
          darkTheme: true,
        ),
        _editableInfoRow(
          context,
          med,
          Icons.inventory_2_outlined,
          'Stock',
          '${_formatNumber(med.stockValue)} ${_stockUnitLabel(med.stockUnit)}',
          'stock',
          warning: med.lowStockEnabled && 
                   med.stockValue <= (med.lowStockThreshold ?? 0),
          darkTheme: true,
        ),
        _editableInfoRow(
          context,
          med,
          Icons.place_outlined,
          'Location',
          (med.storageLocation?.isNotEmpty ?? false)
              ? med.storageLocation!
              : 'Not set',
          'location',
          darkTheme: true,
        ),
      ],
    ),
  );
}

Widget _editableInfoRow(
  BuildContext context,
  Medication med,
  IconData icon,
  String label,
  String value,
  String field, {
  bool warning = false,
  bool darkTheme = false,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  
  final iconColor = darkTheme
      ? Colors.white.withValues(alpha: kReconTextHighOpacity)
      : cs.primary;
  final labelColor = darkTheme
      ? Colors.white.withValues(alpha: kReconTextNormalOpacity)
      : cs.onSurface.withValues(alpha: kOpacityMedium);
  final valueColor = warning
      ? cs.error
      : darkTheme
          ? Colors.white.withValues(alpha: kReconTextHighOpacity)
          : cs.onSurface;
  final isNotSet = value == 'Not set';
  final actualValueColor = isNotSet
      ? (darkTheme
          ? Colors.white.withValues(alpha: kReconTextMutedOpacity)
          : cs.onSurface.withValues(alpha: kOpacityLow))
      : valueColor;
  final chevronColor = darkTheme
      ? Colors.white.withValues(alpha: 0.4)
      : cs.onSurface.withValues(alpha: kOpacityLow);
  
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _showEditDialog(context, med, field),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: kFontWeightSemiBold,
                      color: labelColor,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: kFontWeightMedium,
                      color: actualValueColor,
                      fontStyle: isNotSet ? FontStyle.italic : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: chevronColor,
            ),
          ],
        ),
      ),
    ),
  );
}

void _showEditDialog(BuildContext context, Medication med, String field) {
  final controller = TextEditingController();
  
  // Set initial value based on field
  switch (field) {
    case 'manufacturer':
      controller.text = med.manufacturer ?? '';
      break;
    case 'strength':
      controller.text = med.strengthValue.toString();
      break;
    case 'stock':
      controller.text = med.stockValue.toString();
      break;
    case 'location':
      controller.text = med.storageLocation ?? '';
      break;
  }
  
  String getFieldLabel() {
    switch (field) {
      case 'manufacturer':
        return 'Manufacturer';
      case 'strength':
        return 'Strength';
      case 'stock':
        return 'Stock';
      case 'location':
        return 'Storage Location';
      default:
        return field;
    }
  }
  
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit ${getFieldLabel()}'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: field == 'strength' || field == 'stock'
            ? TextInputType.number
            : TextInputType.text,
        decoration: buildFieldDecoration(
          context,
          hint: 'Enter ${getFieldLabel().toLowerCase()}',
        ),
        style: bodyTextStyle(context),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isEmpty && field != 'manufacturer' && field != 'location') {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Value cannot be empty')),
                );
              }
              return;
            }
            
            // Update medication based on field
            final box = Hive.box<Medication>('medications');
            Medication updated;
            
            switch (field) {
              case 'manufacturer':
                updated = med.copyWith(manufacturer: value.isEmpty ? null : value);
                break;
              case 'strength':
                final num = double.tryParse(value);
                if (num == null || num <= 0) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid number')),
                    );
                  }
                  return;
                }
                updated = med.copyWith(strengthValue: num);
                break;
              case 'stock':
                final num = double.tryParse(value);
                if (num == null || num < 0) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid number')),
                    );
                  }
                  return;
                }
                updated = med.copyWith(stockValue: num);
                break;
              case 'location':
                updated = med.copyWith(storageLocation: value.isEmpty ? null : value);
                break;
              default:
                return;
            }
            
            box.put(med.id, updated);
            Navigator.pop(context);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${getFieldLabel()} updated')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  ).then((_) => controller.dispose());
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
