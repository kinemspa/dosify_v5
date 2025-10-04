import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/field36.dart';
import '../../../widgets/unified_form.dart';
import '../../../widgets/white_syringe_gauge.dart';
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
    // Default to 100 or use provided value
    final defaultDose = widget.initialDoseValue ?? 100;
    _doseCtrl = TextEditingController(
      text: defaultDose == defaultDose.roundToDouble()
          ? defaultDose.toInt().toString()
          : defaultDose.toStringAsFixed(2),
    );
    _doseUnit = widget.initialDoseUnit ?? 'mcg';
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
        const SizedBox(height: 12),
        Text(
          'Reconstitution Calculator',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        const SizedBox(height: 12),
        if (sliderMax > 0 && !sliderMax.isNaN) ...[
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
        const SizedBox(height: 8),
        Text(
          'Fine-tune',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (vialMax != null && sliderMax < totalIU)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Range limited by max vial size (${vialMax.toStringAsFixed(1)} mL)',
              style: kMutedLabelStyle(
                context,
              ).copyWith(fontStyle: FontStyle.italic, fontSize: 11),
            ),
          )
        else if (sliderMax < totalIU)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Range limited by syringe capacity',
              style: kMutedLabelStyle(
                context,
              ).copyWith(fontStyle: FontStyle.italic, fontSize: 11),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 2, top: 2),
          child: Text(
            'Adjust diluent amount (affects IU concentration)',
            style: kMutedLabelStyle(context),
          ),
        ),
        Slider(
          value: _selectedUnits,
          min: sliderMin,
          max: sliderMax,
          divisions: (_syringe.totalUnits - sliderMin.toInt()).clamp(1, 100),
          label: '${_round2(_selectedUnits)} IU',
          onChanged: (v) => setState(() => _selectedUnits = v),
        ),
        // Live syringe gauge preview
        if (S > 0 && D > 0 && !currentV.isNaN && !_selectedUnits.isNaN) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: WhiteSyringeGauge(
              totalIU: _syringe.totalUnits.toDouble(),
              fillIU: _selectedUnits,
            ),
          ),
          const SizedBox(height: 16),
          // Conversational explanation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      const TextSpan(text: 'Reconstitute '),
                      TextSpan(
                        text: '${_fmt(widget.initialStrengthValue)} ${widget.unitLabel}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const TextSpan(text: ' with '),
                      TextSpan(
                        text: '${_fmt(currentV)} mL',
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
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    children: [
                      const TextSpan(text: 'Add '),
                  TextSpan(
                    text: '${_fmt(currentV)} mL',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: _diluentNameCtrl.text.trim().isNotEmpty
                        ? ' ${_diluentNameCtrl.text.trim()}'
                        : ' diluent',
                  ),
                  const TextSpan(text: ' to vial containing '),
                  TextSpan(
                    text: '${_fmt(widget.initialStrengthValue)} ${widget.unitLabel}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                children: [
                  const TextSpan(text: 'This creates '),
                  TextSpan(
                    text: '${_fmt(currentC)} ${widget.unitLabel}/mL',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' = '),
                  TextSpan(
                    text: '${_fmt(currentC)} ${widget.unitLabel} per mL',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' concentration.'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                children: [
                  const TextSpan(text: 'Draw '),
                  TextSpan(
                    text: '${_fmt(_selectedUnits)} IU',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' ('),
                  TextSpan(
                    text: '${_fmt((_selectedUnits / 100) * _syringe.ml)} mL',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ') into '),
                  TextSpan(
                    text: '${_syringe.label}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' syringe for your '),
                  TextSpan(
                    text: '${_fmt(Draw)} ${_doseUnit}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' dose.'),
                ],
              ),
            ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
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
    final diluentName = _diluentNameCtrl.text.trim().isNotEmpty
        ? _diluentNameCtrl.text.trim()
        : 'Diluent';
    final roundedVolume = _roundToHalfMl(calcResult.vialVolume);
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: selected,
                onChanged: (_) => onTap(),
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
                            : theme.colorScheme.onSurface,
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
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: '${_diluentNameCtrl.text.trim().isNotEmpty ? _diluentNameCtrl.text.trim() : "Diluent"}: ',
                          ),
                          TextSpan(
                            text: '${_fmt(roundedVolume)} mL',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(text: 'Concentration: '),
                          TextSpan(
                            text:
                                '${_fmt(calcResult.cPerMl)} ${widget.unitLabel}/mL',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(text: 'Syringe (${_syringe.label}): '),
                          TextSpan(
                            text: '${_fmt(units)} IU / ${_fmt(mlToDraw)} mL',
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
    );
  }
}
