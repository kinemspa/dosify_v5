import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/field36.dart';
import '../../../widgets/unified_form.dart';
import 'ui_consts.dart';
import 'reconstitution_calculator_dialog.dart';

/// Legacy local stepper replaced by shared StepperRow36 for consistency.

/// Reusable reconstitution calculator widget used in both dialog and inline contexts
class ReconstitutionCalculatorWidget extends StatefulWidget {
  const ReconstitutionCalculatorWidget({
    super.key,
    required this.initialStrengthValue,
    required this.unitLabel,
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

  @override
  void initState() {
    super.initState();
    final defaultDose =
        widget.initialDoseValue ?? (widget.initialStrengthValue * 0.05);
    _doseCtrl = TextEditingController(
      text: defaultDose == defaultDose.roundToDouble()
          ? defaultDose.toInt().toString()
          : defaultDose.toStringAsFixed(2),
    );
    _doseUnit = widget.initialDoseUnit ?? widget.unitLabel;
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

  double _round2(double v) => (v * 100).round() / 100.0;

  /// Round to nearest 0.5 mL (whole or half mL)
  double _roundToHalfMl(double v) {
    return (v * 2).round() / 2.0;
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    final s = v.toStringAsFixed(2);
    if (s.endsWith('0')) return v.toStringAsFixed(1);
    return s;
  }

  double _toBaseMass(double value, String from) {
    if (from == 'g') return value * 1000.0;
    if (from == 'mg') return value;
    if (from == 'mcg') return value / 1000.0;
    return value;
  }

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
    final midU = _round2(total * 0.33);
    final highU = _round2(total * 0.80);
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
    // Use strength from parent (already set above)
    final Sraw = widget.initialStrengthValue;
    final Draw = double.tryParse(_doseCtrl.text) ?? 0;

    double S = Sraw;
    double D = Draw;
    if (widget.unitLabel != 'units') {
      final S_mg = _toBaseMass(Sraw, widget.unitLabel);
      final D_mg = _toBaseMass(Draw, _doseUnit);
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
    final currentC = _round2(current.cPerMl);
    final currentV = _roundToHalfMl(
      current.vialVolume,
    ); // Round to nearest 0.5 mL
    final fitsVial = vialMax == null || currentV <= vialMax + 1e-9;

    // Notify parent of calculation result
    final result = ReconstitutionResult(
      perMlConcentration: currentC,
      solventVolumeMl: currentV,
      recommendedUnits: _round2(_selectedUnits),
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
        Divider(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Reconstitution Calculator',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Using vial strength: ${_fmt(widget.initialStrengthValue)} ${widget.unitLabel}',
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
              final v = int.tryParse(_doseCtrl.text.trim()) ?? 0;
              setState(
                () => _doseCtrl.text = (v - 1).clamp(0, 1000000).toString(),
              );
            },
            onInc: () {
              final v = int.tryParse(_doseCtrl.text.trim()) ?? 0;
              setState(
                () => _doseCtrl.text = (v + 1).clamp(0, 1000000).toString(),
              );
            },
            decoration: _fieldDecoration(context, hint: '0'),
          ),
        ),
        _rowLabelField(
          context,
          label: 'Dose Unit',
          field: SmallDropdown36<String>(
            value: _doseUnit,
            width: kSmallControlWidth,
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
            onChanged: (v) => setState(() => _doseUnit = v!),
            decoration: _fieldDecoration(context),
          ),
        ),
        _helperText('Enter the amount per dose and select its unit'),
        _rowLabelField(
          context,
          label: 'Syringe Size',
          field: SmallDropdown36<SyringeSizeMl>(
            value: _syringe,
            width: kSmallControlWidth,
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
        const SizedBox(height: 16),
        if (sliderMax > 0 && !sliderMax.isNaN) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Choose reconstitution option: Concentration • Diluent volume • Syringe draw amount',
              style: kMutedLabelStyle(context),
            ),
          ),
          _buildOptionRow(
            context,
            'Concentrated',
            (_selectedUnits - u1).abs() < 0.01,
            () => setState(() => _selectedUnits = u1),
            conc,
            u1,
          ),
          _buildOptionRow(
            context,
            'Balanced',
            (_selectedUnits - u2).abs() < 0.01,
            () => setState(() => _selectedUnits = u2),
            std,
            u2,
          ),
          _buildOptionRow(
            context,
            'Diluted',
            (_selectedUnits - u3).abs() < 0.01,
            () => setState(() => _selectedUnits = u3),
            dil,
            u3,
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(left: 0, bottom: 8),
            child: Text(
              'No valid options — Check strength, dose, or syringe size',
              style: kMutedLabelStyle(context),
            ),
          ),
        const SizedBox(height: 16),
        Text('Fine-tune', style: Theme.of(context).textTheme.titleSmall),
        _helperText('Adjust diluent amount (affects IU concentration)'),
        Slider(
          value: _selectedUnits,
          min: sliderMin,
          max: sliderMax,
          divisions: (_syringe.totalUnits - sliderMin.toInt()).clamp(1, 100),
          label: '${_round2(_selectedUnits)} IU',
          onChanged: (v) => setState(() => _selectedUnits = v),
        ),
        if (widget.showSummary) ...[
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Summary', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Syringe: ${_syringe.label} • Fill: ${_round2(_selectedUnits)} IU',
              ),
              Text(
                'Concentration: ${currentC.toStringAsFixed(2)} ${widget.unitLabel}/mL',
              ),
              Text(
                'Vial volume: ${currentV.toStringAsFixed(2)} mL' +
                    (vialMax != null
                        ? ' (limit ${vialMax!.toStringAsFixed(2)} mL)'
                        : ''),
              ),
            ],
          ),
        ],
        if (!fitsVial)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Warning: Computed solvent volume (${currentV.toStringAsFixed(2)} mL) exceeds vial size. Try a more concentrated preset (lower IU).',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                        recommendedUnits: _round2(_selectedUnits),
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
    bool selected,
    VoidCallback onTap,
    ({double cPerMl, double vialVolume}) calcResult,
    double units,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ChoiceChip(
            label: Text(
              '${_fmt(calcResult.cPerMl)} ${widget.unitLabel}/mL • ${_fmt(_roundToHalfMl(calcResult.vialVolume))} mL • ${_fmt(units)} IU',
            ),
            selected: selected,
            onSelected: (_) => onTap(),
            selectedColor: theme.colorScheme.primary,
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
            labelStyle: theme.textTheme.bodySmall?.copyWith(
              color: selected ? Colors.white : theme.colorScheme.onSurface,
            ),
            showCheckmark: false,
          ),
        ],
      ),
    );
  }
}
