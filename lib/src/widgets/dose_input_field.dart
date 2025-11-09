// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';

/// MDV input mode for 3-way conversion
enum MdvInputMode {
  strength, // Input strength (mg/mcg), calculate volume + units
  volume, // Input volume (ml), calculate strength + units
  units, // Input syringe units (U), calculate strength + volume
}

/// Smart dose input field that adapts to medication form and provides:
/// - Mode toggle (tablets/strength for tablets, capsules/strength for capsules)
/// - Number input with steppers
/// - Quick action buttons (1/4, 1/2, 1, 2 for tablets)
/// - Live calculation display using DoseCalculator
///
/// Week 2 implementation covers: Tablets, Capsules, Pre-filled Injections, Single Dose Vials
/// Week 3 adds: Multi-Dose Vial (MDV) with 3-way conversion
class DoseInputField extends StatefulWidget {
  const DoseInputField({
    required this.medicationForm,
    required this.strengthPerUnitMcg,
    required this.onDoseChanged,
    super.key,
    this.volumePerUnitMicroliter,
    this.strengthUnit = 'mg',
    this.initialTabletCount,
    this.initialCapsuleCount,
    this.initialInjectionCount,
    this.initialVialCount,
    this.initialStrengthMcg,
    // MDV-specific parameters (Week 3)
    this.totalVialStrengthMcg,
    this.totalVialVolumeMicroliter,
    this.syringeType,
    this.initialVolumeMicroliter,
    this.initialSyringeUnits,
  });

  /// Medication form determines input mode
  final MedicationForm medicationForm;

  /// Strength per unit (tablet/capsule/injection/vial) in micrograms
  final double strengthPerUnitMcg;

  /// Volume per unit (for injections/vials) in microliters
  final double? volumePerUnitMicroliter;

  /// Display unit for strength (mg, mcg, g)
  final String strengthUnit;

  /// Initial values
  final double? initialTabletCount;
  final int? initialCapsuleCount;
  final int? initialInjectionCount;
  final int? initialVialCount;
  final double? initialStrengthMcg;

  /// MDV-specific parameters
  final double?
  totalVialStrengthMcg; // Total strength in vial (e.g., 10mg = 10000mcg)
  final double?
  totalVialVolumeMicroliter; // Total volume in vial (e.g., 5ml = 5000μl)
  final SyringeType? syringeType; // Syringe type for unit scale
  final double? initialVolumeMicroliter; // Initial volume input
  final double? initialSyringeUnits; // Initial syringe units input

  /// Callback when dose changes (returns DoseCalculationResult)
  final ValueChanged<DoseCalculationResult> onDoseChanged;

  @override
  State<DoseInputField> createState() => _DoseInputFieldState();
}

class _DoseInputFieldState extends State<DoseInputField> {
  late TextEditingController _controller;
  late bool
  _isCountMode; // true = count mode, false = strength mode (tablets/capsules)
  late MdvInputMode _mdvMode; // MDV-specific: strength, volume, or units
  DoseCalculationResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    // Initialize mode and value based on medication form and initial data
    _isCountMode = _shouldDefaultToCountMode();
    _mdvMode = _shouldDefaultMdvMode();
    _initializeValue();

    // Schedule calculation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.text.isNotEmpty) {
        _calculate();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _shouldDefaultToCountMode() {
    // Default to count mode if initial count provided, otherwise strength mode
    switch (widget.medicationForm) {
      case MedicationForm.tablet:
        return widget.initialTabletCount != null;
      case MedicationForm.capsule:
        return widget.initialCapsuleCount != null;
      case MedicationForm.prefilledSyringe:
        return widget.initialInjectionCount != null;
      case MedicationForm.singleDoseVial:
        return widget.initialVialCount != null;
      case MedicationForm.multiDoseVial:
        return false; // MDV uses _mdvMode instead
    }
  }

