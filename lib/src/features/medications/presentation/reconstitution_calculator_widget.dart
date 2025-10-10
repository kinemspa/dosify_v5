import 'dart:math';

import 'package:flutter/material.dart';
import '../../../widgets/field36.dart';
import '../../../widgets/unified_form.dart';
import '../../../widgets/white_syringe_gauge.dart';
import 'ui_consts.dart';
import 'reconstitution_calculator_dialog.dart';
import 'reconstitution_calculator_helpers.dart';

/// Legacy local stepper replaced by shared StepperRow36 for consistency.

/// Reusable reconstitution calculator widget used in both dialog and inline contexts
class ReconstitutionCalculatorWidget extends StatefulWidget {
  const ReconstitutionCalculatorWidget({
    super.key,
    required this.initialStrengthValue,
    required this.unitLabel,
    this.medicationName,
    this.initialDoseValue,
    this.initialDoseUnit,
    this.initialSyringeSize,
    this.initialVialSize,
    this.onApply,
    this.onCalculate,
    this.showSummary = true,
    this.showApplyButton = false,
  });

  final double initialStrengthValue;
  final String unitLabel;
  final String? medicationName;
  final double? initialDoseValue;
  final String? initialDoseUnit;
  final SyringeSizeMl? initialSyringeSize;
  final double? initialVialSize;
  final void Function(ReconstitutionResult)? onApply;
  final void Function(ReconstitutionResult, bool)? onCalculate;
  final bool showSummary;
  final bool showApplyButton;

  @override
  State<ReconstitutionCalculatorWidget> createState() =>
      _ReconstitutionCalculatorWidgetState();
}

