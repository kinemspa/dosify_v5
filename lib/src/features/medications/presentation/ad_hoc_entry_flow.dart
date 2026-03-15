import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/notifications/low_stock_notifier.dart';
import 'package:skedux/src/core/utils/id.dart';
import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/inventory_log.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:skedux/src/features/schedules/domain/calculated_entry.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';
import 'package:skedux/src/widgets/entry_action_sheet.dart';

bool _hasAdHocEligibleStock(Medication med) {
  if (med.form == MedicationForm.multiDoseVial) {
    return (med.activeVialVolume ?? med.containerVolumeMl ?? 0) > 0;
  }
  return med.stockValue > 0;
}

String _stockUnitLabel(StockUnit unit) => switch (unit) {
  StockUnit.tablets => 'tablets',
  StockUnit.capsules => 'capsules',
  StockUnit.preFilledSyringes => 'syringes',
  StockUnit.singleDoseVials => 'vials',
  StockUnit.multiDoseVials => 'vials',
  StockUnit.mcg => 'mcg',
  StockUnit.mg => 'mg',
  StockUnit.g => 'g',
};

Future<void> showAdHocMedicationPicker(BuildContext context) async {
  final medications = Hive.box<Medication>('medications').values
      .where(_hasAdHocEligibleStock)
      .toList(growable: false)
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  if (medications.isEmpty) {
    showAppSnackBar(
      context,
      'No medications with available stock for ad hoc entry.',
    );
    return;
  }

  final selected = await showModalBottomSheet<Medication>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final cs = Theme.of(sheetContext).colorScheme;
      return FractionallySizedBox(
        heightFactor: 0.82,
        child: SafeArea(
          child: Padding(
            padding: kPagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ad hoc',
                  style: cardTitleStyle(sheetContext)?.copyWith(
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: kSpacingXS),
                Text(
                  'Select a medication.',
                  style: helperTextStyle(sheetContext),
                ),
                const SizedBox(height: kSpacingM),
                Expanded(
                  child: ListView.separated(
                    itemCount: medications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (itemContext, index) {
                      final medication = medications[index];
                      final secondaryText = medication.form ==
                              MedicationForm.multiDoseVial
                          ? 'Active vial ${(medication.activeVialVolume ?? medication.containerVolumeMl ?? 0).toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} mL'
                          : 'Available ${medication.stockValue.toStringAsFixed(0)} ${_stockUnitLabel(medication.stockUnit)}';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.medication_outlined,
                          color: cs.primary,
                        ),
                        title: Text(
                          medication.name,
                          style: bodyTextStyle(itemContext)?.copyWith(
                            fontWeight: kFontWeightSemiBold,
                            color: cs.primary,
                          ),
                        ),
                        subtitle: Text(
                          secondaryText,
                          style: helperTextStyle(itemContext),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(itemContext).pop(medication),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (selected != null && context.mounted) {
    await showAdHocEntryDialog(context, selected);
  }
}

Future<void> showAdHocEntryDialog(BuildContext context, Medication med) async {
  final now = DateTime.now();
  final isMdv = med.form == MedicationForm.multiDoseVial;
  final entryUnit = isMdv ? 'mL' : _stockUnitLabel(med.stockUnit);
  final defaultAmount = 1.0;

  final id = IdGen.newId(prefix: 'entry_adhoc');
  final draftLog = EntryLog(
    id: id,
    scheduleId: 'ad_hoc',
    scheduleName: 'Ad hoc',
    medicationId: med.id,
    medicationName: med.name,
    scheduledTime: now.toUtc(),
    actionTime: now,
    entryValue: defaultAmount,
    entryUnit: entryUnit,
    action: EntryAction.logged,
  );

  final entry = CalculatedEntry(
    scheduleId: 'ad_hoc',
    scheduleName: 'Ad hoc',
    medicationName: med.name,
    scheduledTime: draftLog.scheduledTime,
    entryValue: defaultAmount,
    entryUnit: entryUnit,
    existingLog: draftLog,
  );

  await EntryActionSheet.show(
    context,
    entry: entry,
    initialStatus: EntryStatus.logged,
    onMarkLogged: (_) async {
      // Ad-hoc persistence is handled inside EntryActionSheet.
    },
    onSnooze: (_) async {
      // Not applicable for ad-hoc entries.
    },
    onSkip: (_) async {
      // Not applicable for ad-hoc entries.
    },
    onDelete: (_) async {
      final logBox = Hive.box<EntryLog>('entry_logs');
      final existing = logBox.get(draftLog.id);
      if (existing == null) return;

      if (existing.action == EntryAction.logged) {
        final medBox = Hive.box<Medication>('medications');
        final currentMed = medBox.get(existing.medicationId);
        if (currentMed != null) {
          final value = existing.actualEntryValue ?? existing.entryValue;
          final unit = existing.actualEntryUnit ?? existing.entryUnit;
          final delta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: currentMed,
            schedule: null,
            entryValue: value,
            entryUnit: unit,
            preferEntryValue: true,
          );
          if (delta != null && delta > 0) {
            final restored = MedicationStockAdjustment.restore(
              medication: currentMed,
              delta: delta,
            );
            await medBox.put(currentMed.id, restored);
            await LowStockNotifier.handleStockChange(
              before: currentMed,
              after: restored,
            );
          }
        }
      }

      await Hive.box<InventoryLog>('inventory_logs').delete(existing.id);
      await logBox.delete(existing.id);
    },
  );
}