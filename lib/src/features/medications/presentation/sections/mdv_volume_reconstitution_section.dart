import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_widget.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';

/// Multi-dose vial specific section for vial volume and reconstitution calculator.
/// Contains all the complex MDV logic including the reconstitution calculator,
/// vial volume input, and dynamic summary display.
class MdvVolumeReconstitutionSection extends StatefulWidget {
  const MdvVolumeReconstitutionSection({
    super.key,
    required this.strengthController,
    required this.strengthUnit,
    required this.perMlController,
    required this.vialVolumeController,
    required this.medicationNameController,
    required this.onReconstitutionChanged,
    this.initialReconResult,
    this.vialVolumeKey,
  });

  final TextEditingController strengthController;
  final Unit strengthUnit;
  final TextEditingController perMlController;
  final TextEditingController vialVolumeController;
  final TextEditingController medicationNameController;
  final Function(ReconstitutionResult?) onReconstitutionChanged;
  final ReconstitutionResult? initialReconResult;
  final GlobalKey? vialVolumeKey;

  @override
  State<MdvVolumeReconstitutionSection> createState() =>
      _MdvVolumeReconstitutionSectionState();
}

class _MdvVolumeReconstitutionSectionState
    extends State<MdvVolumeReconstitutionSection> {
  ReconstitutionResult? _reconResult;
  bool _showCalculator = false;

  @override
  void initState() {
    super.initState();
    _reconResult = widget.initialReconResult;
  }

  double _labelWidth() {
    final width = MediaQuery.of(context).size.width;
    return width >= 400 ? 120.0 : 110.0;
  }

  String _baseUnit(Unit u) => switch (u) {
    Unit.mcg => 'mcg',
    Unit.mg => 'mg',
    Unit.g => 'g',
    _ => u.name,
  };

  /// Convert a double ml value back to SyringeSizeMl enum
  SyringeSizeMl? _mlToSyringeSize(double? ml) {
    if (ml == null) return null;
    if ((ml - 0.3).abs() < 0.01) return SyringeSizeMl.ml0_3;
    if ((ml - 0.5).abs() < 0.01) return SyringeSizeMl.ml0_5;
    if ((ml - 1.0).abs() < 0.01) return SyringeSizeMl.ml1;
    if ((ml - 3.0).abs() < 0.01) return SyringeSizeMl.ml3;
    if ((ml - 5.0).abs() < 0.01) return SyringeSizeMl.ml5;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SectionFormCard(
      title: 'Volume & Reconstitution',
      children: [
        _buildHelperText(),
        const SizedBox(height: 8),
        _buildCalculatorButton(),
        if (_showCalculator) ...[
          const SizedBox(height: 12),
          _buildCalculatorWidget(),
        ] else if (_reconResult != null) ...[
          const SizedBox(height: 12),
          _buildSavedReconstitution(),
        ],
        const SizedBox(height: 24),
        _buildVialVolumeField(),
      ],
    );
  }

  Widget _buildHelperText() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'If vial is already filled or you know the volume, enter it below. Otherwise, use the calculator to determine the correct reconstitution amount.',
        textAlign: TextAlign.left,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildCalculatorButton() {
    final strengthVal = double.tryParse(widget.strengthController.text.trim());
    final hasStrength = strengthVal != null && strengthVal > 0;

    return Center(
      child: _showCalculator
          ? FilledButton.icon(
              onPressed: () => setState(() => _showCalculator = false),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Close Calculator'),
            )
          : OutlinedButton.icon(
              onPressed: hasStrength
                  ? () => setState(() => _showCalculator = true)
                  : null,
              icon: const Icon(Icons.calculate, size: 18),
              label: Text(
                _reconResult == null
                    ? 'Reconstitution Calculator'
                    : 'Edit Reconstitution',
              ),
            ),
    );
  }

  Widget _buildCalculatorWidget() {
    final strengthVal =
        double.tryParse(widget.strengthController.text.trim()) ?? 0;
    final medName = widget.medicationNameController.text.trim();

    return ReconstitutionCalculatorWidget(
      initialStrengthValue: strengthVal,
      unitLabel: _baseUnit(widget.strengthUnit),
      medicationName: medName.isEmpty ? null : medName,
      initialDoseValue: _reconResult?.recommendedDose,
      initialDoseUnit: _reconResult?.doseUnit,
      initialSyringeSize: _mlToSyringeSize(_reconResult?.syringeSizeMl),
      initialVialSize: _reconResult?.maxVialSizeMl,
      showApplyButton: true,
      onCalculate: (result, isIntermediate) {
        // Update vial volume dynamically as user adjusts calculator
        // Only update the field, don't save the result yet
        if (mounted) {
          widget.vialVolumeController.text = result.solventVolumeMl
              .toStringAsFixed(
                result.solventVolumeMl == result.solventVolumeMl.roundToDouble()
                    ? 0
                    : 1,
              );
        }
      },
      onApply: (result) {
        setState(() {
          _reconResult = result;
          _showCalculator = false;

          // Update vial volume with calculated value
          widget.vialVolumeController.text = result.solventVolumeMl
              .toStringAsFixed(
                result.solventVolumeMl == result.solventVolumeMl.roundToDouble()
                    ? 0
                    : 1,
              );

          // Update perMl concentration
          widget.perMlController.text = result.perMlConcentration
              .toStringAsFixed(
                result.perMlConcentration ==
                        result.perMlConcentration.roundToDouble()
                    ? 0
                    : 2,
              );
        });
        widget.onReconstitutionChanged(result);

        // Scroll to vial volume field
        if (widget.vialVolumeKey != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Scrollable.ensureVisible(
              widget.vialVolumeKey!.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        }
      },
    );
  }

  Widget _buildSavedReconstitution() {
    if (_reconResult == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final result = _reconResult!;
    final medName = widget.medicationNameController.text.trim();
    final strengthVal =
        double.tryParse(widget.strengthController.text.trim()) ?? 0;
    final unitLabel = _baseUnit(widget.strengthUnit);
    final diluentName = result.diluentName ?? 'diluent';

    // Format values
    final strengthStr = strengthVal == strengthVal.roundToDouble()
        ? strengthVal.toStringAsFixed(0)
        : strengthVal.toString();
    final volumeStr =
        result.solventVolumeMl == result.solventVolumeMl.roundToDouble()
        ? result.solventVolumeMl.toStringAsFixed(0)
        : result.solventVolumeMl.toStringAsFixed(1);
    final drawStr =
        result.recommendedUnits == result.recommendedUnits.roundToDouble()
        ? result.recommendedUnits.toStringAsFixed(0)
        : result.recommendedUnits.toStringAsFixed(1);
    final mlDrawStr = (result.recommendedUnits / 100).toStringAsFixed(2);
    final syringeStr =
        result.syringeSizeMl == result.syringeSizeMl.roundToDouble()
        ? result.syringeSizeMl.toStringAsFixed(1)
        : result.syringeSizeMl.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Syringe gauge spans full width
        WhiteSyringeGauge(
          totalIU: result.syringeSizeMl * 100,
          fillIU: result.recommendedUnits,
          interactive: false,
        ),
        const SizedBox(height: 12),
        // Main instruction text spans full width
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            children: [
              const TextSpan(text: 'Reconstitute '),
              TextSpan(
                text: '$strengthStr$unitLabel',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (medName.isNotEmpty) TextSpan(text: ' $medName'),
              const TextSpan(text: ' with '),
              TextSpan(
                text: '$volumeStr mL',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: ' $diluentName'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Supporting details span full width
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            children: [
              const TextSpan(text: 'Draw '),
              TextSpan(
                text: '$drawStr IU',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: ' ('),
              TextSpan(
                text: '$mlDrawStr mL',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: ') into a '),
              TextSpan(
                text: '$syringeStr mL',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: ' syringe'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVialVolumeField() {
    final theme = Theme.of(context);
    // Lock field only when reconstitution is saved AND calculator is closed
    // When calculator is open, allow dynamic updates from calculator
    final isLocked = _reconResult != null && !_showCalculator;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelFieldRow(
          key: widget.vialVolumeKey,
          label: 'Vial Volume (mL)',
          labelWidth: _labelWidth(),
          field: StepperRow36(
            controller: widget.vialVolumeController,
            enabled: !isLocked,
            onDec: () {
              if (isLocked) return;
              final d =
                  double.tryParse(widget.vialVolumeController.text.trim()) ?? 0;
              final nv = (d - 0.5).clamp(0, 1000);
              setState(() {
                widget.vialVolumeController.text = nv.toStringAsFixed(1);
              });
            },
            onInc: () {
              if (isLocked) return;
              final d =
                  double.tryParse(widget.vialVolumeController.text.trim()) ?? 0;
              final nv = (d + 0.5).clamp(0, 1000);
              setState(() {
                widget.vialVolumeController.text = nv.toStringAsFixed(1);
              });
            },
            decoration: InputDecoration(
              hintText: '0.0',
              errorStyle: const TextStyle(fontSize: 0, height: 0),
              isDense: false,
              isCollapsed: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(minHeight: kFieldHeight),
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                fontSize: kHintFontSize,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              filled: true,
              fillColor: isLocked
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    )
                  : theme.colorScheme.surfaceContainerLowest,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: _labelWidth() + 8, top: 4),
          child: Text(
            _showCalculator
                ? 'Vial volume updates automatically as you adjust the calculator above'
                : (isLocked
                    ? 'Total volume after reconstitution (locked - use calculator to adjust)'
                    : 'Enter vial volume: if already filled/known, input directly; otherwise use calculator above'),
            textAlign: TextAlign.left,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: kHintFontSize,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
