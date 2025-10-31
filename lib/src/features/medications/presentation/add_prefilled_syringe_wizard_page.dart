// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_wizard_base.dart';
import 'package:dosifi_v5/src/widgets/date_button_36.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/section_form_card.dart';
import 'package:dosifi_v5/src/widgets/small_dropdown_36.dart';
import 'package:dosifi_v5/src/widgets/stepper_row_36.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// Wizard-style Pre-filled Syringe add/edit screen with step-by-step flow
class AddPrefilledSyringeWizardPage extends MedicationWizardBase {
  const AddPrefilledSyringeWizardPage({super.key, super.initial});

  @override
  int get stepCount => 4;

  @override
  List<String> get stepLabels => [
        'STEP 1: BASIC INFORMATION',
        'STEP 2: CONCENTRATION & VOLUME',
        'STEP 3: INVENTORY',
        'STEP 4: STORAGE & REVIEW',
      ];

  @override
  ConsumerState<AddPrefilledSyringeWizardPage> createState() =>
      _AddPrefilledSyringeWizardPageState();
}

class _AddPrefilledSyringeWizardPageState
    extends MedicationWizardState<AddPrefilledSyringeWizardPage> {
  // Step 1: Basic Info
  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // Step 2: Concentration & Volume
  final _concentrationValueCtrl = TextEditingController(text: '0');
  Unit _concentrationUnit = Unit.mg;
  final _volumeValueCtrl = TextEditingController(text: '0');
  VolumeUnit _volumeUnit = VolumeUnit.ml;

  // Step 3: Inventory
  final _stockValueCtrl = TextEditingController(text: '0');
  bool _lowStockEnabled = false;
  final _lowStockThresholdCtrl = TextEditingController(text: '0');

  // Step 4: Storage
  DateTime? _expiry;
  final _batchCtrl = TextEditingController();
  final _storageLocationCtrl = TextEditingController();
  bool _requiresFridge = false;
  bool _requiresFreezer = false;
  bool _protectLight = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final m = widget.initial;
    if (m != null) {
      _nameCtrl.text = m.name;
      _manufacturerCtrl.text = m.manufacturer ?? '';
      _descriptionCtrl.text = m.description ?? '';
      _concentrationValueCtrl.text = m.strengthValue.toString();
      _concentrationUnit = m.strengthUnit;
      _volumeValueCtrl.text = m.volumePerDose?.toString() ?? '0';
      _volumeUnit = m.volumeUnit ?? VolumeUnit.ml;
      _stockValueCtrl.text = m.stockValue.toString();
      _lowStockEnabled = m.lowStockEnabled;
      _lowStockThresholdCtrl.text = m.lowStockThreshold?.toString() ?? '0';
      _expiry = m.expiry;
      _batchCtrl.text = m.batchNumber ?? '';
      _storageLocationCtrl.text = m.storageLocation ?? '';
      _requiresFridge = m.requiresRefrigeration;
      // Parse from storage instructions if available
      final si = (m.storageInstructions ?? '').toLowerCase();
      _requiresFreezer = si.contains('freez');
      _protectLight = si.contains('light');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _concentrationValueCtrl.dispose();
    _volumeValueCtrl.dispose();
    _stockValueCtrl.dispose();
    _lowStockThresholdCtrl.dispose();
    _batchCtrl.dispose();
    _storageLocationCtrl.dispose();
    super.dispose();
  }

  @override
  bool get canProceed {
    switch (currentStep) {
      case 0: // Basic Info
        return _nameCtrl.text.trim().isNotEmpty;
      case 1: // Concentration & Volume
        final conc =
            double.tryParse(_concentrationValueCtrl.text.trim()) ?? 0;
        final vol = double.tryParse(_volumeValueCtrl.text.trim()) ?? 0;
        return conc > 0 && vol > 0;
      case 2: // Inventory
        return true; // Optional
      case 3: // Storage & Review
        return true;
      default:
        return false;
    }
  }

  @override
  String getStepLabel(int step) => widget.stepLabels[step];

  @override
  Widget buildSummaryContent() {
    final name = _nameCtrl.text.trim();
    final manufacturer = _manufacturerCtrl.text.trim();
    final concVal = double.tryParse(_concentrationValueCtrl.text.trim());
    final volVal = double.tryParse(_volumeValueCtrl.text.trim());
    final stock = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
    final threshold = _lowStockEnabled
        ? int.tryParse(_lowStockThresholdCtrl.text.trim())
        : null;
    final headerTitle = name.isEmpty ? 'Pre-filled Syringe' : name;
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.vaccines, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headerTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  if (manufacturer.isNotEmpty) ...{
                    const SizedBox(height: 4),
                    Text(
                      manufacturer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: fg.withValues(alpha: 0.9),
                      ),
                    ),
                  },
                  const SizedBox(height: 2),
                  if (concVal != null && concVal > 0) ...{
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(color: fg),
                        children: [
                          TextSpan(
                            text: concVal == concVal.roundToDouble()
                                ? concVal.toStringAsFixed(0)
                                : concVal.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' ${_concentrationUnit.name}'),
                          if (volVal != null && volVal > 0) ...{
                            const TextSpan(text: ' in '),
                            TextSpan(
                              text: volVal == volVal.roundToDouble()
                                  ? volVal.toStringAsFixed(0)
                                  : volVal.toStringAsFixed(2),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(text: ' ${_volumeUnit.name}'),
                          },
                        ],
                      ),
                    ),
                  },
                  if (stock > 0) ...{
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(color: fg),
                          children: [
                            TextSpan(
                              text: stock.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const TextSpan(text: ' syringes in stock'),
                          ],
                        ),
                      ),
                    ),
                  },
                  if (threshold != null) ...{
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: fg.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(text: 'Alert at '),
                            TextSpan(
                              text: threshold.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const TextSpan(text: ' syringes'),
                          ],
                        ),
                      ),
                    ),
                  },
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_expiry != null)
                  Text(
                    'Exp: ${MaterialLocalizations.of(context).formatCompactDate(_expiry!)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: fg),
                  ),
                if (_requiresFridge || _requiresFreezer || _protectLight) ...{
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_requiresFridge)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.ac_unit, size: 18, color: fg),
                        ),
                      if (_requiresFreezer)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.severe_cold, size: 18, color: fg),
                        ),
                      if (_protectLight)
                        Icon(Icons.light_mode_outlined, size: 18, color: fg),
                    ],
                  ),
                },
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildConcentrationVolumeStep();
      case 2:
        return _buildInventoryStep();
      case 3:
        return _buildStorageReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Enter the name and details of your medication',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          title: 'Details',
          children: [
            LabelFieldRow(
              label: 'Name *',
              field: Field36(
                child: TextField(
                  controller: _nameCtrl,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: buildFieldDecoration(
                    context,
                    hint: 'e.g., Insulin Glargine',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            buildHelperText(
              context,
              'Enter the medication name',
              fullWidth: true,
            ),
            LabelFieldRow(
              label: 'Manufacturer',
              field: Field36(
                child: TextField(
                  controller: _manufacturerCtrl,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: buildFieldDecoration(
                    context,
                    hint: 'e.g., Sanofi',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            buildHelperText(
              context,
              'Brand or company name (optional)',
              fullWidth: true,
            ),
            LabelFieldRow(
              label: 'Description',
              field: TextField(
                controller: _descriptionCtrl,
                style: Theme.of(context).textTheme.bodyMedium,
                minLines: 2,
                maxLines: 3,
                decoration: buildFieldDecoration(
                  context,
                  hint: 'Notes or description',
                ),
              ),
            ),
            buildHelperText(
              context,
              'Optional notes about this medication',
              fullWidth: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConcentrationVolumeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Concentration & Volume', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Enter the medication concentration and syringe volume',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          title: 'Medication Details',
          children: [
            LabelFieldRow(
              label: 'Concentration *',
              field: StepperRow36(
                controller: _concentrationValueCtrl,
                onDec: () {
                  final v =
                      int.tryParse(_concentrationValueCtrl.text.trim()) ?? 0;
                  setState(
                    () => _concentrationValueCtrl.text =
                        (v - 1).clamp(0, 1000000).toString(),
                  );
                },
                onInc: () {
                  final v =
                      int.tryParse(_concentrationValueCtrl.text.trim()) ?? 0;
                  setState(
                    () => _concentrationValueCtrl.text =
                        (v + 1).clamp(0, 1000000).toString(),
                  );
                },
                decoration: buildCompactFieldDecoration(
                  context: context,
                  hint: '0',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            LabelFieldRow(
              label: 'Unit *',
              field: SmallDropdown36<Unit>(
                value: _concentrationUnit,
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
                ],
                onChanged: (v) =>
                    setState(() => _concentrationUnit = v ?? Unit.mg),
              ),
            ),
            buildHelperText(
              context,
              'Active ingredient amount per syringe',
              fullWidth: true,
            ),
            LabelFieldRow(
              label: 'Volume *',
              field: StepperRow36(
                controller: _volumeValueCtrl,
                onDec: () {
                  final v = double.tryParse(_volumeValueCtrl.text.trim()) ?? 0;
                  setState(
                    () => _volumeValueCtrl.text =
                        (v - 0.1).clamp(0, 1000000).toStringAsFixed(1),
                  );
                },
                onInc: () {
                  final v = double.tryParse(_volumeValueCtrl.text.trim()) ?? 0;
                  setState(
                    () => _volumeValueCtrl.text =
                        (v + 0.1).clamp(0, 1000000).toStringAsFixed(1),
                  );
                },
                decoration: buildCompactFieldDecoration(
                  context: context,
                  hint: '0.0',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              ),
            ),
            LabelFieldRow(
              label: 'Volume Unit *',
              field: SmallDropdown36<VolumeUnit>(
                value: _volumeUnit,
                items: const [
                  DropdownMenuItem(
                    value: VolumeUnit.ml,
                    child: Center(child: Text('ml')),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _volumeUnit = v ?? VolumeUnit.ml),
              ),
            ),
            buildHelperText(
              context,
              'Total volume in the pre-filled syringe',
              fullWidth: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Inventory', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Track your syringe inventory and set low stock alerts',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          title: 'Stock Management',
          children: [
            LabelFieldRow(
              label: 'Current stock',
              field: StepperRow36(
                controller: _stockValueCtrl,
                onDec: () {
                  final v = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
                  setState(
                    () => _stockValueCtrl.text =
                        (v - 1).clamp(0, 1000000).toString(),
                  );
                },
                onInc: () {
                  final v = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
                  setState(
                    () => _stockValueCtrl.text =
                        (v + 1).clamp(0, 1000000).toString(),
                  );
                },
                decoration: buildCompactFieldDecoration(
                  context: context,
                  hint: '0',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            buildHelperText(
              context,
              'Number of pre-filled syringes you currently have',
              fullWidth: true,
            ),
            LabelFieldRow(
              label: 'Low stock alert',
              field: Row(
                children: [
                  Checkbox(
                    value: _lowStockEnabled,
                    onChanged: (v) =>
                        setState(() => _lowStockEnabled = v ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'Alert when stock is low',
                      style: checkboxLabelStyle(context),
                    ),
                  ),
                ],
              ),
            ),
            if (_lowStockEnabled) ...{
              LabelFieldRow(
                label: 'Threshold',
                field: StepperRow36(
                  controller: _lowStockThresholdCtrl,
                  onDec: () {
                    final v =
                        int.tryParse(_lowStockThresholdCtrl.text.trim()) ?? 0;
                    setState(
                      () => _lowStockThresholdCtrl.text =
                          (v - 1).clamp(0, 1000000).toString(),
                    );
                  },
                  onInc: () {
                    final v =
                        int.tryParse(_lowStockThresholdCtrl.text.trim()) ?? 0;
                    final stock = int.tryParse(_stockValueCtrl.text.trim()) ??
                        1000000;
                    final newVal = (v + 1).clamp(0, stock);
                    setState(
                      () => _lowStockThresholdCtrl.text = newVal.toString(),
                    );
                    if (newVal == stock && (v + 1) > stock) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Threshold cannot exceed current stock ($stock syringes)',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  decoration: buildCompactFieldDecoration(
                    context: context,
                    hint: '0',
                  ),
                  compact: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            },
            buildHelperText(
              context,
              _lowStockEnabled
                  ? 'Alert when syringes drop to this level'
                  : 'Enable to set a threshold',
              fullWidth: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStorageReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Storage & Review', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Set expiry date and storage conditions, then review before saving',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          title: 'Expiry & Storage',
          children: [
            LabelFieldRow(
              label: 'Expiry date',
              field: DateButton36(
                label: _expiry == null
                    ? 'Select date'
                    : MaterialLocalizations.of(context)
                        .formatCompactDate(_expiry!),
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: now,
                    lastDate: DateTime(now.year + 10),
                    initialDate: _expiry ?? now.add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _expiry = picked);
                  }
                },
                width: kSmallControlWidth,
                selected: _expiry != null,
              ),
            ),
            buildHelperText(
              context,
              'When do the syringes expire?',
              fullWidth: true,
            ),
            LabelFieldRow(
              label: 'Batch No.',
              field: Field36(
                child: TextField(
                  controller: _batchCtrl,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: buildFieldDecoration(context, hint: 'Optional'),
                ),
              ),
            ),
            buildHelperText(
              context,
              'Batch number from the packaging',
              fullWidth: true,
            ),
            LabelFieldRow(
              label: 'Storage location',
              field: Field36(
                child: TextField(
                  controller: _storageLocationCtrl,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: buildFieldDecoration(
                    context,
                    hint: 'e.g., Refrigerator',
                  ),
                ),
              ),
            ),
            buildHelperText(
              context,
              'Where you keep the syringes',
              fullWidth: true,
            ),
            LabelFieldRow(
              label: 'Storage conditions',
              field: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _requiresFridge,
                        onChanged: (v) => setState(() {
                          _requiresFridge = v ?? false;
                          if (_requiresFridge) _requiresFreezer = false;
                        }),
                      ),
                      Expanded(
                        child: Text(
                          'Refrigerate (2-8°C)',
                          style: checkboxLabelStyle(context),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _requiresFreezer,
                        onChanged: (v) => setState(() {
                          _requiresFreezer = v ?? false;
                          if (_requiresFreezer) _requiresFridge = false;
                        }),
                      ),
                      Expanded(
                        child: Text(
                          'Freeze',
                          style: checkboxLabelStyle(context),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _protectLight,
                        onChanged: (v) =>
                            setState(() => _protectLight = v ?? false),
                      ),
                      Expanded(
                        child: Text(
                          'Protect from Light',
                          style: checkboxLabelStyle(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            buildHelperText(
              context,
              'Select all conditions that apply',
              fullWidth: true,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<void> saveMedication() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Save'),
        content: Text(
          widget.initial == null
              ? 'Save this medication to your inventory?'
              : 'Update this medication?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(medicationRepositoryProvider);
    final id = widget.initial?.id ?? _newId();
    final concentration =
        double.tryParse(_concentrationValueCtrl.text.trim()) ?? 0;
    final volume = double.tryParse(_volumeValueCtrl.text.trim()) ?? 0;
    final stock = double.tryParse(_stockValueCtrl.text.trim()) ?? 0;
    final previous = widget.initial;
    final initialStock = previous == null
        ? stock
        : (stock > previous.stockValue
            ? stock
            : (previous.initialStockValue ?? previous.stockValue));

    final storageInstructions = [
      if (_requiresFridge) 'Refrigerate (2-8°C)',
      if (_requiresFreezer) 'Keep frozen',
      if (_protectLight) 'Protect from light',
    ].join('. ');

    final med = Medication(
      id: id,
      form: MedicationForm.prefilledSyringe,
      name: _nameCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty
          ? null
          : _manufacturerCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      strengthValue: concentration,
      strengthUnit: _concentrationUnit,
      volumePerDose: volume,
      volumeUnit: _volumeUnit,
      stockValue: stock,
      stockUnit: StockUnit.syringes,
      initialStockValue: initialStock,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: _lowStockEnabled
          ? double.tryParse(_lowStockThresholdCtrl.text.trim())
          : null,
      expiry: _expiry,
      batchNumber:
          _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
      storageLocation: _storageLocationCtrl.text.trim().isEmpty
          ? null
          : _storageLocationCtrl.text.trim(),
      requiresRefrigeration: _requiresFridge,
      storageInstructions:
          storageInstructions.isEmpty ? null : storageInstructions,
    );

    await repo.saveMedication(med);

    if (mounted) {
      context.pop();
    }
  }

  String _newId() => DateTime.now().millisecondsSinceEpoch.toString();
}
