// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_widget.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';

enum InjectionKind { pfs, single, multi }

class AddEditInjectionUnifiedPage extends ConsumerStatefulWidget {
  const AddEditInjectionUnifiedPage({required this.kind, super.key, this.initial});
  final InjectionKind kind;
  final Medication? initial;

  @override
  ConsumerState<AddEditInjectionUnifiedPage> createState() => _AddEditInjectionUnifiedPageState();
}

class _AddEditInjectionUnifiedPageState extends ConsumerState<AddEditInjectionUnifiedPage> {
  // Floating summary like Tablet/Capsule
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _vialVolumeKey = GlobalKey(); // For scrolling to vial volume
  double _summaryHeight = 0;
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _manufacturer = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();

  final _strength = TextEditingController(text: '0');
  Unit _strengthUnit = Unit.mg;
  final _perMl = TextEditingController();
  final _vialVolume = TextEditingController(text: '0');
  double? _lastCalcDose;
  String? _lastCalcDoseUnit;
  SyringeSizeMl? _lastCalcSyringe;
  double? _lastCalcVialSize;
  ReconstitutionResult? _reconResult; // Track current reconstitution calculation
  bool _showCalculator = false; // Toggle inline calculator visibility

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

    // Determine perUnitLabel based on injection type
    final perUnitLabel = switch (widget.kind) {
      InjectionKind.pfs => 'Syringe',
      InjectionKind.single => 'Vial',
      InjectionKind.multi => 'Vial',
    };

    // For MDV, build custom additionalInfo with 3-line format:
    // Line 1: "10mg per Vial"
    // Line 2: "in 4.5mL of ReconName, X/mL"
    // Line 3: "X unreconstituted vials remain in stock"
    String? mdvAdditionalInfo;
    if (widget.kind == InjectionKind.multi && strengthVal != null && strengthVal > 0) {
      final vialVol = double.tryParse(_vialVolume.text.trim());
      final concentration = double.tryParse(_perMl.text.trim());
      final stockCount = stockVal?.toInt() ?? 0;

      // Line 1: Strength per vial
      final line1 =
          '${strengthVal.toStringAsFixed(strengthVal == strengthVal.roundToDouble() ? 0 : 1)}$unitLabel per Vial';

      // Line 2: Reconstitution details (if available)
      String? line2;
      if (vialVol != null && vialVol > 0 && concentration != null && concentration > 0) {
        final diluentName = _reconResult?.diluentName ?? 'diluent';
        line2 =
            'in ${vialVol.toStringAsFixed(vialVol == vialVol.roundToDouble() ? 0 : 1)}mL of $diluentName, ${concentration.toStringAsFixed(concentration == concentration.roundToDouble() ? 0 : 1)}$unitLabel/mL';
      } else if (vialVol != null && vialVol > 0) {
        line2 =
            'Vial Volume: ${vialVol.toStringAsFixed(vialVol == vialVol.roundToDouble() ? 0 : 1)} mL';
      }

      // Line 3: Stock count
      final line3 =
          '$stockCount unreconstituted ${stockCount == 1 ? "vial" : "vials"} remain in stock';

      // Combine lines with line breaks
      mdvAdditionalInfo = line1;
      if (line2 != null) mdvAdditionalInfo += '\n$line2';
      mdvAdditionalInfo += '\n$line3';
    }

