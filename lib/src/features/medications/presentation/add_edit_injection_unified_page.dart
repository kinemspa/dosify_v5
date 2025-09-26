import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'providers.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';

enum InjectionKind { pfs, single, multi }

enum CalcMode { known, reconstitute }

class AddEditInjectionUnifiedPage extends ConsumerStatefulWidget {
  const AddEditInjectionUnifiedPage({
    super.key,
    required this.kind,
    this.initial,
  });
  final InjectionKind kind;
  final Medication? initial;

  @override
  ConsumerState<AddEditInjectionUnifiedPage> createState() =>
      _AddEditInjectionUnifiedPageState();
}

class _AddEditInjectionUnifiedPageState
    extends ConsumerState<AddEditInjectionUnifiedPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _manufacturer = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();

  final _strength = TextEditingController(text: '0');
  Unit _strengthUnit = Unit.mg;
  final _perMl = TextEditingController();
  final _vialVolume = TextEditingController();
  double? _lastCalcDose;
  String? _lastCalcDoseUnit;
  SyringeSizeMl? _lastCalcSyringe;
  double? _lastCalcVialSize;

  // Inline calculator state (Multi only)
  CalcMode _calcMode = CalcMode.known;
  final _doseInline = TextEditingController();
  String? _doseUnitInline; // defaults set at build based on strength unit
  SyringeSizeMl _syringeInline = SyringeSizeMl.ml1;
  final _vialMaxInline = TextEditingController();
  double _selectedUnitsInline = 50;

  final _stock = TextEditingController(text: '0');
  StockUnit _stockUnit = StockUnit.preFilledSyringes;

  DateTime? _expiry;
  final _batch = TextEditingController();
  final _location = TextEditingController();
  bool _refrigerate = false;
  final _storageNotes = TextEditingController();
  bool _keepFrozen = false;
  bool _lightSensitive = false;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m != null) {
      _name.text = m.name;
      _manufacturer.text = m.manufacturer ?? '';
      _description.text = m.description ?? '';
      _notes.text = m.notes ?? '';
      _strength.text = m.strengthValue.toString();
      _strengthUnit = m.strengthUnit;
      _perMl.text = m.perMlValue?.toString() ?? '';
      _vialVolume.text = m.containerVolumeMl?.toString() ?? '';
      _stock.text = m.stockValue.toString();
      _stockUnit = m.stockUnit;
      _expiry = m.expiry;
      _batch.text = m.batchNumber ?? '';
      _location.text = m.storageLocation ?? '';
      _refrigerate = m.requiresRefrigeration;
      _storageNotes.text = m.storageInstructions ?? '';
      final notesLc = (m.storageInstructions ?? '').toLowerCase();
      _keepFrozen = notesLc.contains('frozen');
      _lightSensitive = notesLc.contains('light');
    } else {
      // Default units per kind
      switch (widget.kind) {
        case InjectionKind.pfs:
          _stockUnit = StockUnit.preFilledSyringes;
          break;
        case InjectionKind.single:
          _stockUnit = StockUnit.singleDoseVials;
          break;
        case InjectionKind.multi:
          _stockUnit = StockUnit.multiDoseVials;
          break;
      }
    }
  }

  InputDecoration _dec(BuildContext context, String label, String? hint) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      hintText: hint,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      constraints: const BoxConstraints(minHeight: 40),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      hintStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: 11,
        color: cs.onSurfaceVariant,
      ),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
    );
  }

  InputDecoration _decDrop(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
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
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
    );
  }

  String _baseUnit(Unit u) {
    if (u == Unit.mcg || u == Unit.mcgPerMl) return 'mcg';
    if (u == Unit.mg || u == Unit.mgPerMl) return 'mg';
    if (u == Unit.g || u == Unit.gPerMl) return 'g';
    return 'units';
  }

  bool get _isPerMl =>
      _strengthUnit == Unit.mcgPerMl ||
      _strengthUnit == Unit.mgPerMl ||
      _strengthUnit == Unit.gPerMl ||
      _strengthUnit == Unit.unitsPerMl;

  double? _strengthForCalculator() {
    final s = double.tryParse(_strength.text);
    if (s == null || s <= 0) return null;
    if (_isPerMl) {
      final v = double.tryParse(_vialVolume.text);
      if (v == null || v <= 0) return null;
      return s * v; // total quantity in vial
    }
    return s;
  }

  Future<void> _openReconstitutionDialog() async {
    final unitLabel = _baseUnit(_strengthUnit);
    final strengthForCalc = _strengthForCalculator() ?? 0;
    final result = await showDialog<ReconstitutionResult>(
      context: context,
      builder: (ctx) => ReconstitutionCalculatorDialog(
        initialStrengthValue: strengthForCalc,
        unitLabel: unitLabel,
        initialDoseValue: _lastCalcDose,
        initialDoseUnit: _lastCalcDoseUnit,
        initialSyringeSize: _lastCalcSyringe,
        initialVialSize: _lastCalcVialSize ?? double.tryParse(_vialVolume.text),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _perMl.text = fmt2(result.perMlConcentration);
        _vialVolume.text = fmt2(result.solventVolumeMl);
        _lastCalcDose = _lastCalcDose ?? double.tryParse(_strength.text);
        _lastCalcDoseUnit = unitLabel;
        _lastCalcSyringe = _lastCalcSyringe ?? SyringeSizeMl.ml1;
        _lastCalcVialSize = result.solventVolumeMl;
      });
    }
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
    final c = (100 * D) / (U <= 0 ? 0.01 : U);
    final v = S / (c <= 0 ? 0.000001 : c);
    return (cPerMl: c, vialVolume: v);
  }

  (double, double, double) _presetUnitsRaw(SyringeSizeMl syringe) {
    final total = syringe.totalUnits.toDouble();
    final minU = (total * 0.05).ceil().toDouble().clamp(1, total);
    final midU = _round2(total * 0.33);
    final highU = _round2(total * 0.80);
    return (minU, midU, highU);
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.kind) {
      InjectionKind.pfs => 'Add Pre filled syringe',
      InjectionKind.single => 'Add Single dose vial',
      InjectionKind.multi => 'Add Multi dose vial',
    };

    final saveEnabled = (() {
      final nameOk = _name.text.trim().isNotEmpty;
      final a = double.tryParse(_strength.text.trim());
      final amtOk = a != null && a > 0;
      final s = double.tryParse(_stock.text.trim());
      final stockOk = s != null && s >= 0;
      return nameOk && amtOk && stockOk;
    })();

    return Scaffold(
      appBar: GradientAppBar(title: title, forceBackButton: true),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 140,
        child: FilledButton.icon(
          onPressed: saveEnabled ? _submit : null,
          icon: const Icon(Icons.save),
          label: Text(widget.initial == null ? 'Save' : 'Update'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionFormCard(
                title: 'General',
                children: [
                  LabelFieldRow(
                    label: 'Name *',
                    field: Field36(
                      child: TextFormField(
                        controller: _name,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: _dec(context, 'Name *', 'eg. AcmeTab-500'),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Manufacturer',
                    field: Field36(
                      child: TextFormField(
                        controller: _manufacturer,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: _dec(
                          context,
                          'Manufacturer',
                          'eg. Contoso Pharma',
                        ),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Description',
                    field: Field36(
                      child: TextFormField(
                        controller: _description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: _dec(
                          context,
                          'Description',
                          'eg. Pain relief',
                        ),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Notes',
                    field: Field36(
                      child: TextFormField(
                        controller: _notes,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: _dec(
                          context,
                          'Notes',
                          'eg. Take with food',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SectionFormCard(
                title: 'Strength',
                children: [
                  LabelFieldRow(
                    label: 'Strength *',
                    field: StepperRow36(
                      controller: _strength,
                      onDec: () {
                        final v = int.tryParse(_strength.text) ?? 0;
                        _strength.text = (v - 1).clamp(0, 1000000).toString();
                        setState(() {});
                      },
                      onInc: () {
                        final v = int.tryParse(_strength.text) ?? 0;
                        _strength.text = (v + 1).clamp(0, 1000000).toString();
                        setState(() {});
                      },
                      decoration: _dec(context, 'Strength *', '0'),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Unit *',
                    field: SmallDropdown36<Unit>(
                      value: _strengthUnit,
                      items: const [
                        DropdownMenuItem(
                          value: Unit.mcg,
                          child: Center(child: Text('mcg')),
                        ),
                        DropdownMenuItem(
                          value: Unit.mg,
                          child: Center(child: Text('mg')),
                        ),
                        DropdownMenuItem(
                          value: Unit.g,
                          child: Center(child: Text('g')),
                        ),
                        DropdownMenuItem(
                          value: Unit.units,
                          child: Center(child: Text('units')),
                        ),
                        DropdownMenuItem(
                          value: Unit.mcgPerMl,
                          child: Center(child: Text('mcg/mL')),
                        ),
                        DropdownMenuItem(
                          value: Unit.mgPerMl,
                          child: Center(child: Text('mg/mL')),
                        ),
                        DropdownMenuItem(
                          value: Unit.gPerMl,
                          child: Center(child: Text('g/mL')),
                        ),
                        DropdownMenuItem(
                          value: Unit.unitsPerMl,
                          child: Center(child: Text('units/mL')),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _strengthUnit = v ?? Unit.mg),
                      decoration: _decDrop(context),
                    ),
                  ),
                  if (_isPerMl)
                    LabelFieldRow(
                      label: 'Per mL',
                      field: SizedBox(
                        width: 160,
                        child: Field36(
                          child: TextFormField(
                            controller: _perMl,
                            style: Theme.of(context).textTheme.bodyMedium,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _dec(context, 'Per mL', '0.0'),
                          ),
                        ),
                      ),
                    ),
                  if (widget.kind == InjectionKind.multi)
                    LabelFieldRow(
                      label: 'Method',
                      field: SegmentedButton<CalcMode>(
                        segments: const [
                          ButtonSegment(
                            value: CalcMode.known,
                            label: Text('Enter volume'),
                          ),
                          ButtonSegment(
                            value: CalcMode.reconstitute,
                            label: Text('Reconstitute'),
                          ),
                        ],
                        selected: {_calcMode},
                        onSelectionChanged: (s) =>
                            setState(() => _calcMode = s.first),
                      ),
                    ),
                  if (widget.kind == InjectionKind.multi &&
                      _calcMode == CalcMode.known)
                    LabelFieldRow(
                      label: 'Vial volume (mL)',
                      field: SizedBox(
                        width: 160,
                        child: Field36(
                          child: TextFormField(
                            controller: _vialVolume,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: _dec(
                              context,
                              'Vial volume (mL)',
                              '0.0',
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.kind == InjectionKind.multi &&
                      _calcMode == CalcMode.reconstitute)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: kLabelColWidth + 8,
                        top: 6,
                        bottom: 6,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _doseInline,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: 'Desired dose',
                                        hintText: '0.00',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 160,
                                    child: DropdownButtonFormField<String>(
                                      value:
                                          _doseUnitInline ??
                                          _baseUnit(_strengthUnit),
                                      items: () {
                                        final base = _baseUnit(_strengthUnit);
                                        if (base == 'units') {
                                          return const [
                                            DropdownMenuItem(
                                              value: 'units',
                                              child: Text('units'),
                                            ),
                                          ];
                                        }
                                        return const [
                                          DropdownMenuItem(
                                            value: 'mcg',
                                            child: Text('mcg'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'mg',
                                            child: Text('mg'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'g',
                                            child: Text('g'),
                                          ),
                                        ];
                                      }(),
                                      onChanged: (v) =>
                                          setState(() => _doseUnitInline = v),
                                      decoration: const InputDecoration(
                                        labelText: 'Dose unit',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<SyringeSizeMl>(
                                      value: _syringeInline,
                                      items: SyringeSizeMl.values
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                '${s.label} • ${s.totalUnits} IU',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) {
                                        if (v == null) return;
                                        setState(() {
                                          _syringeInline = v;
                                          final total = _syringeInline
                                              .totalUnits
                                              .toDouble();
                                          _selectedUnitsInline =
                                              _selectedUnitsInline.clamp(
                                                (0.05 * total)
                                                    .ceil()
                                                    .toDouble(),
                                                total,
                                              );
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Syringe size',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 160,
                                    child: TextFormField(
                                      controller: _vialMaxInline,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: 'Max vial size (mL)',
                                        hintText: 'optional',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  final unitLabel = _baseUnit(_strengthUnit);
                                  final sTxt = _strength.text.trim();
                                  final dTxt = _doseInline.text.trim();
                                  final Sraw = double.tryParse(sTxt) ?? 0;
                                  final Draw = double.tryParse(dTxt) ?? 0;
                                  double S = Sraw, D = Draw;
                                  if (unitLabel != 'units') {
                                    S = _toBaseMass(Sraw, unitLabel);
                                    D = _toBaseMass(
                                      Draw,
                                      _doseUnitInline ?? unitLabel,
                                    );
                                  }
                                  // If strength is per mL, and known vial volume entered, use that; otherwise assume 1mL until user applies result
                                  final vKnown = double.tryParse(
                                    _vialMaxInline.text,
                                  );
                                  final (minURaw, midURaw, highURaw) =
                                      _presetUnitsRaw(_syringeInline);
                                  double totalIU = _syringeInline.totalUnits
                                      .toDouble();
                                  // Limit by max vial size if provided
                                  double iuMax = totalIU;
                                  if (vKnown != null && S > 0 && D > 0) {
                                    final uMaxAllowed = (100 * D * vKnown) / S;
                                    iuMax = uMaxAllowed.clamp(0, totalIU);
                                  }
                                  final double u1 = minURaw.clamp(0, iuMax);
                                  final double u2 = (minURaw + iuMax) / 2.0;
                                  final double u3 = iuMax;
                                  final conc = _compute(S: S, D: D, U: u1);
                                  final std = _compute(S: S, D: D, U: u2);
                                  final dil = _compute(S: S, D: D, U: u3);
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          ChoiceChip(
                                            label: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text('Concentrated'),
                                                Text(
                                                  '${fmt2(conc.cPerMl)} $unitLabel/mL • ${fmt2(conc.vialVolume)} mL • ${fmt2(u1)} IU',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                            selected:
                                                (_selectedUnitsInline - u1)
                                                    .abs() <
                                                0.01,
                                            onSelected: (_) => setState(
                                              () => _selectedUnitsInline = u1,
                                            ),
                                          ),
                                          ChoiceChip(
                                            label: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text('Standard'),
                                                Text(
                                                  '${fmt2(std.cPerMl)} $unitLabel/mL • ${fmt2(std.vialVolume)} mL • ${fmt2(u2)} IU',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                            selected:
                                                (_selectedUnitsInline - u2)
                                                    .abs() <
                                                0.01,
                                            onSelected: (_) => setState(
                                              () => _selectedUnitsInline = u2,
                                            ),
                                          ),
                                          ChoiceChip(
                                            label: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text('Diluted'),
                                                Text(
                                                  '${fmt2(dil.cPerMl)} $unitLabel/mL • ${fmt2(dil.vialVolume)} mL • ${fmt2(u3)} IU',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                            selected:
                                                (_selectedUnitsInline - u3)
                                                    .abs() <
                                                0.01,
                                            onSelected: (_) => setState(
                                              () => _selectedUnitsInline = u3,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                        onPressed: (S > 0 && D > 0 && iuMax > 0)
                                            ? () {
                                                final cur = _compute(
                                                  S: S,
                                                  D: D,
                                                  U: _selectedUnitsInline,
                                                );
                                                setState(() {
                                                  _perMl.text = fmt2(
                                                    _round2(cur.cPerMl),
                                                  );
                                                  _vialVolume.text = fmt2(
                                                    _round2(cur.vialVolume),
                                                  );
                                                  _calcMode = CalcMode
                                                      .known; // collapse after apply
                                                });
                                              }
                                            : null,
                                        icon: const Icon(Icons.check),
                                        label: const Text('Apply to vial'),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: kLabelColWidth + 8),
                    child: Text(
                      'Specify the amount per dose and its unit of measurement.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SectionFormCard(
                title: 'Inventory',
                children: [
                  LabelFieldRow(
                    label: 'Stock quantity *',
                    field: StepperRow36(
                      controller: _stock,
                      onDec: () {
                        final v = int.tryParse(_stock.text) ?? 0;
                        _stock.text = (v - 1).clamp(0, 1000000).toString();
                        setState(() {});
                      },
                      onInc: () {
                        final v = int.tryParse(_stock.text) ?? 0;
                        _stock.text = (v + 1).clamp(0, 1000000).toString();
                        setState(() {});
                      },
                      decoration: _dec(context, 'Stock quantity *', '0'),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Quantity unit',
                    field: SmallDropdown36<StockUnit>(
                      value: _stockUnit,
                      items: [
                        DropdownMenuItem(
                          value: StockUnit.preFilledSyringes,
                          child: Center(child: Text('pre filled syringes')),
                        ),
                        DropdownMenuItem(
                          value: StockUnit.singleDoseVials,
                          child: Center(child: Text('single dose vials')),
                        ),
                        DropdownMenuItem(
                          value: StockUnit.multiDoseVials,
                          child: Center(child: Text('multi dose vials')),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _stockUnit = v ?? _stockUnit),
                      decoration: _decDrop(context),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: kLabelColWidth + 8),
                    child: Text(
                      'Get notified when stock is low',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LabelFieldRow(
                    label: 'Expiry date',
                    field: DateButton36(
                      label: _expiry == null
                          ? 'Select date'
                          : DateFormat.yMd().format(_expiry!),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 10),
                          initialDate: _expiry ?? now,
                        );
                        if (picked != null) setState(() => _expiry = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SectionFormCard(
                title: 'Storage',
                children: [
                  LabelFieldRow(
                    label: 'Batch No.',
                    field: Field36(
                      child: TextFormField(
                        controller: _batch,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: _dec(
                          context,
                          'Batch No.',
                          'Enter batch number',
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: kLabelColWidth + 8,
                      top: 2,
                      bottom: 6,
                    ),
                    child: Text(
                      'Enter the printed batch or lot number',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.75),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Location',
                    field: Field36(
                      child: TextFormField(
                        controller: _location,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: _dec(
                          context,
                          'Location',
                          'eg. Bathroom cabinet',
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: kLabelColWidth + 8,
                      top: 2,
                      bottom: 6,
                    ),
                    child: Text(
                      'Where it’s stored (e.g., Bathroom cabinet)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.75),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Keep refrigerated',
                    field: Row(
                      children: [
                        Checkbox(
                          value: _refrigerate,
                          onChanged: (v) =>
                              setState(() => _refrigerate = v ?? false),
                        ),
                        Text(
                          'Refrigerate',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: kLabelColWidth + 8,
                      top: 0,
                      bottom: 6,
                    ),
                    child: Text(
                      'Enable if this medication must be kept refrigerated',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.75),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Keep frozen',
                    field: Row(
                      children: [
                        Checkbox(
                          value: _keepFrozen,
                          onChanged: (v) =>
                              setState(() => _keepFrozen = v ?? false),
                        ),
                        Text(
                          'Freeze',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: kLabelColWidth + 8,
                      top: 0,
                      bottom: 6,
                    ),
                    child: Text(
                      'Enable if this medication must be kept frozen',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.75),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Keep in dark',
                    field: Row(
                      children: [
                        Checkbox(
                          value: _lightSensitive,
                          onChanged: (v) =>
                              setState(() => _lightSensitive = v ?? false),
                        ),
                        Text(
                          'Dark storage',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: kLabelColWidth + 8,
                      top: 0,
                      bottom: 6,
                    ),
                    child: Text(
                      'Enable if this medication must be protected from light',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.75),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Storage instructions',
                    field: Field36(
                      child: TextFormField(
                        controller: _storageNotes,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: _dec(
                          context,
                          'Storage instructions',
                          'Enter storage instructions',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(medicationRepositoryProvider);
    final id =
        widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

    final stock = double.tryParse(_stock.text.trim()) ?? 0;
    final previous = widget.initial;
    final initialStock = previous == null
        ? stock
        : (stock > previous.stockValue
              ? stock
              : (previous.initialStockValue ?? previous.stockValue));

    final med = Medication(
      id: id,
      form: switch (widget.kind) {
        InjectionKind.pfs => MedicationForm.injectionPreFilledSyringe,
        InjectionKind.single => MedicationForm.injectionSingleDoseVial,
        InjectionKind.multi => MedicationForm.injectionMultiDoseVial,
      },
      name: _name.text.trim(),
      manufacturer: _manufacturer.text.trim().isEmpty
          ? null
          : _manufacturer.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      strengthValue: double.tryParse(_strength.text) ?? 0,
      strengthUnit: _strengthUnit,
      perMlValue: _perMl.text.trim().isEmpty
          ? null
          : double.tryParse(_perMl.text.trim()),
      stockValue: stock,
      stockUnit: _stockUnit,
      expiry: _expiry,
      batchNumber: _batch.text.trim().isEmpty ? null : _batch.text.trim(),
      containerVolumeMl: _vialVolume.text.trim().isEmpty
          ? null
          : double.tryParse(_vialVolume.text.trim()),
      storageLocation: _location.text.trim().isEmpty
          ? null
          : _location.text.trim(),
      requiresRefrigeration: _refrigerate,
      storageInstructions: (() {
        final parts = <String>[];
        final s = _storageNotes.text.trim();
        if (s.isNotEmpty) parts.add(s);
        if (_keepFrozen &&
            !parts.any((p) => p.toLowerCase().contains('frozen')))
          parts.add('Keep frozen');
        if (_lightSensitive &&
            !parts.any((p) => p.toLowerCase().contains('light')))
          parts.add('Protect from light');
        return parts.isEmpty ? null : parts.join('. ');
      })(),
      initialStockValue: initialStock,
    );

    await repo.upsert(med);
    if (!mounted) return;
    context.go('/medications');
  }
}
