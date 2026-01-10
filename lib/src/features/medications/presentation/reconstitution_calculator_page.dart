// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:dosifi_v5/src/features/medications/domain/saved_reconstitution_calculation.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/reconstitution_summary_card.dart';
import 'package:dosifi_v5/src/widgets/saved_reconstitution_sheet.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class ReconstitutionCalculatorPage extends StatefulWidget {
  const ReconstitutionCalculatorPage({
    required this.initialStrengthValue,
    required this.unitLabel,
    super.key,
    this.initialDoseValue,
    this.initialDoseUnit,
    this.initialSyringeSize,
    this.initialVialSize,
  });

  final double initialStrengthValue;
  final String unitLabel; // This becomes the initial unit
  final double? initialDoseValue;
  final String? initialDoseUnit;
  final SyringeSizeMl? initialSyringeSize;
  final double? initialVialSize;

  @override
  State<ReconstitutionCalculatorPage> createState() =>
      _ReconstitutionCalculatorPageState();
}

class _ReconstitutionCalculatorPageState
    extends State<ReconstitutionCalculatorPage> {
  late final TextEditingController _strengthCtrl;
  late final TextEditingController _medNameCtrl;
  late String _selectedUnit; // Track selected unit

  final SavedReconstitutionRepository _savedRepo =
      SavedReconstitutionRepository();
  ReconstitutionResult? _lastResult;
  bool _canSave = false;
  String? _loadedSavedId;

  double? _initialDoseValue;
  String? _initialDoseUnit;
  SyringeSizeMl? _initialSyringeSize;
  double? _initialVialSize;

  @override
  void initState() {
    super.initState();
    _strengthCtrl = TextEditingController(
      text: widget.initialStrengthValue > 0
          ? (widget.initialStrengthValue ==
                    widget.initialStrengthValue.roundToDouble()
                ? widget.initialStrengthValue.toInt().toString()
                : widget.initialStrengthValue.toStringAsFixed(2))
          : '',
    );
    _medNameCtrl = TextEditingController();
    // Initialize unit from unitLabel, default to mg if invalid
    _selectedUnit = _parseUnitFromLabel(widget.unitLabel);

    _initialDoseValue = widget.initialDoseValue;
    _initialDoseUnit = widget.initialDoseUnit;
    _initialSyringeSize = widget.initialSyringeSize;
    _initialVialSize = widget.initialVialSize;
  }

  String _parseUnitFromLabel(String label) {
    // Parse the unit label to get a valid unit string
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('units')) return 'units';
    if (lowerLabel.contains('mcg')) return 'mcg';
    if (lowerLabel.contains('mg')) return 'mg';
    if (lowerLabel.contains('g')) return 'g';
    return 'mg'; // Default to mg
  }

  @override
  void dispose() {
    _strengthCtrl.dispose();
    _medNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCalculatorSheet() async {
    final strengthValue = double.tryParse(_strengthCtrl.text.trim()) ?? 0;
    if (strengthValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter vial strength first')),
      );
      return;
    }

    final result = await showModalBottomSheet<ReconstitutionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ReconstitutionCalculatorDialog(
          initialStrengthValue: strengthValue,
          unitLabel: _selectedUnit,
          initialDoseValue: _initialDoseValue,
          initialDoseUnit: _initialDoseUnit,
          initialSyringeSize: _initialSyringeSize,
          initialVialSize: _initialVialSize,
        ),
      ),
    );

    if (!mounted) return;
    if (result == null) return;

    setState(() {
      _lastResult = result;
      _canSave = true;

      _initialDoseValue = result.recommendedDose;
      _initialDoseUnit = result.doseUnit;
      _initialSyringeSize = _syringeFromMl(result.syringeSizeMl);
      _initialVialSize = result.solventVolumeMl;
    });
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  SyringeSizeMl? _syringeFromMl(double ml) {
    if (ml == 0.3) return SyringeSizeMl.ml0_3;
    if (ml == 0.5) return SyringeSizeMl.ml0_5;
    if (ml == 1.0) return SyringeSizeMl.ml1;
    if (ml == 3.0) return SyringeSizeMl.ml3;
    if (ml == 5.0) return SyringeSizeMl.ml5;
    return null;
  }

  Future<String?> _promptForName(
    BuildContext context, {
    String? initial,
  }) async {
    final ctrl = TextEditingController(text: initial ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Reconstitution'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: buildCompactFieldDecoration(
              context: context,
              hint: 'Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop<String>(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    final trimmed = result?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _saveCurrent() async {
    final strengthValue = double.tryParse(_strengthCtrl.text.trim()) ?? 0;
    if (!_canSave || _lastResult == null || strengthValue <= 0) return;

    final defaultName = _medNameCtrl.text.trim().isNotEmpty
        ? _medNameCtrl.text.trim()
        : 'Reconstitution';

    final name = await _promptForName(context, initial: defaultName);
    if (name == null) return;

    final now = DateTime.now();
    final id = _loadedSavedId ?? _newId();

    final item = SavedReconstitutionCalculation(
      id: id,
      name: name,
      medicationName: _medNameCtrl.text.trim().isNotEmpty
          ? _medNameCtrl.text.trim()
          : null,
      strengthValue: strengthValue,
      strengthUnit: _selectedUnit,
      solventVolumeMl: _lastResult!.solventVolumeMl,
      perMlConcentration: _lastResult!.perMlConcentration,
      recommendedUnits: _lastResult!.recommendedUnits,
      syringeSizeMl: _lastResult!.syringeSizeMl,
      diluentName: _lastResult!.diluentName,
      recommendedDose: _lastResult!.recommendedDose,
      doseUnit: _lastResult!.doseUnit,
      maxVialSizeMl: _lastResult!.maxVialSizeMl,
      createdAt: _loadedSavedId == null ? now : null,
      updatedAt: now,
    );

    await _savedRepo.upsert(item);
    if (!mounted) return;
    setState(() {
      _loadedSavedId = id;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved reconstitution')));
  }

  Future<void> _renameSaved(SavedReconstitutionCalculation item) async {
    final name = await _promptForName(context, initial: item.name);
    if (name == null) return;
    await _savedRepo.upsert(
      item.copyWith(name: name, updatedAt: DateTime.now()),
    );
  }

  Future<void> _deleteSaved(SavedReconstitutionCalculation item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete saved reconstitution?'),
        content: Text('"${item.name}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _savedRepo.delete(item.id);
    if (!mounted) return;
    if (_loadedSavedId == item.id) {
      setState(() => _loadedSavedId = null);
    }
  }

  Future<void> _openSavedSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final height = MediaQuery.of(context).size.height;
        return SizedBox(
          height: height * 0.8,
          child: SavedReconstitutionSheet(
            repo: _savedRepo,
            allowManage: true,
            onRename: _renameSaved,
            onDelete: _deleteSaved,
            onSelect: (item) {
              setState(() {
                _loadedSavedId = item.id;

                _medNameCtrl.text = item.medicationName ?? '';
                _selectedUnit = item.strengthUnit;
                _strengthCtrl.text =
                    item.strengthValue == item.strengthValue.roundToDouble()
                    ? item.strengthValue.toInt().toString()
                    : item.strengthValue.toStringAsFixed(2);

                _initialDoseValue = item.recommendedDose;
                _initialDoseUnit = item.doseUnit;
                _initialSyringeSize = _syringeFromMl(item.syringeSizeMl);
                _initialVialSize = item.solventVolumeMl;
              });
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strengthValue = double.tryParse(_strengthCtrl.text) ?? 0;
    final medName = _medNameCtrl.text.trim().isNotEmpty
        ? _medNameCtrl.text.trim()
        : 'Medication';

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Reconstitution Calculator',
        actions: [
          IconButton(
            onPressed: _openSavedSheet,
            icon: const Icon(Icons.bookmarks),
            tooltip: 'Saved',
          ),
          IconButton(
            onPressed: _canSave ? _saveCurrent : null,
            icon: const Icon(Icons.save),
            tooltip: 'Save',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(kSpacingL),
        children: [
          SectionFormCard(
            title: 'Medication (Optional)',
            neutral: true,
            children: [
              LabelFieldRow(
                label: 'Name',
                field: Field36(
                  child: TextField(
                    controller: _medNameCtrl,
                    decoration: buildCompactFieldDecoration(
                      context: context,
                      hint: 'Optional',
                    ),
                    onChanged: (_) => setState(() {}),
                    textAlign: TextAlign.center,
                    style: bodyTextStyle(context),
                  ),
                ),
              ),
              buildHelperText(
                context,
                'Enter the medication name (optional, for context)',
              ),
            ],
          ),
          sectionSpacing,
          SectionFormCard(
            title: 'Vial Strength',
            neutral: true,
            children: [
              LabelFieldRow(
                label: 'Unit',
                field: SmallDropdown36<String>(
                  value: _selectedUnit,
                  width: kSmallControlWidth,
                  items: const [
                    DropdownMenuItem(
                      value: 'mcg',
                      child: Center(child: Text('mcg')),
                    ),
                    DropdownMenuItem(
                      value: 'mg',
                      child: Center(child: Text('mg')),
                    ),
                    DropdownMenuItem(
                      value: 'g',
                      child: Center(child: Text('g')),
                    ),
                    DropdownMenuItem(
                      value: 'units',
                      child: Center(child: Text('units')),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedUnit = v ?? 'mg'),
                ),
              ),
              buildHelperText(context, 'Select the unit for vial strength'),
              LabelFieldRow(
                label: 'Strength',
                field: StepperRow36(
                  controller: _strengthCtrl,
                  onDec: () {
                    final v = double.tryParse(_strengthCtrl.text) ?? 0;
                    final nv = (v - 1).clamp(0, 10000);
                    setState(() {
                      _strengthCtrl.text = nv == nv.roundToDouble()
                          ? nv.toInt().toString()
                          : nv.toStringAsFixed(2);
                    });
                  },
                  onInc: () {
                    final v = double.tryParse(_strengthCtrl.text) ?? 0;
                    final nv = (v + 1).clamp(0, 10000);
                    setState(() {
                      _strengthCtrl.text = nv == nv.roundToDouble()
                          ? nv.toInt().toString()
                          : nv.toStringAsFixed(2);
                    });
                  },
                  decoration: buildCompactFieldDecoration(
                    context: context,
                    hint: '0',
                  ),
                ),
              ),
              buildHelperText(
                context,
                'Total drug amount in the vial (before reconstitution)',
              ),
            ],
          ),
          sectionSpacing,
          SectionFormCard(
            title: 'Calculator',
            neutral: true,
            children: [
              if (strengthValue <= 0)
                Text(
                  'Enter the vial strength above to use the calculator',
                  style: helperTextStyle(context),
                  textAlign: TextAlign.center,
                )
              else ...[
                if (_lastResult != null)
                  ReconstitutionSummaryCard(
                    strengthValue: strengthValue,
                    strengthUnit: _selectedUnit,
                    medicationName: medName,
                    containerVolumeMl: _lastResult!.solventVolumeMl,
                    perMlValue: _lastResult!.perMlConcentration,
                    reconFluidName: _lastResult!.diluentName,
                    syringeSizeMl: _lastResult!.syringeSizeMl,
                    compact: false,
                    showCardSurface: true,
                  ),
                const SizedBox(height: kSpacingM),
                FilledButton(
                  onPressed: _openCalculatorSheet,
                  child: Text(
                    _lastResult == null ? 'Open Calculator' : 'Recalculate',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
