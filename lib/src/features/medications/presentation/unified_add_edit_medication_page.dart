import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/sections/mdv_volume_reconstitution_section.dart';

/// Unified page for adding/editing all medication types.
/// Handles tablets, capsules, PFS, single-dose vials, and multi-dose vials.
class UnifiedAddEditMedicationPage extends ConsumerStatefulWidget {
  const UnifiedAddEditMedicationPage({
    super.key,
    required this.form,
    this.initial,
  });

  final MedicationForm form;
  final Medication? initial;

  @override
  ConsumerState<UnifiedAddEditMedicationPage> createState() =>
      _UnifiedAddEditMedicationPageState();
}

class _UnifiedAddEditMedicationPageState
    extends ConsumerState<UnifiedAddEditMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _vialVolumeKey = GlobalKey();
  final _scrollCtrl = ScrollController();
  double _summaryHeight = 0;

  // Validation state
  bool _submitted = false;
  bool _touchedName = false;
  bool _touchedStrengthAmt = false;
  bool _touchedStock = false;

  // General section
  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Strength section
  final _strengthValueCtrl = TextEditingController(text: '0');
  Unit _strengthUnit = Unit.mg;

  // Inventory section
  final _stockValueCtrl = TextEditingController(text: '0');
  bool _lowStockEnabled = false;
  final _lowStockCtrl = TextEditingController(text: '0');

  // Storage section
  DateTime? _expiry;
  final _batchCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  bool _requiresFridge = false;
  bool _keepFrozen = false;
  bool _lightSensitive = false;
  final _storageNotesCtrl = TextEditingController();

  // MDV-specific fields
  final _perMlCtrl = TextEditingController();
  final _vialVolumeCtrl = TextEditingController(text: '0');
  ReconstitutionResult? _reconResult;
  bool _showCalculator = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _nameCtrl.addListener(() => setState(() {}));
    _manufacturerCtrl.addListener(() => setState(() {}));
    _strengthValueCtrl.addListener(() => setState(() {}));
    _stockValueCtrl.addListener(() => setState(() {}));
  }

  void _loadInitialData() {
    final m = widget.initial;
    if (m != null) {
      _nameCtrl.text = m.name;
      _manufacturerCtrl.text = m.manufacturer ?? '';
      _descriptionCtrl.text = m.description ?? '';
      _notesCtrl.text = m.notes ?? '';
      _strengthValueCtrl.text = m.strengthValue.toString();
      _strengthUnit = m.strengthUnit;
      _stockValueCtrl.text = m.stockValue.toString();
      _lowStockEnabled = m.lowStockEnabled;
      _lowStockCtrl.text = m.lowStockThreshold?.toString() ?? '0';
      _expiry = m.expiry;
      _batchCtrl.text = m.batchNumber ?? '';
      _storageCtrl.text = m.storageLocation ?? '';
      _requiresFridge = m.requiresRefrigeration;
      _storageNotesCtrl.text = m.storageInstructions ?? '';
      final si = (m.storageInstructions ?? '').toLowerCase();
      _keepFrozen = si.contains('frozen');
      _lightSensitive = si.contains('light');

      // MDV-specific
      if (_isMdv) {
        _perMlCtrl.text = m.perMlValue?.toString() ?? '';
        _vialVolumeCtrl.text = m.containerVolumeMl?.toString() ?? '0';
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    _strengthValueCtrl.dispose();
    _stockValueCtrl.dispose();
    _lowStockCtrl.dispose();
    _batchCtrl.dispose();
    _storageCtrl.dispose();
    _storageNotesCtrl.dispose();
    _perMlCtrl.dispose();
    _vialVolumeCtrl.dispose();
    super.dispose();
  }

  // Helper getters
  bool get _isMdv => widget.form == MedicationForm.injectionMultiDoseVial;
  bool get _isInjection => widget.form.name.startsWith('injection');

  String get _formLabel => switch (widget.form) {
    MedicationForm.tablet => 'Tablet',
    MedicationForm.capsule => 'Capsule',
    MedicationForm.injectionPreFilledSyringe => 'Pre-Filled Syringe',
    MedicationForm.injectionSingleDoseVial => 'Single Dose Vial',
    MedicationForm.injectionMultiDoseVial => 'Multi Dose Vial',
  };

  String get _formLabelPlural => switch (widget.form) {
    MedicationForm.tablet => 'tablets',
    MedicationForm.capsule => 'capsules',
    MedicationForm.injectionPreFilledSyringe => 'pre filled syringes',
    MedicationForm.injectionSingleDoseVial => 'single dose vials',
    MedicationForm.injectionMultiDoseVial => 'multi dose vials',
  };

  StockUnit get _stockUnit => switch (widget.form) {
    MedicationForm.tablet => StockUnit.tablets,
    MedicationForm.capsule => StockUnit.capsules,
    MedicationForm.injectionPreFilledSyringe => StockUnit.preFilledSyringes,
    MedicationForm.injectionSingleDoseVial => StockUnit.singleDoseVials,
    MedicationForm.injectionMultiDoseVial => StockUnit.multiDoseVials,
  };

  String _unitLabel(Unit u) => switch (u) {
    Unit.mcg => 'mcg',
    Unit.mg => 'mg',
    Unit.g => 'g',
    _ => u.name,
  };

  double _labelWidth() {
    final width = MediaQuery.of(context).size.width;
    return width >= 400 ? 120.0 : 110.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null ? 'Add $_formLabel' : 'Edit $_formLabel',
        actions: const [],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollCtrl,
            padding: EdgeInsets.fromLTRB(12, 12, 12, _summaryHeight + 88),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGeneralSection(),
                  const SizedBox(height: 12),
                  _buildStrengthSection(),
                  const SizedBox(height: 12),
                  if (_isMdv) ...[
                    _buildMdvVolumeReconstitutionSection(),
                    const SizedBox(height: 12),
                  ],
                  _buildInventorySection(),
                  const SizedBox(height: 12),
                  _buildStorageSection(),
                ],
              ),
            ),
          ),
          _buildFloatingSummary(),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildGeneralSection() {
    return _section('General', [
      _rowLabelField(
        label: 'Name *',
        field: Field36(
          child: TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(hint: 'eg. Panadol'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (_) => setState(() => _touchedName = true),
          ),
        ),
      ),
      _helperBelowLeft('Enter the medication name'),
      _rowLabelField(
        label: 'Manufacturer',
        field: Field36(
          child: TextFormField(
            controller: _manufacturerCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(hint: 'eg. GSK'),
          ),
        ),
      ),
      _helperBelowLeft('Enter the brand or company name'),
      _rowLabelField(
        label: 'Description',
        field: Field36(
          child: TextFormField(
            controller: _descriptionCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(hint: 'eg. Pain relief'),
          ),
        ),
      ),
      _helperBelowLeft('Optional short description'),
      _rowLabelField(
        label: 'Notes',
        field: TextFormField(
          controller: _notesCtrl,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          minLines: 2,
          maxLines: null,
          decoration: _dec(hint: 'eg. Take with water'),
        ),
      ),
      _helperBelowLeft('Optional notes'),
    ]);
  }

  Widget _buildStrengthSection() {
    return _section('Strength', [
      _rowLabelField(
        label: 'Strength *',
        field: StepperRow36(
          controller: _strengthValueCtrl,
          onDec: () {
            final d = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
            final nv = (d - 1).clamp(0, 1000000000);
            setState(() {
              _strengthValueCtrl.text = nv.toStringAsFixed(0);
              _touchedStrengthAmt = true;
            });
          },
          onInc: () {
            final d = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
            final nv = (d + 1).clamp(0, 1000000000);
            setState(() {
              _strengthValueCtrl.text = nv.toStringAsFixed(0);
              _touchedStrengthAmt = true;
            });
          },
          decoration: _dec(hint: '0'),
        ),
      ),
      _rowLabelField(
        label: 'Unit *',
        field: SmallDropdown36<Unit>(
          value: _strengthUnit,
          items: const [Unit.mcg, Unit.mg, Unit.g]
              .map(
                (u) => DropdownMenuItem(
                  value: u,
                  alignment: AlignmentDirectional.center,
                  child: Center(child: Text(_unitLabel(u))),
                ),
              )
              .toList(),
          onChanged: (u) => setState(() => _strengthUnit = u ?? _strengthUnit),
          decoration: _decDrop(),
        ),
      ),
      _helperBelowCenter(
        'Specify the amount per ${_formLabel.toLowerCase()} and its unit of measurement',
      ),
    ]);
  }

  Widget _buildMdvVolumeReconstitutionSection() {
    return MdvVolumeReconstitutionSection(
      strengthController: _strengthValueCtrl,
      strengthUnit: _strengthUnit,
      perMlController: _perMlCtrl,
      vialVolumeController: _vialVolumeCtrl,
      medicationNameController: _nameCtrl,
      vialVolumeKey: _vialVolumeKey,
      initialReconResult: _reconResult,
      onReconstitutionChanged: (result) {
        setState(() => _reconResult = result);
      },
    );
  }

  Widget _buildInventorySection() {
    return _section('Inventory', [
      _rowLabelField(
        label: 'Stock quantity *',
        field: StepperRow36(
          controller: _stockValueCtrl,
          onDec: () {
            final d = double.tryParse(_stockValueCtrl.text.trim()) ?? 0;
            final nv = (d - 1).clamp(0, 1000000000);
            setState(() {
              _stockValueCtrl.text = nv.toStringAsFixed(0);
              _touchedStock = true;
            });
          },
          onInc: () {
            final d = double.tryParse(_stockValueCtrl.text.trim()) ?? 0;
            final nv = (d + 1).clamp(0, 1000000000);
            setState(() {
              _stockValueCtrl.text = nv.toStringAsFixed(0);
              _touchedStock = true;
            });
          },
          decoration: _dec(hint: '0'),
        ),
      ),
      _helperBelowLeft(
        _isMdv
            ? 'Track the number of unreconstituted sealed vials you have in storage'
            : 'Enter the quantity of $_formLabelPlural in stock',
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: CheckboxListTile(
              value: _lowStockEnabled,
              onChanged: (v) => setState(() => _lowStockEnabled = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('Low stock alerts'),
              subtitle: const Text('Notify when reaching threshold'),
            ),
          ),
        ],
      ),
      if (_lowStockEnabled) ...[
        _rowLabelField(
          label: 'Alert at',
          field: StepperRow36(
            controller: _lowStockCtrl,
            onDec: () {
              final d = double.tryParse(_lowStockCtrl.text.trim()) ?? 0;
              final nv = (d - 1).clamp(0, 1000000000);
              setState(() => _lowStockCtrl.text = nv.toStringAsFixed(0));
            },
            onInc: () {
              final d = double.tryParse(_lowStockCtrl.text.trim()) ?? 0;
              final nv = (d + 1).clamp(0, 1000000000);
              setState(() => _lowStockCtrl.text = nv.toStringAsFixed(0));
            },
            decoration: _dec(hint: '0'),
          ),
        ),
        _helperBelowLeft('Receive alert when stock reaches this level'),
      ],
    ]);
  }

  Widget _buildStorageSection() {
    return _section('Storage', [
      _rowLabelField(
        label: 'Expiry',
        field: DateButton36(
          label: _expiry == null
              ? 'Pick expiry date'
              : DateFormat.yMd().format(_expiry!),
          onPressed: _pickExpiry,
          selected: _expiry != null,
        ),
      ),
      _helperBelowLeft('Optional expiry date'),
      _rowLabelField(
        label: 'Batch #',
        field: Field36(
          child: TextFormField(
            controller: _batchCtrl,
            decoration: _dec(hint: 'eg. B12345'),
          ),
        ),
      ),
      _rowLabelField(
        label: 'Location',
        field: Field36(
          child: TextFormField(
            controller: _storageCtrl,
            decoration: _dec(hint: 'eg. Kitchen cabinet'),
          ),
        ),
      ),
      const SizedBox(height: 8),
      _storageToggles(),
      const SizedBox(height: 8),
      _rowLabelField(
        label: 'Storage notes',
        field: TextFormField(
          controller: _storageNotesCtrl,
          keyboardType: TextInputType.multiline,
          minLines: 2,
          maxLines: null,
          decoration: _dec(hint: 'eg. Keep away from children'),
        ),
      ),
    ]);
  }

  Widget _storageToggles() {
    return Column(
      children: [
        CheckboxListTile(
          value: _requiresFridge,
          onChanged: (v) => setState(() => _requiresFridge = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text('Refrigerate (2-8°C)'),
        ),
        CheckboxListTile(
          value: _keepFrozen,
          onChanged: (v) => setState(() => _keepFrozen = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text('Freeze (below 0°C)'),
        ),
        CheckboxListTile(
          value: _lightSensitive,
          onChanged: (v) => setState(() => _lightSensitive = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text('Protect from light'),
        ),
      ],
    );
  }

  Widget _buildFloatingSummary() {
    // Summary card implementation
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: _floatingSummaryCard(),
      ),
    );
  }

  SummaryHeaderCard _floatingSummaryCard() {
    final name = _nameCtrl.text.trim();
    final manufacturer = _manufacturerCtrl.text.trim();
    final strengthVal = double.tryParse(_strengthValueCtrl.text.trim());
    final stockVal = double.tryParse(_stockValueCtrl.text.trim());
    final initialStock = widget.initial?.initialStockValue ?? stockVal ?? 0;
    final unitLabel = _unitLabel(_strengthUnit);
    final threshold = double.tryParse(_lowStockCtrl.text.trim());

    // MDV-specific 3-line format
    String? mdvAdditionalInfo;
    if (_isMdv && strengthVal != null && strengthVal > 0) {
      final vialVol = double.tryParse(_vialVolumeCtrl.text.trim());
      final concentration = double.tryParse(_perMlCtrl.text.trim());
      final stockCount = stockVal?.toInt() ?? 0;

      // Line 1: Strength per vial
      final line1 =
          '${strengthVal.toStringAsFixed(strengthVal == strengthVal.roundToDouble() ? 0 : 1)}$unitLabel per Vial';

      // Line 2: Reconstitution details (if available)
      String? line2;
      if (vialVol != null &&
          vialVol > 0 &&
          concentration != null &&
          concentration > 0) {
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

      // Combine lines
      mdvAdditionalInfo = line1;
      if (line2 != null) mdvAdditionalInfo += '\n$line2';
      mdvAdditionalInfo += '\n$line3';
    }

    final card = SummaryHeaderCard(
      key: _summaryKey,
      title: name.isEmpty ? _formLabel : name,
      manufacturer: manufacturer.isEmpty ? null : manufacturer,
      strengthValue: strengthVal,
      strengthUnitLabel: unitLabel,
      stockCurrent: stockVal ?? 0,
      stockInitial: initialStock,
      stockUnitLabel: _isMdv
          ? 'unreconstituted $_formLabelPlural'
          : _formLabelPlural,
      expiryDate: _expiry,
      showRefrigerate: _requiresFridge,
      showFrozen: _keepFrozen,
      showDark: _lightSensitive,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: threshold,
      includeNameInStrengthLine: false,
      perTabletLabel: name.isNotEmpty,
      formLabelPlural: _formLabelPlural,
      additionalInfo: mdvAdditionalInfo,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSummaryHeight());
    return card;
  }

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

  Widget _buildSaveButton() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: _summaryHeight + 12,
      child: Center(
        child: FilledButton.icon(
          onPressed: _validateAndSave,
          icon: const Icon(Icons.save),
          label: const Text('Save Medication'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _validateAndSave() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    // Build and save medication
    await _saveMedication();
  }

  Future<void> _saveMedication() async {
    final repo = ref.read(medicationRepositoryProvider);
    final id = widget.initial?.id ?? _newId();
    final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
    final stock = double.tryParse(_stockValueCtrl.text.trim()) ?? 0;
    final previous = widget.initial;
    final initialStock = previous == null
        ? stock
        : (stock > previous.stockValue
              ? stock
              : (previous.initialStockValue ?? previous.stockValue));

    final med = Medication(
      id: id,
      form: widget.form,
      name: _nameCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty
          ? null
          : _manufacturerCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      strengthValue: strength,
      strengthUnit: _strengthUnit,
      perMlValue: _isMdv ? double.tryParse(_perMlCtrl.text.trim()) : null,
      stockValue: stock,
      stockUnit: _stockUnit, // Auto-set based on form!
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: _lowStockEnabled && _lowStockCtrl.text.isNotEmpty
          ? double.tryParse(_lowStockCtrl.text.trim())
          : null,
      expiry: _expiry,
      batchNumber: _batchCtrl.text.trim().isEmpty
          ? null
          : _batchCtrl.text.trim(),
      storageLocation: _storageCtrl.text.trim().isEmpty
          ? null
          : _storageCtrl.text.trim(),
      requiresRefrigeration: _requiresFridge,
      storageInstructions: _buildStorageInstructions(),
      initialStockValue: initialStock,
      containerVolumeMl: _isMdv
          ? double.tryParse(_vialVolumeCtrl.text.trim())
          : null,
    );

    await repo.upsert(med);
    if (!mounted) return;
    context.go('/medications');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Medication saved')));
  }

  String? _buildStorageInstructions() {
    final parts = <String>[];
    final s = _storageNotesCtrl.text.trim();
    if (s.isNotEmpty) parts.add(s);
    if (_keepFrozen && !parts.any((p) => p.toLowerCase().contains('frozen'))) {
      parts.add('Keep frozen');
    }
    if (_lightSensitive &&
        !parts.any((p) => p.toLowerCase().contains('light'))) {
      parts.add('Protect from light');
    }
    return parts.isEmpty ? null : parts.join('. ');
  }

  String _newId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return 'med_$ms';
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
      initialDate: _expiry ?? now,
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  // UI Helpers
  Widget _section(String title, List<Widget> children) {
    return SectionFormCard(title: title, children: children);
  }

  Widget _rowLabelField({required String label, required Widget field}) {
    return LabelFieldRow(label: label, field: field, labelWidth: _labelWidth());
  }

  Widget _helperBelowLeft(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: _labelWidth() + 8, top: 4, bottom: 12),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: kHintFontSize,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _helperBelowCenter(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec({String? hint}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      hintText: hint,
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      hintStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: kHintFontSize,
        color: cs.onSurfaceVariant,
      ),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
    );
  }

  InputDecoration _decDrop() {
    final theme = Theme.of(context);
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLowest,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    );
  }
}
