// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/core/utils/id.dart';
import 'package:dosifi_v5/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:dosifi_v5/src/features/medications/domain/saved_reconstitution_calculation.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_widget.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
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
  bool _showLoadSaveOptions = false;

  double? _initialDoseValue;
  String? _initialDoseUnit;
  SyringeSizeMl? _initialSyringeSize;
  double? _initialVialSize;
  String? _initialDiluentName;

  bool _isSameResult(ReconstitutionResult a, ReconstitutionResult b) {
    bool sameDouble(double? x, double? y) {
      if (x == null && y == null) return true;
      if (x == null || y == null) return false;
      return (x - y).abs() < 1e-9;
    }

    return sameDouble(a.perMlConcentration, b.perMlConcentration) &&
        sameDouble(a.solventVolumeMl, b.solventVolumeMl) &&
        sameDouble(a.calculatedUnits, b.calculatedUnits) &&
        sameDouble(a.syringeSizeMl, b.syringeSizeMl) &&
        sameDouble(a.calculatedDose, b.calculatedDose) &&
        sameDouble(a.maxVialSizeMl, b.maxVialSizeMl) &&
        a.diluentName == b.diluentName &&
        a.doseUnit == b.doseUnit;
  }

  void _onCalculation(ReconstitutionResult result, bool isValid) {
    final shouldUpdate =
        _lastResult == null ||
        !_isSameResult(_lastResult!, result) ||
        _canSave != isValid;
    if (!shouldUpdate) return;

    setState(() {
      _lastResult = result;
      _canSave = isValid;

      _initialDoseValue = result.calculatedDose;
      _initialDoseUnit = result.doseUnit;
      _initialSyringeSize = _syringeFromMl(result.syringeSizeMl);
      _initialVialSize = result.solventVolumeMl;
      _initialDiluentName = result.diluentName;
    });
  }

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

  String _newId() => IdGen.newId(prefix: 'recon');

  void _loadSavedCalculation(SavedReconstitutionCalculation item) {
    setState(() {
      _loadedSavedId = item.id;

      _medNameCtrl.text = item.medicationName ?? '';
      _selectedUnit = item.strengthUnit;
      _strengthCtrl.text =
          item.strengthValue == item.strengthValue.roundToDouble()
          ? item.strengthValue.toInt().toString()
          : item.strengthValue.toStringAsFixed(2);

      _initialDoseValue = item.calculatedDose;
      _initialDoseUnit = item.doseUnit;
      _initialSyringeSize = _syringeFromMl(item.syringeSizeMl);
      _initialVialSize = item.solventVolumeMl;
      _initialDiluentName = item.diluentName;

      _lastResult = ReconstitutionResult(
        perMlConcentration: item.perMlConcentration,
        solventVolumeMl: item.solventVolumeMl,
        calculatedUnits: item.calculatedUnits,
        syringeSizeMl: item.syringeSizeMl,
        diluentName: item.diluentName,
        calculatedDose: item.calculatedDose,
        doseUnit: item.doseUnit,
        maxVialSizeMl: item.maxVialSizeMl,
      );
      _canSave = true;
    });
  }

  void _startNewReconstitution() {
    setState(() {
      _loadedSavedId = null;
      _lastResult = null;
      _canSave = false;

      _initialDoseValue = widget.initialDoseValue;
      _initialDoseUnit = widget.initialDoseUnit;
      _initialSyringeSize = widget.initialSyringeSize;
      _initialVialSize = widget.initialVialSize;
      _initialDiluentName = null;
    });
  }

  SyringeSizeMl? _syringeFromMl(double ml) {
    if (ml == 0.3) return SyringeSizeMl.ml0_3;
    if (ml == 0.5) return SyringeSizeMl.ml0_5;
    if (ml == 1.0) return SyringeSizeMl.ml1;
    if (ml == 3.0) return SyringeSizeMl.ml3;
    if (ml == 5.0) return SyringeSizeMl.ml5;
    return null;
  }

  String _formatNoTrailing(double value) {
    final str = value.toStringAsFixed(2);
    if (str.contains('.')) {
      return str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return str;
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
            textCapitalization: kTextCapitalizationDefault,
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

  Future<String?> _promptForMedicationName(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Medication name required'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: kTextCapitalizationDefault,
            decoration: buildCompactFieldDecoration(
              context: context,
              hint: 'Medication name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop<String>(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
              child: const Text('Continue'),
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

    // Standalone calculator: require medication name before saving.
    if (_medNameCtrl.text.trim().isEmpty) {
      final entered = await _promptForMedicationName(context);
      if (entered == null) return;
      setState(() {
        _medNameCtrl.text = entered;
      });
    }

    final baseName = _medNameCtrl.text.trim().isNotEmpty
        ? _medNameCtrl.text.trim()
        : 'Reconstitution';

    final parts = <String>[baseName];
    final dose = _lastResult!.calculatedDose;
    final doseUnit = _lastResult!.doseUnit;
    if (dose != null &&
        dose > 0 &&
        doseUnit != null &&
        doseUnit.trim().isNotEmpty) {
      parts.add('${_formatNoTrailing(dose)} ${doseUnit.trim()}');
    }
    parts.add('${_formatNoTrailing(_lastResult!.solventVolumeMl)} mL');

    final defaultName = parts.join(' - ');

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
      calculatedUnits: _lastResult!.calculatedUnits,
      syringeSizeMl: _lastResult!.syringeSizeMl,
      diluentName: _lastResult!.diluentName,
      calculatedDose: _lastResult!.calculatedDose,
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

    showAppSnackBar(context, 'Saved reconstitution');
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
            includeMedicationOwned: false,
            onRename: _renameSaved,
            onDelete: _deleteSaved,
            onSelect: (item) {
              _loadSavedCalculation(item);
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
    final medName = _medNameCtrl.text.trim();
    final fg = reconForegroundColor(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget helper(String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: helperTextStyle(context)?.copyWith(
            color: fg.withValues(alpha: kReconTextMutedOpacity),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    BoxDecoration panelDecoration() {
      return BoxDecoration(
        color: reconBackgroundActiveColor(context),
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.18),
          width: kBorderWidthThin,
        ),
      );
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Reconstitution\nCalculator',
        titleMaxLines: 2,
        compactTitle: true,
      ),
      body: ColoredBox(
        color: reconBackgroundDarkColor(context),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(kSpacingL),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate,
                      color: fg.withValues(alpha: 0.9),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reconstitution Reference Calculator',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: fg,
                          fontWeight: kFontWeightBold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Select a reconstitution option below or fine-tune the values',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg.withValues(alpha: kReconTextMutedOpacity),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Divider(
                color: theme.brightness == Brightness.dark
                    ? cs.outlineVariant.withValues(alpha: kOpacitySubtleLow)
                    : fg.withValues(alpha: 0.12),
                height: 1,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: panelDecoration(),
                child: ValueListenableBuilder(
                  valueListenable: _savedRepo.listenable(),
                  builder: (context, box, _) {
                    final saved = _savedRepo.allSorted(includeOwned: false);
                    final hasSaved = saved.isNotEmpty;

                    return ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: kSpacingM,
                        vertical: 0,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(
                        kSpacingM,
                        0,
                        kSpacingM,
                        kSpacingM,
                      ),
                      shape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      collapsedShape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      iconColor: fg.withValues(alpha: kOpacityMediumHigh),
                      collapsedIconColor: fg.withValues(
                        alpha: kOpacityMediumHigh,
                      ),
                      textColor: fg.withValues(alpha: kOpacityMediumHigh),
                      collapsedTextColor: fg.withValues(
                        alpha: kOpacityMediumHigh,
                      ),
                      title: Text(
                        'Load & Save',
                        style: bodyTextStyle(
                          context,
                        )?.copyWith(color: fg.withValues(alpha: 0.9)),
                      ),
                      subtitle: Text(
                        hasSaved
                            ? 'Load a saved reconstitution or save current values.'
                            : 'No saved reconstitutions yet.',
                        style: helperTextStyle(context)?.copyWith(
                          color: fg.withValues(alpha: kReconTextMutedOpacity),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      initiallyExpanded: _showLoadSaveOptions,
                      onExpansionChanged: (expanded) {
                        setState(() => _showLoadSaveOptions = expanded);
                      },
                      children: [
                        LabelFieldRow(
                          label: 'Load',
                          lightText: true,
                          field: SmallDropdown36<String>(
                            value: _loadedSavedId ?? 'new',
                            items: [
                              const DropdownMenuItem(
                                value: 'new',
                                child: Center(child: Text('New')),
                              ),
                              ...saved.map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Center(
                                    child: Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null || value == 'new') {
                                _startNewReconstitution();
                                return;
                              }
                              final selected = saved.where(
                                (s) => s.id == value,
                              );
                              if (selected.isEmpty) return;
                              _loadSavedCalculation(selected.first);
                            },
                          ),
                        ),
                        if (_medNameCtrl.text.trim().isEmpty)
                          helper(
                            'Saving will prompt for medication name if blank.',
                          ),
                        const SizedBox(height: kSpacingS),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: hasSaved ? _openSavedSheet : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: fg.withValues(alpha: 0.92),
                                  side: BorderSide(
                                    color: fg.withValues(alpha: 0.25),
                                    width: kBorderWidthThin,
                                  ),
                                ),
                                icon: const Icon(Icons.bookmarks_outlined),
                                label: const Text('Manage saved'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _canSave ? _saveCurrent : null,
                                icon: const Icon(Icons.save),
                                label: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: panelDecoration(),
                padding: const EdgeInsets.all(kSpacingL),
                child: Column(
                  children: [
                    LabelFieldRow(
                      label: 'Medication Name',
                      lightText: true,
                      field: Field36(
                        child: TextField(
                          controller: _medNameCtrl,
                          decoration: buildCompactFieldDecoration(
                            context: context,
                            hint: 'Optional (required to save)',
                          ),
                          onChanged: (_) => setState(() {}),
                          textAlign: TextAlign.center,
                          textCapitalization: kTextCapitalizationDefault,
                          style: bodyTextStyle(context),
                        ),
                      ),
                    ),
                    helper(
                      'Optional. Not used in calculations — only used when saving or searching.',
                    ),
                    const SizedBox(height: kSpacingS),
                    LabelFieldRow(
                      label: 'Strength',
                      lightText: true,
                      field: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SmallDropdown36<String>(
                            value: _selectedUnit,
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
                            onChanged: (v) =>
                                setState(() => _selectedUnit = v ?? 'mg'),
                          ),
                          const SizedBox(height: kSpacingS),
                          StepperRow36(
                            controller: _strengthCtrl,
                            onDec: () {
                              final v =
                                  double.tryParse(_strengthCtrl.text) ?? 0;
                              final nv = (v - 1).clamp(0, 10000);
                              setState(() {
                                _strengthCtrl.text = nv == nv.roundToDouble()
                                    ? nv.toInt().toString()
                                    : nv.toStringAsFixed(2);
                              });
                            },
                            onInc: () {
                              final v =
                                  double.tryParse(_strengthCtrl.text) ?? 0;
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
                        ],
                      ),
                    ),
                    helper(
                      'Required. Strength (S) is the total compound amount in the vial (before mixing). Use the unit from the vial label.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (strengthValue <= 0)
                Text(
                  'Enter the vial strength above to use the calculator',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fg.withValues(alpha: kReconTextMutedOpacity),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                ReconstitutionCalculatorWidget(
                  key: ValueKey(_loadedSavedId ?? 'new'),
                  initialStrengthValue: strengthValue,
                  unitLabel: _selectedUnit,
                  medicationName: medName.isNotEmpty ? medName : null,
                  initialDiluentName: _initialDiluentName,
                  initialDoseValue: _initialDoseValue,
                  initialDoseUnit: _initialDoseUnit,
                  initialSyringeSize: _initialSyringeSize,
                  initialVialSize: _initialVialSize,
                  onCalculate: _onCalculation,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
