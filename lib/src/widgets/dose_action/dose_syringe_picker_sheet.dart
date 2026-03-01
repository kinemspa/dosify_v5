import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_value_formatter.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// MDV dose change mode: by strength, volume, or syringe units.
enum MdvDoseChangeMode { strength, volume, units }

// ─── Pure utility functions ───────────────────────────────────────────────────

/// Returns the short strength-unit label for [med] (e.g. 'mg', 'mcg').
///
/// Extracted from [DoseActionSheet._mdvStrengthUnitFor].
String mdvStrengthUnitFor(Medication med) {
  return switch (med.strengthUnit) {
    Unit.mcg || Unit.mcgPerMl => 'mcg',
    Unit.mg || Unit.mgPerMl => 'mg',
    Unit.g || Unit.gPerMl => 'g',
    Unit.units || Unit.unitsPerMl => 'units',
  };
}

/// Infers the [MdvDoseChangeMode] from a raw dose-unit string.
///
/// Extracted from [DoseActionSheet._inferMdvModeFromUnit].
MdvDoseChangeMode inferMdvModeFromUnit(String rawUnit) {
  final u = rawUnit.trim().toLowerCase();
  if (u == 'ml' || u.contains('ml')) return MdvDoseChangeMode.volume;
  if (u == 'u' || u.contains('unit')) return MdvDoseChangeMode.units;
  return MdvDoseChangeMode.strength;
}

/// Returns the unit label shown next to the dose stepper for [mode].
///
/// Extracted from [DoseActionSheet._mdvDoseChangeUnitLabel].
String mdvDoseChangeUnitLabel(MdvDoseChangeMode mode, String strengthUnit) {
  return switch (mode) {
    MdvDoseChangeMode.units => 'units',
    MdvDoseChangeMode.volume => 'ml',
    MdvDoseChangeMode.strength => strengthUnit,
  };
}

/// Picks the best default [SyringeType] for [med] given an optional override.
///
/// Extracted from [DoseActionSheet._defaultMdvSyringeType].
SyringeType defaultMdvSyringeType(
  Medication med, {
  required double? overrideValue,
  required String overrideUnit,
}) {
  final doseVolumeMl = med.volumePerDose;
  if (doseVolumeMl != null && doseVolumeMl > 0) {
    return SyringeTypeLookup.forVolumeMl(doseVolumeMl);
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
/// Extracted from [DoseActionSheet._mdvStrengthToMcg].
double mdvStrengthToMcg(double value, String strengthUnit) {
  return switch (strengthUnit) {
    'mcg' => value,
    'mg' => value * 1000,
    'g' => value * 1000000,
    'units' => value,
    _ => value * 1000,
  };
}

/// Computes the [DoseCalculationResult] for an MDV dose-override text entry.
///
/// Returns `null` if any required parameter is missing or parsing fails.
/// Extracted from [DoseActionSheet._mdvDoseChangeResult].
DoseCalculationResult? mdvDoseChangeResult({
  required Medication med,
  required String rawText,
  required MdvDoseChangeMode? mode,
  required SyringeType? syringe,
  required String strengthUnit,
}) {
  final totalStrengthMcg = mdvTotalVialStrengthMcg(med);
  final totalVolumeMicroliter = mdvTotalVialVolumeMicroliter(med);
  if (mode == null || syringe == null) return null;
  if (totalStrengthMcg == null || totalVolumeMicroliter == null) return null;

  final value = double.tryParse(rawText.trim()) ?? 0;
  return switch (mode) {
    MdvDoseChangeMode.strength => DoseCalculator.calculateFromStrengthMDV(
      strengthMcg: mdvStrengthToMcg(value, strengthUnit),
      totalVialStrengthMcg: totalStrengthMcg,
      totalVialVolumeMicroliter: totalVolumeMicroliter,
      syringeType: syringe,
    ),
    MdvDoseChangeMode.volume => DoseCalculator.calculateFromVolumeMDV(
      volumeMicroliter: value * 1000,
      totalVialStrengthMcg: totalStrengthMcg,
      totalVialVolumeMicroliter: totalVolumeMicroliter,
      syringeType: syringe,
    ),
    MdvDoseChangeMode.units => DoseCalculator.calculateFromUnitsMDV(
      syringeUnits: value,
      totalVialStrengthMcg: totalStrengthMcg,
      totalVialVolumeMicroliter: totalVolumeMicroliter,
      syringeType: syringe,
    ),
  };
}

/// Total vial strength in micrograms for an MDV [med].
///
/// Extracted from [DoseActionSheet._mdvTotalVialStrengthMcg].
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
/// Extracted from [DoseActionSheet._mdvTotalVialVolumeMicroliter].
double? mdvTotalVialVolumeMicroliter(Medication med) {
  if (med.form != MedicationForm.multiDoseVial) return null;
  final volumeMl = med.containerVolumeMl ?? 1.0;
  return volumeMl * 1000;
}

// ─── Widget ───────────────────────────────────────────────────────────────────

/// Renders MDV-specific dose change controls: mode selector, syringe selector,
/// and the dose value stepper.
///
/// Extracted from [DoseActionSheet._buildEditSectionChildren] (MDV branch).
class DoseMdvControls extends StatelessWidget {
  const DoseMdvControls({
    super.key,
    required this.mode,
    required this.syringe,
    required this.strengthUnit,
    required this.doseOverrideController,
    required this.onModeChanged,
    required this.onSyringeChanged,
    required this.onValueChanged,
  });

  final MdvDoseChangeMode mode;
  final SyringeType syringe;
  final String strengthUnit;
  final TextEditingController doseOverrideController;
  final ValueChanged<MdvDoseChangeMode> onModeChanged;
  final ValueChanged<SyringeType> onSyringeChanged;
  final VoidCallback onValueChanged;

  String get _unitLabel => mdvDoseChangeUnitLabel(mode, strengthUnit);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelFieldRow(
          label: 'Mode',
          field: SmallDropdown36<MdvDoseChangeMode>(
            value: mode,
            items: const [
              DropdownMenuItem(
                value: MdvDoseChangeMode.strength,
                child: Text('Strength'),
              ),
              DropdownMenuItem(
                value: MdvDoseChangeMode.volume,
                child: Text('Volume'),
              ),
              DropdownMenuItem(
                value: MdvDoseChangeMode.units,
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
                controller: doseOverrideController,
                onDec: () {
                  final step = DoseValueFormatter.stepSizeForUnit(_unitLabel);
                  final v =
                      double.tryParse(doseOverrideController.text) ?? 0;
                  doseOverrideController.text = DoseValueFormatter.format(
                    (v - step).clamp(0.0, double.infinity),
                    _unitLabel,
                  );
                  onValueChanged();
                },
                onInc: () {
                  final step = DoseValueFormatter.stepSizeForUnit(_unitLabel);
                  final v =
                      double.tryParse(doseOverrideController.text) ?? 0;
                  doseOverrideController.text = DoseValueFormatter.format(
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