    final card = SummaryHeaderCard(
      key: _summaryKey,
      title: headerTitle,
      manufacturer: manufacturer.isEmpty ? null : manufacturer,
      strengthValue: strengthVal,
      strengthUnitLabel: _isPerMl ? '$unitLabel/mL' : unitLabel,
      stockCurrent: stockVal ?? 0,
      stockInitial: widget.initial?.initialStockValue ?? stockVal ?? 0,
      stockUnitLabel: 'unreconstituted $stockUnitLabel',
      expiryDate: _expiry,
      showRefrigerate: _refrigerate,
      showFrozen: _keepFrozen,
      showDark: _lightSensitive,
      perTabletLabel: false,
      perUnitLabel: perUnitLabel,
      formLabelPlural: stockUnitLabel,
      additionalInfo: mdvAdditionalInfo,
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
        case InjectionKind.single:
          _stockUnit = StockUnit.singleDoseVials;
        case InjectionKind.multi:
          _stockUnit = StockUnit.multiDoseVials;
      }
    }
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
                        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
                        child: Text(
                          'Provide general details for this medication.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Name *',
                        field: Field36(
                          child: TextFormField(
                            controller: _name,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: buildFieldDecoration(context, hint: 'eg. AcmeTab-500'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, top: 2, bottom: 6),
                        child: Text(
                          'Enter the medication name',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
                          ),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Manufacturer',
                        field: Field36(
                          child: TextFormField(
                            controller: _manufacturer,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: buildFieldDecoration(context, hint: 'eg. Contoso Pharma'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, top: 2, bottom: 6),
                        child: Text(
                          'Enter the brand or company name',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
                          ),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Description',
                        field: Field36(
                          child: TextFormField(
                            controller: _description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: buildFieldDecoration(context, hint: 'eg. Pain relief'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, top: 2, bottom: 6),
                        child: Text(
                          'Optional short description',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
                          ),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Notes',
                        field: TextFormField(
                          controller: _notes,
                          keyboardType: TextInputType.multiline,
                          minLines: 2,
                          maxLines: null,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: buildFieldDecoration(context, hint: 'eg. Take with food'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, top: 2, bottom: 6),
                        child: Text(
                          'Optional notes',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
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
                            _strength.text = (v - 1).clamp(0, 1000000).toString();
                            setState(() {});
                          },
                          onInc: () {
                            final v = int.tryParse(_strength.text) ?? 0;
                            _strength.text = (v + 1).clamp(0, 1000000).toString();
                            setState(() {});
                          },
                          decoration: buildCompactFieldDecoration(hint: '0'),
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
                          onChanged: (v) => setState(() => _strengthUnit = v ?? Unit.mg),
                          decoration: buildCompactFieldDecoration(),
                        ),
                      ),
                      if (_isPerMl)
                        LabelFieldRow(
                          label: 'Per mL',
                          field: StepperRow36(
                            controller: _perMl,
                            onDec: () {
                              final v = double.tryParse(_perMl.text.trim()) ?? 0;
                              _perMl.text = (v - 1).clamp(0, 1000000).toStringAsFixed(0);
                              setState(() {});
                            },
                            onInc: () {
                              final v = double.tryParse(_perMl.text.trim()) ?? 0;
                              _perMl.text = (v + 1).clamp(0, 1000000).toStringAsFixed(0);
                              setState(() {});
                            },
                            decoration: buildCompactFieldDecoration(hint: '0'),
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.75),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, top: 2, bottom: 6),
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

                  // Volume & Reconstitution Card (Multi dose vials only)
                  if (widget.kind == InjectionKind.multi)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionFormCard(
                          title: 'Active Vial',
                          neutral: true,
                          children: [
                            // Helper text under heading, full width (only show if user tried to open without strength)
                            if (_showCalculator && _strengthForCalculator() == null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                                child: Text(
                                  'Please enter the vial strength above before using the reconstitution calculator.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else if (!_showCalculator)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                                child: Text(
                                  'Enter the volume of fluid in the vial, or use the calculator to determine the correct reconstitution amount.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            // Reconstitution Calculator Button
                            Center(
                              child: _showCalculator
                                  ? FilledButton.icon(
                                      onPressed: () {
                                        setState(() => _showCalculator = false);
                                      },
                                      icon: const Icon(Icons.close),
                                      label: Text(
                                        _reconResult == null
                                            ? 'Reconstitution Calculator'
                                            : 'Edit Reconstitution',
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: () {
                                        if (_strengthForCalculator() == null) {
                                          // Show error in helper text when clicked without strength
                                          setState(() => _showCalculator = true);
                                        } else {
                                          setState(() => _showCalculator = true);
                                        }
                                      },
                                      icon: const Icon(Icons.calculate),
                                      label: Text(
                                        _reconResult == null
                                            ? 'Reconstitution Calculator'
                                            : 'Edit Reconstitution',
                                      ),
                                    ),
                            ),
                            // Show saved reconstitution info if exists and calculator hidden
                            if (_reconResult != null && !_showCalculator) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  children: [
                                    WhiteSyringeGauge(
                                      totalIU: _reconResult!.syringeSizeMl * 100,
                                      fillIU: _reconResult!.recommendedUnits,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 16),
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
                                            text:
                                                '${_strength.text.trim()} ${_baseUnit(_strengthUnit)}',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                          if (_name.text.trim().isNotEmpty) ...[
                                            const TextSpan(text: ' '),
                                            TextSpan(
                                              text: _name.text.trim(),
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                          const TextSpan(text: ' with '),
                                          TextSpan(
                                            text:
                                                '${_reconResult!.solventVolumeMl.toStringAsFixed(_reconResult!.solventVolumeMl == _reconResult!.solventVolumeMl.roundToDouble() ? 0 : 1)} mL',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                          if (_reconResult!.diluentName != null &&
                                              _reconResult!.diluentName!.isNotEmpty)
                                            TextSpan(text: ' ${_reconResult!.diluentName}'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Split into 3 lines like calculator display
                                    RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Draw '),
                                          TextSpan(
                                            text:
                                                '${_reconResult!.recommendedUnits.toStringAsFixed(1)} IU',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(text: ' ('),
                                          TextSpan(
                                            text:
                                                '${(_reconResult!.recommendedUnits / 100 * _reconResult!.syringeSizeMl).toStringAsFixed(2)} mL',
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
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        children: [
                                          const TextSpan(text: 'into a '),
                                          TextSpan(
                                            text:
                                                '${_reconResult!.syringeSizeMl.toStringAsFixed(1)} mL',
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
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        children: [
                                          const TextSpan(text: 'for your '),
                                          TextSpan(
                                            text:
                                                '${_reconResult!.perMlConcentration.toStringAsFixed(_reconResult!.perMlConcentration == _reconResult!.perMlConcentration.roundToDouble() ? 0 : 1)} ${_baseUnit(_strengthUnit)}',
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
                            ],
                            // Inline calculator when shown
                            if (_showCalculator)
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLowest.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(top: 8),
                                child: Column(
                                  children: [
                                    ReconstitutionCalculatorWidget(
                                      initialStrengthValue:
                                          double.tryParse(_strength.text.trim()) ?? 0,
                                      unitLabel: _baseUnit(_strengthUnit),
                                      medicationName: _name.text.trim().isNotEmpty
                                          ? _name.text.trim()
                                          : null,
                                      initialDoseValue: _lastCalcDose,
                                      initialDoseUnit: _lastCalcDoseUnit,
                                      initialSyringeSize: _lastCalcSyringe,
                                      initialVialSize: _lastCalcVialSize,
                                      showSummary: false,
                                      showApplyButton: true,
                                      onApply: (result) {
                                        setState(() {
                                          _perMl.text = fmt2(result.perMlConcentration);
                                          _vialVolume.text = fmt2(result.solventVolumeMl);
                                          _reconResult = result;
                                          _showCalculator = false; // Hide calculator after save
                                        });
                                        // Scroll to vial volume field after save
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (_vialVolumeKey.currentContext != null) {
                                            Scrollable.ensureVisible(
                                              _vialVolumeKey.currentContext!,
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                        });
                                      },
                                      onCalculate: (result, isValid) {
                                        // Preview only, don't save yet
                                      },
                                    ),
                                    if (_reconResult != null) ...[
                                      const SizedBox(height: 12),
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _reconResult = null;
                                              _perMl.text = '';
                                            });
                                          },
                                          icon: const Icon(Icons.clear),
                                          label: const Text('Clear Reconstitution'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            // Add spacing after calculator/saved display
                            if (!_showCalculator) const SizedBox(height: 24),
                            // Vial Volume field (always visible when calculator hidden)
                            if (!_showCalculator) ...[
                              LabelFieldRow(
                                key: _vialVolumeKey, // For scrolling after save
                                label: 'Vial volume (mL)',
                                field: StepperRow36(
                                  controller: _vialVolume,
                                  enabled: _reconResult == null, // Disable if reconstituted
                                  onDec: () {
                                    if (_reconResult != null) return;
                                    final v = int.tryParse(_vialVolume.text.trim()) ?? 0;
                                    setState(
                                      () => _vialVolume.text = (v - 1).clamp(0, 1000000).toString(),
                                    );
                                  },
                                  onInc: () {
                                    if (_reconResult != null) return;
                                    final v = int.tryParse(_vialVolume.text.trim()) ?? 0;
                                    setState(
                                      () => _vialVolume.text = (v + 1).clamp(0, 1000000).toString(),
                                    );
                                  },
                                  decoration: buildCompactFieldDecoration(hint: '0'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  right: 8,
                                  top: 2,
                                  bottom: 6,
                                ),
                                child: Text(
                                  _reconResult != null
                                      ? 'Edit reconstitution to change vial volume.'
                                      : 'Enter known volume or use calculator to determine reconstitution amount.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant.withOpacity(0.75),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  if (widget.kind == InjectionKind.multi) const SizedBox(height: 12),

                  SectionFormCard(
                    title: widget.kind == InjectionKind.multi ? 'Vial Inventory' : 'Inventory',
                    neutral: true,
                    children: [
                      // Helper text for inventory section
                      if (widget.kind == InjectionKind.multi)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                          child: Text(
                            'Track the number of vials you have in storage. This includes unreconstituted sealed vials or pre-reconstituted multi-dose vials. Used for restocking and low stock alerts.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.75),
                            ),
                          ),
                        ),
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
                          decoration: buildCompactFieldDecoration(hint: '0'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, top: 2, bottom: 6),
                        child: Text(
                          'Enter the number of ${switch (widget.kind) {
                            InjectionKind.pfs => 'pre-filled syringes',
                            InjectionKind.single => 'single dose vials',
                            InjectionKind.multi => 'vials',
                          }} currently in stock',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
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
                          width: kSmallControlWidth,
                          selected: _expiry != null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, top: 2, bottom: 6),
                        child: Text(
                          'Enter the expiry date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
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
                            decoration: buildFieldDecoration(context, hint: 'Enter batch number'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, top: 2, bottom: 6),
                        child: Text(
                          'Enter the printed batch or lot number',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
                          ),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Location',
                        field: Field36(
                          child: TextFormField(
                            controller: _location,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: buildFieldDecoration(context, hint: 'eg. Bathroom cabinet'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, top: 2, bottom: 6),
                        child: Text(
                          'Where it’s stored (e.g., Bathroom cabinet)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
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
                                    : (v) => setState(() => _refrigerate = v ?? false),
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
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, top: 2, bottom: 4),
                        child: Text(
                          'Enable if this medication must be kept refrigerated',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
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
                            Text('Freeze', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, top: 2, bottom: 4),
                        child: Text(
                          'Enable if this medication must be kept frozen',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
                          ),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Keep in dark',
                        field: Row(
                          children: [
                            Checkbox(
                              value: _lightSensitive,
                              onChanged: (v) => setState(() => _lightSensitive = v ?? false),
                            ),
                            Text('Dark storage', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: kLabelColWidth + 8, bottom: 6),
                        child: Text(
                          'Enable if this medication must be protected from light',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
                          ),
                        ),
                      ),
                      LabelFieldRow(
                        label: 'Storage instructions',
                        field: Field36(
                          child: TextFormField(
                            controller: _storageNotes,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: buildFieldDecoration(
                              context,
                              hint: 'Enter storage instructions',
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
    final id = widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

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
      manufacturer: _manufacturer.text.trim().isEmpty ? null : _manufacturer.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      strengthValue: double.tryParse(_strength.text) ?? 0,
      strengthUnit: _strengthUnit,
      perMlValue: _perMl.text.trim().isEmpty ? null : double.tryParse(_perMl.text.trim()),
      stockValue: stock,
      stockUnit: _stockUnit,
      expiry: _expiry,
      batchNumber: _batch.text.trim().isEmpty ? null : _batch.text.trim(),
      containerVolumeMl: _vialVolume.text.trim().isEmpty
          ? null
          : double.tryParse(_vialVolume.text.trim()),
      storageLocation: _location.text.trim().isEmpty ? null : _location.text.trim(),
      requiresRefrigeration: _refrigerate,
      storageInstructions: (() {
        final parts = <String>[];
        final s = _storageNotes.text.trim();
        if (s.isNotEmpty) parts.add(s);
        if (_keepFrozen && !parts.any((p) => p.toLowerCase().contains('frozen'))) {
          parts.add('Keep frozen');
        }
        if (_lightSensitive && !parts.any((p) => p.toLowerCase().contains('light'))) {
          parts.add('Protect from light');
        }
        return parts.isEmpty ? null : parts.join('. ');
      })(),
      initialStockValue: initialStock,
    );

    // Show confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Confirm Medication',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Styled summary preview block
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF09A8BD), Color(0xFF18537D)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                '${med.name}${med.manufacturer != null ? " from ${med.manufacturer}" : ""}',
                style: const TextStyle(color: Colors.white, height: 1.3),
              ),
            ),
            const SizedBox(height: 12),
            // Full details list
            _detailRow(ctx, 'Form', switch (widget.kind) {
              InjectionKind.pfs => 'Pre-Filled Syringe',
              InjectionKind.single => 'Single Dose Vial',
              InjectionKind.multi => 'Multi Dose Vial',
            }),
            _detailRow(ctx, 'Name', med.name),
            if (med.manufacturer != null) _detailRow(ctx, 'Manufacturer', med.manufacturer!),
            _detailRow(
              ctx,
              'Strength',
              '${fmt2(med.strengthValue)} ${_baseUnit(med.strengthUnit)}',
            ),
            if (med.perMlValue != null && widget.kind == InjectionKind.multi)
              _detailRow(
                ctx,
                'Concentration',
                '${fmt2(med.perMlValue!)} ${_baseUnit(med.strengthUnit)}/mL',
              ),
            if (med.containerVolumeMl != null && widget.kind == InjectionKind.multi)
              _detailRow(ctx, 'Vial Volume', '${fmt2(med.containerVolumeMl!)} mL'),
            _detailRow(ctx, 'Stock', '${fmt2(med.stockValue)} ${_stockUnitLabel()}'),
            _detailRow(
              ctx,
              'Expiry',
              med.expiry != null
                  ? DateTime.now().isAfter(med.expiry!)
                        ? 'Expired'
                        : '${med.expiry!.day}/${med.expiry!.month}/${med.expiry!.year}'
                  : 'No expiry',
            ),
            if (med.batchNumber != null) _detailRow(ctx, 'Batch #', med.batchNumber!),
            if (med.storageLocation != null) _detailRow(ctx, 'Storage', med.storageLocation!),
            _detailRow(ctx, 'Requires refrigeration', med.requiresRefrigeration ? 'Yes' : 'No'),
            if (med.storageInstructions != null)
              _detailRow(ctx, 'Storage notes', med.storageInstructions!),
            if (med.description != null) _detailRow(ctx, 'Description', med.description!),
            if (med.notes != null) _detailRow(ctx, 'Notes', med.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await repo.upsert(med);
      if (!mounted) return;
      context.go('/medications');
    }
  }

  String _stockUnitLabel() {
    return switch (widget.kind) {
      InjectionKind.pfs => 'pre-filled syringes',
      InjectionKind.single => 'single dose vials',
      InjectionKind.multi => 'multi dose vials',
    };
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
