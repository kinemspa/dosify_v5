import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/format.dart';
import '../../../widgets/field36.dart';
import '../../../widgets/unified_form.dart';
import 'ui_consts.dart';
import 'reconstitution_calculator_dialog.dart';

class ReconstitutionCalculatorPage extends StatefulWidget {
  const ReconstitutionCalculatorPage({
    super.key,
    required this.initialStrengthValue,
    required this.unitLabel,
    this.initialDoseValue,
    this.initialDoseUnit,
    this.initialSyringeSize,
    this.initialVialSize,
  });

  final double initialStrengthValue;
  final String unitLabel;
  final double? initialDoseValue;
  final String? initialDoseUnit;
  final SyringeSizeMl? initialSyringeSize;
  final double? initialVialSize;

  @override
  State<ReconstitutionCalculatorPage> createState() =>
      _ReconstitutionCalculatorPageState();
}

class _ReconstitutionCalculatorPageState
    extends State<ReconstitutionCalculatorPage> {
  late final TextEditingController _strengthCtrl;
  late final TextEditingController _doseCtrl;
  final TextEditingController _vialSizeCtrl = TextEditingController();
  final TextEditingController _diluentCtrl = TextEditingController();
  late String _doseUnit; // 'mcg'|'mg'|'g'|'units'
  SyringeSizeMl _syringe = SyringeSizeMl.ml1;
  double _selectedUnits = 50;

  @override
  void initState() {
    super.initState();
    _strengthCtrl = TextEditingController(
      text: widget.initialStrengthValue.toStringAsFixed(2),
    );
    final defaultDose =
        widget.initialDoseValue ?? (widget.initialStrengthValue * 0.05);
    _doseCtrl = TextEditingController(
      text: defaultDose == defaultDose.roundToDouble()
          ? defaultDose.toInt().toString()
          : defaultDose.toStringAsFixed(2),
    );
    _doseUnit = widget.initialDoseUnit ?? widget.unitLabel;
    _syringe = widget.initialSyringeSize ?? _syringe;
    if (widget.initialVialSize != null)
      _vialSizeCtrl.text = widget.initialVialSize!.toStringAsFixed(2);
    _selectedUnits = _syringe.totalUnits * 0.5;
  }

  @override
  void dispose() {
    _strengthCtrl.dispose();
    _doseCtrl.dispose();
    _vialSizeCtrl.dispose();
    _diluentCtrl.dispose();
    super.dispose();
  }

  double _round2(double v) => (v * 100).round() / 100.0;
  double _toBaseMass(double value, String from) {
    if (from == 'g') return value * 1000.0; // g->mg
    if (from == 'mg') return value; // mg base
    if (from == 'mcg') return value / 1000.0; // mcg->mg
    return value; // units pass-through
  }

  ({double cPerMl, double vialVolume}) _compute({
    required double S,
    required double D,
    required double U,
  }) {
    final c = (100 * D) / max(U, 0.01);
    final v = S / max(c, 0.000001);
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
    // Use unified left-label row for consistency with other editors.
    return LabelFieldRow(label: label, field: field);
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
    final Sraw = double.tryParse(_strengthCtrl.text) ?? 0;
    final Draw = double.tryParse(_doseCtrl.text) ?? 0;

    // Convert mass units to mg base if needed
    double S = Sraw, D = Draw;
    if (widget.unitLabel != 'units') {
      S = _toBaseMass(Sraw, widget.unitLabel);
      D = _toBaseMass(Draw, _doseUnit);
    }

    final vialMax = double.tryParse(_vialSizeCtrl.text);
    final (minURaw, _, __) = _presetUnitsRaw();

    final totalIU = _syringe.totalUnits.toDouble();
    double iuMin = minURaw;
    double iuMax = totalIU;
    if (vialMax != null && S > 0 && D > 0) {
      final uMaxAllowed = (100 * D * vialMax) / S; // U <= this
      iuMax = uMaxAllowed.clamp(0, totalIU).toDouble();
      if (iuMax < iuMin) iuMin = iuMax;
    }

    final sliderMin = iuMin;
    final sliderMax = iuMax;
    _selectedUnits = _selectedUnits.clamp(sliderMin, sliderMax);

    // Presets evenly spaced
    final u1 = sliderMin;
    final u2 = sliderMin + (sliderMax - sliderMin) / 2.0;
    final u3 = sliderMax;

    final cur = _compute(S: S, D: D, U: _selectedUnits);
    final curC = _round2(cur.cPerMl);
    final curV = _round2(cur.vialVolume);
    final fits = vialMax == null || curV <= vialMax + 1e-9;

    final conc = _compute(S: S, D: D, U: u1);
    final std = _compute(S: S, D: D, U: u2);
    final dil = _compute(S: S, D: D, U: u3);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Reconstitution Calculator'),
        actions: [
          TextButton(
            onPressed: (S > 0 && D > 0 && fits)
                ? () {
                    final result = ReconstitutionResult(
                      perMlConcentration: curC,
                      solventVolumeMl: curV,
                      recommendedUnits: _round2(_selectedUnits),
                      syringeSizeMl: _syringe.ml,
                      diluentName: _diluentCtrl.text.trim().isNotEmpty
                          ? _diluentCtrl.text.trim()
                          : null,
                    );
                    context.pop(result);
                  }
                : null,
            child: const Text('Save Reconstitution'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
        children: [
          Divider(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
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
                controller: _diluentCtrl,
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
          _rowLabelField(
            context,
            label: 'Vial Strength',
            field: StepperRow36(
              controller: _strengthCtrl,
              onDec: () {
                final v = double.tryParse(_strengthCtrl.text) ?? 0;
                final nv = (v - 1).clamp(0, 10000);
                setState(() => _strengthCtrl.text = nv.toStringAsFixed(0));
              },
              onInc: () {
                final v = double.tryParse(_strengthCtrl.text) ?? 0;
                final nv = (v + 1).clamp(0, 10000);
                setState(() => _strengthCtrl.text = nv.toStringAsFixed(0));
              },
              decoration: _fieldDecoration(
                context,
                hint: '${widget.unitLabel}',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 128, bottom: 8, top: 2),
            child: Text(
              'Total drug amount in the source vial',
              style: kMutedLabelStyle(context),
            ),
          ),
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
              decoration: _fieldDecoration(context),
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
          Padding(
            padding: const EdgeInsets.only(left: 128, bottom: 8, top: 2),
            child: Text(
              'Enter the amount per dose and select its unit',
              style: kMutedLabelStyle(context),
            ),
          ),
          _rowLabelField(
            context,
            label: 'Syringe Size',
            field: Field36(
              child: DropdownButtonFormField<SyringeSizeMl>(
                value: _syringe,
                items: SyringeSizeMl.values
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
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
          ),
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
          Padding(
            padding: const EdgeInsets.only(left: 128, bottom: 8, top: 2),
            child: Text(
              'Maximum capacity in mL of the vial (optional constraint)',
              style: kMutedLabelStyle(context),
            ),
          ),
          Divider(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          if (sliderMax > 0 && !sliderMax.isNaN) ...[
            _buildOptionRow(
              context,
              'Concentrated',
              (_selectedUnits - u1).abs() < 0.01,
              () => setState(() => _selectedUnits = u1),
              conc,
              u1,
              widget.unitLabel,
            ),
            _buildOptionRow(
              context,
              'Balanced',
              (_selectedUnits - u2).abs() < 0.01,
              () => setState(() => _selectedUnits = u2),
              std,
              u2,
              widget.unitLabel,
            ),
            _buildOptionRow(
              context,
              'Diluted',
              (_selectedUnits - u3).abs() < 0.01,
              () => setState(() => _selectedUnits = u3),
              dil,
              u3,
              widget.unitLabel,
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
          Padding(
            padding: const EdgeInsets.only(left: 128, bottom: 8, top: 2),
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
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 6,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Syringe: ${_syringe.label} • Fill: ${fmt2(_selectedUnits)} IU',
              ),
              Text('Concentration: ${fmt2(curC)} ${widget.unitLabel}/mL'),
              Text(
                'Vial volume: ${fmt2(curV)} mL' +
                    (vialMax != null ? ' (limit ${fmt2(vialMax)} mL)' : ''),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: (S > 0 && D > 0 && fits)
                    ? () {
                        final result = ReconstitutionResult(
                          perMlConcentration: curC,
                          solventVolumeMl: curV,
                          recommendedUnits: _round2(_selectedUnits),
                          syringeSizeMl: _syringe.ml,
                          diluentName: _diluentCtrl.text.trim().isNotEmpty
                              ? _diluentCtrl.text.trim()
                              : null,
                        );
                        context.pop(result);
                      }
                    : null,
                child: const Text('Save Reconstitution'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildOptionRow(
  BuildContext context,
  String label,
  bool selected,
  VoidCallback onTap,
  ({double cPerMl, double vialVolume}) calcResult,
  double units,
  String unitLabel,
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
            '${fmt2(calcResult.cPerMl)} $unitLabel/mL • ${fmt2(calcResult.vialVolume)} mL • ${fmt2(units)} IU',
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
