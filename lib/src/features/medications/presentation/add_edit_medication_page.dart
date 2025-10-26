// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/sections/mdv_volume_reconstitution_section.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/med_editor_template.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// Unified page for adding/editing all medication types.
/// Supports tablet, capsule, pre-filled syringe, single-dose vial, and multi-dose vial.
class AddEditMedicationPage extends ConsumerStatefulWidget {
  const AddEditMedicationPage({required this.form, super.key, this.initial});

  final MedicationForm form;
  final Medication? initial;

  @override
  ConsumerState<AddEditMedicationPage> createState() =>
      _AddEditMedicationPageState();
}

class _AddEditMedicationPageState extends ConsumerState<AddEditMedicationPage> {
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
  final GlobalKey _vialVolumeKey = GlobalKey();
  ReconstitutionResult? _reconResult;
  bool _calculatorVisible = false;

  // MDV Active Vial fields
  final _activeVialLowStockMlCtrl = TextEditingController(text: '0');
  bool _activeVialLowStockEnabled = false;
  final _activeVialBatchCtrl = TextEditingController();
  final _activeVialStorageCtrl = TextEditingController();
  bool _activeVialRequiresFridge = false;
  bool _activeVialKeepFrozen = false;
  bool _activeVialLightSensitive = false;
  DateTime? _activeVialExpiry; // Uses reconstitutedVialExpiry

  // MDV Backup Stock fields
  final _backupVialsBatchCtrl = TextEditingController();
  final _backupVialsStorageCtrl = TextEditingController();
  bool _backupVialsRequiresFridge = false;
  bool _backupVialsKeepFrozen = false;
  bool _backupVialsLightSensitive = false;
  DateTime? _backupVialsExpiry;

  bool get _isMdv => widget.form == MedicationForm.injectionMultiDoseVial;

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

