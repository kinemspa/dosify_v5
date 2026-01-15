// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
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
    this.onStrengthUnitChanged,
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

  /// Optional: called when the user changes the displayed strength unit
  /// (mcg/mg/g) in tablet strength mode.
  final ValueChanged<String>? onStrengthUnitChanged;

  @override
  State<DoseInputField> createState() => _DoseInputFieldState();
}

class _DoseInputFieldState extends State<DoseInputField> {
  late TextEditingController _controller;
  late bool
  _isCountMode; // true = count mode, false = strength mode (tablets/capsules)
  late MdvInputMode _mdvMode; // MDV-specific: strength, volume, or units
  late String _mdvStrengthUnit;
  late String _strengthUnit;
  DoseCalculationResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    // Initialize mode and value based on medication form and initial data
    _isCountMode = _shouldDefaultToCountMode();
    _mdvMode = _shouldDefaultMdvMode();
    _mdvStrengthUnit = widget.strengthUnit;
    _strengthUnit = _normalizeStrengthUnit(widget.strengthUnit);
    _initializeValue();

    final initialText = _controller.text.trim();
    if (initialText.isNotEmpty) {
      _result = _computeResult(initialText);
    }

    // Schedule calculation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Avoid calling parent callbacks during build; notify after first frame.
      if (_result != null) {
        widget.onDoseChanged(_result!);
        return;
      }