  MdvInputMode _shouldDefaultMdvMode() {
    // Default MDV mode based on what initial value was provided
    if (widget.medicationForm != MedicationForm.multiDoseVial) {
      return MdvInputMode.strength; // Default for non-MDV
    }

    if (widget.initialSyringeUnits != null) {
      return MdvInputMode.units;
    } else if (widget.initialVolumeMicroliter != null) {
      return MdvInputMode.volume;
    } else {
      return MdvInputMode.strength; // Default to strength input
    }
  }

  void _initializeValue() {
    if (widget.medicationForm == MedicationForm.multiDoseVial) {
      // MDV uses _mdvMode
      switch (_mdvMode) {
        case MdvInputMode.strength:
          if (widget.initialStrengthMcg != null) {
            final value = _convertMcgToDisplayUnit(widget.initialStrengthMcg!);
            _controller.text = value.toString();
          } else {
            _controller.text = '';
          }
        case MdvInputMode.volume:
          if (widget.initialVolumeMicroliter != null) {
            // Convert microliters to ml
            final ml = widget.initialVolumeMicroliter! / 1000;
            _controller.text = ml.toString();
          } else {
            _controller.text = '';
          }
        case MdvInputMode.units:
          if (widget.initialSyringeUnits != null) {
            _controller.text = widget.initialSyringeUnits.toString();
          } else {
            _controller.text = '';
          }
      }
    } else if (_isCountMode) {
      switch (widget.medicationForm) {
        case MedicationForm.tablet:
          // Default to 1.0 if no initial value to ensure calculation works
          _controller.text = (widget.initialTabletCount ?? 1.0).toString();
        case MedicationForm.capsule:
          _controller.text = (widget.initialCapsuleCount ?? 1).toString();
        case MedicationForm.prefilledSyringe:
          _controller.text = (widget.initialInjectionCount ?? 1).toString();
        case MedicationForm.singleDoseVial:
          _controller.text = (widget.initialVialCount ?? 1).toString();
        case MedicationForm.multiDoseVial:
          _controller.text = '';
      }
    } else {
      // Strength mode (tablets/capsules)
      if (widget.initialStrengthMcg != null) {
        // Convert mcg to display unit
        final value = _convertMcgToDisplayUnit(widget.initialStrengthMcg!);
        _controller.text = value.toString();
      } else {
        _controller.text = '';
      }
    }
  }

  double _convertMcgToDisplayUnit(double mcg) {
    switch (widget.strengthUnit) {
      case 'mcg':
        return mcg;
      case 'mg':
        return mcg / 1000;
      case 'g':
        return mcg / 1000000;
      default:
        return mcg / 1000; // Default to mg
    }
  }

  double _convertDisplayUnitToMcg(double value) {
    switch (widget.strengthUnit) {
      case 'mcg':
        return value;
      case 'mg':
        return value * 1000;
      case 'g':
        return value * 1000000;
      default:
        return value * 1000; // Default to mg
    }
  }

