import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/med_editor_template.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';

/// Template-based unified page for adding/editing medications.
/// Phase 1: Supports tablet, capsule, PFS, and single-dose vial.
/// MDV support coming in Phase 2.
class UnifiedAddEditMedicationPageTemplate extends ConsumerStatefulWidget {
  const UnifiedAddEditMedicationPageTemplate({
    super.key,
    required this.form,
    this.initial,
  });

  final MedicationForm form;
  final Medication? initial;

  @override
  ConsumerState<UnifiedAddEditMedicationPageTemplate> createState() =>
      _UnifiedAddEditMedicationPageTemplateState();
}

class _UnifiedAddEditMedicationPageTemplateState
    extends ConsumerState<UnifiedAddEditMedicationPageTemplate> {
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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Add listeners for summary updates
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
    }
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  // Helper getters
  String get _formLabel => switch (widget.form) {
    MedicationForm.tablet => 'Tablet',
    MedicationForm.capsule => 'Capsule',
    MedicationForm.injectionPreFilledSyringe => 'Pre-Filled Syringe',
    MedicationForm.injectionSingleDoseVial => 'Single Dose Vial',
    MedicationForm.injectionMultiDoseVial => 'Multi Dose Vial (coming soon)',
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

  InputDecoration _dec(BuildContext context, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      hintText: hint,
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5), width: kOutlineWidth),
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

  @override
  Widget build(BuildContext context) {
    // Reject MDV for now
    if (widget.form == MedicationForm.injectionMultiDoseVial) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Not Implemented Yet', forceBackButton: true),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Multi-Dose Vial support is coming in Phase 2.\nPlease use the old unified page for now.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null ? 'Add $_formLabel' : 'Edit $_formLabel',
        forceBackButton: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 140,
        child: FilledButton.icon(
          onPressed: _saveMedication,
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ),
      body: MedEditorTemplate(
        appBarTitle: widget.initial == null ? 'Add $_formLabel' : 'Edit $_formLabel',
        summaryBuilder: (key) => _buildSummaryCard(key),

        // General
        nameField: Field36(
          child: TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: _dec(context, hint: 'eg. DosifiTab-500'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        manufacturerField: Field36(
          child: TextFormField(
            controller: _manufacturerCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: _dec(context, hint: 'eg. Dosifi Labs'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        descriptionField: Field36(
          child: TextFormField(
            controller: _descriptionCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: _dec(context, hint: 'eg. Pain relief'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        notesField: Field36(
          child: TextFormField(
            controller: _notesCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: _dec(context, hint: 'eg. Take with water'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        nameHelp: 'Enter the medication name',
        manufacturerHelp: 'Enter the brand or company name',
        descriptionHelp: 'Optional short description',
        notesHelp: 'Optional notes',

        // Strength
        strengthStepper: StepperRow36(
          controller: _strengthValueCtrl,
          onDec: () {
            final v = int.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
            setState(() => _strengthValueCtrl.text = (v - 1).clamp(0, 1000000).toString());
          },
          onInc: () {
            final v = int.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
            setState(() => _strengthValueCtrl.text = (v + 1).clamp(0, 1000000).toString());
          },
          decoration: const InputDecoration(
            hintText: '0',
            isDense: false,
            isCollapsed: false,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(minHeight: kFieldHeight),
          ),
        ),
        unitDropdown: SmallDropdown36<Unit>(
          value: _strengthUnit,
          width: kSmallControlWidth,
          items: const [
            DropdownMenuItem(value: Unit.mcg, child: Center(child: Text('mcg'))),
            DropdownMenuItem(value: Unit.mg, child: Center(child: Text('mg'))),
            DropdownMenuItem(value: Unit.g, child: Center(child: Text('g'))),
          ],
          onChanged: (v) => setState(() => _strengthUnit = v ?? _strengthUnit),
        ),
        strengthHelp: 'Specify the amount per ${_formLabel.toLowerCase()} and its unit of measurement.',

        // Inventory
        stockStepper: StepperRow36(
          controller: _stockValueCtrl,
          onDec: () {
            final v = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
            setState(() => _stockValueCtrl.text = (v - 1).clamp(0, 1000000).toString());
          },
          onInc: () {
            final v = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
            setState(() => _stockValueCtrl.text = (v + 1).clamp(0, 1000000).toString());
          },
          decoration: const InputDecoration(
            hintText: '0',
            isDense: false,
            isCollapsed: false,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(minHeight: kFieldHeight),
          ),
        ),
        stockHelp: 'Enter the amount currently in stock',
        lowStockRow: Row(
          children: [
            Checkbox(value: _lowStockEnabled, onChanged: (v) => setState(() => _lowStockEnabled = v ?? false)),
            Expanded(
              child: Text(
                'Enable alert when stock is low',
                style: kCheckboxLabelStyle(context),
                softWrap: true,
                maxLines: 2,
              ),
            ),
          ],
        ),
        lowStockThresholdField: _lowStockEnabled
            ? StepperRow36(
                controller: _lowStockCtrl,
                onDec: () {
                  final v = int.tryParse(_lowStockCtrl.text.trim()) ?? 0;
                  setState(() => _lowStockCtrl.text = (v - 1).clamp(0, 1000000).toString());
                },
                onInc: () {
                  final v = int.tryParse(_lowStockCtrl.text.trim()) ?? 0;
                  final maxStock = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
                  setState(() => _lowStockCtrl.text = (v + 1).clamp(0, maxStock).toString());
                },
                decoration: const InputDecoration(
                  hintText: '0',
                  isDense: false,
                  isCollapsed: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(minHeight: kFieldHeight),
                ),
                compact: true,
              )
            : null,
        lowStockHelp: _lowStockEnabled
            ? (() {
                final stock = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
                final thr = int.tryParse(_lowStockCtrl.text.trim()) ?? 0;
                if (stock > 0 && thr >= stock) {
                  return 'Max threshold cannot exceed stock count.';
                }
                return 'Set the stock level that triggers a low stock alert';
              })()
            : null,
        lowStockHelpColor: (() {
          if (!_lowStockEnabled) return null;
          final stock = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
          final thr = int.tryParse(_lowStockCtrl.text.trim()) ?? 0;
          return (stock > 0 && thr >= stock) ? Colors.orange : null;
        })(),
        quantityDropdown: null, // Stock unit is auto-determined by form type
        expiryDateButton: DateButton36(
          label: _expiry == null
              ? 'Select date'
              : MaterialLocalizations.of(context).formatCompactDate(_expiry!),
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
        expiryHelp: 'Enter the expiry date',

        // Storage
        batchField: Field36(
          child: TextFormField(
            controller: _batchCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: const InputDecoration(hintText: 'Enter batch number'),
          ),
        ),
        batchHelp: 'Enter the printed batch or lot number',
        locationField: Field36(
          child: TextFormField(
            controller: _storageCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: const InputDecoration(hintText: 'eg. Bathroom cabinet'),
          ),
        ),
        locationHelp: "Where it's stored (e.g., Bathroom cabinet)",
        refrigerateRow: Opacity(
          opacity: _keepFrozen ? 0.5 : 1.0,
          child: Row(
            children: [
              Checkbox(
                value: _requiresFridge,
                onChanged: _keepFrozen ? null : (v) => setState(() => _requiresFridge = v ?? false),
              ),
              Text(
                'Refrigerate',
                style: _keepFrozen ? kMutedLabelStyle(context) : Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        refrigerateHelp: 'Enable if this medication must be kept refrigerated',
        freezeRow: Row(
          children: [
            Checkbox(
              value: _keepFrozen,
              onChanged: (v) => setState(() {
                _keepFrozen = v ?? false;
                if (_keepFrozen) _requiresFridge = false;
              }),
            ),
            Text('Freeze', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        freezeHelp: 'Enable if this medication must be kept frozen',
        darkRow: Row(
          children: [
            Checkbox(
              value: _lightSensitive,
              onChanged: (v) => setState(() => _lightSensitive = v ?? false),
            ),
            Text('Dark storage', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        darkHelp: 'Enable if this medication must be protected from light',
        storageInstructionsField: Field36(
          child: TextFormField(
            controller: _storageNotesCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: const InputDecoration(hintText: 'Enter storage instructions'),
          ),
        ),
        storageInstructionsHelp: 'Special handling notes (e.g., Keep upright)',
      ),
    );
  }

  Widget _buildSummaryCard(GlobalKey key) {
    final name = _nameCtrl.text.trim();
    final manufacturer = _manufacturerCtrl.text.trim();
    final strengthVal = double.tryParse(_strengthValueCtrl.text.trim());
    final stockVal = double.tryParse(_stockValueCtrl.text.trim());
    final initialStock = widget.initial?.initialStockValue ?? stockVal ?? 0;
    final unitLabel = _unitLabel(_strengthUnit);
    final threshold = double.tryParse(_lowStockCtrl.text.trim());
    final headerTitle = name.isEmpty ? _formLabel : name;

    return SummaryHeaderCard(
      key: key,
      title: headerTitle,
      manufacturer: manufacturer.isEmpty ? null : manufacturer,
      strengthValue: strengthVal,
      strengthUnitLabel: unitLabel,
      stockCurrent: stockVal ?? 0,
      stockInitial: initialStock,
      stockUnitLabel: _formLabelPlural,
      expiryDate: _expiry,
      showRefrigerate: _requiresFridge,
      showFrozen: _keepFrozen,
      showDark: _lightSensitive,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: threshold,
      includeNameInStrengthLine: false,
      perTabletLabel: name.isNotEmpty,
      formLabelPlural: _formLabelPlural,
    );
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
}
