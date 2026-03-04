import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_calculator.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_value_formatter.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// MDV entry change mode: by strength, volume, or syringe units.
enum MdvEntryChangeMode { strength, volume, units }

// ─── Pure utility functions ───────────────────────────────────────────────────

/// Returns the short strength-unit label for [med] (e.g. 'mg', 'mcg').
///
/// Extracted from [EntryActionSheet._mdvStrengthUnitFor].
String mdvStrengthUnitFor(Medication med) {
  return switch (med.strengthUnit) {
    Unit.mcg || Unit.mcgPerMl => 'mcg',
    Unit.mg || Unit.mgPerMl => 'mg',
    Unit.g || Unit.gPerMl => 'g',
    Unit.units || Unit.unitsPerMl => 'units',
  };
}

/// Infers the [MdvEntryChangeMode] from a raw entry-unit string.
///
/// Extracted from [EntryActionSheet._inferMdvModeFromUnit].
MdvEntryChangeMode inferMdvModeFromUnit(String rawUnit) {
  final u = rawUnit.trim().toLowerCase();
  if (u == 'ml' || u.contains('ml')) return MdvEntryChangeMode.volume;
  if (u == 'u' || u.contains('unit')) return MdvEntryChangeMode.units;
  return MdvEntryChangeMode.strength;
}

/// Returns the unit label shown next to the entry stepper for [mode].
///
/// Extracted from [EntryActionSheet._mdvEntryChangeUnitLabel].
String mdvEntryChangeUnitLabel(MdvEntryChangeMode mode, String strengthUnit) {
  return switch (mode) {
    MdvEntryChangeMode.units => 'units',
    MdvEntryChangeMode.volume => 'ml',
    MdvEntryChangeMode.strength => strengthUnit,
  };
}

/// Picks the best default [SyringeType] for [med] given an optional override.
///
/// Extracted from [EntryActionSheet._defaultMdvSyringeType].
SyringeType defaultMdvSyringeType(
  Medication med, {
  required double? overrideValue,
  required String overrideUnit,
}) {
  final entryVolumeMl = med.volumePerEntry;
  if (entryVolumeMl != null && entryVolumeMl > 0) {
    return SyringeTypeLookup.forVolumeMl(entryVolumeMl);
  }

  final unit = overrideUnit.trim().toLowerCase();
  final v = overrideValue;
  if (v != null && v > 0) {
    if (unit == 'ml' || unit.contains('ml')) {
      return SyringeTypeLookup.forVolumeMl(v);
    }
    if (unit == 'u' || unit.contains('unit')) {
      return SyringeTypeLookup.forUnits(v);
    }
  }

  return SyringeType.ml_1_0;
}

/// Converts [value] in [strengthUnit] to micrograms.
///
/// Extracted from [EntryActionSheet._mdvStrengthToMcg].
double mdvStrengthToMcg(double value, String strengthUnit) {
  return switch (strengthUnit) {
    'mcg' => value,
    'mg' => value * 1000,
    'g' => value * 1000000,
    'units' => value,
    _ => value * 1000,
  };
}

/// Computes the [EntryCalculationResult] for an MDV entry-override text entry.
///
/// Returns `null` if any required parameter is missing or parsing fails.
/// Extracted from [EntryActionSheet._mdvEntryChangeResult].
EntryCalculationResult? mdvEntryChangeResult({
  required Medication med,
  required String rawText,
  required MdvEntryChangeMode? mode,
  required SyringeType? syringe,
  required String strengthUnit,
}) {
  final totalStrengthMcg = mdvTotalVialStrengthMcg(med);
  final totalVolumeMicroliter = mdvTotalVialVolumeMicroliter(med);
  if (mode == null || syringe == null) return null;
  if (totalStrengthMcg == null || totalVolumeMicroliter == null) return null;

  final value = double.tryParse(rawText.trim()) ?? 0;
  return switch (mode) {
    MdvEntryChangeMode.strength => EntryCalculator.calculateFromStrengthMDV(
      strengthMcg: mdvStrengthToMcg(value, strengthUnit),
      totalVialStrengthMcg: totalStrengthMcg,
      totalVialVolumeMicroliter: totalVolumeMicroliter,
      syringeType: syringe,
    ),
    MdvEntryChangeMode.volume => EntryCalculator.calculateFromVolumeMDV(
      volumeMicroliter: value * 1000,
      totalVialStrengthMcg: totalStrengthMcg,
      totalVialVolumeMicroliter: totalVolumeMicroliter,
      syringeType: syringe,
    ),
    MdvEntryChangeMode.units => EntryCalculator.calculateFromUnitsMDV(
      syringeUnits: value,
      totalVialStrengthMcg: totalStrengthMcg,
      totalVialVolumeMicroliter: totalVolumeMicroliter,
      syringeType: syringe,
    ),
  };
}

