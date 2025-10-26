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
    this.onCalculatorVisibilityChanged,
  });

  final TextEditingController strengthController;
  final Unit strengthUnit;
  final TextEditingController perMlController;
  final TextEditingController vialVolumeController;
  final TextEditingController medicationNameController;
  final Function(ReconstitutionResult?) onReconstitutionChanged;
  final ReconstitutionResult? initialReconResult;
  final GlobalKey? vialVolumeKey;
  final Function(bool)? onCalculatorVisibilityChanged;

  @override
  State<MdvVolumeReconstitutionSection> createState() =>
      _MdvVolumeReconstitutionSectionState();
}

class _MdvVolumeReconstitutionSectionState
    extends State<MdvVolumeReconstitutionSection> {
  ReconstitutionResult? _reconResult;
  bool _showCalculator = false;
  final GlobalKey _calculatorKey = GlobalKey();
  final GlobalKey _summaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _reconResult = widget.initialReconResult;
    // Add listener to update summary card when vial volume changes manually
    widget.vialVolumeController.addListener(_onVialVolumeChanged);
  }
  
  @override
  void dispose() {
    widget.vialVolumeController.removeListener(_onVialVolumeChanged);
    super.dispose();
  }
  
  void _onVialVolumeChanged() {
    // Only update if not locked and recon result exists
    if (!_showCalculator && _reconResult != null) {
      final nv = double.tryParse(widget.vialVolumeController.text.trim());
      if (nv != null && nv != _reconResult!.solventVolumeMl) {
        setState(() {
          _updateSummaryCardVolume(nv);
        });
      }
    }
  }
  
  void _updateSummaryCardVolume(double newVolume) {
    if (_reconResult != null) {
      // Just update the volume, keep everything else from saved calculator result
      setState(() {
        _reconResult = ReconstitutionResult(
          perMlConcentration: _reconResult!.perMlConcentration,
          solventVolumeMl: newVolume,
          recommendedUnits: _reconResult!.recommendedUnits,
          syringeSizeMl: _reconResult!.syringeSizeMl,
          diluentName: _reconResult!.diluentName,
          recommendedDose: _reconResult!.recommendedDose,
          doseUnit: _reconResult!.doseUnit,
          maxVialSizeMl: _reconResult!.maxVialSizeMl,
        );
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
  
  void _scrollToCalculator() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _calculatorKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.0, // Align to top
        );
      }
    });
  }
  
  void _scrollToSummary() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _summaryKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

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
        _buildCalculatorButton(),
        if (_showCalculator) ...[
          const SizedBox(height: 12),
          Container(
            key: _calculatorKey,
            child: _buildCalculatorWidget(),
          ),
        ] else if (_reconResult != null) ...[
          const SizedBox(height: 12),
          Container(
            key: _summaryKey,
            child: _buildSavedReconstitution(),
          ),
        ],
        const SizedBox(height: 24),
        _buildVialVolumeField(isDarkMode),
      ],
    );
  }


  Widget _buildCalculatorButton() {
    final strengthVal = double.tryParse(widget.strengthController.text.trim());
    final hasStrength = strengthVal != null && strengthVal > 0;
    final theme = Theme.of(context);

    return Center(
      child: _showCalculator
          ? FilledButton.icon(
              onPressed: () {
                setState(() => _showCalculator = false);
                widget.onCalculatorVisibilityChanged?.call(false);
              },
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Close Calculator'),
            )
          : (_reconResult != null
              // Show combined Reconstituted chip + Edit button
              ? OutlinedButton.icon(
                  onPressed: hasStrength
                      ? () {
                          setState(() => _showCalculator = true);
                          widget.onCalculatorVisibilityChanged?.call(true);
                          _scrollToCalculator();
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reconstituted',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('•'),
                      SizedBox(width: 6),
                      Text('Edit'),
                    ],
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: hasStrength
                      ? () {
                          setState(() => _showCalculator = true);
                          widget.onCalculatorVisibilityChanged?.call(true);
                          _scrollToCalculator();
                        }
                      : null,
                  icon: const Icon(Icons.calculate, size: 18),
                  label: const Text('Reconstitution Calculator'),
                )),
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
          _scrollToSummary();

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
        widget.onCalculatorVisibilityChanged?.call(false); // Notify parent calculator is closed

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
    
    // Check if current volume exceeds max constraint
    final maxVialSize = result.maxVialSizeMl ?? 1000.0;
    final exceedsMax = result.solventVolumeMl > maxVialSize && maxVialSize < 1000.0;

    // Format values with consistent 2 decimal places for volume
    final strengthStr = strengthVal == strengthVal.roundToDouble()
        ? strengthVal.toStringAsFixed(0)
        : strengthVal.toString();
    final volumeStr = exceedsMax ? '—' : result.solventVolumeMl.toStringAsFixed(2);
    final drawStr = exceedsMax
        ? '—'
        : (result.recommendedUnits == result.recommendedUnits.roundToDouble()
            ? result.recommendedUnits.toStringAsFixed(0)
            : result.recommendedUnits.toStringAsFixed(1));
    final mlDrawStr = exceedsMax
        ? '—'
        : (result.recommendedUnits / 100 * result.syringeSizeMl).toStringAsFixed(2);
    final syringeStr = result.syringeSizeMl.toStringAsFixed(1);

    // Build the full rich summary card
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full summary card (no padding towards parent, full width)
        Container(
          padding: kReconSummaryPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.08),
                theme.colorScheme.primary.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(kReconSummaryBorderRadius),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: kReconSummaryBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                // Icon header
                Icon(
                  Icons.science_outlined,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 10),
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
                          fontSize: 17,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (medName.isNotEmpty) ...[
                        TextSpan(
                          text: '  of  ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(kReconTextHighOpacity),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: medName,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                          fontSize: 28,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: '  of  ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(kReconTextHighOpacity),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: diluentName,
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Divider matching calculator style
                Container(
                  height: kReconDividerHeight,
                  margin: EdgeInsets.symmetric(vertical: kReconDividerVerticalMargin),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        theme.colorScheme.primary.withOpacity(kReconDividerOpacity),
                        Colors.transparent,
                      ],
                      stops: kReconDividerStops,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
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
                          fontSize: 19,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '$mlDrawStr mL',
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                          fontSize: 15,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' syringe'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Dose info or out-of-range warning
                if (exceedsMax)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kReconErrorBackground.withOpacity(kReconErrorOpacity),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kReconErrorBackground.withOpacity(0.5),
                        width: kReconSummaryBorderWidth,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 16,
                          color: kReconErrorBackground,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Volume exceeds max vial size (${maxVialSize.toStringAsFixed(1)} mL)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: kReconErrorBackground,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (result.recommendedDose != null && result.doseUnit != null)
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
                            fontSize: 15,
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
        const SizedBox(height: 12),
        // Target dose heading
        Text(
          'Target Dose',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Syringe gauge with number indicator
        WhiteSyringeGauge(
          totalUnits: result.syringeSizeMl * 100,
          fillUnits: exceedsMax ? 0 : result.recommendedUnits,
          showValueLabel: true,
        ),
      ],
    );
  }

  Widget _buildVialVolumeField(bool isDarkMode) {
    final theme = Theme.of(context);
    // Lock field while calculator is open, unlock after save
    final isLocked = _showCalculator;
    
    // Check if current value exceeds max constraint
    final maxVialSize = _reconResult?.maxVialSizeMl ?? 1000.0;
    final currentValue = double.tryParse(widget.vialVolumeController.text.trim()) ?? 0;
    final exceedsMax = currentValue > maxVialSize && maxVialSize < 1000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelFieldRow(
          key: widget.vialVolumeKey,
          label: 'Total Volume (mL)',
          labelWidth: _labelWidth(),
          lightText: isDarkMode, // Make label visible on dark background
      field: isLocked
              ? SizedBox(
                  width: 120,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _reconResult != null && _showCalculator
                          ? _reconResult!.solventVolumeMl.toStringAsFixed(2)
                          : (widget.vialVolumeController.text.isEmpty
                              ? '0.00'
                              : widget.vialVolumeController.text),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : StepperRow36(
                  controller: widget.vialVolumeController,
                  enabled: true,
                  onDec: () {
                    final d = double.tryParse(widget.vialVolumeController.text.trim()) ?? 0;
                    final nv = (d - 0.5).clamp(0.0, 999.99);
                    setState(() {
                      widget.vialVolumeController.text = nv.toStringAsFixed(2);
                      // Update summary card if saved recon exists
                      _updateSummaryCardVolume(nv.toDouble());
                    });
                  },
                  onInc: () {
                    final d = double.tryParse(widget.vialVolumeController.text.trim()) ?? 0;
                    final nv = (d + 0.5).clamp(0.0, 999.99);
                    setState(() {
                      widget.vialVolumeController.text = nv.toStringAsFixed(2);
                      // Update summary card if saved recon exists
                      _updateSummaryCardVolume(nv.toDouble());
                    });
                  },
                  decoration: buildCompactFieldDecoration(
                    context: context,
                    hint: '0.0',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  compact: true,
                ),
        ),
        Padding(
          padding: EdgeInsets.only(left: _labelWidth() + 8, top: 4),
          child: Text(
            exceedsMax
                ? 'Warning: Volume exceeds max vial size (${maxVialSize.toStringAsFixed(1)} mL)'
                : (_showCalculator
                    ? 'Total volume updates automatically as you adjust the calculator above'
                    : 'Total volume after reconstitution'),
            textAlign: TextAlign.left,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: kHintFontSize,
              color: exceedsMax
                  ? Colors.orange
                  : (isDarkMode
                      ? Colors.white.withOpacity(kReconTextMediumOpacity)
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75)),
              fontStyle: FontStyle.italic,
              fontWeight: exceedsMax ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}
