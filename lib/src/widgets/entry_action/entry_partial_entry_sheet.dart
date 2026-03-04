import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_calculator.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_value_formatter.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/entry_action/entry_syringe_picker_sheet.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// The content of the "Advanced" section inside [EntryActionSheet].
///
/// Renders either:
/// - an **ad-hoc amount** stepper when [isAdHoc] is true, or
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdHoc && existingLog != null) ..._buildAdHocSection(context),
        if (!isAdHoc) ..._buildEntryOverrideSection(context),
      ],
    );
  }

  // ─── Ad-hoc section ────────────────────────────────────────────────────────

  List<Widget> _buildAdHocSection(BuildContext context) {
    final controller = amountController!;
    final unit = existingLog!.entryUnit;
    final max = maxAdHocAmount ?? double.infinity;

    return [
      Text('Amount', style: sectionTitleStyle(context)),
      const SizedBox(height: kSpacingS),
      Row(
        children: [
          Expanded(
            child: StepperRow36(
              controller: controller,
              onDec: () {
                final step = EntryValueFormatter.stepSizeForUnit(unit);
                final v = double.tryParse(controller.text) ?? 0;
                controller.text = EntryValueFormatter.format(
                  (v - step).clamp(0.0, max),
                  unit,
                );
                onChanged();
              },
              onInc: () {
                final step = EntryValueFormatter.stepSizeForUnit(unit);
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
      if (!isMdv || med == null)
        _buildSimpleOverride(context, controller)
      else
        EntryMdvControls(
          mode: mdvMode ?? MdvEntryChangeMode.strength,
          syringe: mdvSyringe ?? SyringeType.ml_1_0,
          strengthUnit: mdvStrengthUnit,
          entryOverrideController: controller,
          onModeChanged: onMdvModeChanged,
          onSyringeChanged: onMdvSyringeChanged,
          onValueChanged: onChanged,
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
              final step = EntryValueFormatter.stepSizeForUnit(unit);
              final v = double.tryParse(controller.text) ?? 0;
              controller.text = EntryValueFormatter.format(
                (v - step).clamp(0.0, double.infinity),
                unit,
              );
              onChanged();
            },
            onInc: () {
              final step = EntryValueFormatter.stepSizeForUnit(unit);
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
