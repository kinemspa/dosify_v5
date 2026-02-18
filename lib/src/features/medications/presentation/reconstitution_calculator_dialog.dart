// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/id.dart';
import 'package:dosifi_v5/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:dosifi_v5/src/features/medications/domain/saved_reconstitution_calculation.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_widget.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/widgets/saved_reconstitution_sheet.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';

enum SyringeSizeMl { ml0_3, ml0_5, ml1, ml3, ml5 }

extension SyringeSizeX on SyringeSizeMl {
  double get ml => switch (this) {
    SyringeSizeMl.ml0_3 => 0.3,
    SyringeSizeMl.ml0_5 => 0.5,
    SyringeSizeMl.ml1 => 1.0,
    SyringeSizeMl.ml3 => 3.0,
    SyringeSizeMl.ml5 => 5.0,
  };

  int get totalUnits =>
      (ml * SyringeType.ml_1_0.unitsPerMl).round(); // 100 units per mL mapping

  String get label => '${ml.toStringAsFixed(1)} mL';
}

class ReconstitutionResult {
  const ReconstitutionResult({
    required this.perMlConcentration,
    required this.solventVolumeMl,
    required this.recommendedUnits,
    required this.syringeSizeMl,
    this.diluentName,
    this.recommendedDose,
    this.doseUnit,
    this.maxVialSizeMl,
    this.strengthValueUsed,
    this.strengthUnitUsed,
  });

  final double perMlConcentration; // same base unit as dose/strength (per mL)
  final double solventVolumeMl; // mL to add to vial
  final double recommendedUnits; // syringe units fill for the dose
  final double syringeSizeMl; // chosen syringe size mL
  final String? diluentName; // name of diluent fluid (e.g., 'Sterile Water')
  final double? recommendedDose; // desired dose value for reopening calculator
  final String? doseUnit; // dose unit (mcg/mg/g) for reopening calculator
  final double?
  maxVialSizeMl; // max vial size constraint for reopening calculator
  final double? strengthValueUsed;
  final String? strengthUnitUsed;
}

class ReconstitutionCalculatorDialog extends StatefulWidget {
  const ReconstitutionCalculatorDialog({
    super.key,
    required this.initialStrengthValue,
    required this.unitLabel, // e.g., mg, mcg, g, units
    this.initialDiluentName,
    this.initialDoseValue,
    this.initialDoseUnit,
    this.initialSyringeSize,
    this.initialVialSize,
    this.onStrengthAdjusted,
  });

  final double initialStrengthValue; // total quantity in the vial (S)
  final String unitLabel;
  final String? initialDiluentName;
  final double? initialDoseValue;
  final String? initialDoseUnit; // 'mcg'|'mg'|'g'|'units'
  final SyringeSizeMl? initialSyringeSize;
  final double? initialVialSize; // mL
  final void Function(double strengthValue, String strengthUnit)?
  onStrengthAdjusted;

  @override
  State<ReconstitutionCalculatorDialog> createState() =>
      _ReconstitutionCalculatorDialogState();
}