  void _calculate() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _result = null);
      return;
    }

    DoseCalculationResult result;

    if (_isCountMode) {
      // Count mode: calculate from number of units
      switch (widget.medicationForm) {
        case MedicationForm.tablet:
          final count = double.tryParse(text) ?? 0;
          result = DoseCalculator.calculateFromTablets(
            tabletCount: count,
            strengthPerTabletMcg: widget.strengthPerUnitMcg,
            strengthUnit: widget.strengthUnit,
          );
          break;

        case MedicationForm.capsule:
          final count = int.tryParse(text) ?? 0;
          result = DoseCalculator.calculateFromCapsules(
            capsuleCount: count,
            strengthPerCapsuleMcg: widget.strengthPerUnitMcg,
          );
          break;

        case MedicationForm.prefilledSyringe:
          final count = int.tryParse(text) ?? 0;
          result = DoseCalculator.calculateFromPrefilledInjections(
            injectionCount: count,
            strengthPerInjectionMcg: widget.strengthPerUnitMcg,
            volumePerInjectionMicroliter: widget.volumePerUnitMicroliter ?? 0,
          );
          break;

        case MedicationForm.singleDoseVial:
          final count = int.tryParse(text) ?? 0;
          result = DoseCalculator.calculateFromSingleDoseVials(
            vialCount: count,
            strengthPerVialMcg: widget.strengthPerUnitMcg,
            volumePerVialMicroliter: widget.volumePerUnitMicroliter ?? 0,
          );
          break;

        case MedicationForm.multiDoseVial:
          // MDV in count mode not supported - should use MDV modes
          result = DoseCalculationResult.error('Use MDV mode toggle');
          break;
      }
    } else if (widget.medicationForm == MedicationForm.multiDoseVial) {
      // MDV mode: use 3-way calculation based on _mdvMode
      final value = double.tryParse(text) ?? 0;

      // Validate required parameters
      if (widget.totalVialStrengthMcg == null ||
          widget.totalVialVolumeMicroliter == null ||
          widget.syringeType == null) {
        result = DoseCalculationResult.error(
          'MDV requires vial strength, volume, and syringe type',
        );
      } else {
        switch (_mdvMode) {
          case MdvInputMode.strength:
            // Input: desired dose strength → calc volume + units
            final strengthMcg = _convertDisplayUnitToMcg(value);
            result = DoseCalculator.calculateFromStrengthMDV(
              strengthMcg: strengthMcg,
              totalVialStrengthMcg: widget.totalVialStrengthMcg!,
              totalVialVolumeMicroliter: widget.totalVialVolumeMicroliter!,
              syringeType: widget.syringeType!,
            );

          case MdvInputMode.volume:
            // Input: desired dose volume (in ml) → calc volume + units
            final volumeMicroliter = value * 1000; // Convert ml to µL
            result = DoseCalculator.calculateFromVolumeMDV(
              volumeMicroliter: volumeMicroliter,
              totalVialStrengthMcg: widget.totalVialStrengthMcg!,
              totalVialVolumeMicroliter: widget.totalVialVolumeMicroliter!,
              syringeType: widget.syringeType!,
            );

          case MdvInputMode.units:
            // Input: desired syringe units → calc strength + volume
            result = DoseCalculator.calculateFromUnitsMDV(
              syringeUnits: value,
              totalVialStrengthMcg: widget.totalVialStrengthMcg!,
              totalVialVolumeMicroliter: widget.totalVialVolumeMicroliter!,
              syringeType: widget.syringeType!,
            );
        }
      }
    } else {
      // Strength mode: calculate from total strength
      final value = double.tryParse(text) ?? 0;
      final strengthMcg = _convertDisplayUnitToMcg(value);

      switch (widget.medicationForm) {
        case MedicationForm.tablet:
          result = DoseCalculator.calculateFromStrength(
            strengthMcg: strengthMcg,
            strengthPerTabletMcg: widget.strengthPerUnitMcg,
          );
          break;

        case MedicationForm.capsule:
          result = DoseCalculator.calculateFromStrengthCapsules(
            strengthMcg: strengthMcg,
            strengthPerCapsuleMcg: widget.strengthPerUnitMcg,
          );
          break;

        case MedicationForm.prefilledSyringe:
        case MedicationForm.singleDoseVial:
        case MedicationForm.multiDoseVial:
          // These don't support strength mode in Week 2
          result = DoseCalculationResult.error('Strength mode not supported');
          break;
      }
    }

    setState(() => _result = result);
    widget.onDoseChanged(result);
  }

  void _toggleMode() {
    setState(() {
      _isCountMode = !_isCountMode;
      _controller.clear();
      _result = null;
    });
    widget.onDoseChanged(
      DoseCalculationResult.error('Mode changed - enter new dose'),
    );
  }

  void _toggleMdvMode(MdvInputMode newMode) {
    if (_mdvMode == newMode) return;
    setState(() {
      _mdvMode = newMode;
      _controller.clear();
      _result = null;
    });
    widget.onDoseChanged(
      DoseCalculationResult.error('Mode changed - enter new dose'),
    );
  }

  void _increment({double? customStep}) {
    final current = double.tryParse(_controller.text) ?? 0;
    double step;

    if (customStep != null) {
      step = customStep;
    } else if (widget.medicationForm == MedicationForm.tablet && _isCountMode) {
      step = 0.25; // 1/4 tablet increments
    } else {
      step = 1;
    }

    _controller.text = (current + step).toString();
    _calculate();
  }

  void _decrement({double? customStep}) {
    final current = double.tryParse(_controller.text) ?? 0;
    double step;

    if (customStep != null) {
      step = customStep;
    } else if (widget.medicationForm == MedicationForm.tablet && _isCountMode) {
      step = 0.25; // 1/4 tablet increments
    } else {
      step = 1;
    }

    final newValue = current - step;
    if (newValue >= 0) {
      _controller.text = newValue.toString();
      _calculate();
    }
  }

  void _setQuickValue(double value) {
    _controller.text = value.toString();
    _calculate();
  }

  void _onSyringeDragChanged(double newUnits) {
    // Week 4: Handle interactive syringe drag
    // User dragged the syringe to adjust units - recalculate from units
    if (widget.medicationForm != MedicationForm.multiDoseVial) return;
    if (widget.totalVialStrengthMcg == null ||
        widget.totalVialVolumeMicroliter == null ||
        widget.syringeType == null)
      return;

    // Calculate from units
    final result = DoseCalculator.calculateFromUnitsMDV(
      syringeUnits: newUnits,
      totalVialStrengthMcg: widget.totalVialStrengthMcg!,
      totalVialVolumeMicroliter: widget.totalVialVolumeMicroliter!,
      syringeType: widget.syringeType!,
    );

    setState(() {
      _result = result;
    });

    // Update text field to show new value in current mode
    if (result.success && !result.hasError) {
      switch (_mdvMode) {
        case MdvInputMode.strength:
          final strengthMcg = result.doseMassMcg ?? 0;
          final displayValue = _convertMcgToDisplayUnit(strengthMcg);
          _controller.text = displayValue.toString();
        case MdvInputMode.volume:
          final volumeMl = (result.doseVolumeMicroliter ?? 0) / 1000;
          _controller.text = volumeMl.toString();
        case MdvInputMode.units:
          _controller.text = newUnits.toString();
      }
    }

    widget.onDoseChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode toggle (tablets/capsules OR MDV)
        if (_supportsModeToggle()) ...[
          _buildModeToggle(cs),
          const SizedBox(height: kFieldGroupSpacing),
        ],

        // MDV mode toggle (3-way: Strength | Volume | Units)
        if (widget.medicationForm == MedicationForm.multiDoseVial) ...[
          _buildMdvModeToggle(cs),
          const SizedBox(height: kFieldGroupSpacing),
        ],

        // Input row with steppers
        _buildInputRow(cs),
        const SizedBox(height: kCardInnerSpacing),

        // Quick action buttons (tablets only in count mode)
        if (widget.medicationForm == MedicationForm.tablet && _isCountMode) ...[
          _buildQuickButtons(cs),
          const SizedBox(height: kCardInnerSpacing),
        ],

        // MDV syringe graphic (when result available)
        if (widget.medicationForm == MedicationForm.multiDoseVial &&
            _result != null &&
            !_result!.hasError &&
            _result!.syringeUnits != null &&
            widget.syringeType != null) ...[
          _buildSyringeGraphic(cs),
          const SizedBox(height: kCardInnerSpacing),
        ],

        // MDV 3-value display (always visible when result available)
        if (widget.medicationForm == MedicationForm.multiDoseVial &&
            _result != null &&
            !_result!.hasError) ...[
          _buildMdvThreeValueDisplay(cs),
          const SizedBox(height: kCardInnerSpacing),
        ],

        // Live calculation display
        if (_result != null) _buildResultDisplay(cs),
      ],
    );
  }

  bool _supportsModeToggle() {
    return widget.medicationForm == MedicationForm.tablet ||
        widget.medicationForm == MedicationForm.capsule;
  }

  Widget _buildModeToggle(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: _buildModeButton(
            label: _getCountModeLabel(),
            isSelected: _isCountMode,
            onTap: () {
              if (!_isCountMode) _toggleMode();
            },
            cs: cs,
          ),
        ),
        const SizedBox(width: kButtonSpacing),
        Expanded(
          child: _buildModeButton(
            label: 'Strength',
            isSelected: !_isCountMode,
            onTap: () {
              if (_isCountMode) _toggleMode();
            },
            cs: cs,
          ),
        ),
      ],
    );
  }

  String _getCountModeLabel() {
    switch (widget.medicationForm) {
      case MedicationForm.tablet:
        return 'Tablets';
      case MedicationForm.capsule:
        return 'Capsules';
      case MedicationForm.prefilledSyringe:
        return 'Injections';
      case MedicationForm.singleDoseVial:
        return 'Vials';
      case MedicationForm.multiDoseVial:
        return 'MDV';
    }
  }

  Widget _buildMdvModeToggle(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: _buildModeButton(
            label: 'Strength',
            isSelected: _mdvMode == MdvInputMode.strength,
            onTap: () => _toggleMdvMode(MdvInputMode.strength),
            cs: cs,
          ),
        ),
        const SizedBox(width: kButtonSpacing),
        Expanded(
          child: _buildModeButton(
            label: 'Volume',
            isSelected: _mdvMode == MdvInputMode.volume,
            onTap: () => _toggleMdvMode(MdvInputMode.volume),
            cs: cs,
          ),
        ),
        const SizedBox(width: kButtonSpacing),
        Expanded(
          child: _buildModeButton(
            label: 'Units',
            isSelected: _mdvMode == MdvInputMode.units,
            onTap: () => _toggleMdvMode(MdvInputMode.units),
            cs: cs,
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return Material(
      color: isSelected ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(kBorderRadiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        child: Container(
          height: kStandardFieldHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.outlineVariant.withOpacity(kCardBorderOpacity),
              width: isSelected ? kBorderWidthMedium : kBorderWidthThin,
            ),
            borderRadius: BorderRadius.circular(kBorderRadiusMedium),
          ),
          child: Text(
            label,
            style: buttonTextStyle(context)?.copyWith(
              color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight: isSelected ? kFontWeightSemiBold : kFontWeightMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow(ColorScheme cs) {
    return Row(
      children: [
        // Decrement button
        _buildStepperButton(icon: Icons.remove, onPressed: _decrement, cs: cs),
        const SizedBox(width: kStepperButtonSpacing),

        // Input field
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: buildFieldDecoration(context, hint: _getInputHint()),
            onChanged: (_) => _calculate(),
          ),
        ),
        const SizedBox(width: kStepperButtonSpacing),

        // Increment button
        _buildStepperButton(icon: Icons.add, onPressed: _increment, cs: cs),
      ],
    );
  }

  String _getInputHint() {
    if (widget.medicationForm == MedicationForm.multiDoseVial) {
      switch (_mdvMode) {
        case MdvInputMode.strength:
          return 'e.g., 500';
        case MdvInputMode.volume:
          return 'e.g., 0.25';
        case MdvInputMode.units:
          return 'e.g., 25';
      }
    } else if (_isCountMode) {
      switch (widget.medicationForm) {
        case MedicationForm.tablet:
          return 'e.g., 2 or 1.5';
        case MedicationForm.capsule:
          return 'e.g., 3';
        case MedicationForm.prefilledSyringe:
          return 'e.g., 2';
        case MedicationForm.singleDoseVial:
          return 'e.g., 1';
        case MedicationForm.multiDoseVial:
          return '';
      }
    } else {
      return 'e.g., 100';
    }
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme cs,
  }) {
    return SizedBox(
      width: kStepperButtonSize,
      height: kStepperButtonSize,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: kIconSizeMedium),
        padding: EdgeInsets.zero,
        iconSize: kIconSizeMedium,
        style: IconButton.styleFrom(
          backgroundColor: cs.surfaceContainerHigh,
          foregroundColor: cs.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickButtons(ColorScheme cs) {
    final buttons = [('1/4', 0.25), ('1/2', 0.5), ('1', 1.0), ('2', 2.0)];

    return Wrap(
      spacing: kButtonSpacing,
      runSpacing: kButtonSpacing,
      children: buttons.map((btn) {
        return ActionChip(
          label: Text(btn.$1),
          onPressed: () => _setQuickValue(btn.$2),
          padding: const EdgeInsets.symmetric(
            horizontal: kCardInnerSpacing,
            vertical: 0,
          ),
          backgroundColor: cs.surfaceContainerHighest,
          labelStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: kFontWeightMedium),
        );
      }).toList(),
    );
  }

  Widget _buildSyringeGraphic(ColorScheme cs) {
    if (_result == null || widget.syringeType == null) {
      return const SizedBox.shrink();
    }

    final totalUnits = widget.syringeType!.maxUnits;
    final fillUnits = _result!.syringeUnits ?? 0;

    return WhiteSyringeGauge(
      totalUnits: totalUnits,
      fillUnits: fillUnits,
      interactive: true, // Week 4: Interactive fine-tuning
      onChanged: _onSyringeDragChanged,
      showValueLabel: true, // Show value during drag
    );
  }

  Widget _buildMdvThreeValueDisplay(ColorScheme cs) {
    if (_result == null) return const SizedBox.shrink();

    final strengthMcg = _result!.doseMassMcg ?? 0;
    final volumeMl = (_result!.doseVolumeMicroliter ?? 0) / 1000;
    final units = _result!.syringeUnits ?? 0;

    // Format values
    String strengthStr;
    if (strengthMcg >= 1000) {
      strengthStr = '${(strengthMcg / 1000).toStringAsFixed(2)}mg';
    } else {
      strengthStr = '${strengthMcg.toStringAsFixed(0)}mcg';
    }

    final volumeStr = '${volumeMl.toStringAsFixed(2)}ml';
    final unitsStr = '${units.toStringAsFixed(1)} Units';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(kCardBorderOpacity),
          width: kBorderWidthThin,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMdvValueChip(
            value: strengthStr,
            isActive: _mdvMode == MdvInputMode.strength,
            cs: cs,
          ),
          Text('•', style: bodyTextStyle(context)),
          _buildMdvValueChip(
            value: volumeStr,
            isActive: _mdvMode == MdvInputMode.volume,
            cs: cs,
          ),
          Text('•', style: bodyTextStyle(context)),
          _buildMdvValueChip(
            value: unitsStr,
            isActive: _mdvMode == MdvInputMode.units,
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _buildMdvValueChip({
    required String value,
    required bool isActive,
    required ColorScheme cs,
  }) {
    return Text(
      value,
      style: bodyTextStyle(context)?.copyWith(
        fontWeight: isActive ? kFontWeightBold : kFontWeightMedium,
        color: isActive ? cs.primary : cs.onSurfaceVariant,
      ),
    );
  }

  Widget _buildResultDisplay(ColorScheme cs) {
    if (_result == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: _result!.hasError
            ? cs.errorContainer
            : (_result!.hasWarning
                  ? Colors.orange.withOpacity(0.1)
                  : cs.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(
          color: _result!.hasError
              ? cs.error
              : (_result!.hasWarning
                    ? Colors.orange
                    : cs.outlineVariant.withOpacity(kCardBorderOpacity)),
          width: kBorderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main display text
          Text(
            _result!.displayText,
            style: bodyTextStyle(context)?.copyWith(
              fontWeight: kFontWeightSemiBold,
              color: _result!.hasError
                  ? cs.onErrorContainer
                  : (_result!.hasWarning
                        ? Colors.orange.shade900
                        : cs.onSurface),
            ),
          ),

          // Warning message
          if (_result!.hasWarning) ...[
            const SizedBox(height: kHelperTextTopPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: kIconSizeSmall,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _result!.warning!,
                    style: helperTextStyle(
                      context,
                    )?.copyWith(color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ],

          // Error message
          if (_result!.hasError) ...[
            const SizedBox(height: kHelperTextTopPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: kIconSizeSmall,
                  color: cs.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _result!.error!,
                    style: helperTextStyle(context)?.copyWith(color: cs.error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
