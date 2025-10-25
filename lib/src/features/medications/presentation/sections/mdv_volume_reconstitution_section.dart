// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_widget.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';

/// Multi-dose vial specific section for vial volume and reconstitution calculator.
/// Contains all the complex MDV logic including the reconstitution calculator,
/// vial volume input, and dynamic summary display.
class MdvVolumeReconstitutionSection extends StatefulWidget {
  const MdvVolumeReconstitutionSection({
    required this.strengthController,
    required this.strengthUnit,
    required this.perMlController,
    required this.vialVolumeController,
    required this.medicationNameController,
    required this.onReconstitutionChanged,
    super.key,
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
    
    // Add listener for vial volume validation
    widget.vialVolumeController.addListener(_validateVialVolume);
  }
  
  @override
  void dispose() {
    widget.vialVolumeController.removeListener(_validateVialVolume);
    super.dispose();
  }
  
  /// Validates vial volume input and shows snackbar if exceeds max size
  void _validateVialVolume() {
    final maxVialSize = _reconResult?.maxVialSizeMl ?? 1000.0;
    final parsedValue = double.tryParse(widget.vialVolumeController.text.trim());
    
    if (parsedValue != null && parsedValue > maxVialSize && mounted) {
      // Debounce snackbar to avoid spam
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Vial volume cannot exceed max vial size (${maxVialSize.toStringAsFixed(1)} mL)',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
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
    // Make card dark when calculator is open OR when result is saved
    final isDarkMode = _showCalculator || _reconResult != null;
    
    return SectionFormCard(
      title: 'Volume & Reconstitution',
      backgroundColor: isDarkMode ? kReconBackgroundActive : null,
      neutral: !isDarkMode, // Use neutral style when not in dark mode
      children: [
        _buildHelperText(isDarkMode),
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
        _buildVialVolumeField(isDarkMode),
      ],
    );
  }

  Widget _buildHelperText(bool isDarkMode) {
    final theme = Theme.of(context);
    // Use white text when dark mode is active
    final textColor = isDarkMode
        ? Colors.white.withOpacity(kReconTextMediumOpacity)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'If vial is already filled or you know the volume, enter it below. Otherwise, use the calculator to determine the correct reconstitution amount.',
        textAlign: TextAlign.left,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
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
        // Lock to 2 decimal places for consistency
        if (mounted) {
          widget.vialVolumeController.text = result.solventVolumeMl.toStringAsFixed(2);
        }
      },
      onApply: (result) {
        setState(() {
          _reconResult = result;
          _showCalculator = false; // Close calculator after save

          // Update vial volume with calculated value, locked to 2 decimals
          widget.vialVolumeController.text = result.solventVolumeMl.toStringAsFixed(2);

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

    // Format values with consistent 2 decimal places for volume
    final strengthStr = strengthVal == strengthVal.roundToDouble()
        ? strengthVal.toStringAsFixed(0)
        : strengthVal.toString();
    final volumeStr = result.solventVolumeMl.toStringAsFixed(2);
    final drawStr =
        result.recommendedUnits == result.recommendedUnits.roundToDouble()
        ? result.recommendedUnits.toStringAsFixed(0)
        : result.recommendedUnits.toStringAsFixed(1);
    final mlDrawStr = (result.recommendedUnits / 100 * result.syringeSizeMl).toStringAsFixed(2);
    final syringeStr = result.syringeSizeMl.toStringAsFixed(1);

    // Build the full rich summary card (same as in calculator)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reconstituted badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Reconstituted',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Full summary card
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.12),
                  theme.colorScheme.primary.withOpacity(0.05),
                  theme.colorScheme.secondary.withOpacity(0.08),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon header
                Icon(
                  Icons.science_outlined,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                // First line: Reconstitute X of MEDNAME
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(kReconTextHighOpacity),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Reconstitute '),
                      TextSpan(
                        text: '$strengthStr $unitLabel',
                        style: TextStyle(
                          fontSize: 20,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (medName.isNotEmpty) ...[
                        TextSpan(
                          text: '  of  ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(kReconTextHighOpacity),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: medName,
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Second line: with X mL of DILUENT
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(kReconTextHighOpacity),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'with '),
                      TextSpan(
                        text: '$volumeStr mL',
                        style: TextStyle(
                          fontSize: 32,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: '  of  ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(kReconTextHighOpacity),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: diluentName,
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Divider
                Container(
                  width: 60,
                  height: 2,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        theme.colorScheme.primary.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Draw instruction
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(kReconTextHighOpacity),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Draw '),
                      TextSpan(
                        text: '$drawStr Units  ',
                        style: TextStyle(
                          fontSize: 22,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '$mlDrawStr mL',
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Syringe instruction
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(kReconTextHighOpacity),
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      const TextSpan(text: 'into a '),
                      TextSpan(
                        text: '$syringeStr mL',
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' syringe'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Dose info
                if (result.recommendedDose != null && result.doseUnit != null)
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(kReconTextMediumOpacity),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'for a dose of '),
                        TextSpan(
                          text:
                              '${result.recommendedDose!.toStringAsFixed(result.recommendedDose! == result.recommendedDose!.roundToDouble() ? 0 : 2)} ${result.doseUnit}',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Syringe gauge
        WhiteSyringeGauge(
          totalUnits: result.syringeSizeMl * 100,
          fillUnits: result.recommendedUnits,
        ),
      ],
    );
  }

  Widget _buildVialVolumeField(bool isDarkMode) {
    final theme = Theme.of(context);
    // Always allow manual edit, even after saving reconstitution result
    // Remove the lock behavior entirely

    // Define max vial size constraint (if saved reconstitution has it)
    final maxVialSize = _reconResult?.maxVialSizeMl ?? 1000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelFieldRow(
          key: widget.vialVolumeKey,
          label: 'Total Volume (mL)',
          labelWidth: _labelWidth(),
          field: StepperRow36(
            controller: widget.vialVolumeController,
            onDec: () {
              final d =
                  double.tryParse(widget.vialVolumeController.text.trim()) ?? 0;
              final nv = (d - 0.5).clamp(0, maxVialSize);
              setState(() {
                widget.vialVolumeController.text = nv.toStringAsFixed(2);
              });
            },
            onInc: () {
              final d =
                  double.tryParse(widget.vialVolumeController.text.trim()) ?? 0;
              final nv = (d + 0.5).clamp(0, maxVialSize);
              setState(() {
                widget.vialVolumeController.text = nv.toStringAsFixed(2);
              });
            },
            decoration: buildCompactFieldDecoration(
              context: context,
              hint: '0.0',
            ),
            // Restrict manual input to 2 decimal places
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            compact: true,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: _labelWidth() + 8, top: 4),
          child: Text(
            _showCalculator
                ? 'Vial volume updates automatically as you adjust the calculator above'
                : 'Enter vial volume: if already filled/known, input directly; otherwise use calculator above',
            textAlign: TextAlign.left,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: kHintFontSize,
              color: isDarkMode
                  ? Colors.white.withOpacity(kReconTextMediumOpacity)
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
