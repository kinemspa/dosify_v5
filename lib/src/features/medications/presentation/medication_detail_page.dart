// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class MedicationDetailPage extends StatelessWidget {
  const MedicationDetailPage({super.key, this.medicationId, this.initial});
  final String? medicationId;
  final Medication? initial;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Medication>('medications');
    final med = initial ?? (medicationId != null ? box.get(medicationId) : null);

    if (med == null) {
      return const Scaffold(
        appBar: GradientAppBar(title: 'Medication', forceBackButton: true),
        body: Center(child: Text('Medication not found')),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    Widget detailRow(String label, String? value) {
      if (value == null || value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: fieldLabelStyle(context)?.copyWith(
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: bodyTextStyle(context)?.copyWith(
                color: cs.onSurface,
                height: kLineHeightNormal,
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
                MedicationForm.injectionPreFilledSyringe =>
                  '/medications/edit/injection/pfs/${med.id}',
                MedicationForm.injectionSingleDoseVial =>
                  '/medications/edit/injection/single/${med.id}',
                MedicationForm.injectionMultiDoseVial =>
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
                    content: Text('Deleted "${med.name}" — removed $removed linked schedule(s)'),
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
          SummaryHeaderCard(
            title: med.name,
            manufacturer: med.manufacturer,
            strengthValue: med.strengthValue,
            strengthUnitLabel: _unitLabel(med.strengthUnit),
            stockCurrent: med.stockValue,
            stockUnitLabel: _stockUnitLabel(med.stockUnit),
            lowStockEnabled: med.lowStockEnabled,
            lowStockThreshold: med.lowStockThreshold,
            showRefrigerate: med.requiresRefrigeration,
            expiryDate: med.expiry,
            neutral: true,
          ),
          const SizedBox(height: 16),

          // General Info
          _modernSection(
            context,
            'General',
            Icons.medication_outlined,
            [
              detailRow('Medication Name', med.name),
              detailRow('Type', _formLabel(med.form)),
              detailRow('Manufacturer', med.manufacturer),
              detailRow('Batch Number', med.batchNumber),
              detailRow('Description', med.description),
            ],
          ),
          const SizedBox(height: 12),

          // Strength & Composition
          _modernSection(
            context,
            'Strength & Composition',
            Icons.science_outlined,
            [
              detailRow(
                'Strength',
                '${med.strengthValue} ${_unitLabel(med.strengthUnit)}',
              ),
              if (med.perMlValue != null)
                detailRow(
                  'Concentration',
                  '${med.perMlValue} ${_concentrationLabel(med.strengthUnit)}',
                ),
              if (med.containerVolumeMl != null)
                detailRow('Vial Volume', '${med.containerVolumeMl} mL'),
            ],
          ),
          const SizedBox(height: 12),

          // Inventory
          _modernSection(
            context,
            'Inventory',
            Icons.inventory_2_outlined,
            [
              detailRow(
                'Current Stock',
                '${med.stockValue} ${_stockUnitLabel(med.stockUnit)}',
              ),
              if (med.lowStockEnabled)
                detailRow(
                  'Low Stock Alert',
                  'Enabled at ${med.lowStockThreshold ?? 0} ${_stockUnitLabel(med.stockUnit)}',
                )
              else
                detailRow('Low Stock Alert', 'Disabled'),
            ],
          ),
          const SizedBox(height: 12),

          // Storage
          _modernSection(
            context,
            'Storage',
            Icons.kitchen_outlined,
            [
              if (med.expiry != null)
                detailRow('Expiry Date', _fmtDate(med.expiry!)),
              detailRow('Storage Location', med.storageLocation),
              if (med.requiresRefrigeration)
                detailRow('Storage Requirements', 'Requires Refrigeration'),
              detailRow('Storage Instructions', med.storageInstructions),
            ],
          ),
          const SizedBox(height: 12),

          // Notes
          if (med.notes != null && med.notes!.isNotEmpty)
            _modernSection(
              context,
              'Notes',
              Icons.notes_outlined,
              [
                detailRow('Additional Notes', med.notes),
              ],
            ),

          const SizedBox(height: 80), // Space for FAB if needed
        ],
      ),
    );
  }
}

// Helper functions
String _twoDigits(int n) => n.toString().padLeft(2, '0');
String _fmtDate(DateTime d) =>
    '${_twoDigits(d.day)}/${_twoDigits(d.month)}/${d.year % 100}';

String _formLabel(MedicationForm form) => switch (form) {
      MedicationForm.tablet => 'Tablet',
      MedicationForm.capsule => 'Capsule',
      MedicationForm.injectionPreFilledSyringe => 'Pre-Filled Syringe',
      MedicationForm.injectionSingleDoseVial => 'Single Dose Vial',
      MedicationForm.injectionMultiDoseVial => 'Multi Dose Vial',
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

String _concentrationLabel(Unit u) => switch (u) {
      Unit.mg || Unit.mgPerMl => 'mg/mL',
      Unit.mcg || Unit.mcgPerMl => 'mcg/mL',
      Unit.g || Unit.gPerMl => 'g/mL',
      Unit.units || Unit.unitsPerMl => 'units/mL',
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
  final visibleChildren = children.where((w) => w is! SizedBox || w.key != null).toList();
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
              Icon(
                icon,
                size: 20,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: sectionTitleStyle(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...visibleChildren,
        ],
      ),
    ),
  );
}
