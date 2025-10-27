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
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// Wizard-style MDV add screen with clear step-by-step flow
class AddMdvWizardPage extends ConsumerStatefulWidget {
  const AddMdvWizardPage({super.key, this.initial});

  final Medication? initial;

  @override
  ConsumerState<AddMdvWizardPage> createState() => _AddMdvWizardPageState();
}

class _AddMdvWizardPageState extends ConsumerState<AddMdvWizardPage> {
  int _currentStep = 0;

  // Step 1: Basic Info
  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // Step 2: Strength & Reconstitution
  final _strengthValueCtrl = TextEditingController(text: '0');
  Unit _strengthUnit = Unit.mg;
  final _perMlCtrl = TextEditingController();
  final _vialVolumeCtrl = TextEditingController(text: '0');
  ReconstitutionResult? _reconResult;

  // Step 3: Initial Stock (Sealed Vials)
  final _stockValueCtrl = TextEditingController(text: '0');
  bool _lowStockEnabled = false;
  final _lowStockCtrl = TextEditingController(text: '0');
  DateTime? _expiry;
  final _batchCtrl = TextEditingController();

  // Step 4: Storage
  final _storageCtrl = TextEditingController();
  String? _storageCondition = 'room_temp';

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
      _strengthValueCtrl.text = m.strengthValue.toString();
      _strengthUnit = m.strengthUnit;
      _perMlCtrl.text = m.perMlValue?.toString() ?? '';
      _vialVolumeCtrl.text = m.containerVolumeMl?.toString() ?? '0';
      _stockValueCtrl.text = m.stockValue.toString();
      _lowStockEnabled = m.lowStockEnabled;
      _lowStockCtrl.text = m.lowStockThreshold?.toString() ?? '0';
      _expiry = m.backupVialsExpiry ?? m.expiry;
      _batchCtrl.text = m.backupVialsBatchNumber ?? m.batchNumber ?? '';
      _storageCtrl.text =
          m.backupVialsStorageLocation ?? m.storageLocation ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _strengthValueCtrl.dispose();
    _stockValueCtrl.dispose();
    _lowStockCtrl.dispose();
    _batchCtrl.dispose();
    _storageCtrl.dispose();
    _perMlCtrl.dispose();
    _vialVolumeCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0: // Basic Info
        return _nameCtrl.text.trim().isNotEmpty;
      case 1: // Strength & Reconstitution
        final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
        return strength > 0;
      case 2: // Initial Stock
        return true; // Optional
      case 3: // Storage
        return true; // Optional
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceed && _currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
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
      form: MedicationForm.injectionMultiDoseVial,
      name: _nameCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty
          ? null
          : _manufacturerCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      notes: null,
      strengthValue: strength,
      strengthUnit: _strengthUnit,
      perMlValue: _perMlCtrl.text.isNotEmpty
          ? double.tryParse(_perMlCtrl.text.trim())
          : null,
      stockValue: stock,
      stockUnit: StockUnit.multiDoseVials,
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
      requiresRefrigeration: _storageCondition == 'refrigerated',
      storageInstructions: _buildStorageInstructions(),
      containerVolumeMl: _vialVolumeCtrl.text.isNotEmpty
          ? double.tryParse(_vialVolumeCtrl.text.trim())
          : null,
      initialStockValue: initialStock,
      backupVialsBatchNumber: _batchCtrl.text.trim().isEmpty
          ? null
          : _batchCtrl.text.trim(),
      backupVialsStorageLocation: _storageCtrl.text.trim().isEmpty
          ? null
          : _storageCtrl.text.trim(),
      backupVialsRequiresRefrigeration: _storageCondition == 'refrigerated',
      backupVialsRequiresFreezer: _storageCondition == 'frozen',
      backupVialsLightSensitive: _storageCondition == 'protect_light',
      backupVialsExpiry: _expiry,
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
    if (_storageCondition == 'frozen') parts.add('Keep frozen');
    if (_storageCondition == 'protect_light') parts.add('Protect from light');
    return parts.isEmpty ? null : parts.join('. ');
  }

  String _newId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return 'med_$ms';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null
            ? 'Add Multi-Dose Vial'
            : 'Edit Multi-Dose Vial',
        forceBackButton: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildStepIndicator(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: kPagePadding,
              child: _buildStepContent(),
            ),
          ),

          // Navigation buttons
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++) ...[
            _StepCircle(
              number: i + 1,
              isActive: i == _currentStep,
              isCompleted: i < _currentStep,
            ),
            if (i < 3)
              Expanded(
                child: Container(
                  height: 2,
                  color: i < _currentStep
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildStrengthReconStep();
      case 2:
        return _buildInitialStockStep();
      case 3:
        return _buildStorageStep();
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
          neutral: true,
          children: [
            LabelFieldRow(
              label: 'Name *',
              field: Field36(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: buildFieldDecoration(
                    context,
                    hint: 'e.g., Insulin',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            buildHelperText(context, 'Enter the medication name'),
            LabelFieldRow(
              label: 'Manufacturer',
              field: Field36(
                child: TextField(
                  controller: _manufacturerCtrl,
                  decoration: buildFieldDecoration(
                    context,
                    hint: 'e.g., NovoNordisk',
                  ),
                ),
              ),
            ),
            buildHelperText(context, 'Brand or company name (optional)'),
            LabelFieldRow(
              label: 'Description',
              field: TextField(
                controller: _descriptionCtrl,
                minLines: 2,
                maxLines: 3,
                decoration: buildFieldDecoration(
                  context,
                  hint: 'Notes or description',
                ),
              ),
            ),
            buildHelperText(context, 'Optional notes about this medication'),
          ],
        ),
      ],
    );
  }

  Widget _buildStrengthReconStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Strength & Reconstitution', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Multi-dose vials require reconstitution (mixing with liquid). Enter the strength and use our calculator to find the right mix.',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          title: 'Medication Strength',
          neutral: true,
          children: [
            LabelFieldRow(
              label: 'Strength *',
              field: StepperRow36(
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
                decoration: buildCompactFieldDecoration(
                  context: context,
                  hint: '0',
                ),
              ),
            ),
            LabelFieldRow(
              label: 'Unit *',
              field: SmallDropdown36<Unit>(
                value: _strengthUnit,
                items: const [
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
              'Total drug amount in the vial BEFORE mixing with liquid',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ReconstitutionInfoCard(
          onCalculate: () async {
            final result = await showDialog<ReconstitutionResult>(
              context: context,
              builder: (context) => ReconstitutionCalculatorDialog(
                initialStrengthValue:
                    double.tryParse(_strengthValueCtrl.text.trim()) ?? 0,
                unitLabel: _strengthUnit.name,
              ),
            );
            if (result != null) {
              setState(() {
                _reconResult = result;
                _vialVolumeCtrl.text = result.solventVolumeMl.toString();
                _perMlCtrl.text = result.perMlConcentration.toString();
              });
            }
          },
          result: _reconResult,
        ),
      ],
    );
  }

  Widget _buildInitialStockStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Initial Stock', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          'How many sealed (unopened) vials do you have right now?',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          title: 'Sealed Vials',
          neutral: true,
          children: [
            LabelFieldRow(
              label: 'Quantity',
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
              ),
            ),
            buildHelperText(context, 'Number of sealed, unopened vials'),
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
            if (_lowStockEnabled) ...[
              LabelFieldRow(
                label: 'Threshold',
                field: StepperRow36(
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
                ),
              ),
            ],
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
            buildHelperText(context, 'When do sealed vials expire?'),
            LabelFieldRow(
              label: 'Batch No.',
              field: Field36(
                child: TextField(
                  controller: _batchCtrl,
                  decoration: buildFieldDecoration(context, hint: 'Optional'),
                ),
              ),
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
          'Where do you store your sealed vials?',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          title: 'Storage Location',
          neutral: true,
          children: [
            LabelFieldRow(
              label: 'Location',
              field: Field36(
                child: TextField(
                  controller: _storageCtrl,
                  decoration: buildFieldDecoration(
                    context,
                    hint: 'e.g., Fridge, Medicine cabinet',
                  ),
                ),
              ),
            ),
            buildHelperText(context, 'Where you keep unopened vials'),
            LabelFieldRow(
              label: 'Condition',
              field: Field36(
                child: DropdownButtonFormField<String>(
                  value: _storageCondition,
                  decoration: buildFieldDecoration(context, hint: 'Select'),
                  items: const [
                    DropdownMenuItem(
                      value: 'room_temp',
                      child: Text('Room Temperature'),
                    ),
                    DropdownMenuItem(
                      value: 'refrigerated',
                      child: Text('Refrigerated (2-8°C)'),
                    ),
                    DropdownMenuItem(value: 'frozen', child: Text('Frozen')),
                    DropdownMenuItem(
                      value: 'protect_light',
                      child: Text('Protect from Light'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _storageCondition = v),
                ),
              ),
            ),
            buildHelperText(context, 'Storage temperature requirements'),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _canProceed
                  ? (_currentStep < 3 ? _nextStep : _saveMedication)
                  : null,
              child: Text(_currentStep < 3 ? 'Continue' : 'Save Medication'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.number,
    required this.isActive,
    required this.isCompleted,
  });

  final int number;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? cs.primary
            : cs.surfaceContainerHighest,
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, size: 16, color: cs.onPrimary)
            : Text(
                number.toString(),
                style: bodyTextStyle(context)?.copyWith(
                  fontWeight: kFontWeightBold,
                  color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class _ReconstitutionInfoCard extends StatelessWidget {
  const _ReconstitutionInfoCard({required this.onCalculate, this.result});

  final VoidCallback onCalculate;
  final ReconstitutionResult? result;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reconstitution Calculator',
                style: bodyTextStyle(context)?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: kFontWeightBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result == null
                ? 'Multi-dose vials need to be mixed with liquid (reconstituted). Use our calculator to find the perfect ratio.'
                : 'Reconstitution calculated! Add ${result!.solventVolumeMl} mL solvent to vial',
            style: mutedTextStyle(
              context,
            )?.copyWith(color: Colors.white.withOpacity(0.75)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCalculate,
              icon: const Icon(Icons.science),
              label: Text(result == null ? 'Open Calculator' : 'Recalculate'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
