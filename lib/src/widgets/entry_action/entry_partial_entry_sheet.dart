import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:skedux/src/features/schedules/domain/entry_calculator.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/entry_value_formatter.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/widgets/entry_action/entry_syringe_picker_sheet.dart';
import 'package:skedux/src/widgets/unified_form.dart';

/// The content of the entry details section inside [EntryActionSheet].
///
/// Renders either:
/// - an **ad hoc amount** stepper when [isAdHoc] is true, or
/// - a **entry-override** stepper (with optional MDV controls) for scheduled
///   entries.
///
/// Extracted from [EntryActionSheet._buildEditSectionChildren].
class EntryPartialEntrySection extends StatelessWidget {
  const EntryPartialEntrySection({
    super.key,
    required this.isAdHoc,
    required this.existingLog,
    required this.scheduleId,
    required this.amountController,
    required this.maxAdHocAmount,
    required this.entryBaseUnit,
    required this.entryOverrideController,
    required this.entryOverrideUnit,
    required this.mdvMode,
    required this.mdvSyringe,
    required this.mdvStrengthUnit,
    required this.onChanged,
    required this.onMdvModeChanged,
    required this.onMdvSyringeChanged,
    required this.onUnitChanged,
    this.onMdvStrengthUnitChanged,
  });

  final bool isAdHoc;
  final EntryLog? existingLog;

  /// Schedule ID used to look up the schedule and determine if the medication
  /// is an MDV.
  final String? scheduleId;

  /// Controller for the ad-hoc amount field (non-null when [isAdHoc]).
  final TextEditingController? amountController;

  /// Upper bound for the ad-hoc amount, or `null` for unbounded.
  final double? maxAdHocAmount;

  /// Base entry unit from the parent entry (fallback when no override is set).
  final String entryBaseUnit;

  /// Controller for the scheduled-entry override field (non-null when not ad-hoc).
  final TextEditingController? entryOverrideController;

  /// Currently selected entry override unit (e.g. 'mg', 'ml').
  final String? entryOverrideUnit;

  /// MDV entry-change mode (strength / volume / units). `null` for non-MDV.
  final MdvEntryChangeMode? mdvMode;

  /// Currently selected syringe type for MDV. `null` for non-MDV.
  final SyringeType? mdvSyringe;

  /// Strength unit label (e.g. 'mg') used in MDV mode.
  final String mdvStrengthUnit;

  /// Called whenever the user makes any change — parent should call
  /// `setState(() => _hasChanged = true)`.
  final VoidCallback onChanged;

  final ValueChanged<MdvEntryChangeMode> onMdvModeChanged;
  final ValueChanged<SyringeType> onMdvSyringeChanged;

  /// Called when the user changes the entry-unit dropdown (non-MDV only).
  final ValueChanged<String> onUnitChanged;

  /// Called when the user changes the strength unit in MDV strength mode.
  final ValueChanged<String>? onMdvStrengthUnitChanged;