/// Total vial strength in micrograms for an MDV [med].
///
/// Extracted from [EntryActionSheet._mdvTotalVialStrengthMcg].
double? mdvTotalVialStrengthMcg(Medication med) {
  if (med.form != MedicationForm.multiDoseVial) return null;

  final volumeMl = med.containerVolumeMl ?? 1.0;
  final strength = med.strengthValue;

  return switch (med.strengthUnit) {
    Unit.mcg => strength,
    Unit.mg => strength * 1000,
    Unit.g => strength * 1000000,
    Unit.units => strength,
    Unit.mcgPerMl => strength * volumeMl,
    Unit.mgPerMl => (strength * 1000) * volumeMl,
    Unit.gPerMl => (strength * 1000000) * volumeMl,
    Unit.unitsPerMl => strength * volumeMl,
  };
}

/// Total vial volume in microliters for an MDV [med].
///
/// Extracted from [EntryActionSheet._mdvTotalVialVolumeMicroliter].
double? mdvTotalVialVolumeMicroliter(Medication med) {
  if (med.form != MedicationForm.multiDoseVial) return null;
  final volumeMl = med.containerVolumeMl ?? 1.0;
  return volumeMl * 1000;
}

// ─── Widget ───────────────────────────────────────────────────────────────────

/// Renders MDV-specific entry change controls: mode selector, syringe selector,
/// and the entry value stepper.
///
/// Extracted from [EntryActionSheet._buildEditSectionChildren] (MDV branch).
class EntryMdvControls extends StatelessWidget {
  const EntryMdvControls({
    super.key,
    required this.mode,
    required this.syringe,
    required this.strengthUnit,
    required this.entryOverrideController,
    required this.onModeChanged,
    required this.onSyringeChanged,
    required this.onValueChanged,
  });

  final MdvEntryChangeMode mode;
  final SyringeType syringe;
  final String strengthUnit;
  final TextEditingController entryOverrideController;
  final ValueChanged<MdvEntryChangeMode> onModeChanged;
  final ValueChanged<SyringeType> onSyringeChanged;
  final VoidCallback onValueChanged;

  String get _unitLabel => mdvEntryChangeUnitLabel(mode, strengthUnit);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelFieldRow(
          label: 'Mode',
          field: SmallDropdown36<MdvEntryChangeMode>(
            value: mode,
            items: const [
              DropdownMenuItem(
                value: MdvEntryChangeMode.strength,
                child: Text('Strength'),
              ),
              DropdownMenuItem(
                value: MdvEntryChangeMode.volume,
                child: Text('Volume'),
              ),
              DropdownMenuItem(
                value: MdvEntryChangeMode.units,
                child: Text('Units'),
              ),
            ],
            onChanged: (value) {
              if (value == null || value == mode) return;
              onModeChanged(value);
            },
          ),
        ),
        const SizedBox(height: kSpacingXS),
        LabelFieldRow(
          label: 'Syringe',
          field: SmallDropdown36<SyringeType>(
            value: syringe,
            items: SyringeType.values
                .where((t) => t != SyringeType.ml_10_0)
                .map(
                  (t) => DropdownMenuItem<SyringeType>(
                    value: t,
                    child: Text(t.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null || value == syringe) return;
              onSyringeChanged(value);
            },
          ),
        ),
        const SizedBox(height: kSpacingXS),
        Row(
          children: [
            Expanded(
              child: StepperRow36(
                controller: entryOverrideController,
                onDec: () {
                  final step = EntryValueFormatter.stepSizeForUnit(_unitLabel);
                  final v =
                      double.tryParse(entryOverrideController.text) ?? 0;
                  entryOverrideController.text = EntryValueFormatter.format(
                    (v - step).clamp(0.0, double.infinity),
                    _unitLabel,
                  );
                  onValueChanged();
                },
                onInc: () {
                  final step = EntryValueFormatter.stepSizeForUnit(_unitLabel);
                  final v =
                      double.tryParse(entryOverrideController.text) ?? 0;
                  entryOverrideController.text = EntryValueFormatter.format(
                    (v + step).clamp(0.0, double.infinity),
                    _unitLabel,
                  );
                  onValueChanged();
                },
                decoration: buildCompactFieldDecoration(context: context),
              ),
            ),
            const SizedBox(width: kSpacingS),
            Text(
              _unitLabel,
              style: helperTextStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightMedium),
            ),
          ],
        ),
        const SizedBox(height: kSpacingXS),
      ],
    );
  }
}