class _ReconstitutionCalculatorDialogState
    extends State<ReconstitutionCalculatorDialog> {
  final SavedReconstitutionRepository _savedRepo =
      SavedReconstitutionRepository();
  final ScrollController _contentScrollController = ScrollController();

  ReconstitutionResult? _lastResult;
  bool _canSubmit = false;
  bool _showDownScrollHint = false;
  bool _showLoadSaveOptions = false;
  late double _activeStrengthValue;
  late String _activeUnitLabel;
  String? _seedDiluentName;
  double? _seedDoseValue;
  String? _seedDoseUnit;
  SyringeSizeMl? _seedSyringeSize;
  double? _seedVialSize;
  int _calculatorSeedVersion = 0;

  @override
  void initState() {
    super.initState();
    _activeStrengthValue = widget.initialStrengthValue;
    _activeUnitLabel = widget.unitLabel;
    _seedDiluentName = widget.initialDiluentName;
    _seedDoseValue = widget.initialDoseValue;
    _seedDoseUnit = widget.initialDoseUnit;
    _seedSyringeSize = widget.initialSyringeSize;
    _seedVialSize = widget.initialVialSize;
  }

  void _onCalculation(ReconstitutionResult result, bool isValid) {
    setState(() {
      _lastResult = result;
      _canSubmit = isValid;
    });
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }

  void _updateDownScrollHint(ScrollMetrics metrics) {
    final shouldShow = metrics.maxScrollExtent > (metrics.pixels + 0.5);
    if (_showDownScrollHint == shouldShow) return;
    if (!mounted) return;
    setState(() => _showDownScrollHint = shouldShow);
  }

  SyringeSizeMl _inferSyringeSize(double syringeSizeMl) {
    if (syringeSizeMl <= 0.3) return SyringeSizeMl.ml0_3;
    if (syringeSizeMl <= 0.5) return SyringeSizeMl.ml0_5;
    if (syringeSizeMl <= 1.0) return SyringeSizeMl.ml1;
    if (syringeSizeMl <= 3.0) return SyringeSizeMl.ml3;
    return SyringeSizeMl.ml5;
  }

  String _formatNoTrailing(double value) {
    final str = value.toStringAsFixed(2);
    if (str.contains('.')) {
      return str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return str;
  }

  void _applySavedSeed(SavedReconstitutionCalculation saved) {
    setState(() {
      _seedDiluentName = saved.diluentName;
      _seedDoseValue = saved.recommendedDose;
      _seedDoseUnit = saved.doseUnit;
      _seedSyringeSize = _inferSyringeSize(saved.syringeSizeMl);
      _seedVialSize = saved.solventVolumeMl;
      _calculatorSeedVersion += 1;
      _lastResult = null;
      _canSubmit = false;
    });
  }

  bool _sameStrength(SavedReconstitutionCalculation saved) {
    const epsilon = 1e-6;
    final sameUnit =
        saved.strengthUnit.toLowerCase() == _activeUnitLabel.toLowerCase();
    final sameValue =
        (saved.strengthValue - _activeStrengthValue).abs() <= epsilon;
    return sameUnit && sameValue;
  }

  Future<String?> _promptForName(
    BuildContext context, {
    String? initial,
  }) async {
    final ctrl = TextEditingController(text: initial ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );

    final trimmed = result?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _saveCurrentPreset() async {
    final result = _lastResult;
    if (!_canSubmit || result == null || _activeStrengthValue <= 0) return;

    final dose = result.recommendedDose;
    final doseUnit = result.doseUnit?.trim();
    final defaultNameParts = <String>['Reconstitution'];
    if (dose != null && dose > 0 && doseUnit != null && doseUnit.isNotEmpty) {
      defaultNameParts.add('${_formatNoTrailing(dose)} $doseUnit');
    }
    defaultNameParts.add('${_formatNoTrailing(result.solventVolumeMl)} mL');

    final name = await _promptForName(
      context,
      initial: defaultNameParts.join(' - '),
    );
    if (name == null) return;

    final now = DateTime.now();
    final item = SavedReconstitutionCalculation(
      id: IdGen.newId(prefix: 'recon'),
      name: name,
      strengthValue: _activeStrengthValue,
      strengthUnit: _activeUnitLabel,
      solventVolumeMl: result.solventVolumeMl,
      perMlConcentration: result.perMlConcentration,
      recommendedUnits: result.recommendedUnits,
      syringeSizeMl: result.syringeSizeMl,
      diluentName: result.diluentName,
      recommendedDose: result.recommendedDose,
      doseUnit: result.doseUnit,
      maxVialSizeMl: result.maxVialSizeMl,
      createdAt: now,
      updatedAt: now,
    );

    await _savedRepo.upsert(item);
    if (!mounted) return;
    showAppSnackBar(context, 'Saved reconstitution');
  }

  Future<void> _openLoadSavedSheet() async {
    final selected = await showModalBottomSheet<SavedReconstitutionCalculation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SavedReconstitutionSheet(
          repo: _savedRepo,
          includeMedicationOwned: true,
          onSelect: (item) => Navigator.of(sheetContext).pop(item),
        );
      },
    );

    if (selected == null) return;

    if (!_sameStrength(selected)) {
      final decision = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Strength mismatch'),
          content: Text(
            'Saved reconstitution uses ${_formatNoTrailing(selected.strengthValue)} ${selected.strengthUnit}, '
            'but this medication is set to ${_formatNoTrailing(_activeStrengthValue)} $_activeUnitLabel.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop<String>('cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop<String>('keep'),
              child: const Text('Keep current'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop<String>('adjust'),
              child: const Text('Use saved strength'),
            ),
          ],
        ),
      );

      if (decision == null || decision == 'cancel') return;
      if (decision == 'adjust') {
        setState(() {
          _activeStrengthValue = selected.strengthValue;
          _activeUnitLabel = selected.strengthUnit;
          _calculatorSeedVersion += 1;
          _lastResult = null;
          _canSubmit = false;
        });
        widget.onStrengthAdjusted?.call(
          selected.strengthValue,
          selected.strengthUnit,
        );
      }
    }

    _applySavedSeed(selected);
    if (!mounted) return;
    showAppSnackBar(context, 'Loaded saved reconstitution');
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_contentScrollController.hasClients) return;
      _updateDownScrollHint(_contentScrollController.position);
    });

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fg = reconForegroundColor(context);

    return Container(
      decoration: BoxDecoration(
        color: reconBackgroundDarkColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: fg.withValues(alpha: 0.9),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Reconstitution Calculator',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: fg,
                    fontWeight: kFontWeightBold,
                  ),
                ),
              ],
            ),
          ),
          // Helper text
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Select a reconstitution option below or fine-tune the values',
              style: theme.textTheme.bodySmall?.copyWith(
                color: fg.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, kSpacingS),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                border: Border.all(
                  color: fg.withValues(alpha: kOpacitySubtleLow),
                  width: kBorderWidthThin,
                ),
              ),
              child: ExpansionTile(
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
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                collapsedShape: const RoundedRectangleBorder(
                  side: BorderSide.none,
                ),
                iconColor: fg.withValues(alpha: kOpacityMediumHigh),
                collapsedIconColor: fg.withValues(alpha: kOpacityMediumHigh),
                textColor: fg.withValues(alpha: kOpacityMediumHigh),
                collapsedTextColor: fg.withValues(alpha: kOpacityMediumHigh),
                title: Text(
                  'Load & Save',
                  style: microHelperTextStyle(
                    context,
                    color: fg.withValues(alpha: kOpacityMediumHigh),
                  ),
                ),
                initiallyExpanded: _showLoadSaveOptions,
                onExpansionChanged: (expanded) {
                  setState(() => _showLoadSaveOptions = expanded);
                },
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openLoadSavedSheet,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Load saved'),
                        ),
                      ),
                      const SizedBox(width: kSpacingS),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _canSubmit ? _saveCurrentPreset : null,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save preset'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(
            color: theme.brightness == Brightness.dark
                ? cs.outlineVariant.withValues(alpha: kOpacitySubtleLow)
                : fg.withValues(alpha: 0.12),
            height: 1,
          ),
          // Content
          Flexible(
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.axis == Axis.vertical) {
                      _updateDownScrollHint(notification.metrics);
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _contentScrollController,
                    padding: const EdgeInsets.all(20),
                    child: ReconstitutionCalculatorWidget(
                      key: ValueKey<int>(_calculatorSeedVersion),
                      initialStrengthValue: _activeStrengthValue,
                      unitLabel: _activeUnitLabel,
                      initialDiluentName: _seedDiluentName,
                      initialDoseValue: _seedDoseValue,
                      initialDoseUnit: _seedDoseUnit,
                      initialSyringeSize: _seedSyringeSize,
                      initialVialSize: _seedVialSize,
                      onCalculate: _onCalculation,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedOpacity(
                      opacity: _showDownScrollHint ? 1 : 0,
                      duration: kAnimationFast,
                      curve: kCurveSnappy,
                      child: Padding(
                        padding: kReconstitutionDialogScrollHintPadding,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: kReconstitutionDialogScrollHintIconSize,
                          color: fg.withValues(alpha: kOpacityMediumHigh),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? cs.outlineVariant.withValues(alpha: kOpacitySubtleLow)
                      : fg.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop<ReconstitutionResult>(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fg,
                      side: BorderSide(color: fg.withValues(alpha: 0.3)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _canSubmit
                        ? () {
                            Navigator.of(context).pop(_lastResult);
                          }
                        : null,
                    child: const Text('Save Reconstitution'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