      if (_controller.text.isNotEmpty) {
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
    if (widget.medicationForm == MedicationForm.multiDoseVial) {
      return false;
    }

    final hasInitialStrength = widget.initialStrengthMcg != null;

    switch (widget.medicationForm) {
      case MedicationForm.tablet:
        if (widget.initialTabletCount != null) return true;
        if (hasInitialStrength) return false;
        return true; // Default to tablet count mode
      case MedicationForm.capsule:
        if (widget.initialCapsuleCount != null) return true;
        if (hasInitialStrength) return false;
        return true; // Capsules default to count mode
      case MedicationForm.prefilledSyringe:
        return true; // Only count input supported
      case MedicationForm.singleDoseVial:
        return true; // Only count input supported
      case MedicationForm.multiDoseVial:
        return false;
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
            _controller.text = fmt2(value);
          } else {
            _controller.text = '';
          }
          break;
        case MdvInputMode.volume:
          if (widget.initialVolumeMicroliter != null) {
            // Convert microliters to ml
            final ml = widget.initialVolumeMicroliter! / 1000;
            _controller.text = fmt2(ml);
          } else {
            _controller.text = '';
          }
          break;
        case MdvInputMode.units:
          if (widget.initialSyringeUnits != null) {
            _controller.text = fmt2(widget.initialSyringeUnits!);
          } else {
            _controller.text = '';
          }
          break;
      }
    } else if (_isCountMode) {
      switch (widget.medicationForm) {
        case MedicationForm.tablet:
          // Default to 1.0 if no initial value to ensure calculation works
          _controller.text = (widget.initialTabletCount ?? 1.0).toString();
          break;
        case MedicationForm.capsule:
          _controller.text = (widget.initialCapsuleCount ?? 1).toString();
          break;
        case MedicationForm.prefilledSyringe:
          _controller.text = (widget.initialInjectionCount ?? 1).toString();
          break;
        case MedicationForm.singleDoseVial:
          _controller.text = (widget.initialVialCount ?? 1).toString();
          break;
        case MedicationForm.multiDoseVial:
          _controller.text = '';
          break;
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
    switch (_effectiveStrengthUnit()) {
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
    switch (_effectiveStrengthUnit()) {
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

  String _effectiveStrengthUnit() {
    if (widget.medicationForm == MedicationForm.multiDoseVial &&
        _mdvMode == MdvInputMode.strength) {
      return _mdvStrengthUnit;
    }
    return _strengthUnit;
  }

  String _normalizeStrengthUnit(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'mcg' || v == 'mg' || v == 'g') return v;
    return 'mg';
  }

  DoseCalculationResult _computeResult(String text) {
    DoseCalculationResult result;

    if (_isCountMode) {
      // Count mode: calculate from number of units
      switch (widget.medicationForm) {
        case MedicationForm.tablet:
          final count = double.tryParse(text) ?? 0;
          result = DoseCalculator.calculateFromTablets(
            tabletCount: count,
            strengthPerTabletMcg: widget.strengthPerUnitMcg,
            strengthUnit: _effectiveStrengthUnit(),
          );
          break;

        case MedicationForm.capsule:
          final count = _tryParseWholeNumber(text);
          if (count == null) {
            result = DoseCalculationResult.error(
              'Capsule count must be a whole number',
            );
            break;
          }
          result = DoseCalculator.calculateFromCapsules(
            capsuleCount: count,
            strengthPerCapsuleMcg: widget.strengthPerUnitMcg,
          );
          break;

        case MedicationForm.prefilledSyringe:
          final count = _tryParseWholeNumber(text);
          if (count == null) {
            result = DoseCalculationResult.error(
              'Injection count must be a whole number',
            );
            break;
          }
          result = DoseCalculator.calculateFromPrefilledInjections(
            injectionCount: count,
            strengthPerInjectionMcg: widget.strengthPerUnitMcg,
            volumePerInjectionMicroliter: widget.volumePerUnitMicroliter ?? 0,
          );
          break;

        case MedicationForm.singleDoseVial:
          final count = _tryParseWholeNumber(text);
          if (count == null) {
            result = DoseCalculationResult.error(
              'Vial count must be a whole number',
            );
            break;
          }
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
            break;

          case MdvInputMode.volume:
            // Input: desired dose volume (in ml) → calc volume + units
            final volumeMicroliter = value * 1000; // Convert ml to µL
            result = DoseCalculator.calculateFromVolumeMDV(
              volumeMicroliter: volumeMicroliter,
              totalVialStrengthMcg: widget.totalVialStrengthMcg!,
              totalVialVolumeMicroliter: widget.totalVialVolumeMicroliter!,
              syringeType: widget.syringeType!,
            );
            break;

          case MdvInputMode.units:
            // Input: desired syringe units → calc strength + volume
            result = DoseCalculator.calculateFromUnitsMDV(
              syringeUnits: value,
              totalVialStrengthMcg: widget.totalVialStrengthMcg!,
              totalVialVolumeMicroliter: widget.totalVialVolumeMicroliter!,
              syringeType: widget.syringeType!,
            );
            break;
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

    return result;
  }

  void _calculate() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _result = null);
      return;
    }

    final result = _computeResult(text);

    setState(() => _result = result);
    widget.onDoseChanged(result);
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
    final step = _defaultStepperStep(customStep: customStep);
    if (widget.medicationForm == MedicationForm.multiDoseVial &&
        _mdvMode == MdvInputMode.units) {
      final isWholeNumber = (current - current.roundToDouble()).abs() < 0.0001;
      final newValue = isWholeNumber
          ? (current + step)
          : current.ceilToDouble();
      _controller.text = _formatStepperValue(newValue);
    } else {
      final newValue = _snapToReasonablePrecision(current + step);
      _controller.text = _formatStepperValue(newValue);
    }
    _calculate();
  }

  void _decrement({double? customStep}) {
    final current = double.tryParse(_controller.text) ?? 0;
    final step = _defaultStepperStep(customStep: customStep);
    if (widget.medicationForm == MedicationForm.multiDoseVial &&
        _mdvMode == MdvInputMode.units) {
      final isWholeNumber = (current - current.roundToDouble()).abs() < 0.0001;
      final newValue = isWholeNumber
          ? (current - step)
          : current.floorToDouble();
      if (newValue >= 0) {
        _controller.text = _formatStepperValue(newValue);
        _calculate();
      }
      return;
    }

    final newValue = _snapToReasonablePrecision(current - step);
    if (newValue >= 0) {
      _controller.text = _formatStepperValue(newValue);
      _calculate();
    }
  }

  double _defaultStepperStep({double? customStep}) {
    if (customStep != null) {
      return customStep;
    }

    if (widget.medicationForm == MedicationForm.multiDoseVial) {
      switch (_mdvMode) {
        case MdvInputMode.volume:
          return 0.01;
        case MdvInputMode.units:
          return 1;
        case MdvInputMode.strength:
          return 1;
      }
    }

    // Count mode: tablets allow quarter-tablet steps; other unit-count forms are whole numbers.
    if (_isCountMode) {
      if (widget.medicationForm == MedicationForm.tablet) {
        return 0.25;
      }
      return 1;
    }

    // Strength mode: step in increments that correspond to valid unit counts.
    switch (widget.medicationForm) {
      case MedicationForm.tablet:
        // 1/4 tablet strength steps (e.g., 10mg tablet => 2.5mg increments).
        final stepMcg = widget.strengthPerUnitMcg * 0.25;
        final stepDisplay = _convertMcgToDisplayUnit(stepMcg);
        return stepDisplay > 0 ? stepDisplay : 1;

      case MedicationForm.capsule:
        // Whole capsules only.
        final stepDisplay = _convertMcgToDisplayUnit(widget.strengthPerUnitMcg);
        return stepDisplay > 0 ? stepDisplay : 1;

      case MedicationForm.prefilledSyringe:
      case MedicationForm.singleDoseVial:
      case MedicationForm.multiDoseVial:
        // Strength mode not supported for these forms.
        return 1;
    }
  }

  double _snapToReasonablePrecision(double value) {
    // Avoid displaying floating-point artifacts like 0.30000000000004.
    return double.parse(value.toStringAsFixed(6));
  }

  void _setQuickValue(double value) {
    _controller.text = value.toString();
    _calculate();
  }

  bool _requiresWholeNumber() {
    if (!_isCountMode) {
      return false;
    }

    switch (widget.medicationForm) {
      case MedicationForm.capsule:
      case MedicationForm.prefilledSyringe:
      case MedicationForm.singleDoseVial:
        return true;
      case MedicationForm.tablet:
      case MedicationForm.multiDoseVial:
        return false;
    }
  }

  String _formatStepperValue(double value) {
    if (_requiresWholeNumber()) {
      return value.round().toString();
    }

    final isWholeNumber = (value - value.roundToDouble()).abs() < 0.0001;
    if (isWholeNumber) {
      return value.round().toString();
    }
    return value.toString();
  }

  int? _tryParseWholeNumber(String text) {
    final parsed = double.tryParse(text);
    if (parsed == null) {
      return null;
    }

    final rounded = parsed.round();
    if ((parsed - rounded).abs() > 0.0001) {
      return null;
    }

    return rounded;
  }

  void _onSyringeDragChanged(double newUnits) {
    // Week 4: Handle interactive syringe drag
    // User dragged the syringe to adjust units - recalculate from units
    if (widget.medicationForm != MedicationForm.multiDoseVial) return;
    if (widget.totalVialStrengthMcg == null ||
        widget.totalVialVolumeMicroliter == null ||
        widget.syringeType == null)
      return;

    final clamped = newUnits.clamp(0, widget.syringeType!.maxUnits.toDouble());
    final snapped = _mdvMode == MdvInputMode.units
        ? clamped.roundToDouble()
        : double.parse(clamped.toStringAsFixed(2));

    // Calculate from units
    final result = DoseCalculator.calculateFromUnitsMDV(
      syringeUnits: snapped,
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
          _controller.text = fmt2(displayValue);
          break;
        case MdvInputMode.volume:
          final volumeMl = (result.doseVolumeMicroliter ?? 0) / 1000;
          _controller.text = fmt2(volumeMl);
          break;
        case MdvInputMode.units:
          _controller.text = _formatUnits(snapped);
          break;
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
          const SizedBox(height: kSpacingS),
          _buildTabletCapsuleHelperText(),
          if (widget.medicationForm == MedicationForm.tablet) ...[
            const SizedBox(height: kSpacingS),
            Visibility(
              visible: _shouldShowTabletStrengthUnitPicker(),
              maintainAnimation: true,
              maintainSize: true,
              maintainState: true,
              child: _buildTabletStrengthUnitPicker(),
            ),
          ],
          const SizedBox(height: kFieldGroupSpacing),
        ],

        // MDV mode toggle (3-way: Strength | Volume | Units)
        if (widget.medicationForm == MedicationForm.multiDoseVial) ...[
          _buildMdvModeToggle(cs),
          const SizedBox(height: kSpacingS),
          _buildMdvModeHelperText(),
          if (_mdvMode == MdvInputMode.strength &&
              widget.strengthUnit != 'units') ...[
            const SizedBox(height: kSpacingS),
            _buildMdvStrengthUnitPicker(),
          ],
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

        // MDV syringe gauge (always visible; drag to fine-tune)
        if (widget.medicationForm == MedicationForm.multiDoseVial &&
            widget.syringeType != null) ...[
          _buildMdvSyringeSection(cs),
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

  Widget _buildTabletCapsuleHelperText() {
    if (widget.medicationForm != MedicationForm.tablet &&
        widget.medicationForm != MedicationForm.capsule) {
      return const SizedBox.shrink();
    }

    final countLabel = widget.medicationForm == MedicationForm.tablet
        ? 'Tablets'
        : 'Capsules';
    final perUnitLabel = widget.medicationForm == MedicationForm.tablet
        ? 'tablet'
        : 'capsule';

    return Text(
      'Select $countLabel to enter quantity. Select Strength to enter a dose amount; the app calculates the equivalent using the strength per $perUnitLabel.',
      style: helperTextStyle(context),
    );
  }

  Widget _buildMdvModeHelperText() {
    if (widget.medicationForm != MedicationForm.multiDoseVial) {
      return const SizedBox.shrink();
    }

    return Text(
      'Select a dose input mode: Strength, Volume, or Units. The app calculates the other values automatically.',
      style: helperTextStyle(context),
    );
  }

  String _formatUnits(double v) {
    return fmt2(v);
  }

  bool _supportsModeToggle() {
    return widget.medicationForm == MedicationForm.tablet ||
        widget.medicationForm == MedicationForm.capsule;
  }

  bool _shouldShowTabletStrengthUnitPicker() {
    return widget.medicationForm == MedicationForm.tablet && !_isCountMode;
  }

  Widget _buildTabletStrengthUnitPicker() {
    return LabelFieldRow(
      label: 'Unit',
      field: SmallDropdown36<String>(
        value: _strengthUnit,
        items: const [
          DropdownMenuItem(value: 'mcg', child: Text('mcg')),
          DropdownMenuItem(value: 'mg', child: Text('mg')),
          DropdownMenuItem(value: 'g', child: Text('g')),
        ],
        onChanged: (value) {
          if (value == null || value == _strengthUnit) return;

          final raw = double.tryParse(_controller.text.trim());
          final mcg = raw == null ? null : _convertDisplayUnitToMcg(raw);

          setState(() {
            _strengthUnit = value;
            if (mcg != null) {
              _controller.text = fmt2(_convertMcgToDisplayUnit(mcg));
            }
          });

          widget.onStrengthUnitChanged?.call(value);
          _calculate();
        },
      ),
    );
  }

  Widget _buildModeToggle(ColorScheme cs) {
    final value = _isCountMode ? 'count' : 'strength';

    return LabelFieldRow(
      label: 'Dose Type',
      field: SmallDropdown36<String>(
        value: value,
        items: [
          DropdownMenuItem(
            value: 'count',
            child: Text(_getCountModeLabel(), style: bodyTextStyle(context)),
          ),
          DropdownMenuItem(
            value: 'strength',
            child: Text('Strength', style: bodyTextStyle(context)),
          ),
        ],
        onChanged: (newValue) {
          final shouldCount = newValue == 'count';
          if (shouldCount == _isCountMode) return;

          setState(() {
            _isCountMode = shouldCount;
            _controller.clear();
            _result = null;
          });

          widget.onDoseChanged(
            DoseCalculationResult.error('Mode changed - enter new dose'),
          );
        },
      ),
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
      color: isSelected ? cs.primary.withValues(alpha: 0.08) : cs.surface,
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
                  : cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
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
    if (widget.medicationForm != MedicationForm.multiDoseVial) {
      final stepper = StepperRow36(
        controller: _controller,
        onDec: _decrement,
        onInc: _increment,
        decoration: buildFieldDecoration(context, hint: _getInputHint()),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        onChanged: (_) => _calculate(),
      );

      if (widget.medicationForm == MedicationForm.tablet) {
        return Center(child: stepper);
      }

      return stepper;
    }

    final unitLabel = _getInlineUnitLabel();
    return Row(
      children: [
        // Decrement button
        _buildStepperButton(icon: Icons.remove, onPressed: _decrement, cs: cs),
        const SizedBox(width: kStepperButtonSpacing),

        // Input field
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.numberWithOptions(
              decimal: _mdvMode != MdvInputMode.units,
            ),
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                _mdvMode == MdvInputMode.units
                    ? RegExp(r'^\d*')
                    : RegExp(r'^\d*\.?\d*'),
              ),
            ],
            decoration: buildFieldDecoration(context, hint: _getInputHint()),
            onChanged: (_) => _calculate(),
          ),
        ),
        if (unitLabel != null) ...[
          const SizedBox(width: kSpacingS),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 34),
            child: Text(
              unitLabel,
              style: bodyTextStyle(context)?.copyWith(
                fontWeight: kFontWeightSemiBold,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(width: kStepperButtonSpacing),

        // Increment button
        _buildStepperButton(icon: Icons.add, onPressed: _increment, cs: cs),
      ],
    );
  }

  String? _getInlineUnitLabel() {
    if (widget.medicationForm != MedicationForm.multiDoseVial) return null;
    switch (_mdvMode) {
      case MdvInputMode.volume:
        return 'mL';
      case MdvInputMode.units:
        return 'U';
      case MdvInputMode.strength:
        final u = _effectiveStrengthUnit();
        if (u == 'mcg') return 'mcg';
        if (u == 'mg') return 'mg';
        if (u == 'g') return 'g';
        if (u == 'units') return 'units';
        return u;
    }
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
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(kStepperButtonSize, kStepperButtonSize),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
            width: kBorderWidthThin,
          ),
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          ),
        ),
        child: Icon(icon, size: kIconSizeMedium),
      ),
    );
  }

  Widget _buildQuickButtons(ColorScheme cs) {
    final buttons = [('1/4', 0.25), ('1/2', 0.5), ('1', 1.0), ('2', 2.0)];
    final borderColor = cs.outlineVariant.withValues(alpha: kCardBorderOpacity);

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
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
            backgroundColor: cs.surface,
            side: BorderSide(color: borderColor, width: kBorderWidthThin),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            ),
            labelStyle: bodyTextStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightMedium),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMdvStrengthUnitPicker() {
    return LabelFieldRow(
      label: 'Unit',
      field: SmallDropdown36<String>(
        value: _mdvStrengthUnit,
        items: const [
          DropdownMenuItem(value: 'mcg', child: Text('mcg')),
          DropdownMenuItem(value: 'mg', child: Text('mg')),
          DropdownMenuItem(value: 'g', child: Text('g')),
        ],
        onChanged: (value) {
          if (value == null || value == _mdvStrengthUnit) return;

          final raw = double.tryParse(_controller.text.trim());
          // Convert the existing value to the new unit so the dose stays consistent.
          final mcg = raw == null ? null : _convertDisplayUnitToMcg(raw);

          setState(() {
            _mdvStrengthUnit = value;
            if (mcg != null) {
              _controller.text = fmt2(_convertMcgToDisplayUnit(mcg));
            }
          });

          _calculate();
        },
      ),
    );
  }

  Widget _buildMdvSyringeSection(ColorScheme cs) {
    final totalUnits = widget.syringeType!.maxUnits.toDouble();
    final parsedUnits = double.tryParse(_controller.text.trim()) ?? 0;
    final fillUnits =
        (_result?.syringeUnits ??
                (_mdvMode == MdvInputMode.units ? parsedUnits : 0))
            .clamp(0, totalUnits)
            .toDouble();

    final helper = _mdvMode == MdvInputMode.units
        ? 'Drag the syringe or use +/- for fine adjustments (U = Units)'
        : 'Syringe units preview (drag to fine-tune)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(helper, style: helperTextStyle(context)),
        const SizedBox(height: kSpacingS),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_mdvMode == MdvInputMode.units) ...[
              _buildStepperButton(
                icon: Icons.remove,
                onPressed: () => _decrement(customStep: 1),
                cs: cs,
              ),
              const SizedBox(width: kSpacingS),
            ],
            Expanded(
              child: WhiteSyringeGauge(
                totalUnits: totalUnits,
                fillUnits: fillUnits,
                interactive: true,
                onChanged: _onSyringeDragChanged,
                showValueLabel: true,
              ),
            ),
            if (_mdvMode == MdvInputMode.units) ...[
              const SizedBox(width: kSpacingS),
              _buildStepperButton(
                icon: Icons.add,
                onPressed: () => _increment(customStep: 1),
                cs: cs,
              ),
            ],
          ],
        ),
      ],
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
      strengthStr = '${fmt3(strengthMcg / 1000)}mg';
    } else {
      strengthStr = '${strengthMcg.toStringAsFixed(0)}mcg';
    }

    final volumeStr = '${fmt2(volumeMl)}ml';
    final unitsStr = '${fmt2(units)} Units';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
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

    final warningTint = cs.tertiary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: _result!.hasError
            ? cs.errorContainer
            : (_result!.hasWarning
                  ? warningTint.withValues(alpha: 0.10)
                  : cs.surface),
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(
          color: _result!.hasError
              ? cs.error
              : (_result!.hasWarning
                    ? warningTint
                    : cs.outlineVariant.withValues(alpha: kCardBorderOpacity)),
          width: kBorderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main display text
          Align(
            alignment: Alignment.center,
            child: Text(
              _result!.displayText,
              textAlign: TextAlign.center,
              style: bodyTextStyle(context)?.copyWith(
                fontWeight: kFontWeightSemiBold,
                color: _result!.hasError
                    ? cs.onErrorContainer
                    : (_result!.hasWarning
                          ? warningTint
                          : cs.onSurfaceVariant.withValues(
                              alpha: kOpacityMediumLow,
                            )),
              ),
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
                  color: warningTint,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _result!.warning!,
                    style: helperTextStyle(
                      context,
                    )?.copyWith(color: warningTint),
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
