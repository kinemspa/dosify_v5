// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/app/app_navigator.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/core/utils/id.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_wizard_base.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/missing_required_fields_card.dart';
import 'package:dosifi_v5/src/widgets/wizard_text_field36.dart';
import 'package:dosifi_v5/src/widgets/smart_expiry_picker.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// Wizard-style Tablet add/edit screen with step-by-step flow
class AddTabletWizardPage extends MedicationWizardBase {
  const AddTabletWizardPage({
    super.key,
    super.initial,
    super.initialMedicationId,
  });

  @override
  int get stepCount => 5;

  @override
  List<String> get stepLabels => [
    'STEP 1: BASIC INFORMATION',
    'STEP 2: STRENGTH & DOSAGE',
    'STEP 3: INVENTORY',
    'STEP 4: STORAGE',
    'STEP 5: REVIEW & CONFIRM',
  ];

  @override
  ConsumerState<AddTabletWizardPage> createState() =>
      _AddTabletWizardPageState();
}

class _AddTabletWizardPageState
    extends MedicationWizardState<AddTabletWizardPage> {
  Medication? _resolvedInitial;

  Medication? _effectiveInitial() {
    if (widget.initial != null) return widget.initial;
    final id = widget.initialMedicationId;
    if (id == null) return null;
    _resolvedInitial ??= Hive.box<Medication>('medications').get(id);
    return _resolvedInitial;
  }

  // Step 1: Basic Info
  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // Step 2: Strength
  final _strengthValueCtrl = TextEditingController(text: '0');
  Unit _strengthUnit = Unit.mg;

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
    final m = _effectiveInitial();
    if (m != null) {
      _nameCtrl.text = m.name;
      _manufacturerCtrl.text = m.manufacturer ?? '';
      _descriptionCtrl.text = m.description ?? '';
      _strengthValueCtrl.text = m.strengthValue.toString();
      _strengthUnit = m.strengthUnit;
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
    } else {
      _expiry = DateTime.now().add(
        const Duration(days: kDefaultTabletCapsuleExpiryDays),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _strengthValueCtrl.dispose();
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
      case 1: // Strength
        final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
        return strength > 0;
      case 2: // Inventory
        return true; // Optional
      case 3: // Storage
        return true;
      case 4: // Review
        return _missingRequiredForSave().isEmpty;
      default:
        return false;
    }
  }

  List<String> _missingRequiredForSave() {
    final missing = <String>[];
    if (_nameCtrl.text.trim().isEmpty) missing.add('Name');
    final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
    if (strength <= 0) missing.add('Strength');
    return missing;
  }

  @override
  String getStepLabel(int step) => widget.stepLabels[step];

  @override
  Widget buildSummaryContent() {
    final name = _nameCtrl.text.trim();
    final manufacturer = _manufacturerCtrl.text.trim();
    final strengthVal = double.tryParse(_strengthValueCtrl.text.trim());
    final stock = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
    final threshold = _lowStockEnabled
        ? int.tryParse(_lowStockThresholdCtrl.text.trim())
        : null;
    final headerTitle = name.isEmpty ? 'Tablet' : name;
    final theme = Theme.of(context);
    final fg = medicationDetailHeaderForegroundColor(context);

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
              child: Icon(Icons.medication, color: fg),
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
                  if (strengthVal != null && strengthVal > 0) ...{
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(color: fg),
                        children: [
                          TextSpan(
                            text: strengthVal == strengthVal.roundToDouble()
                                ? strengthVal.toStringAsFixed(0)
                                : strengthVal.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' ${_strengthUnit.name}'),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(text: ' tablets in stock'),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' tablets'),
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
        return _buildStrengthStep();
      case 2:
        return _buildInventoryStep();
      case 3:
        return _buildStorageStep();
      case 4:
        return _buildReviewStep();
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
          neutral: true,
          title: 'Details',
          children: [
            LabelFieldRow(
              label: 'Name *',
              field: WizardTextField36(
                controller: _nameCtrl,
                hint: 'e.g., Example medication',
                onChanged: (_) => setState(() {}),
              ),
            ),
            buildHelperText(
              context,
              'Enter the medication name',
              fullWidth: true,
            ),
            LabelFieldRow(
              label: 'Manufacturer',
              field: WizardTextField36(
                controller: _manufacturerCtrl,
                hint: 'e.g., PharmaInc',
                onChanged: (_) => setState(() {}),
              ),
            ),
            buildHelperText(
              context,
              'Brand or company name (optional)',
              fullWidth: true,
            ),
            LabelFieldRow(
              label: 'Description',
              field: WizardTextField36(
                controller: _descriptionCtrl,
                hint: 'Notes or description',
                minLines: 2,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
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

  Widget _buildStrengthStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Strength & Dosage', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Enter the active ingredient amount per tablet',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          neutral: true,
          title: 'Medication Strength',
          children: [
            LabelFieldRow(
              label: 'Strength *',
              field: StepperRow36(
                controller: _strengthValueCtrl,
                onChanged: (_) => setState(() {}),
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
                ],
                onChanged: (v) => setState(() => _strengthUnit = v ?? Unit.mg),
              ),
            ),
            buildHelperText(
              context,
              'Enter the active ingredient amount per tablet (usually printed on packaging)',
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
          'Track your tablet inventory and set low stock alerts',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          neutral: true,
          title: 'Stock Management',
          children: [
            LabelFieldRow(
              label: 'Current stock',
              field: StepperRow36(
                controller: _stockValueCtrl,
                onDec: () {
                  final v = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
                  setState(
                    () => _stockValueCtrl.text = (v - 1)
                        .clamp(0, 1000000)
                        .toString(),
                  );
                },
                onInc: () {
                  final v = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
                  setState(
                    () => _stockValueCtrl.text = (v + 1)
                        .clamp(0, 1000000)
                        .toString(),
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
              'Number of tablets you currently have',
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
                      () => _lowStockThresholdCtrl.text = (v - 1)
                          .clamp(0, 1000000)
                          .toString(),
                    );
                  },
                  onInc: () {
                    final v =
                        int.tryParse(_lowStockThresholdCtrl.text.trim()) ?? 0;
                    final stock =
                        int.tryParse(_stockValueCtrl.text.trim()) ?? 1000000;
                    final newVal = (v + 1).clamp(0, stock);
                    setState(
                      () => _lowStockThresholdCtrl.text = newVal.toString(),
                    );
                    if (newVal == stock && (v + 1) > stock) {
                      showAppSnackBar(
                        context,
                        'Threshold cannot exceed current stock ($stock tablets)',
                        duration: kAppSnackBarDurationShort,
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
                  ? 'Alert when tablets drop to this level'
                  : 'Enable to set a threshold',
              fullWidth: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStorageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Storage', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Set expiry date and storage conditions',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          neutral: true,
          title: 'Expiry & Storage',
          children: [
            LabelFieldRow(
              label: 'Expiry date',
              field: DateButton36(
                label: _expiry == null
                    ? 'Select date'
                    : MaterialLocalizations.of(
                        context,
                      ).formatCompactDate(_expiry!),
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await SmartExpiryPicker.show(
                    context,
                    firstDate: now,
                    lastDate: DateTime(now.year + 10),
                    initialDate:
                        _expiry ??
                        now.add(
                          const Duration(days: kDefaultTabletCapsuleExpiryDays),
                        ),
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
              'When do the tablets expire?',
              fullWidth: true,
            ),
            LabelFieldRow(
              label: 'Batch No.',
              field: Field36(
                child: TextField(
                  controller: _batchCtrl,
                  textCapitalization: kTextCapitalizationDefault,
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
                  textCapitalization: kTextCapitalizationDefault,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: buildFieldDecoration(
                    context,
                    hint: 'e.g., Medicine cabinet',
                  ),
                ),
              ),
            ),
            buildHelperText(
              context,
              'Where you keep the tablets',
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Save'),
        content: Text(
          !widget.isEditing
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

    if (confirmed == false) return;

    final repo = ref.read(medicationRepositoryProvider);
    final initial = _effectiveInitial();
    final id = initial?.id ?? _newId();
    final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
    final stock = double.tryParse(_stockValueCtrl.text.trim()) ?? 0;
    final previous = initial;
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
      form: MedicationForm.tablet,
      name: _nameCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty
          ? null
          : _manufacturerCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      strengthValue: strength,
      strengthUnit: _strengthUnit,
      stockValue: stock,
      stockUnit: StockUnit.tablets,
      initialStockValue: initialStock,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: _lowStockEnabled
          ? double.tryParse(_lowStockThresholdCtrl.text.trim())
          : null,
      expiry: _expiry,
      batchNumber: _batchCtrl.text.trim().isEmpty
          ? null
          : _batchCtrl.text.trim(),
      storageLocation: _storageLocationCtrl.text.trim().isEmpty
          ? null
          : _storageLocationCtrl.text.trim(),
      requiresRefrigeration: _requiresFridge,
      storageInstructions: storageInstructions.isEmpty
          ? null
          : storageInstructions,
    );

    try {
      await repo.upsert(med);
      if (mounted) {
        showAppSnackBar(context, 'Medication saved');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          goToMedications(context);
        });
      }
    } catch (e, stack) {
      debugPrint('AddTabletWizardPage: save failed: $e\n$stack');
      if (mounted) {
        showAppSnackBar(context, 'Error saving: $e');
      }
    }
  }

  String _newId() => IdGen.newId(prefix: 'med');

  Widget _buildReviewStep() {
    final missing = _missingRequiredForSave();
    final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
    final stock = double.tryParse(_stockValueCtrl.text.trim()) ?? 0;
    final threshold = _lowStockEnabled
        ? double.tryParse(_lowStockThresholdCtrl.text.trim())
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & Confirm', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Please review all information before saving',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        if (missing.isNotEmpty) ...[
          MissingRequiredFieldsCard(
            fields: missing,
            title: 'Required info missing',
            message: 'Go back and fill the required fields (*) before saving.',
          ),
          const SizedBox(height: kSpacingM),
        ],
        SectionFormCard(
          neutral: true,
          title: 'Medication Details',
          titleStyle: reviewCardTitleStyle(context),
          children: [
            _reviewRow('Name', _nameCtrl.text.trim()),
            _reviewRow('Type', 'Tablet'),
            _reviewRow('Manufacturer', _manufacturerCtrl.text.trim()),
            _reviewRow('Description', _descriptionCtrl.text.trim()),
          ],
        ),
        const SizedBox(height: 12),
        SectionFormCard(
          neutral: true,
          title: 'Strength',
          titleStyle: reviewCardTitleStyle(context),
          children: [
            _reviewRow(
              'Active Ingredient',
              '${fmt2(strength)} ${_strengthUnit.name}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionFormCard(
          neutral: true,
          title: 'Inventory',
          titleStyle: reviewCardTitleStyle(context),
          children: [
            _reviewRow('Current Stock', '${fmt2(stock)} tablets'),
            _reviewRow(
              'Low Stock Alert',
              !_lowStockEnabled
                  ? 'Disabled'
                  : (threshold == null
                        ? 'Enabled'
                        : 'Enabled at ${fmt2(threshold)} tablets'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionFormCard(
          neutral: true,
          title: 'Storage',
          titleStyle: reviewCardTitleStyle(context),
          children: [
            if (_expiry != null)
              _reviewRow(
                'Expiry Date',
                MaterialLocalizations.of(context).formatCompactDate(_expiry!),
              ),
            _reviewRow('Batch Number', _batchCtrl.text.trim()),
            _reviewRow('Storage Location', _storageLocationCtrl.text.trim()),
            if (_requiresFridge)
              _reviewRow('Refrigeration', 'Required (2-8°C)'),
            if (_requiresFreezer) _reviewRow('Storage', 'Freezer'),
            if (_protectLight)
              _reviewRow('Light Sensitivity', 'Protect from light'),
          ],
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: reviewRowLabelStyle(context)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: bodyTextStyle(context))),
        ],
      ),
    );
  }
}