  @override
  Widget build(BuildContext context) {
    final adHocMedication = isAdHoc && existingLog != null
        ? Hive.box<Medication>('medications').get(existingLog!.medicationId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdHoc && existingLog != null)
          ..._buildAdHocSection(context, adHocMedication),
        if (!isAdHoc) ..._buildEntryOverrideSection(context),
      ],
    );
  }

  // ─── Ad hoc section ────────────────────────────────────────────────────────

  List<Widget> _buildAdHocSection(
    BuildContext context,
    Medication? medication,
  ) {
    final controller = amountController!;
    final unit = existingLog!.entryUnit;
    final max = maxAdHocAmount ?? double.infinity;
    final isMdv = medication?.form == MedicationForm.multiDoseVial;
    final overrideController = entryOverrideController;

    return [
      if (isMdv && overrideController != null && medication != null) ...[
        Text('Required entry settings', style: sectionTitleStyle(context)),
        const SizedBox(height: kSpacingXS),
        buildHelperText(
          context,
          'Choose how this entry should be recorded. The app will calculate the linked strength, volume, and syringe units automatically.',
          fullWidth: true,
        ),
        const SizedBox(height: kSpacingS),
        EntryMdvControls(
          medication: medication,
          mode: mdvMode ?? MdvEntryChangeMode.volume,
          syringe: mdvSyringe ?? SyringeType.ml_1_0,
          strengthUnit: mdvStrengthUnit,
          entryOverrideController: overrideController,
          onModeChanged: onMdvModeChanged,
          onSyringeChanged: onMdvSyringeChanged,
          onValueChanged: onChanged,
          onStrengthUnitChanged: onMdvStrengthUnitChanged,
        ),
        const SizedBox(height: kSpacingM),
      ],
      if (!isMdv) ...[
        Text('Amount', style: sectionTitleStyle(context)),
        const SizedBox(height: kSpacingS),
        Row(
          children: [
            Expanded(
              child: StepperRow36(
                controller: controller,
                onDec: () {
                  final step = EntryValueFormatter.incrementStepForUnit(unit);
                  final v = double.tryParse(controller.text) ?? 0;
                  controller.text = EntryValueFormatter.format(
                    (v - step).clamp(0.0, max),
                    unit,
                  );
                  onChanged();
                },
                onInc: () {
                  final step = EntryValueFormatter.incrementStepForUnit(unit);
                  final v = double.tryParse(controller.text) ?? 0;
                  controller.text = EntryValueFormatter.format(
                    (v + step).clamp(0.0, max),
                    unit,
                  );
                  onChanged();
                },
                decoration: buildCompactFieldDecoration(context: context),
              ),
            ),
            const SizedBox(width: kSpacingS),
            Text(
              unit,
              style: helperTextStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightMedium),
            ),
          ],
        ),
      ],
      const SizedBox(height: kSpacingM),
    ];
  }

  // ─── Scheduled-entry override section ───────────────────────────────────────

  List<Widget> _buildEntryOverrideSection(BuildContext context) {
    final controller = entryOverrideController;
    if (controller == null) return const [];

    final schedule =
        scheduleId != null ? Hive.box<Schedule>('schedules').get(scheduleId) : null;
    final medId = schedule?.medicationId;
    final med =
        medId != null ? Hive.box<Medication>('medications').get(medId) : null;
    final isMdv = med?.form == MedicationForm.multiDoseVial;

    return [
      Text('Entry change', style: sectionTitleStyle(context)),
      const SizedBox(height: kSpacingXS),
      if (isMdv && med != null) ...[
        buildHelperText(
          context,
          'Choose how this entry should be recorded. The app will calculate the linked strength, volume, and syringe units automatically.',
          fullWidth: true,
        ),
        const SizedBox(height: kSpacingS),
      ],
      if (!isMdv || med == null)
        _buildSimpleOverride(context, controller)
      else
        EntryMdvControls(
          medication: med,
          mode: mdvMode ?? MdvEntryChangeMode.strength,
          syringe: mdvSyringe ?? SyringeType.ml_1_0,
          strengthUnit: mdvStrengthUnit,
          entryOverrideController: controller,
          onModeChanged: onMdvModeChanged,
          onSyringeChanged: onMdvSyringeChanged,
          onValueChanged: onChanged,
          onStrengthUnitChanged: onMdvStrengthUnitChanged,
        ),
      const SizedBox(height: kSpacingM),
    ];
  }

  Widget _buildSimpleOverride(
    BuildContext context,
    TextEditingController controller,
  ) {
    const strengthUnits = <String>['mcg', 'mg', 'g'];
    final normalizedUnit = (entryOverrideUnit ?? entryBaseUnit).toLowerCase();
    final selectedUnit =
        strengthUnits.contains(normalizedUnit) ? normalizedUnit : 'mg';
    final unit = entryOverrideUnit ?? '';

    return Row(
      children: [
        Expanded(
          child: StepperRow36(
            controller: controller,
            onDec: () {
              final step = EntryValueFormatter.incrementStepForUnit(unit);
              final v = double.tryParse(controller.text) ?? 0;
              controller.text = EntryValueFormatter.format(
                (v - step).clamp(0.0, double.infinity),
                unit,
              );
              onChanged();
            },
            onInc: () {
              final step = EntryValueFormatter.incrementStepForUnit(unit);
              final v = double.tryParse(controller.text) ?? 0;
              controller.text = EntryValueFormatter.format(
                (v + step).clamp(0.0, double.infinity),
                unit,
              );
              onChanged();
            },
            decoration: buildCompactFieldDecoration(context: context),
          ),
        ),
        const SizedBox(width: kSpacingS),
        SizedBox(
          width: kCompactControlWidth,
          child: SmallDropdown36<String>(
            value: selectedUnit,
            items: strengthUnits
                .map(
                  (u) => DropdownMenuItem<String>(
                    value: u,
                    child: Text(u),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null || value == entryOverrideUnit) return;
              onUnitChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class EntryMdvCalculatedValuesCard extends StatelessWidget {
  const EntryMdvCalculatedValuesCard({
    super.key,
    required this.medication,
    required this.rawText,
    required this.mode,
    required this.syringe,
    required this.strengthUnit,
  });

  final Medication? medication;
  final String rawText;
  final MdvEntryChangeMode mode;
  final SyringeType syringe;
  final String strengthUnit;

  @override
  Widget build(BuildContext context) {
    final med = medication;
    if (med == null) return const SizedBox.shrink();

    final result = mdvEntryChangeResult(
      med: med,
      rawText: rawText,
      mode: mode,
      syringe: syringe,
      strengthUnit: strengthUnit,
    );
    if (result == null) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

    if (result.hasError) {
      return Container(
        margin: const EdgeInsets.only(top: kSpacingS),
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingS,
          vertical: kSpacingS,
        ),
        decoration: BoxDecoration(
          color: cs.secondary.withValues(alpha: kOpacityFaint),
          borderRadius: BorderRadius.circular(kBorderRadiusMedium),
          border: Border.all(
            color: cs.secondary.withValues(alpha: kOpacityMediumHigh),
            width: kBorderWidthThin,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: cs.secondary,
              size: kIconSizeMedium,
            ),
            const SizedBox(width: kSpacingS),
            Expanded(
              child: Text(
                result.error ?? 'Entry is outside the selected syringe capacity.',
                style: helperTextStyle(context, color: cs.onSurface)?.copyWith(
                  fontWeight: kFontWeightSemiBold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    String fmt(double value) {
      return EntryValueFormatter.format(value, 'mg');
    }

    String strengthText() {
      final mcg = result.entryMassMcg ?? 0;
      final value = switch (strengthUnit) {
        'mcg' => mcg,
        'mg' => mcg / 1000,
        'g' => mcg / 1000000,
        'units' => mcg,
        _ => mcg / 1000,
      };
      return '${fmt(value)} $strengthUnit';
    }

    String volumeText() {
      final volumeMl = (result.entryVolumeMicroliter ?? 0) / 1000;
      return '${EntryValueFormatter.format(volumeMl, 'ml')} mL';
    }

    String unitsText() {
      final units = (result.syringeUnits ?? 0).toDouble();
      return MedicationDisplayHelpers.formatSyringeUnits(units, longLabel: true);
    }

    Widget stat(String label, String value) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: microHelperTextStyle(context)?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: helperTextStyle(context)?.copyWith(
                fontWeight: kFontWeightSemiBold,
                color: cs.primary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: kSpacingS),
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingS,
        vertical: kSpacingS,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(
          color: cs.primary.withValues(alpha: kOpacityLow),
          width: kBorderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calculated values',
            style: helperTextStyle(context)?.copyWith(
              color: cs.primary,
              fontWeight: kFontWeightSemiBold,
            ),
          ),
          const SizedBox(height: 2),
          buildHelperText(
            context,
            'These three values stay in sync for the current vial concentration.',
            fullWidth: true,
          ),
          if (result.warning != null) ...[
            const SizedBox(height: 2),
            buildHelperText(
              context,
              result.warning!,
              color: cs.secondary,
              fullWidth: true,
            ),
          ],
          const SizedBox(height: kSpacingXS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stat('Strength', strengthText()),
              const SizedBox(width: kSpacingS),
              stat('Volume', volumeText()),
              const SizedBox(width: kSpacingS),
              stat('Units', unitsText()),
            ],
          ),
        ],
      ),
    );
  }
}
