import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../medications/domain/medication.dart';
import '../domain/enums.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:hive/hive.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

class MedicationDetailPage extends StatelessWidget {
  const MedicationDetailPage({super.key, this.medicationId, this.initial});
  final String? medicationId;
  final Medication? initial;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Medication>('medications');
    final med = initial ?? (medicationId != null ? box.get(medicationId!) : null);

    if (med == null) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Medication', forceBackButton: true),
        body: const Center(child: Text('Medication not found')),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurfaceVariant,
    );
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: cs.onSurface,
    );

    Widget row(String label, String? value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 160, child: Text(label, style: labelStyle)),
              const SizedBox(width: 8),
              Expanded(child: Text(value ?? '-', style: valueStyle)),
            ],
          ),
        );

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
                MedicationForm.injectionPreFilledSyringe => '/medications/edit/injection/pfs/${med.id}',
                MedicationForm.injectionSingleDoseVial => '/medications/edit/injection/single/${med.id}',
                MedicationForm.injectionMultiDoseVial => '/medications/edit/injection/multi/${med.id}',
              };
              context.push(route);
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () async {
              final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete medication?'),
                      content: Text('Delete "${med.name}"? This will cancel and disable any future schedules for this medication. Past dose history (if any) remains.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
                      ],
                    ),
                  ) ??
                  false;
              if (!ok) return;

              // Cancel notifications and disable (not delete) related schedules so past records remain available
              final schedulesBox = Hive.box<Schedule>('schedules');
              final related = schedulesBox.values.where((s) => s.medicationId == med.id).toList(growable: false);
              int disabled = 0;
              for (final s in related) {
                await ScheduleScheduler.cancelFor(s.id);
                // Re-save schedule with active=false to prevent future scheduling but keep for reporting
                final updated = Schedule(
                  id: s.id,
                  name: s.name,
                  medicationName: s.medicationName,
                  doseValue: s.doseValue,
                  doseUnit: s.doseUnit,
                  minutesOfDay: s.minutesOfDay,
                  daysOfWeek: s.daysOfWeek,
                  minutesOfDayUtc: s.minutesOfDayUtc,
                  daysOfWeekUtc: s.daysOfWeekUtc,
                  medicationId: s.medicationId,
                  active: false,
                  timesOfDay: s.timesOfDay,
                  timesOfDayUtc: s.timesOfDayUtc,
                  cycleEveryNDays: s.cycleEveryNDays,
                  cycleAnchorDate: s.cycleAnchorDate,
                  doseUnitCode: s.doseUnitCode,
                  doseMassMcg: s.doseMassMcg,
                  doseVolumeMicroliter: s.doseVolumeMicroliter,
                  doseTabletQuarters: s.doseTabletQuarters,
                  doseCapsules: s.doseCapsules,
                  doseSyringes: s.doseSyringes,
                  doseVials: s.doseVials,
                  doseIU: s.doseIU,
                  displayUnitCode: s.displayUnitCode,
                  inputModeCode: s.inputModeCode,
                  createdAt: s.createdAt,
                );
                await schedulesBox.put(updated.id, updated);
                disabled++;
              }

              await box.delete(med.id);
              if (context.mounted) {
                context.go('/medications');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${med.name}" — disabled $disabled schedule(s)')),
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
          _section(context, 'General', [
            row('Name', med.name),
            row('Medication Type', switch (med.form) {
              MedicationForm.tablet => 'Tablet',
              MedicationForm.capsule => 'Capsule',
              MedicationForm.injectionPreFilledSyringe => 'Pre-Filled Syringe',
              MedicationForm.injectionSingleDoseVial => 'Single Dose Vial',
              MedicationForm.injectionMultiDoseVial => 'Multi Dose Vial',
            }),
            row('Manufacturer', med.manufacturer),
            row('Batch', med.batchNumber),
          ]),
          const SizedBox(height: 12),
          _section(context, 'Strength & Composition', [
            row('Strength', '${med.strengthValue} ${med.strengthUnit.name}'),
            if (med.perMlValue != null) row('Per mL', '${med.perMlValue} ${switch (med.strengthUnit) { Unit.mg => 'mg/mL', Unit.mcg => 'mcg/mL', Unit.g => 'g/mL', Unit.units => 'units/mL', Unit.mgPerMl => 'mg/mL', Unit.mcgPerMl => 'mcg/mL', Unit.gPerMl => 'g/mL', Unit.unitsPerMl => 'units/mL' }}'),
          ]),
          const SizedBox(height: 12),
          _section(context, 'Inventory', [
            row('Stock', '${med.stockValue} ${med.stockUnit.name}'),
            row('Low stock enabled', med.lowStockEnabled ? 'Yes' : 'No'),
            if (med.lowStockThreshold != null) row('Low stock threshold', '${med.lowStockThreshold}'),
          ]),
          const SizedBox(height: 12),
          _section(context, 'Storage', [
            row('Expiry', med.expiry != null ? _fmtDate(med.expiry!) : null),
            row('Storage location', med.storageLocation),
            row('Requires refrigeration', med.requiresRefrigeration ? 'Yes' : 'No'),
            row('Storage instructions', med.storageInstructions),
          ]),
          const SizedBox(height: 12),
          _section(context, 'Notes', [
            row('Description', med.description),
            row('Notes', med.notes),
          ]),
        ],
      ),
    );
  }
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');
String _fmtDate(DateTime d) => '${_twoDigits(d.day)}/${_twoDigits(d.month)}/${d.year % 100}';

Widget _section(BuildContext context, String title, List<Widget> children) {
  final theme = Theme.of(context);
  return Card(
    elevation: 0,
    color: theme.colorScheme.surfaceContainerLowest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    ),
  );
}
