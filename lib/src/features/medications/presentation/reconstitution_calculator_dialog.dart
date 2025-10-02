import 'dart:math';

import 'package:flutter/material.dart';
import '../../../widgets/field36.dart';
import 'ui_consts.dart';

enum SyringeSizeMl { ml0_3, ml0_5, ml1, ml3, ml5 }

extension SyringeSizeX on SyringeSizeMl {
  double get ml => switch (this) {
    SyringeSizeMl.ml0_3 => 0.3,
    SyringeSizeMl.ml0_5 => 0.5,
    SyringeSizeMl.ml1 => 1.0,
    SyringeSizeMl.ml3 => 3.0,
    SyringeSizeMl.ml5 => 5.0,
  };

  int get totalUnits => (ml * 100).round(); // assume 100 IU per mL mapping

  String get label => '${ml.toStringAsFixed(1)} mL';
}

class ReconstitutionResult {
  const ReconstitutionResult({
    required this.perMlConcentration,
    required this.solventVolumeMl,
    required this.recommendedUnits,
    required this.syringeSizeMl,
  });

  final double perMlConcentration; // same base unit as dose/strength (per mL)
  final double solventVolumeMl; // mL to add to vial
  final double recommendedUnits; // IU fill for the dose
  final double syringeSizeMl; // chosen syringe size mL
}

class ReconstitutionCalculatorDialog extends StatefulWidget {
  const ReconstitutionCalculatorDialog({
    super.key,
    required this.initialStrengthValue,
    required this.unitLabel, // e.g., mg, mcg, g, units
    this.initialDoseValue,
    this.initialDoseUnit,
    this.initialSyringeSize,
    this.initialVialSize,
  });

  final double initialStrengthValue; // total quantity in the vial (S)
  final String unitLabel;
  final double? initialDoseValue;
  final String? initialDoseUnit; // 'mcg'|'mg'|'g'|'units'
  final SyringeSizeMl? initialSyringeSize;
  final double? initialVialSize; // mL

  @override
  State<ReconstitutionCalculatorDialog> createState() =>
      _ReconstitutionCalculatorDialogState();
}

