// Flutter imports:
// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/saved_reconstitution_sheet.dart';
import 'package:dosifi_v5/src/widgets/smart_expiry_picker.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/wizard_navigation_bar.dart';
import 'package:flutter/material.dart';
// Package imports:
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Wizard-style MDV add screen with clear step-by-step flow
class AddMdvWizardPage extends ConsumerStatefulWidget {
  const AddMdvWizardPage({super.key, this.initial});

  final Medication? initial;

  @override
  ConsumerState<AddMdvWizardPage> createState() => _AddMdvWizardPageState();
}

class _AddMdvWizardPageState extends ConsumerState<AddMdvWizardPage> {
  int _currentStep = 0;
  final _scrollController = ScrollController();

  final SavedReconstitutionRepository _savedReconRepo =
      SavedReconstitutionRepository();

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

  // Step 3: Reconstituted Vial Details
  final _activeVialVolumeMlCtrl = TextEditingController();
  final _activeVialLowStockMlCtrl = TextEditingController(text: '1.0');
  bool _activeVialLowStockEnabled = false; // Default OFF
  DateTime? _activeVialExpiry;
  final _activeVialStorageCtrl = TextEditingController();
  bool _activeVialRequiresFridge = false;
  bool _activeVialRequiresFreezer = false;
  bool _activeVialProtectLight = false;