class _ReconstitutionCalculatorWidgetState
    extends State<ReconstitutionCalculatorWidget> {
  late final TextEditingController _doseCtrl;
  final TextEditingController _vialSizeCtrl = TextEditingController();
  final TextEditingController _diluentNameCtrl = TextEditingController();
  late String _doseUnit;
  SyringeSizeMl _syringe = SyringeSizeMl.ml1;
  double _selectedUnits = 50;
  String? _selectedOption; // Track which option is selected

  @override
  void initState() {
    super.initState();
    // Default to 100 or use provided value
    final defaultDose = widget.initialDoseValue ?? 100;
    _doseCtrl = TextEditingController(
      text: defaultDose == defaultDose.roundToDouble()
          ? defaultDose.toInt().toString()
          : defaultDose.toStringAsFixed(2),
    );
    // Set dose unit to match vial unit for IU medications, otherwise default to mcg
    _doseUnit =
        widget.initialDoseUnit ??
        (widget.unitLabel == 'units' ? 'units' : 'mcg');
    _syringe = widget.initialSyringeSize ?? _syringe;
    if (widget.initialVialSize != null) {
      _vialSizeCtrl.text = widget.initialVialSize!.toStringAsFixed(2);
    }
    _selectedUnits = _syringe.totalUnits * 0.5;
  }

  @override
  void dispose() {
    _doseCtrl.dispose();
    _vialSizeCtrl.dispose();
    _diluentNameCtrl.dispose();
    super.dispose();
  }

  // Helper methods now imported from reconstitution_calculator_helpers.dart
  // - round2() - Round to 2 decimal places
  // - roundToHalfMl() - Round to nearest 0.5 mL
  // - formatDouble() - Format for display (was _fmt)
  // - toBaseMass() - Convert units to mg (was _toBaseMass)

  ({double cPerMl, double vialVolume}) _computeForUnits({
    required double S,
    required double D,
    required double U,
  }) {
    // S = total strength in vial (mg)
    // D = desired dose per injection (mg)
    // U = IU units to draw from syringe
    // Formula: V = (S / D) × (U / 100)
    // Concentration: C = D × (100 / U)
    final c = (100 * D) / max(U, 0.01);
    final v = (S / max(D, 0.000001)) * (U / 100.0);
    return (cPerMl: c, vialVolume: v);
  }

  (double, double, double) _presetUnitsRaw() {
    final total = _syringe.totalUnits.toDouble();
    final minU = max(5, (total * 0.05).ceil()).toDouble();
    final midU = round2(total * 0.33);
    final highU = round2(total * 0.80);
    return (minU, midU, highU);
  }

  InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
          width: 0.75,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2.0),
      ),
    );
  }

  Widget _rowLabelField(
    BuildContext context, {
    required String label,
    required Widget field,
  }) {
    // Use unified row to ensure consistent label styling and spacing.
    return LabelFieldRow(label: label, field: field);
  }

  Widget _helperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 128, bottom: 8, top: 2),
      child: Text(text, style: kMutedLabelStyle(context)),
    );
  }

  Widget _pillBtn(BuildContext context, String label, VoidCallback onTap) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          width: 36,
          height: kFieldHeight,
          child: Center(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show calculator content if strength is valid
    if (widget.initialStrengthValue <= 0) {
      return const SizedBox.shrink();
    }

    // Sync dose unit with vial unit when vial changes to/from 'units'
    // This handles the case where user changes medication strength unit
    if (widget.unitLabel == 'units' && _doseUnit != 'units') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _doseUnit = 'units';
          });
        }
      });
    } else if (widget.unitLabel != 'units' && _doseUnit == 'units') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _doseUnit = 'mcg'; // Default back to mcg for mass-based units
          });
        }
      });
    }

    // Use strength from parent (already set above)
    final Sraw = widget.initialStrengthValue;
    final Draw = double.tryParse(_doseCtrl.text) ?? 0;

    double S = Sraw;
    double D = Draw;
    if (widget.unitLabel != 'units') {
      final S_mg = toBaseMass(Sraw, widget.unitLabel);
      final D_mg = toBaseMass(Draw, _doseUnit);
      S = S_mg;
      D = D_mg;
    }

    final vialMax = double.tryParse(_vialSizeCtrl.text);
    final (minURaw, midURaw, highURaw) = _presetUnitsRaw();

    double totalIU = _syringe.totalUnits.toDouble();
    double iuMin = minURaw;
    double iuMax = totalIU;
    if (vialMax != null && S > 0 && D > 0) {
      final uMaxAllowed = (100 * D * vialMax) / S;
      iuMax = uMaxAllowed.clamp(0, totalIU).toDouble();
      if (iuMax < iuMin) iuMin = iuMax;
    }

    final sliderMin = iuMin;
    final sliderMax = iuMax;
    _selectedUnits = _selectedUnits.clamp(sliderMin, sliderMax);

    final current = _computeForUnits(S: S, D: D, U: _selectedUnits);
    final currentC = round2(current.cPerMl);
    final currentV = current.vialVolume; // Use precise value for live display
    final currentVRounded = roundToHalfMl(
      current.vialVolume,
    ); // Rounded for saving
    final fitsVial = vialMax == null || currentV <= vialMax + 1e-9;

    // Notify parent of calculation result (use rounded value for saving)
    final result = ReconstitutionResult(
      perMlConcentration: currentC,
      solventVolumeMl: currentVRounded,
      recommendedUnits: round2(_selectedUnits),
      syringeSizeMl: _syringe.ml,
      diluentName: _diluentNameCtrl.text.trim().isNotEmpty
          ? _diluentNameCtrl.text.trim()
          : null,
    );
    final isValid = S > 0 && D > 0 && fitsVial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCalculate?.call(result, isValid);
    });

    double u1 = sliderMin;
    double u3 = sliderMax;
    double u2 = sliderMin + (sliderMax - sliderMin) / 2.0;

    final conc = _computeForUnits(S: S, D: D, U: u1);
    final std = _computeForUnits(S: S, D: D, U: u2);
    final dil = _computeForUnits(S: S, D: D, U: u3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Reconstitution Calculator',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Using vial strength: ${formatDouble(widget.initialStrengthValue)} ${widget.unitLabel}',
            style: kMutedLabelStyle(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'The calculator determines how much diluent to add for correct doses. Enter fluid name, desired dose, syringe size, optional max vial size, then select an option below or adjust with the slider.',
            style: kMutedLabelStyle(context),
          ),
        ),
        _rowLabelField(
          context,
          label: 'Diluent',
          field: Field36(
            child: TextField(
              controller: _diluentNameCtrl,
              decoration: _fieldDecoration(
                context,
                hint: 'e.g., Sterile Water',
              ),
              onChanged: (_) => setState(() {}),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        _helperText('Reconstitution fluid name'),
        _rowLabelField(
          context,
          label: 'Desired Dose',
          field: StepperRow36(
            controller: _doseCtrl,
            onDec: () {
              final v = double.tryParse(_doseCtrl.text.trim()) ?? 0;
              final newVal = (v - 1).clamp(1, double.infinity);
              setState(() {
                _doseCtrl.text = newVal == newVal.roundToDouble()
                    ? newVal.toInt().toString()
                    : newVal.toString();
              });
            },
            onInc: () {
              final v = double.tryParse(_doseCtrl.text.trim()) ?? 0;
              final newVal = (v + 1).clamp(1, double.infinity);
              setState(() {
                _doseCtrl.text = newVal == newVal.roundToDouble()
                    ? newVal.toInt().toString()
                    : newVal.toString();
              });
            },
            decoration: _fieldDecoration(context, hint: '100'),
          ),
        ),
        _rowLabelField(
          context,
          label: 'Dose Unit',
          field: SmallDropdown36<String>(
            value: _doseUnit,
            items: [
              if (widget.unitLabel == 'units')
                const DropdownMenuItem(
                  value: 'units',
                  child: Center(child: Text('units')),
                ),
              if (widget.unitLabel != 'units') ...const [
                DropdownMenuItem(
                  value: 'mcg',
                  child: Center(child: Text('mcg')),
                ),
                DropdownMenuItem(
                  value: 'mg',
                  child: Center(child: Text('mg')),
                ),
                DropdownMenuItem(
                  value: 'g',
                  child: Center(child: Text('g')),
                ),
              ],
            ],
            onChanged: (v) {
              // Don't reset dose value when changing unit
              setState(() => _doseUnit = v!);
            },
            decoration: _fieldDecoration(context),
          ),
        ),
        _helperText('Enter the amount per dose and select its unit'),
        _rowLabelField(
          context,
          label: 'Syringe Size',
          field: SmallDropdown36<SyringeSizeMl>(
            value: _syringe,
            items: SyringeSizeMl.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Center(child: Text(s.label)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _syringe = v!;
              final total = _syringe.totalUnits.toDouble();
              _selectedUnits = max(
                _selectedUnits,
                max(5, (0.05 * total).ceil()).toDouble(),
              );
            }),
            decoration: _fieldDecoration(context),
          ),
        ),
        _helperText('Select the syringe capacity'),
        _rowLabelField(
          context,
          label: 'Max Vial Size',
          field: StepperRow36(
            controller: _vialSizeCtrl,
            onDec: () {
              final v = int.tryParse(_vialSizeCtrl.text.trim()) ?? 0;
              setState(
                () => _vialSizeCtrl.text = (v - 1).clamp(0, 100).toString(),
              );
            },
            onInc: () {
              final v = int.tryParse(_vialSizeCtrl.text.trim()) ?? 0;
              setState(
                () => _vialSizeCtrl.text = (v + 1).clamp(0, 100).toString(),
              );
            },
            decoration: _fieldDecoration(context, hint: 'mL'),
          ),
        ),
        _helperText('Maximum capacity in mL of the vial (optional constraint)'),
        Divider(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
        const SizedBox(height: 12),
        if (sliderMax > 0 && !sliderMax.isNaN) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Select a reconstitution option',
              style: kMutedLabelStyle(context),
            ),
          ),
          _buildOptionRow(
            context,
            'Concentrated',
            'concentrated',
            _selectedOption,
            () => setState(() {
              _selectedUnits = u1;
              _selectedOption = 'concentrated';
            }),
            conc,
            u1,
            isValid: u1 >= sliderMin && u1 <= sliderMax,
          ),
          _buildOptionRow(
            context,
            'Balanced',
            'balanced',
            _selectedOption,
            () => setState(() {
              _selectedUnits = u2;
              _selectedOption = 'balanced';
            }),
            std,
            u2,
            isValid: u2 >= sliderMin && u2 <= sliderMax,
          ),
          _buildOptionRow(
            context,
            'Diluted',
            'diluted',
            _selectedOption,
            () => setState(() {
              _selectedUnits = u3;
              _selectedOption = 'diluted';
            }),
            dil,
            u3,
            isValid: u3 >= sliderMin && u3 <= sliderMax,
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(left: 0, bottom: 8),
            child: Text(
              'No valid options — Check strength, dose, or syringe size',
              style: kMutedLabelStyle(context),
            ),
          ),
        const SizedBox(height: 12),
        // Support text above syringe
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            'Drag the fill line or tap on the syringe to adjust diluent amount',
            style: kMutedLabelStyle(context),
          ),
        ),
        // Range limit warning removed - using snackbar only for cleaner UI
        const SizedBox(height: 8),
        // Live syringe gauge preview (interactive)
        if (S > 0 && D > 0 && !currentV.isNaN && !_selectedUnits.isNaN) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                WhiteSyringeGauge(
                  totalIU: _syringe.totalUnits.toDouble(),
                  fillIU: _selectedUnits,
                  interactive: true,
                  maxConstraint: sliderMax,
                  onMaxConstraintHit: () {
                    // Show snackbar when user hits constraint
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          vialMax != null
                              ? 'Limited by max vial size (${vialMax.toStringAsFixed(1)} mL)'
                              : 'Limited by syringe capacity',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onChanged: (newValue) {
                    // Clamp to slider min/max
                    final clampedValue = newValue.clamp(sliderMin, sliderMax);
                    setState(() {
                      _selectedUnits = clampedValue;
                      _selectedOption =
                          null; // Clear option selection on manual adjust
                    });
                  },
                ),
                Positioned(
                  top: -2,
                  right: 0,
                  child: Text(
                    '${_syringe.label} Syringe',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Conversational explanation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      const TextSpan(text: 'Reconstitute '),
                      TextSpan(
                        text:
                            '${formatDouble(widget.initialStrengthValue)} ${widget.unitLabel}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (widget.medicationName != null &&
                          widget.medicationName!.isNotEmpty) ...[
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: widget.medicationName!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                      const TextSpan(text: ' with '),
                      TextSpan(
                        text: '${currentV.toStringAsFixed(2)} mL',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: _diluentNameCtrl.text.trim().isNotEmpty
                            ? ' ${_diluentNameCtrl.text.trim()}'
                            : ' diluent',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Split into 3 lines to prevent shifting
                RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: 'Draw '),
                      TextSpan(
                        text: '${_selectedUnits.toStringAsFixed(1)} IU',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' ('),
                      TextSpan(
                        text:
                            '${((_selectedUnits / 100) * _syringe.ml).toStringAsFixed(2)} mL',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ')'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: 'into a '),
                      TextSpan(
                        text: _syringe.label,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' syringe'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: 'for your '),
                      TextSpan(
                        text: '${formatDouble(Draw)} $_doseUnit',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' dose'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (!fitsVial)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Warning: Computed solvent volume (${currentV.toStringAsFixed(2)} mL) exceeds vial size. Try a more concentrated preset (lower IU).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        if (widget.showApplyButton) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: (S > 0 && D > 0 && fitsVial)
                  ? () {
                      final result = ReconstitutionResult(
                        perMlConcentration: currentC,
                        solventVolumeMl: currentV,
                        recommendedUnits: round2(_selectedUnits),
                        syringeSizeMl: _syringe.ml,
                        diluentName: _diluentNameCtrl.text.trim().isNotEmpty
                            ? _diluentNameCtrl.text.trim()
                            : null,
                      );
                      widget.onApply?.call(result);
                    }
                  : null,
              child: const Text('Save Reconstitution'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionRow(
    BuildContext context,
    String label,
    String optionValue,
    String? selectedValue,
    VoidCallback onTap,
    ({double cPerMl, double vialVolume}) calcResult,
    double units, {
    bool isValid = true,
  }) {
    final selected = selectedValue == optionValue;
    final theme = Theme.of(context);
    final diluentName = _diluentNameCtrl.text.trim().isNotEmpty
        ? _diluentNameCtrl.text.trim()
        : 'Diluent';
    final roundedVolume = roundToHalfMl(calcResult.vialVolume);
    // Calculate actual mL to draw for the dose
    final mlToDraw = (units / 100) * _syringe.ml;

    // Get explainer text based on label
    String explainerText;
    if (label == 'Concentrated') {
      explainerText = 'Strong small dosage';
    } else if (label == 'Balanced') {
      explainerText = 'Approx 50% syringe size dosage';
    } else if (label == 'Diluted') {
      explainerText = 'Large doses';
    } else {
      explainerText = '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: isValid ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: isValid ? 1.0 : 0.4,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: 2, // Consistent width to prevent nudging
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Radio<String>(
                  value: optionValue,
                  groupValue: selectedValue,
                  onChanged: isValid ? (_) => onTap() : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.5,
                                ),
                        ),
                      ),
                      if (explainerText.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          explainerText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selected
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${_diluentNameCtrl.text.trim().isNotEmpty ? _diluentNameCtrl.text.trim() : "Diluent"}: ',
                            ),
                            TextSpan(
                              text: '${formatDouble(roundedVolume)} mL',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selected
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                          ),
                          children: [
                            TextSpan(text: 'Concentration: '),
                            TextSpan(
                              text:
                                  '${formatDouble(calcResult.cPerMl)} ${widget.unitLabel}/mL',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selected
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                          ),
                          children: [
                            TextSpan(text: 'Syringe (${_syringe.label}): '),
                            TextSpan(
                              text:
                                  '${formatDouble(units)} IU / ${formatDouble(mlToDraw)} mL',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
