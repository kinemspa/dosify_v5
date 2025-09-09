import 'dart:math';

import 'package:flutter/material.dart';

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
  });

  final double initialStrengthValue; // total quantity in the vial (S)
  final String unitLabel;

  @override
  State<ReconstitutionCalculatorDialog> createState() => _ReconstitutionCalculatorDialogState();
}

class _ReconstitutionCalculatorDialogState extends State<ReconstitutionCalculatorDialog> {
  late final TextEditingController _strengthCtrl;
  late final TextEditingController _doseCtrl;
  final TextEditingController _vialSizeCtrl = TextEditingController();

  SyringeSizeMl _syringe = SyringeSizeMl.ml1;

  // Slider-driving IU selection
  double _selectedUnits = 50; // default mid for 1mL syringe

  @override
  void initState() {
    super.initState();
    _strengthCtrl = TextEditingController(text: widget.initialStrengthValue.toStringAsFixed(2));
    _doseCtrl = TextEditingController(text: (widget.initialStrengthValue * 0.05).toStringAsFixed(2));
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
  ({double cPerMl, double vialVolume}) _computeForUnits({required double S, required double D, required double U}) {
    final c = (100 * D) / max(U, 0.01);
    final v = S / max(c, 0.000001);
    return (cPerMl: c, vialVolume: v);
  }

  (double, double, double) _presetUnits() {
    final total = _syringe.totalUnits.toDouble();
    final minU = max(5, (total * 0.05).ceil()).toDouble();
    final midU = _round2(total * 0.33);
    final highU = _round2(total * 0.80);
    return (minU, midU, highU);
  }

  @override
  Widget build(BuildContext context) {
    final S = double.tryParse(_strengthCtrl.text) ?? 0;
    final D = double.tryParse(_doseCtrl.text) ?? 0;
    final vialMax = double.tryParse(_vialSizeCtrl.text);

    final (minU, midU, highU) = _presetUnits();

    // Ensure slider bounds adapt to syringe
    final sliderMin = minU;
    final sliderMax = _syringe.totalUnits.toDouble();
    _selectedUnits = _selectedUnits.clamp(sliderMin, sliderMax);

    // Compute for the current slider selection
    final current = _computeForUnits(S: S, D: D, U: _selectedUnits);
    final currentC = _round2(current.cPerMl);
    final currentV = _round2(current.vialVolume);
    final fitsVial = vialMax == null || currentV <= vialMax + 1e-9;

    // Presets
    final conc = _computeForUnits(S: S, D: D, U: minU);
    final std = _computeForUnits(S: S, D: D, U: midU);
    final dil = _computeForUnits(S: S, D: D, U: highU);

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
            TextField(
              controller: _strengthCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Vial Quantity (${widget.unitLabel})',
                helperText: 'Total amount in the vial',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _doseCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Desired Dose (${widget.unitLabel})',
                helperText: 'Amount per dose',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SyringeSizeMl>(
              value: _syringe,
              items: SyringeSizeMl.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() {
                _syringe = v!;
                final total = _syringe.totalUnits.toDouble();
                _selectedUnits = max(_selectedUnits, max(5, (0.05 * total).ceil()).toDouble());
              }),
              decoration: const InputDecoration(labelText: 'Syringe Size'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _vialSizeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Vial Size (mL, optional)',
                helperText: 'Max volume of the vial (leave empty for none) ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text('Presets'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              _PresetChip(
                label: 'Concentrated',
                selected: (_selectedUnits - minU).abs() < 0.01,
                onTap: () => setState(() => _selectedUnits = minU),
                subtitle:
                    '${_round2(conc.cPerMl)} ${widget.unitLabel}/mL • ${_round2(conc.vialVolume)} mL',
              ),
              _PresetChip(
                label: 'Standard',
                selected: (_selectedUnits - midU).abs() < 0.01,
                onTap: () => setState(() => _selectedUnits = midU),
                subtitle:
                    '${_round2(std.cPerMl)} ${widget.unitLabel}/mL • ${_round2(std.vialVolume)} mL',
              ),
              _PresetChip(
                label: 'Diluted',
                selected: (_selectedUnits - highU).abs() < 0.01,
                onTap: () => setState(() => _selectedUnits = highU),
                subtitle:
                    '${_round2(dil.cPerMl)} ${widget.unitLabel}/mL • ${_round2(dil.vialVolume)} mL',
              ),
            ]),
            const SizedBox(height: 16),
            Text('Adjust fill (${_syringe.totalUnits} IU max)'),
            Slider(
              value: _selectedUnits,
              min: sliderMin,
              max: sliderMax,
              divisions: (_syringe.totalUnits - sliderMin.toInt()).clamp(1, 100),
              label: '${_round2(_selectedUnits)} IU',
              onChanged: (v) => setState(() => _selectedUnits = v),
            ),
            // Visual syringe bar
            LinearProgressIndicator(
              value: (_selectedUnits / sliderMax).clamp(0, 1),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              formulaText(_selectedUnits, currentC, currentV),
              style: Theme.of(context).textTheme.bodySmall,
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
    return ChoiceChip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [Text(label), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