      // MDV-specific
      if (_isMdv) {
        _perMlCtrl.text = m.perMlValue?.toString() ?? '';
        _vialVolumeCtrl.text = m.containerVolumeMl?.toString() ?? '0';
        
        // Active vial fields
        _activeVialLowStockMlCtrl.text = m.activeVialLowStockMl?.toString() ?? '0';
        _activeVialLowStockEnabled = m.activeVialLowStockMl != null && m.activeVialLowStockMl! > 0;
        _activeVialBatchCtrl.text = m.activeVialBatchNumber ?? '';
        _activeVialStorageCtrl.text = m.activeVialStorageLocation ?? '';
        _activeVialRequiresFridge = m.activeVialRequiresRefrigeration;
        _activeVialKeepFrozen = m.activeVialRequiresFreezer;
        _activeVialLightSensitive = m.activeVialLightSensitive;
        _activeVialExpiry = m.reconstitutedVialExpiry;
        
        // Backup vials fields
        _backupVialsBatchCtrl.text = m.backupVialsBatchNumber ?? '';
        _backupVialsStorageCtrl.text = m.backupVialsStorageLocation ?? '';
        _backupVialsRequiresFridge = m.backupVialsRequiresRefrigeration;
        _backupVialsKeepFrozen = m.backupVialsRequiresFreezer;
        _backupVialsLightSensitive = m.backupVialsLightSensitive;
        _backupVialsExpiry = m.backupVialsExpiry;
      }
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
    _perMlCtrl.dispose();
    _vialVolumeCtrl.dispose();
    // MDV active vial
    _activeVialLowStockMlCtrl.dispose();
    _activeVialBatchCtrl.dispose();
    _activeVialStorageCtrl.dispose();
    // MDV backup vials
    _backupVialsBatchCtrl.dispose();
    _backupVialsStorageCtrl.dispose();
    super.dispose();
  }

  // Helper getters
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

  String _getStrengthHelp() {
    return switch (widget.form) {
      MedicationForm.tablet =>
        'Enter the active ingredient amount per tablet (e.g., 500 mg). This is usually printed on the packaging.',
      MedicationForm.capsule =>
        'Enter the active ingredient amount per capsule (e.g., 250 mg). Check the label or packaging.',
      MedicationForm.injectionPreFilledSyringe =>
        'Enter the total drug concentration (e.g., 100 mg/mL). For ready-to-use syringes, use mg/mL units.',
      MedicationForm.injectionSingleDoseVial =>
        'Enter the total amount in the vial (e.g., 50 mg) or concentration (e.g., 10 mg/mL) as printed on the label.',
      MedicationForm.injectionMultiDoseVial =>
        'Enter the total drug amount in the vial (e.g., 1000 mg). This is the amount BEFORE reconstitution.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null ? 'Add $_formLabel' : 'Edit $_formLabel',
        forceBackButton: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _calculatorVisible
          ? null
          : SizedBox(
              width: 140,
              child: FilledButton.icon(
                onPressed: _saveMedication,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
      body: MedEditorTemplate(
        appBarTitle: widget.initial == null
            ? 'Add $_formLabel'
            : 'Edit $_formLabel',
        summaryBuilder: _buildSummaryCard,

        // General
        nameField: Field36(
          child: TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: buildFieldDecoration(
              context,
              hint: 'eg. DosifiTab-500',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        manufacturerField: Field36(
          child: TextFormField(
            controller: _manufacturerCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: buildFieldDecoration(context, hint: 'eg. Dosifi Labs'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        descriptionField: Field36(
          child: TextFormField(
            controller: _descriptionCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: buildFieldDecoration(context, hint: 'eg. Pain relief'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        notesField: TextFormField(
          controller: _notesCtrl,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          minLines: 2,
          maxLines: null,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: buildFieldDecoration(
            context,
            hint: 'eg. Take with water',
          ),
          onChanged: (_) => setState(() {}),
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
            setState(
              () => _strengthValueCtrl.text = (v - 1)
                  .clamp(0, 1000000)
                  .toString(),
            );
          },
          onInc: () {
            final v = int.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
            setState(
              () => _strengthValueCtrl.text = (v + 1)
                  .clamp(0, 1000000)
                  .toString(),
            );
          },
          decoration: buildCompactFieldDecoration(context: context, hint: '0'),
        ),
        unitDropdown: SmallDropdown36<Unit>(
          value: _strengthUnit,
          items: [
            const DropdownMenuItem(
              value: Unit.mcg,
              child: Center(child: Text('mcg')),
            ),
            const DropdownMenuItem(
              value: Unit.mg,
              child: Center(child: Text('mg')),
            ),
            const DropdownMenuItem(
              value: Unit.g,
              child: Center(child: Text('g')),
            ),
            const DropdownMenuItem(
              value: Unit.units,
              child: Center(child: Text('units')),
            ),
            // Add concentration units for pre-filled syringes and single dose vials
            if (widget.form == MedicationForm.injectionPreFilledSyringe ||
                widget.form == MedicationForm.injectionSingleDoseVial) ...[
              const DropdownMenuItem(
                value: Unit.mcgPerMl,
                child: Center(child: Text('mcg/mL')),
              ),
              const DropdownMenuItem(
                value: Unit.mgPerMl,
                child: Center(child: Text('mg/mL')),
              ),
              const DropdownMenuItem(
                value: Unit.gPerMl,
                child: Center(child: Text('g/mL')),
              ),
              const DropdownMenuItem(
                value: Unit.unitsPerMl,
                child: Center(child: Text('units/mL')),
              ),
            ],
          ],
          onChanged: (v) => setState(() => _strengthUnit = v ?? _strengthUnit),
        ),
        strengthHelp: _getStrengthHelp(),

        // MDV Volume & Reconstitution section (only for multi-dose vials)
        mdvSection: _isMdv
            ? MdvVolumeReconstitutionSection(
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
                onCalculatorVisibilityChanged: (visible) {
                  setState(() => _calculatorVisible = visible);
                },
              )
            : null,

        // Inventory
        stockStepper: StepperRow36(
          controller: _stockValueCtrl,
          onDec: () {
            final v = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
            setState(
              () => _stockValueCtrl.text = (v - 1).clamp(0, 1000000).toString(),
            );
          },
          onInc: () {
            final v = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
            setState(
              () => _stockValueCtrl.text = (v + 1).clamp(0, 1000000).toString(),
            );
          },
          decoration: buildCompactFieldDecoration(context: context, hint: '0'),
        ),
        stockHelp: _isMdv
            ? 'Track the number of unreconstituted sealed vials you have in storage'
            : 'Enter the number of $_formLabelPlural currently in stock',
        lowStockRow: Row(
          children: [
            Checkbox(
              value: _lowStockEnabled,
              onChanged: (v) => setState(() => _lowStockEnabled = v ?? false),
            ),
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
                  setState(
                    () => _lowStockCtrl.text = (v - 1)
                        .clamp(0, 1000000)
                        .toString(),
                  );
                },
                onInc: () {
                  final v = int.tryParse(_lowStockCtrl.text.trim()) ?? 0;
                  final maxStock =
                      int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
                  setState(
                    () => _lowStockCtrl.text = (v + 1)
                        .clamp(0, maxStock)
                        .toString(),
                  );
                },
                decoration: buildCompactFieldDecoration(
                  context: context,
                  hint: '0',
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
            decoration: buildFieldDecoration(
              context,
              hint: 'Enter batch number',
            ),
          ),
        ),
        batchHelp: 'Enter the printed batch or lot number',
        locationField: Field36(
          child: TextFormField(
            controller: _storageCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: buildFieldDecoration(
              context,
              hint: 'eg. Bathroom cabinet',
            ),
          ),
        ),
        locationHelp: "Where it's stored (e.g., Bathroom cabinet)",
        refrigerateRow: Opacity(
          opacity: _keepFrozen ? 0.5 : 1.0,
          child: Row(
            children: [
              Checkbox(
                value: _requiresFridge,
                onChanged: _keepFrozen
                    ? null
                    : (v) => setState(() => _requiresFridge = v ?? false),
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
            decoration: buildFieldDecoration(
              context,
              hint: 'Enter storage instructions',
            ),
          ),
        ),
        storageInstructionsHelp: 'Special handling notes (e.g., Keep upright)',
      ),
    );
  }

  Widget _buildSummaryCard(GlobalKey key) {
    // Hide summary when calculator is open
    if (_calculatorVisible) {
      return const SizedBox.shrink();
    }
    
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
      perMlValue: _isMdv && _perMlCtrl.text.isNotEmpty
          ? double.tryParse(_perMlCtrl.text.trim())
          : null,
      stockCurrent: stockVal ?? 0,
      stockInitial: initialStock,
      stockUnitLabel: _formLabelPlural,
      expiryDate: _expiry,
      showRefrigerate: _requiresFridge,
      showFrozen: _keepFrozen,
      showDark: _lightSensitive,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: threshold,
      perTabletLabel:
          name.isNotEmpty &&
          (widget.form == MedicationForm.tablet ||
              widget.form == MedicationForm.capsule),
      formLabelPlural: _formLabelPlural,
      // MDV reconstitution gauge data
      reconTotalIU: _isMdv && _reconResult != null
          ? _reconResult!.syringeSizeMl * 100
          : null,
      reconFillIU: _isMdv && _reconResult != null
          ? _reconResult!.recommendedUnits
          : null,
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
      // MDV-specific: include perMlValue and containerVolumeMl
      perMlValue: _isMdv && _perMlCtrl.text.isNotEmpty
          ? double.tryParse(_perMlCtrl.text.trim())
          : null,
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
      // MDV-specific: vial volume (total volume after reconstitution)
      containerVolumeMl: _isMdv && _vialVolumeCtrl.text.isNotEmpty
          ? double.tryParse(_vialVolumeCtrl.text.trim())
          : null,
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
