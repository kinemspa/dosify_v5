import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/format.dart';
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
  late String _doseUnit; // 'mcg'|'mg'|'g'|'units'
  SyringeSizeMl _syringe = SyringeSizeMl.ml1;
  double _selectedUnits = 50;

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
                    );
                    context.pop(result);
                  }
                : null,
            child: const Text('Apply'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _doseCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Desired Dose',
                    helperText: 'Amount per dose',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                  decoration: const InputDecoration(labelText: 'Dose Unit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<SyringeSizeMl>(
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
          Text('Presets (IU)'),
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
          Text('Adjust fill (${_syringe.totalUnits} IU max)'),
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
                        );
                        context.pop(result);
                      }
                    : null,
                child: const Text('Apply to vial'),
              ),
            ],
          ),
        ),
      ),
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
        children: [
          Text(label),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