  // Step 4: Sealed Inventory (Optional)
  bool _hasBackupVials = false;
  final _backupVialsQtyCtrl = TextEditingController(text: '0');
  bool _backupVialsLowStockEnabled = false;
  final _backupVialsLowStockCtrl = TextEditingController(text: '0');
  DateTime? _backupVialsExpiry;
  final _backupVialsBatchCtrl = TextEditingController();
  final _backupVialsStorageCtrl = TextEditingController();
  bool _backupVialsRequiresFridge = false;
  bool _backupVialsRequiresFreezer = false;
  bool _backupVialsProtectLight = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Listen to vial volume changes to update saved reconstitution
    _vialVolumeCtrl.addListener(_onVialVolumeChanged);
  }

  void _onVialVolumeChanged() {
    if (_reconResult != null) {
      final newVolume = double.tryParse(_vialVolumeCtrl.text.trim());
      if (newVolume != null && newVolume != _reconResult!.solventVolumeMl) {
        // Recalculate concentration based on new volume
        final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
        final newConcentration = strength > 0 && newVolume > 0
            ? strength / newVolume
            : _reconResult!.perMlConcentration;

        // Update the reconstitution result with new volume and concentration
        setState(() {
          _reconResult = ReconstitutionResult(
            perMlConcentration: newConcentration,
            solventVolumeMl: newVolume,
            recommendedUnits: _reconResult!.recommendedUnits,
            syringeSizeMl: _reconResult!.syringeSizeMl,
            diluentName: _reconResult!.diluentName,
            recommendedDose: _reconResult!.recommendedDose,
            doseUnit: _reconResult!.doseUnit,
            maxVialSizeMl: _reconResult!.maxVialSizeMl,
          );
          // Update the per mL display
          _perMlCtrl.text = newConcentration.toStringAsFixed(2);
        });
      }
    }
  }

  Unit _unitFromName(String name) {
    for (final unit in Unit.values) {
      if (unit.name == name) return unit;
    }
    return Unit.mg;
  }

  Future<void> _useSavedReconstitution() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final height = MediaQuery.of(context).size.height;
        return SizedBox(
          height: height * 0.8,
          child: SavedReconstitutionSheet(
            repo: _savedReconRepo,
            onSelect: (item) {
              final result = ReconstitutionResult(
                perMlConcentration: item.perMlConcentration,
                solventVolumeMl: item.solventVolumeMl,
                recommendedUnits: item.recommendedUnits,
                syringeSizeMl: item.syringeSizeMl,
                diluentName: item.diluentName,
                recommendedDose: item.recommendedDose,
                doseUnit: item.doseUnit,
                maxVialSizeMl: item.maxVialSizeMl,
              );

              setState(() {
                _strengthValueCtrl.text =
                    item.strengthValue == item.strengthValue.roundToDouble()
                    ? item.strengthValue.toInt().toString()
                    : item.strengthValue.toStringAsFixed(2);
                _strengthUnit = _unitFromName(item.strengthUnit);

                _reconResult = result;
                _vialVolumeCtrl.text = result.solventVolumeMl.toStringAsFixed(
                  2,
                );
                _perMlCtrl.text = result.perMlConcentration.toString();
                _activeVialVolumeMlCtrl.text = result.solventVolumeMl
                    .toStringAsFixed(2);
              });

              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
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

      // Reconstituted Vial
      _activeVialVolumeMlCtrl.text = m.containerVolumeMl?.toString() ?? '0';
      _activeVialLowStockMlCtrl.text =
          m.activeVialLowStockMl?.toString() ?? '1.0';
      _activeVialLowStockEnabled = m.activeVialLowStockMl != null;
      _activeVialExpiry = m.reconstitutedVialExpiry;
      _activeVialStorageCtrl.text = m.activeVialStorageLocation ?? '';
      _activeVialRequiresFridge = m.activeVialRequiresRefrigeration;
      _activeVialRequiresFreezer = m.activeVialRequiresFreezer;
      _activeVialProtectLight = m.activeVialLightSensitive;

      // Backup vials
      _hasBackupVials = m.stockValue > 0;
      _backupVialsQtyCtrl.text = m.stockValue.toString();
      _backupVialsLowStockEnabled = m.lowStockEnabled;
      _backupVialsLowStockCtrl.text = m.lowStockThreshold?.toString() ?? '0';
      _backupVialsExpiry = m.backupVialsExpiry ?? m.expiry;
      _backupVialsBatchCtrl.text =
          m.backupVialsBatchNumber ?? m.batchNumber ?? '';
      _backupVialsStorageCtrl.text =
          m.backupVialsStorageLocation ?? m.storageLocation ?? '';
      _backupVialsRequiresFridge = m.backupVialsRequiresRefrigeration;
      _backupVialsRequiresFreezer = m.backupVialsRequiresFreezer;
      _backupVialsProtectLight = m.backupVialsLightSensitive;
    }
  }

  @override
  void dispose() {
    _vialVolumeCtrl.removeListener(_onVialVolumeChanged);
    _scrollController.dispose();
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _strengthValueCtrl.dispose();
    _perMlCtrl.dispose();
    _vialVolumeCtrl.dispose();
    _activeVialVolumeMlCtrl.dispose();
    _activeVialLowStockMlCtrl.dispose();
    _activeVialStorageCtrl.dispose();
    _backupVialsQtyCtrl.dispose();
    _backupVialsLowStockCtrl.dispose();
    _backupVialsBatchCtrl.dispose();
    _backupVialsStorageCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0: // Basic Info
        return _nameCtrl.text.trim().isNotEmpty;
      case 1: // Strength & Reconstitution
        final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
        final volume = double.tryParse(_vialVolumeCtrl.text.trim()) ?? 0;
        return strength > 0 && volume > 0;
      case 2: // Reconstituted Vial
        // Step 3 is always optional - user doesn't need to fill anything
        return true;
      case 3: // Sealed Inventory
        return true; // Optional
      case 4: // Review
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceed && _currentStep < 4) {
      setState(() => _currentStep++);
      // Scroll to top of next step
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveMedication() async {
    // Show confirmation dialog
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
    final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
    final backupStock = _hasBackupVials
        ? (double.tryParse(_backupVialsQtyCtrl.text.trim()) ?? 0.0)
        : 0.0;
    final previous = widget.initial;
    final initialStock = previous == null
        ? backupStock
        : (backupStock > previous.stockValue
              ? backupStock
              : (previous.initialStockValue ?? previous.stockValue));

    final med = Medication(
      id: id,
      form: MedicationForm.multiDoseVial,
      name: _nameCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty
          ? null
          : _manufacturerCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      strengthValue: strength,
      strengthUnit: _strengthUnit,
      perMlValue: _perMlCtrl.text.isNotEmpty
          ? double.tryParse(_perMlCtrl.text.trim())
          : null,
      // Backup vials stock
      stockValue: backupStock,
      stockUnit: StockUnit.multiDoseVials,
      lowStockEnabled: _hasBackupVials && _backupVialsLowStockEnabled,
      lowStockThreshold:
          _hasBackupVials &&
              _backupVialsLowStockEnabled &&
              _backupVialsLowStockCtrl.text.isNotEmpty
          ? double.tryParse(_backupVialsLowStockCtrl.text.trim())
          : null,
      expiry: _backupVialsExpiry,
      batchNumber:
          _hasBackupVials && _backupVialsBatchCtrl.text.trim().isNotEmpty
          ? _backupVialsBatchCtrl.text.trim()
          : null,
      storageLocation:
          _hasBackupVials && _backupVialsStorageCtrl.text.trim().isNotEmpty
          ? _backupVialsStorageCtrl.text.trim()
          : null,
      requiresRefrigeration: _hasBackupVials && _backupVialsRequiresFridge,
      // Total vial volume after reconstitution
      containerVolumeMl: _vialVolumeCtrl.text.isNotEmpty
          ? double.tryParse(_vialVolumeCtrl.text.trim())
          : null,
      initialStockValue: initialStock,
      activeVialVolume:
          previous?.activeVialVolume ??
          (_vialVolumeCtrl.text.isNotEmpty
              ? double.tryParse(_vialVolumeCtrl.text.trim())
              : null),
      // Reconstituted Vial fields
      activeVialLowStockMl:
          _activeVialLowStockEnabled &&
              _activeVialLowStockMlCtrl.text.isNotEmpty
          ? double.tryParse(_activeVialLowStockMlCtrl.text.trim())
          : null,
      activeVialStorageLocation: _activeVialStorageCtrl.text.trim().isEmpty
          ? null
          : _activeVialStorageCtrl.text.trim(),
      activeVialRequiresRefrigeration: _activeVialRequiresFridge,
      activeVialRequiresFreezer: _activeVialRequiresFreezer,
      activeVialLightSensitive: _activeVialProtectLight,
      reconstitutedVialExpiry: _activeVialExpiry,
      // Backup vials fields
      backupVialsBatchNumber:
          _hasBackupVials && _backupVialsBatchCtrl.text.trim().isNotEmpty
          ? _backupVialsBatchCtrl.text.trim()
          : null,
      backupVialsStorageLocation:
          _hasBackupVials && _backupVialsStorageCtrl.text.trim().isNotEmpty
          ? _backupVialsStorageCtrl.text.trim()
          : null,
      backupVialsRequiresRefrigeration:
          _hasBackupVials && _backupVialsRequiresFridge,
      backupVialsRequiresFreezer:
          _hasBackupVials && _backupVialsRequiresFreezer,
      backupVialsLightSensitive: _hasBackupVials && _backupVialsProtectLight,
      backupVialsExpiry: _hasBackupVials ? _backupVialsExpiry : null,
      diluentName: _reconResult?.diluentName,
    );

    await repo.upsert(med);
    if (!mounted) return;
    if (widget.initial != null) {
      context.pop();
    } else {
      context.go('/medications');
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Medication saved')));
  }

  String _newId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return 'med_$ms';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildUnifiedHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: kPagePadding,
              child: KeyedSubtree(
                key: ValueKey<int>(_currentStep),
                child: _buildStepContent(),
              ),
            ),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildUnifiedHeader() {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kMedicationDetailGradientStart,
            kMedicationDetailGradientEnd,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppBar Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.initial == null
                          ? 'Add Multi-Dose Vial'
                          : 'Edit Multi-Dose Vial',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance back button
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: keyboardOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Column(
                children: [
                  // Step indicator
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        for (int i = 0; i < 5; i++) ...[
                          _StepCircle(
                            number: i + 1,
                            isActive: i == _currentStep,
                            isCompleted: i < _currentStep,
                          ),
                          if (i < 4)
                            Expanded(
                              child: Container(
                                height: 1.5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: i < _currentStep
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onPrimary
                                            .withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  // Current step label
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      _getStepLabel(_currentStep),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Divider
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.15),
                  ),
                  // Summary content
                  Container(
                    constraints: const BoxConstraints(minHeight: 100),
                    padding: const EdgeInsets.all(12),
                    child: _buildSummaryContent(),
                  ),
                ],
              ),
              secondChild: Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepLabel(int step) {
    switch (step) {
      case 0:
        return 'STEP 1: BASIC INFORMATION';
      case 1:
        return 'STEP 2: STRENGTH & RECONSTITUTION';
      case 2:
        return 'STEP 3: RECONSTITUTED VIAL DETAILS';
      case 3:
        return 'STEP 4: SEALED INVENTORY (OPTIONAL)';
      case 4:
        return 'STEP 5: REVIEW & SAVE';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildStrengthReconStep();
      case 2:
        return _buildActiveVialStep();
      case 3:
        return _buildBackupInventoryStep();
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
          title: 'Details',
          neutral: true,
          children: [
            LabelFieldRow(
              label: 'Name *',
              field: Field36(
                child: TextField(
                  controller: _nameCtrl,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: buildFieldDecoration(
                    context,
                    hint: 'e.g., Peptide',
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
                    hint: 'e.g., BioTech',
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
              fullWidth: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ReconstitutionInfoCard(
          medicationName: _nameCtrl.text.trim(),
          onCalculate: () async {
            final strength =
                double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
            if (strength <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter medication strength first'),
                ),
              );
              return;
            }
            // Determine initial syringe size from saved result
            SyringeSizeMl? initialSyringe;
            if (_reconResult != null) {
              final savedSizeMl = _reconResult!.syringeSizeMl;
              if (savedSizeMl == 0.3) {
                initialSyringe = SyringeSizeMl.ml0_3;
              } else if (savedSizeMl == 0.5) {
                initialSyringe = SyringeSizeMl.ml0_5;
              } else if (savedSizeMl == 1.0) {
                initialSyringe = SyringeSizeMl.ml1;
              } else if (savedSizeMl == 3.0) {
                initialSyringe = SyringeSizeMl.ml3;
              } else if (savedSizeMl == 5.0) {
                initialSyringe = SyringeSizeMl.ml5;
              }
            }

            final result = await showModalBottomSheet<ReconstitutionResult>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) =>
                    ReconstitutionCalculatorDialog(
                      initialStrengthValue: strength,
                      unitLabel: _strengthUnit.name,
                      initialSyringeSize: initialSyringe,
                      initialVialSize: _reconResult?.solventVolumeMl,
                    ),
              ),
            );
            if (result != null) {
              setState(() {
                _reconResult = result;
                _vialVolumeCtrl.text = result.solventVolumeMl.toStringAsFixed(
                  2,
                );
                _perMlCtrl.text = result.perMlConcentration.toString();
                // Auto-fill Reconstituted Vial volume
                _activeVialVolumeMlCtrl.text = result.solventVolumeMl
                    .toStringAsFixed(2);
              });
            }
          },
          onUseSaved: _useSavedReconstitution,
          result: _reconResult,
        ),
        const SizedBox(height: 16),
        SectionFormCard(
          title: 'Total Vial Volume',
          neutral: true,
          children: [
            LabelFieldRow(
              label: 'Volume (mL) *',
              field: StepperRow36(
                controller: _vialVolumeCtrl,
                onDec: () {
                  final v = double.tryParse(_vialVolumeCtrl.text.trim()) ?? 0;
                  setState(
                    () => _vialVolumeCtrl.text = (v - 0.5)
                        .clamp(0, 999)
                        .toStringAsFixed(2),
                  );
                },
                onInc: () {
                  final v = double.tryParse(_vialVolumeCtrl.text.trim()) ?? 0;
                  setState(
                    () => _vialVolumeCtrl.text = (v + 0.5)
                        .clamp(0, 999)
                        .toStringAsFixed(2),
                  );
                },
                decoration: buildCompactFieldDecoration(
                  context: context,
                  hint: '0.00',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
            buildHelperText(
              context,
              'If you know the total volume, enter it here. Otherwise, use the calculator above to determine the correct reconstitution.',
              fullWidth: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveVialStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reconstituted Vial Details', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          "Track the reconstituted vial you're currently using for dosing",
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          title: 'Low Stock Alert',
          neutral: true,
          children: [
            LabelFieldRow(
              label: 'Low stock alert',
              field: Row(
                children: [
                  Checkbox(
                    value: _activeVialLowStockEnabled,
                    onChanged: (v) =>
                        setState(() => _activeVialLowStockEnabled = v ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'Alert when volume is low',
                      style: checkboxLabelStyle(context),
                    ),
                  ),
                ],
              ),
            ),
            if (_activeVialLowStockEnabled) ...[
              LabelFieldRow(
                label: 'Threshold (mL)',
                field: StepperRow36(
                  controller: _activeVialLowStockMlCtrl,
                  onDec: () {
                    final v =
                        double.tryParse(
                          _activeVialLowStockMlCtrl.text.trim(),
                        ) ??
                        0;
                    final vialVol =
                        double.tryParse(_vialVolumeCtrl.text.trim()) ?? 999;
                    setState(
                      () => _activeVialLowStockMlCtrl.text = (v - 0.5)
                          .clamp(0, vialVol)
                          .toStringAsFixed(2),
                    );
                  },
                  onInc: () {
                    final v =
                        double.tryParse(
                          _activeVialLowStockMlCtrl.text.trim(),
                        ) ??
                        0;
                    final vialVol =
                        double.tryParse(_vialVolumeCtrl.text.trim()) ?? 999;
                    final newVal = (v + 0.5).clamp(0, vialVol);
                    setState(
                      () => _activeVialLowStockMlCtrl.text = newVal
                          .toStringAsFixed(2),
                    );
                    // Show message if clamped
                    if (newVal == vialVol && (v + 0.5) > vialVol) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Threshold cannot exceed total vial volume ($vialVol mL)',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  decoration: buildCompactFieldDecoration(
                    context: context,
                    hint: '1.0',
                  ),
                  compact: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                ),
              ),
              buildHelperText(
                context,
                'Alert when volume drops to this level',
                fullWidth: true,
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        SectionFormCard(
          title: 'Expiry & Storage',
          neutral: true,
          children: [
            LabelFieldRow(
              label: 'Expiry date',
              field: DateButton36(
                label: _activeVialExpiry == null
                    ? 'Select date'
                    : MaterialLocalizations.of(
                        context,
                      ).formatCompactDate(_activeVialExpiry!),
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await SmartExpiryPicker.show(
                    context,
                    firstDate: now,
                    lastDate: DateTime(now.year + 2),
                    initialDate:
                        _activeVialExpiry ?? now.add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() => _activeVialExpiry = picked);
                  }
                },
                width: kSmallControlWidth,
                selected: _activeVialExpiry != null,
              ),
            ),
            buildHelperText(
              context,
              'When does the reconstituted vial expire? (usually 28-30 days)',
              fullWidth: true,
            ),
            LabelFieldRow(
              label: 'Storage location',
              field: Field36(
                child: TextField(
                  controller: _activeVialStorageCtrl,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: buildFieldDecoration(
                    context,
                    hint: 'e.g., Fridge',
                  ),
                ),
              ),
            ),
            buildHelperText(
              context,
              'Where you keep the Reconstituted Vial',
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
                        value: _activeVialRequiresFridge,
                        onChanged: (v) => setState(() {
                          _activeVialRequiresFridge = v ?? false;
                          if (_activeVialRequiresFridge) {
                            _activeVialRequiresFreezer = false;
                          }
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
                        value: _activeVialRequiresFreezer,
                        onChanged: (v) => setState(() {
                          _activeVialRequiresFreezer = v ?? false;
                          if (_activeVialRequiresFreezer) {
                            _activeVialRequiresFridge = false;
                          }
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
                        value: _activeVialProtectLight,
                        onChanged: (v) => setState(
                          () => _activeVialProtectLight = v ?? false,
                        ),
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

  Widget _buildBackupInventoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sealed Inventory', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Optional: Track sealed vials for future use',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        SectionFormCard(
          title: 'Additional Sealed Vials',
          neutral: true,
          children: [
            LabelFieldRow(
              label: 'Track inventory',
              field: Row(
                children: [
                  Checkbox(
                    value: _hasBackupVials,
                    onChanged: (v) =>
                        setState(() => _hasBackupVials = v ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'I have additional sealed vials to track',
                      style: checkboxLabelStyle(context),
                    ),
                  ),
                ],
              ),
            ),
            buildHelperText(
              context,
              "Enable if you have more vials that you'll reconstitute later",
              fullWidth: true,
            ),
          ],
        ),
        if (_hasBackupVials) ...[
          const SizedBox(height: 16),
          SectionFormCard(
            title: 'Sealed Vial Stock',
            neutral: true,
            children: [
              LabelFieldRow(
                label: 'Quantity',
                field: StepperRow36(
                  controller: _backupVialsQtyCtrl,
                  onDec: () {
                    final v =
                        int.tryParse(_backupVialsQtyCtrl.text.trim()) ?? 0;
                    setState(
                      () => _backupVialsQtyCtrl.text = (v - 1)
                          .clamp(0, 1000000)
                          .toString(),
                    );
                  },
                  onInc: () {
                    final v =
                        int.tryParse(_backupVialsQtyCtrl.text.trim()) ?? 0;
                    setState(
                      () => _backupVialsQtyCtrl.text = (v + 1)
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
              buildHelperText(
                context,
                'Number of sealed, unopened vials',
                fullWidth: true,
              ),
              LabelFieldRow(
                label: 'Low stock alert',
                field: Row(
                  children: [
                    Checkbox(
                      value: _backupVialsLowStockEnabled,
                      onChanged: (v) => setState(
                        () => _backupVialsLowStockEnabled = v ?? false,
                      ),
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
              if (_backupVialsLowStockEnabled) ...[
                LabelFieldRow(
                  label: 'Threshold',
                  field: StepperRow36(
                    controller: _backupVialsLowStockCtrl,
                    onDec: () {
                      final v =
                          int.tryParse(_backupVialsLowStockCtrl.text.trim()) ??
                          0;
                      final qty =
                          int.tryParse(_backupVialsQtyCtrl.text.trim()) ??
                          1000000;
                      setState(
                        () => _backupVialsLowStockCtrl.text = (v - 1)
                            .clamp(0, qty)
                            .toString(),
                      );
                    },
                    onInc: () {
                      final v =
                          int.tryParse(_backupVialsLowStockCtrl.text.trim()) ??
                          0;
                      final qty =
                          int.tryParse(_backupVialsQtyCtrl.text.trim()) ??
                          1000000;
                      final newVal = (v + 1).clamp(0, qty);
                      setState(
                        () => _backupVialsLowStockCtrl.text = newVal.toString(),
                      );
                      // Show message if clamped
                      if (newVal == qty && (v + 1) > qty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Threshold cannot exceed total quantity ($qty vials)',
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
                  ),
                ),
              ],
              LabelFieldRow(
                label: 'Expiry date',
                field: DateButton36(
                  label: _backupVialsExpiry == null
                      ? 'Select date'
                      : MaterialLocalizations.of(
                          context,
                        ).formatCompactDate(_backupVialsExpiry!),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await SmartExpiryPicker.show(
                      context,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 10),
                      initialDate: _backupVialsExpiry ?? now,
                    );
                    if (picked != null) {
                      setState(() => _backupVialsExpiry = picked);
                    }
                  },
                  width: kSmallControlWidth,
                  selected: _backupVialsExpiry != null,
                ),
              ),
              buildHelperText(
                context,
                'When do sealed vials expire?',
                fullWidth: true,
              ),
              LabelFieldRow(
                label: 'Batch No.',
                field: Field36(
                  child: TextField(
                    controller: _backupVialsBatchCtrl,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: buildFieldDecoration(context, hint: 'Optional'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionFormCard(
            title: 'Sealed Vial Storage',
            neutral: true,
            children: [
              LabelFieldRow(
                label: 'Location',
                field: Field36(
                  child: TextField(
                    controller: _backupVialsStorageCtrl,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: buildFieldDecoration(
                      context,
                      hint: 'e.g., Freezer, Medicine cabinet',
                    ),
                  ),
                ),
              ),
              buildHelperText(
                context,
                'Where you keep unopened vials',
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
                          value: _backupVialsRequiresFridge,
                          onChanged: (v) => setState(() {
                            _backupVialsRequiresFridge = v ?? false;
                            if (_backupVialsRequiresFridge) {
                              _backupVialsRequiresFreezer = false;
                            }
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
                          value: _backupVialsRequiresFreezer,
                          onChanged: (v) => setState(() {
                            _backupVialsRequiresFreezer = v ?? false;
                            if (_backupVialsRequiresFreezer) {
                              _backupVialsRequiresFridge = false;
                            }
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
                          value: _backupVialsProtectLight,
                          onChanged: (v) => setState(
                            () => _backupVialsProtectLight = v ?? false,
                          ),
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
      ],
    );
  }

  Widget _buildReviewStep() {
    final name = _nameCtrl.text.trim();
    final manufacturer = _manufacturerCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
    final vialVolume = double.tryParse(_vialVolumeCtrl.text.trim()) ?? 0;
    final backupQty = _hasBackupVials
        ? (int.tryParse(_backupVialsQtyCtrl.text.trim()) ?? 0)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & Save', style: sectionTitleStyle(context)),
        const SizedBox(height: 8),
        Text(
          'Review all entered information. You can go back to any step to make changes.',
          style: mutedTextStyle(context),
        ),
        const SizedBox(height: 24),
        // Basic Info
        SectionFormCard(
          title: 'Step 1: Basic Information',
          neutral: true,
          children: [
            _reviewRow('Name', name.isEmpty ? '(Not entered)' : name),
            _reviewRow(
              'Manufacturer',
              manufacturer.isEmpty ? '(Not set)' : manufacturer,
            ),
            _reviewRow(
              'Description',
              description.isEmpty ? '(Not set)' : description,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Strength & Reconstitution
        SectionFormCard(
          title: 'Step 2: Strength & Reconstitution',
          neutral: true,
          children: [
            _reviewRow(
              'Strength',
              '$strength ${_strengthUnit.name}${_perMlCtrl.text.isNotEmpty ? ' (${_perMlCtrl.text} ${_strengthUnit.name}/mL)' : ''}',
            ),
            _reviewRow('Total Vial Volume', '$vialVolume mL'),
            _reviewRow(
              'Reconstitution',
              _reconResult != null
                  ? 'Add ${_reconResult!.solventVolumeMl.toStringAsFixed(1)} mL${_reconResult!.diluentName != null && _reconResult!.diluentName!.isNotEmpty ? ' ${_reconResult!.diluentName}' : ' solvent'}'
                  : '(Not calculated)',
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Active Vial
        SectionFormCard(
          title: 'Step 3: Reconstituted Vial Details',
          neutral: true,
          children: [
            _reviewRow(
              'Low Stock Alert',
              _activeVialLowStockEnabled
                  ? 'Alert at ${_activeVialLowStockMlCtrl.text} mL threshold'
                  : '(Disabled)',
            ),
            _reviewRow(
              'Expiry Date',
              _activeVialExpiry != null
                  ? MaterialLocalizations.of(
                      context,
                    ).formatCompactDate(_activeVialExpiry!)
                  : '(Not set)',
            ),
            _reviewRow(
              'Storage Location',
              _activeVialStorageCtrl.text.trim().isEmpty
                  ? '(Not set)'
                  : _activeVialStorageCtrl.text.trim(),
            ),
            _reviewRow(
              'Storage Conditions',
              (_activeVialRequiresFridge ||
                      _activeVialRequiresFreezer ||
                      _activeVialProtectLight)
                  ? [
                      if (_activeVialRequiresFridge) 'Refrigerate',
                      if (_activeVialRequiresFreezer) 'Freeze',
                      if (_activeVialProtectLight) 'Protect from Light',
                    ].join(', ')
                  : '(None)',
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Sealed Vials
        SectionFormCard(
          title: 'Step 4: Sealed Inventory',
          neutral: true,
          children: [
            _reviewRow(
              'Sealed Vials',
              _hasBackupVials ? '$backupQty sealed vials' : '(None)',
            ),
            if (_hasBackupVials) ...[
              _reviewRow(
                'Low Stock Alert',
                _backupVialsLowStockEnabled
                    ? 'Alert at ${_backupVialsLowStockCtrl.text} vials threshold'
                    : '(Disabled)',
              ),
              _reviewRow(
                'Expiry Date',
                _backupVialsExpiry != null
                    ? MaterialLocalizations.of(
                        context,
                      ).formatCompactDate(_backupVialsExpiry!)
                    : '(Not set)',
              ),
              _reviewRow(
                'Batch Number',
                _backupVialsBatchCtrl.text.trim().isEmpty
                    ? '(Not set)'
                    : _backupVialsBatchCtrl.text.trim(),
              ),
              _reviewRow(
                'Storage Location',
                _backupVialsStorageCtrl.text.trim().isEmpty
                    ? '(Not set)'
                    : _backupVialsStorageCtrl.text.trim(),
              ),
              _reviewRow(
                'Storage Conditions',
                (_backupVialsRequiresFridge ||
                        _backupVialsRequiresFreezer ||
                        _backupVialsProtectLight)
                    ? [
                        if (_backupVialsRequiresFridge) 'Refrigerate',
                        if (_backupVialsRequiresFreezer) 'Freeze',
                        if (_backupVialsProtectLight) 'Protect from Light',
                      ].join(', ')
                    : '(None)',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent() {
    final name = _nameCtrl.text.trim();
    final manufacturer = _manufacturerCtrl.text.trim();
    final strengthVal = double.tryParse(_strengthValueCtrl.text.trim());
    final vialVolume = double.tryParse(_vialVolumeCtrl.text.trim()) ?? 0;
    final unitLabel = _strengthUnit.name;
    final activeThreshold = _activeVialLowStockEnabled
        ? double.tryParse(_activeVialLowStockMlCtrl.text.trim())
        : null;
    final headerTitle = name.isEmpty ? 'Multi-Dose Vial' : name;
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
              child: Icon(Icons.addchart, color: fg),
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
                  if (manufacturer.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      manufacturer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: fg.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  if (strengthVal != null && strengthVal > 0) ...[
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
                          TextSpan(text: ' $unitLabel'),
                          if (_perMlCtrl.text.isNotEmpty)
                            TextSpan(
                              text: ' (${_perMlCtrl.text} $unitLabel/mL)',
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (vialVolume > 0) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(color: fg),
                          children: [
                            const TextSpan(text: 'Total vial: '),
                            TextSpan(
                              text: vialVolume == vialVolume.roundToDouble()
                                  ? vialVolume.toStringAsFixed(0)
                                  : vialVolume.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(text: ' mL'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_hasBackupVials) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(color: fg),
                          children: [
                            const TextSpan(text: 'Backup: '),
                            TextSpan(
                              text: _backupVialsQtyCtrl.text.trim().isEmpty
                                  ? '0'
                                  : _backupVialsQtyCtrl.text.trim(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(text: ' sealed vials'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (activeThreshold != null) ...[
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
                              text:
                                  activeThreshold ==
                                      activeThreshold.roundToDouble()
                                  ? activeThreshold.toStringAsFixed(0)
                                  : activeThreshold.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' mL remaining'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_activeVialExpiry != null)
                  Text(
                    'Exp: ${MaterialLocalizations.of(context).formatCompactDate(_activeVialExpiry!)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: fg),
                  ),
                // Storage condition icons for active vial only
                if (_activeVialRequiresFridge ||
                    _activeVialRequiresFreezer ||
                    _activeVialProtectLight) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_activeVialRequiresFridge)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.ac_unit, size: 18, color: fg),
                        ),
                      if (_activeVialRequiresFreezer)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.severe_cold, size: 18, color: fg),
                        ),
                      if (_activeVialProtectLight)
                        Icon(Icons.light_mode_outlined, size: 18, color: fg),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    return WizardNavigationBar(
      currentStep: _currentStep,
      stepCount: 5,
      canProceed: _canProceed,
      onBack: _currentStep > 0 ? _previousStep : null,
      onContinue: _nextStep,
      onSave: _saveMedication,
      saveLabel: 'Save Medication',
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
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? cs.onPrimary
            : cs.onPrimary.withValues(alpha: 0.2),
        border: Border.all(
          color: isCompleted || isActive
              ? cs.onPrimary
              : cs.onPrimary.withValues(alpha: 0.3),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, size: 12, color: cs.primary)
            : Text(
                number.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isActive
                      ? cs.primary
                      : cs.onPrimary.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
      ),
    );
  }
}

class _ReconstitutionInfoCard extends StatelessWidget {
  const _ReconstitutionInfoCard({
    required this.onCalculate,
    required this.medicationName,
    this.result,
    this.onUseSaved,
  });

  final VoidCallback onCalculate;
  final VoidCallback? onUseSaved;
  final String medicationName;
  final ReconstitutionResult? result;

  String _formatNoTrailing(double value) {
    final str = value.toStringAsFixed(2);
    if (str.contains('.')) {
      return str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: reconBackgroundDarkColor(context),
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
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reconstitution Calculator',
                style: bodyTextStyle(context)?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: kFontWeightBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (result == null)
            Text(
              'Multi-dose vials need to be mixed with liquid (reconstituted). Use the calculator to determine the correct volume.',
              style: mutedTextStyle(
                context,
              )?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
            )
          else ...[
            // "Reconstitute [MEDNAME] with [AMOUNT] of [RECONNAME]"
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: kReconTextHighOpacity),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Reconstitute '),
                  if (medicationName.isNotEmpty) ...[
                    TextSpan(
                      text: medicationName,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' '),
                  ],
                  const TextSpan(text: 'with '),
                  TextSpan(
                    text: '${_formatNoTrailing(result!.solventVolumeMl)} mL',
                    style: TextStyle(
                      fontSize: 32,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (result!.diluentName != null &&
                      result!.diluentName!.isNotEmpty) ...[
                    TextSpan(
                      text: '  of  ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(
                          alpha: kReconTextHighOpacity,
                        ),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: result!.diluentName!,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCalculate,
              icon: const Icon(Icons.science),
              label: Text(result == null ? 'Open Calculator' : 'Recalculate'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
          ),
          if (onUseSaved != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUseSaved,
                icon: const Icon(Icons.bookmarks),
                label: const Text('Use Saved'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
