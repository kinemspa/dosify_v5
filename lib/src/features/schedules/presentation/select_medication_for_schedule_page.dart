import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

class SelectMedicationForSchedulePage extends StatelessWidget {
  const SelectMedicationForSchedulePage({super.key});

  String _formatMedicationType(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return 'Tablet';
      case MedicationForm.capsule:
        return 'Capsule';
      case MedicationForm.injectionPreFilledSyringe:
        return 'Pre-Filled Syringe';
      case MedicationForm.injectionSingleDoseVial:
        return 'Single Dose Vial';
      case MedicationForm.injectionMultiDoseVial:
        return 'Multi-Dose Vial';
    }
  }

  String _formatStrength(Medication m) {
    final value = m.strengthValue;
    final formattedValue = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '$formattedValue ${_unitDisplayName(m.strengthUnit)}';
  }

  String _unitDisplayName(Unit unit) {
    switch (unit) {
      case Unit.mcg:
        return 'mcg';
      case Unit.mg:
        return 'mg';
      case Unit.g:
        return 'g';
      case Unit.units:
        return 'IU';
      case Unit.mcgPerMl:
        return 'mcg/mL';
      case Unit.mgPerMl:
        return 'mg/mL';
      case Unit.gPerMl:
        return 'g/mL';
      case Unit.unitsPerMl:
        return 'IU/mL';
    }
  }

  String _formatStock(Medication m) {
    switch (m.form) {
      case MedicationForm.tablet:
        final qty = m.stockValue?.toInt() ?? 0;
        return '$qty tablet${qty == 1 ? '' : 's'} remaining';
      case MedicationForm.capsule:
        final qty = m.stockValue?.toInt() ?? 0;
        return '$qty capsule${qty == 1 ? '' : 's'} remaining';
      case MedicationForm.injectionPreFilledSyringe:
        final qty = m.stockValue?.toInt() ?? 0;
        return '$qty syringe${qty == 1 ? '' : 's'} remaining';
      case MedicationForm.injectionSingleDoseVial:
        final qty = m.stockValue?.toInt() ?? 0;
        return '$qty vial${qty == 1 ? '' : 's'} remaining';
      case MedicationForm.injectionMultiDoseVial:
        final qty = m.stockValue?.toInt() ?? 0;
        return '$qty vial${qty == 1 ? '' : 's'} in stock';
    }
  }

  Color _getStockColor(BuildContext context, Medication m) {
    final qty = m.stockValue?.toInt() ?? 0;
    final lowStock = m.lowStockThreshold?.toInt() ?? 5;
    if (qty == 0) {
      return Theme.of(context).colorScheme.error;
    } else if (qty <= lowStock) {
      return Colors.orange;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Medication>('medications');
    final meds = box.values.toList(growable: false);

    // Filter out medications with no stock
    final availableMeds = meds.where((m) => (m.stockValue ?? 0) > 0).toList();

    return Scaffold(
      appBar: const GradientAppBar(title: 'Select Medication'),
      body: availableMeds.isEmpty
          ? Center(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No medications with stock',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add medications first to create schedules',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final m = availableMeds[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(m),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                label: 'Type',
                                value: _formatMedicationType(m.form),
                                icon: Icons.medication,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Strength',
                                value: _formatStrength(m),
                                icon: Icons.science_outlined,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Stock',
                                value: _formatStock(m),
                                icon: Icons.inventory_2_outlined,
                                valueColor: _getStockColor(context, m),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: availableMeds.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
