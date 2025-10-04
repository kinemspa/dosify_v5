import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'providers.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_widget.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';

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
  // Floating summary like Tablet/Capsule
  final GlobalKey _summaryKey = GlobalKey();
  double _summaryHeight = 0;
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
  ReconstitutionResult?
  _reconResult; // Track current reconstitution calculation

  // Inline calculator state (Multi only)
  CalcMode _calcMode = CalcMode.known;

  final _stock = TextEditingController(text: '0');
  StockUnit _stockUnit = StockUnit.preFilledSyringes;

  DateTime? _expiry;
  final _batch = TextEditingController();
  final _location = TextEditingController();
  bool _refrigerate = false;
  final _storageNotes = TextEditingController();
  bool _keepFrozen = false;
  bool _lightSensitive = false;

  void _updateSummaryHeight() {
    final ctx = _summaryKey.currentContext;
    if (ctx != null) {
      final rb = ctx.findRenderObject();
      if (rb is RenderBox) {
        final h = rb.size.height;
        if (h != _summaryHeight && h > 0) setState(() => _summaryHeight = h);
      }
    }
  }

  SummaryHeaderCard _floatingSummaryCard() {
    final name = _name.text.trim();
    final manufacturer = _manufacturer.text.trim();
    final strengthVal = double.tryParse(_strength.text.trim());
    final stockVal = double.tryParse(_stock.text.trim());
    final unitLabel = _baseUnit(_strengthUnit);
    final headerTitle = switch (widget.kind) {
      InjectionKind.pfs => name.isEmpty ? 'Pre‑Filled Syringes' : name,
      InjectionKind.single => name.isEmpty ? 'Single Dose Vials' : name,
      InjectionKind.multi => name.isEmpty ? 'Multi Dose Vials' : name,
    };
    final stockUnitLabel = switch (widget.kind) {
      InjectionKind.pfs => 'pre filled syringes',
      InjectionKind.single => 'single dose vials',
      InjectionKind.multi => 'multi dose vials',
    };

    // Build additional notes including reconstitution info
    String? additionalNotes;
    if (widget.kind == InjectionKind.multi &&
        _reconResult != null &&
        _calcMode == CalcMode.reconstitute) {
      final r = _reconResult!;
      final diluentText = r.diluentName?.isNotEmpty == true
          ? r.diluentName
          : 'diluent';
      final syringeSize = r.syringeSizeMl.toStringAsFixed(1);
      final volume = r.solventVolumeMl.toStringAsFixed(2);
      final units = r.recommendedUnits.toStringAsFixed(0);
      additionalNotes =
          'Reconstitute with $volume mL $diluentText for $units IU on a $syringeSize mL syringe';
    }

    // Determine perUnitLabel based on injection type
    final perUnitLabel = switch (widget.kind) {
      InjectionKind.pfs => 'Syringe',
      InjectionKind.single => 'Vial',
      InjectionKind.multi => 'Vial',
    };

    final card = SummaryHeaderCard(
      key: _summaryKey,
      title: headerTitle,
      manufacturer: manufacturer.isEmpty ? null : manufacturer,
      strengthValue: strengthVal,
      strengthUnitLabel: _isPerMl ? '$unitLabel/mL' : unitLabel,
      perMlValue: _isPerMl ? double.tryParse(_perMl.text) : null,
      stockCurrent: stockVal ?? 0,
      stockInitial: widget.initial?.initialStockValue ?? stockVal ?? 0,
      stockUnitLabel: stockUnitLabel,
      expiryDate: _expiry,
      showRefrigerate: _refrigerate,
      showFrozen: _keepFrozen,
      showDark: _lightSensitive,
      lowStockEnabled: false,
      includeNameInStrengthLine: false,
      perTabletLabel: false,
      perUnitLabel: perUnitLabel,
      formLabelPlural: stockUnitLabel,
      additionalInfo: additionalNotes,
      // Add syringe gauge for reconstitution
      reconTotalIU: _reconResult != null
          ? (_reconResult!.syringeSizeMl * 100)
          : null,
      reconFillIU: _reconResult?.recommendedUnits,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSummaryHeight());
    return card;
  }

  @override
  void initState() {
    super.initState();
    // Add listeners to update summary dynamically
    _name.addListener(() => setState(() {}));
    _manufacturer.addListener(() => setState(() {}));

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
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      hintText: hint,
      // Keep height stable when error by suppressing the default error line
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
          width: kOutlineWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: kFocusedOutlineWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
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
        borderSide: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
          width: 0.75,
        ),
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
    double minU = (total * 0.05).ceil().toDouble();
    if (minU < 1.0) minU = 1.0;
    if (minU > total) minU = total;
    final double midU = _round2(total * 0.33);
    final double highU = _round2(total * 0.80);
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: _summaryHeight + 10),
                  SectionFormCard(
                    title: 'General',
                    neutral: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          bottom: 6,
                        ),
                        child: Text(
                          'Provide general details for this medication.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Name *',
                        field: Field36(
                          child: TextFormField(
                            controller: _name,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: _dec(
                              context,
                              'Name *',
                              'eg. AcmeTab-500',
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
                          'Enter the medication name',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
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
                      Padding(
                        padding: const EdgeInsets.only(
                          left: kLabelColWidth + 8,
                          top: 2,
                          bottom: 6,
                        ),
                        child: Text(
                          'Enter the brand or company name',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
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
                      Padding(
                        padding: const EdgeInsets.only(
                          left: kLabelColWidth + 8,
                          top: 2,
                          bottom: 6,
                        ),
                        child: Text(
                          'Optional short description',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
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
                      Padding(
                        padding: const EdgeInsets.only(
                          left: kLabelColWidth + 8,
                          top: 2,
                          bottom: 6,
                        ),
                        child: Text(
                          'Optional notes',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SectionFormCard(
                    title: 'Strength',
                    neutral: true,
                    children: [
                      LabelFieldRow(
                        label: 'Strength *',
                        field: StepperRow36(
                          controller: _strength,
                          onDec: () {
                            final v = int.tryParse(_strength.text) ?? 0;
                            _strength.text = (v - 1)
                                .clamp(0, 1000000)
                                .toString();
                            setState(() {});
                          },
                          onInc: () {
                            final v = int.tryParse(_strength.text) ?? 0;
                            _strength.text = (v + 1)
                                .clamp(0, 1000000)
                                .toString();
                            setState(() {});
                          },
                          decoration: _dec(context, 'Strength *', '0'),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Unit *',
                        field: SmallDropdown36<Unit>(
                          value: _strengthUnit,
                          width: kSmallControlWidth,
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
                          field: StepperRow36(
                            controller: _perMl,
                            onDec: () {
                              final v =
                                  double.tryParse(_perMl.text.trim()) ?? 0;
                              _perMl.text = (v - 1)
                                  .clamp(0, 1000000)
                                  .toStringAsFixed(0);
                              setState(() {});
                            },
                            onInc: () {
                              final v =
                                  double.tryParse(_perMl.text.trim()) ?? 0;
                              _perMl.text = (v + 1)
                                  .clamp(0, 1000000)
                                  .toStringAsFixed(0);
                              setState(() {});
                            },
                            decoration: _dec(context, 'Per mL', '0'),
                          ),
                        ),
                      if (_isPerMl)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: kLabelColWidth + 8,
                            top: 2,
                            bottom: 6,
                          ),
                          child: Text(
                            'Enter the volume per mL',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.75),
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
                          'Specify the amount per dose and its unit of measurement.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      if (widget.kind == InjectionKind.multi)
                        LabelFieldRow(
                          label: 'Volume Entry',
                          field: Wrap(
                            spacing: 8,
                            children: [
                              PrimaryChoiceChip(
                                label: Text('Enter volume'),
                                selected: _calcMode == CalcMode.known,
                                onSelected: (_) =>
                                    setState(() => _calcMode = CalcMode.known),
                              ),
                              PrimaryChoiceChip(
                                label: Text('Reconstitute'),
                                selected: _calcMode == CalcMode.reconstitute,
                                onSelected: (_) => setState(
                                  () => _calcMode = CalcMode.reconstitute,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.kind == InjectionKind.multi &&
                          _calcMode == CalcMode.known)
                        LabelFieldRow(
                          label: 'Vial volume (mL)',
                          field: StepperRow36(
                            controller: _vialVolume,
                            onDec: () {
                              final v =
                                  int.tryParse(_vialVolume.text.trim()) ?? 0;
                              setState(
                                () => _vialVolume.text = (v - 1)
                                    .clamp(0, 1000000)
                                    .toString(),
                              );
                            },
                            onInc: () {
                              final v =
                                  int.tryParse(_vialVolume.text.trim()) ?? 0;
                              setState(
                                () => _vialVolume.text = (v + 1)
                                    .clamp(0, 1000000)
                                    .toString(),
                              );
                            },
                            decoration: _dec(context, 'Vial volume (mL)', '0'),
                          ),
                        ),
                      if (widget.kind == InjectionKind.multi &&
                          _calcMode == CalcMode.reconstitute)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 0,
                            right: 0,
                            top: 12,
                            bottom: 6,
                          ),
                          child: ReconstitutionCalculatorWidget(
                            initialStrengthValue:
                                double.tryParse(_strength.text.trim()) ?? 0,
                            unitLabel: _baseUnit(_strengthUnit),
                            showSummary: false,
                            showApplyButton: true,
                            onApply: (result) {
                              setState(() {
                                _perMl.text = fmt2(result.perMlConcentration);
                                _vialVolume.text = fmt2(result.solventVolumeMl);
                                _reconResult =
                                    result; // Store result for summary
                                _calcMode =
                                    CalcMode.known; // collapse after apply
                              });
                            },
                            onCalculate: (result, isValid) {
                              // Update summary card with live reconstitution result
                              setState(() {
                                _reconResult = isValid ? result : null;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionFormCard(
                    title: 'Inventory',
                    neutral: true,
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
                      Padding(
                        padding: const EdgeInsets.only(
                          left: kLabelColWidth + 8,
                          top: 2,
                          bottom: 6,
                        ),
                        child: Text(
                          'Enter the amount currently in stock',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
                              ),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Quantity unit',
                        field: SmallDropdown36<StockUnit>(
                          value: _stockUnit,
                          width: kSmallControlWidth,
                          items: [
                            if (widget.kind == InjectionKind.pfs)
                              const DropdownMenuItem(
                                value: StockUnit.preFilledSyringes,
                                child: Center(child: Text('syringes')),
                              ),
                            if (widget.kind == InjectionKind.single)
                              const DropdownMenuItem(
                                value: StockUnit.singleDoseVials,
                                child: Center(child: Text('single dose vials')),
                              ),
                            if (widget.kind == InjectionKind.multi)
                              const DropdownMenuItem(
                                value: StockUnit.multiDoseVials,
                                child: Center(child: Text('vials')),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _stockUnit = v ?? _stockUnit),
                          decoration: _decDrop(context),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: kLabelColWidth + 8,
                        ),
                        child: Text(
                          'Get notified when stock is low',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                            if (picked != null)
                              setState(() => _expiry = picked);
                          },
                          width: kSmallControlWidth,
                          selected: _expiry != null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: kLabelColWidth + 8,
                          top: 2,
                          bottom: 6,
                        ),
                        child: Text(
                          'Enter the expiry date',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionFormCard(
                    title: 'Storage',
                    neutral: true,
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
                              ),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Keep refrigerated',
                        field: Opacity(
                          opacity: _keepFrozen ? 0.5 : 1.0,
                          child: Row(
                            children: [
                              Checkbox(
                                value: _refrigerate,
                                onChanged: _keepFrozen
                                    ? null
                                    : (v) => setState(
                                        () => _refrigerate = v ?? false,
                                      ),
                              ),
                              Text(
                                'Refrigerate',
                                style: _keepFrozen
                                    ? kMutedLabelStyle(context)
                                    : Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: kLabelColWidth + 8,
                          top: 2,
                          bottom: 4,
                        ),
                        child: Text(
                          'Enable if this medication must be kept refrigerated',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
                              ),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Keep frozen',
                        field: Row(
                          children: [
                            Checkbox(
                              value: _keepFrozen,
                              onChanged: (v) => setState(() {
                                _keepFrozen = v ?? false;
                                if (_keepFrozen) _refrigerate = false;
                              }),
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
                          top: 2,
                          bottom: 4,
                        ),
                        child: Text(
                          'Enable if this medication must be kept frozen',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.75),
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
          Positioned(
            left: 16,
            right: 16,
            top: 8,
            child: IgnorePointer(child: _floatingSummaryCard()),
          ),
        ],
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