class _ReconstitutionCalculatorDialogState
    extends State<ReconstitutionCalculatorDialog> {
  late final TextEditingController _strengthCtrl;
  late final TextEditingController _doseCtrl;
  final TextEditingController _vialSizeCtrl = TextEditingController();

  // Dose unit selection (must be same dimension as strength)
  late String _doseUnit; // 'mcg'|'mg'|'g'|'units'

  SyringeSizeMl _syringe = SyringeSizeMl.ml1;

  // Slider-driving IU selection
  double _selectedUnits = 50; // default mid for 1mL syringe

  @override
  void initState() {
    super.initState();
    _strengthCtrl = TextEditingController(
      text: widget.initialStrengthValue.toStringAsFixed(2),
    );
    _doseCtrl = TextEditingController(
      text: (widget.initialDoseValue ?? (widget.initialStrengthValue * 0.05))
          .toStringAsFixed(2),
    );
    _doseUnit =
        widget.initialDoseUnit ??
        widget.unitLabel; // default to strength unit label
    _syringe = widget.initialSyringeSize ?? _syringe;
    if (widget.initialVialSize != null) {
      _vialSizeCtrl.text = widget.initialVialSize!.toStringAsFixed(2);
    }
    _selectedUnits = _syringe.totalUnits * 0.5;
  }

  @override
  void dispose() {
    _strengthCtrl.dispose();
    _doseCtrl.dispose();
    _vialSizeCtrl.dispose();
    super.dispose();
  }

  double _round2(double v) => (v * 100).round() / 100.0;

  // Compute per spec: C = D / (U * mL_per_IU) where mL_per_IU = 1/100
  // So C (per mL) = (100 * D) / U. Solvent volume V = S / C.
  double _toBaseMass(double value, String from) {
    if (from == 'g') return value * 1000.0; // gram -> mg
    if (from == 'mg') return value; // mg base
    if (from == 'mcg') return value / 1000.0; // mcg -> mg
    return value; // 'units' or mismatched: return as-is
  }

  ({double cPerMl, double vialVolume}) _computeForUnits({
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
          width: 0.75,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.primary,
          width: 2.0,
        ),
      ),
    );
  }

  Widget _rowLabelField(BuildContext context, {required String label, required Widget field}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: field),
        ],
      ),
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
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Sraw = double.tryParse(_strengthCtrl.text) ?? 0;
    final Draw = double.tryParse(_doseCtrl.text) ?? 0;

    // If strength unit is mg-like and dose unit differs, convert dose into strength unit
    // Only mass conversions mcg/mg/g are supported; 'units' passes through
    double S = Sraw;
    double D = Draw;
    if (widget.unitLabel != 'units') {
      // Convert everything to mg base for computation
      final S_mg = _toBaseMass(Sraw, widget.unitLabel);
      final D_mg = _toBaseMass(Draw, _doseUnit);
      S = S_mg;
      D = D_mg;
    }

    final vialMax = double.tryParse(_vialSizeCtrl.text);

    final (minURaw, midURaw, highURaw) = _presetUnitsRaw();

    // Allowed IU range respecting vial volume max
    double totalIU = _syringe.totalUnits.toDouble();
    double iuMin = minURaw; // baseline lower-end comfort
    double iuMax = totalIU;
    if (vialMax != null && S > 0 && D > 0) {
      final uMaxAllowed = (100 * D * vialMax) / S; // U <= this
      iuMax = uMaxAllowed.clamp(0, totalIU).toDouble();
      if (iuMax < iuMin) iuMin = iuMax; // collapse range if tiny
    }

    final sliderMin = iuMin;
    final sliderMax = iuMax;
    _selectedUnits = _selectedUnits.clamp(sliderMin, sliderMax);

    // Current selection compute
    final current = _computeForUnits(S: S, D: D, U: _selectedUnits);
    final currentC = _round2(current.cPerMl);
    final currentV = _round2(current.vialVolume);
    final fitsVial = vialMax == null || currentV <= vialMax + 1e-9;

    // Evenly spaced presets across [iuMin, iuMax]
    double u1 = sliderMin;
    double u3 = sliderMax;
    double u2 = sliderMin + (sliderMax - sliderMin) / 2.0;

    final conc = _computeForUnits(S: S, D: D, U: u1);
    final std = _computeForUnits(S: S, D: D, U: u2);
    final dil = _computeForUnits(S: S, D: D, U: u3);

    double _fitU(double U) => U;

    String formulaText(double U, double c, double v) =>
        'Units = (Dose / (Strength / Solvent)) × (Syringe Units / Syringe Capacity).\n' // reference text
        'Selected: ${_round2(U)} IU on ${_syringe.label}. Concentration = ${_round2(c)} ${widget.unitLabel}/mL. Vial volume = ${_round2(v)} mL';

    return AlertDialog(
      title: const Text('Reconstitution Calculator'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rowLabelField(
              context,
              label: 'Vial Quantity',
              field: Row(
                children: [
                  _pillBtn(context, '−', () {
                    final v = double.tryParse(_strengthCtrl.text) ?? 0;
                    final nv = (v - 1).clamp(0, 10000);
                    setState(() => _strengthCtrl.text = nv.toStringAsFixed(0));
                  }),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Field36(
                      child: TextField(
                        controller: _strengthCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _fieldDecoration(context, hint: '${widget.unitLabel}'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _pillBtn(context, '+', () {
                    final v = double.tryParse(_strengthCtrl.text) ?? 0;
                    final nv = (v + 1).clamp(0, 10000);
                    setState(() => _strengthCtrl.text = nv.toStringAsFixed(0));
                  }),
                ],
              ),
            ),
            _rowLabelField(
              context,
              label: 'Desired Dose',
              field: Row(
                children: [
                  Expanded(
                    child: Field36(
                      child: TextField(
                        controller: _doseCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _fieldDecoration(context),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 96,
                    child: Field36(
                      child: DropdownButtonFormField<String>(
                        value: _doseUnit,
                        items: [
                          if (widget.unitLabel == 'units')
                            const DropdownMenuItem(
                              value: 'units',
                              child: Text('units'),
                            ),
                          if (widget.unitLabel != 'units') ...const [
                            DropdownMenuItem(value: 'mcg', child: Text('mcg')),
                            DropdownMenuItem(value: 'mg', child: Text('mg')),
                            DropdownMenuItem(value: 'g', child: Text('g')),
                          ],
                        ],
                        onChanged: (v) => setState(() => _doseUnit = v!),
                        decoration: _fieldDecoration(context),
                      ),
                    ),
                  ),
                ],
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
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.label} • ${s.totalUnits} IU'),
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
            ),
            _rowLabelField(
              context,
              label: 'Max Vial (mL)',
              field: Field36(
                child: TextField(
                  controller: _vialSizeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration(context, hint: 'Optional'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Presets', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PresetChip(
                  label: 'Concentrated',
                  selected: (_selectedUnits - u1).abs() < 0.01,
                  onTap: () => setState(() => _selectedUnits = u1),
                  subtitle:
                      '${_round2(conc.cPerMl)} ${widget.unitLabel}/mL • ${_round2(conc.vialVolume)} mL • ${_round2(u1)} IU\nLow volume; less injection volume',
                ),
                _PresetChip(
                  label: 'Standard',
                  selected: (_selectedUnits - u2).abs() < 0.01,
                  onTap: () => setState(() => _selectedUnits = u2),
                  subtitle:
                      '${_round2(std.cPerMl)} ${widget.unitLabel}/mL • ${_round2(std.vialVolume)} mL • ${_round2(u2)} IU\nBalanced midpoint',
                ),
                _PresetChip(
                  label: 'Diluted',
                  selected: (_selectedUnits - u3).abs() < 0.01,
                  onTap: () => setState(() => _selectedUnits = u3),
                  subtitle:
                      '${_round2(dil.cPerMl)} ${widget.unitLabel}/mL • ${_round2(dil.vialVolume)} mL • ${_round2(u3)} IU\nHighest volume within limit',
                ),
                if (sliderMax <= 0 || sliderMax.isNaN)
                  _PresetChip(
                    label: 'No valid options',
                    selected: false,
                    onTap: () {},
                    subtitle: 'Check strength, dose, or syringe size',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Adjust fill (${_syringe.totalUnits} IU max)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: _selectedUnits,
              min: sliderMin,
              max: sliderMax,
              divisions: (_syringe.totalUnits - sliderMin.toInt()).clamp(
                1,
                100,
              ),
              label: '${_round2(_selectedUnits)} IU',
              onChanged: (v) => setState(() => _selectedUnits = v),
            ),
            // Visual syringe fill indicator
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  // Background syringe outline (white)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Fill indicator (thicker white line)
                  FractionallySizedBox(
                    widthFactor: (_selectedUnits / sliderMax).clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Summary
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
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
            if (!fitsVial)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Warning: Computed solvent volume (${currentV.toStringAsFixed(2)} mL) exceeds vial size. Try a more concentrated preset (lower IU).',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<ReconstitutionResult>(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (S > 0 && D > 0 && fitsVial)
              ? () {
                  final result = ReconstitutionResult(
                    perMlConcentration: currentC,
                    solventVolumeMl: currentV,
                    recommendedUnits: _round2(_selectedUnits),
                    syringeSizeMl: _syringe.ml,
                  );
                  Navigator.of(context).pop(result);
                }
              : null,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.subtitle,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? theme.colorScheme.onPrimary : null,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                  : null,
            ),
          ),
        ],
      ),
      showCheckmark: false,
      selectedColor: theme.colorScheme.primary,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
