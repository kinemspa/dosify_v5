// Dart imports:
import 'dart:async';
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_helpers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';

/// Legacy local stepper replaced by shared StepperRow36 for consistency.

/// Reusable reconstitution calculator widget used in both dialog and inline contexts
class ReconstitutionCalculatorWidget extends StatefulWidget {
  const ReconstitutionCalculatorWidget({
    required this.initialStrengthValue,
    required this.unitLabel,
    super.key,
    this.medicationName,
    this.initialDiluentName,
    this.initialDoseValue,
    this.initialDoseUnit,
    this.initialSyringeSize,
    this.initialVialSize,
    this.onApply,
    this.onCalculate,
    this.showSummary = true,
    this.showApplyButton = false,
  });

  final double initialStrengthValue;
  final String unitLabel;
  final String? medicationName;
  final String? initialDiluentName;
  final double? initialDoseValue;
  final String? initialDoseUnit;
  final SyringeSizeMl? initialSyringeSize;
  final double? initialVialSize;
  final void Function(ReconstitutionResult)? onApply;
  final void Function(ReconstitutionResult, bool)? onCalculate;
  final bool showSummary;
  final bool showApplyButton;

  @override
  State<ReconstitutionCalculatorWidget> createState() =>
      _ReconstitutionCalculatorWidgetState();
}

class _ReconstitutionCalculatorWidgetState
    extends State<ReconstitutionCalculatorWidget>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _doseCtrl;
  final TextEditingController _vialSizeCtrl = TextEditingController();
  final TextEditingController _diluentNameCtrl = TextEditingController();
  late String _doseUnit;
  SyringeSizeMl _syringe = SyringeSizeMl.ml1;
  double _selectedUnits = 50;
  String? _selectedOption; // Track which option is selected
  Timer? _repeatTimer;
  bool _isIncrementing = true;

  // Animation for smooth preset transitions
  late AnimationController _transitionController;
  late Animation<double> _unitsAnimation;
  double _targetUnits = 50;

  String _normalizeDoseUnit({
    required String? unit,
    required String unitLabel,
  }) {
    if (unitLabel == 'units') return 'units';
    switch ((unit ?? '').trim().toLowerCase()) {
      case 'mcg':
      case 'mg':
      case 'g':
        return unit!.trim().toLowerCase();
      default:
        return 'mcg';
    }
  }

  @override
  void initState() {
    super.initState();
    // Default to 100 or use provided value
    final defaultDose = widget.initialDoseValue ?? 100;
    _doseCtrl = TextEditingController(
      text: defaultDose == defaultDose.roundToDouble()
          ? defaultDose.toInt().toString()
          : defaultDose.toStringAsFixed(2),
    );
    // Set dose unit to match vial unit for units-based medications, otherwise default to mcg
    _doseUnit = _normalizeDoseUnit(
      unit: widget.initialDoseUnit,
      unitLabel: widget.unitLabel,
    );
    _syringe = widget.initialSyringeSize ?? _syringe;
    if (widget.initialVialSize != null) {
      _vialSizeCtrl.text = widget.initialVialSize!.toStringAsFixed(2);
    }
    final initialDiluentName = widget.initialDiluentName?.trim();
    if (initialDiluentName != null && initialDiluentName.isNotEmpty) {
      _diluentNameCtrl.text = initialDiluentName;
    }
    _selectedUnits = _syringe.totalUnits * 0.5;
    _targetUnits = _selectedUnits;

    // Initialize animation controller
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _unitsAnimation =
        Tween<double>(begin: _selectedUnits, end: _targetUnits).animate(
          CurvedAnimation(
            parent: _transitionController,
            curve: Curves.easeInOutCubic,
          ),
        )..addListener(() {
          setState(() {
            _selectedUnits = _unitsAnimation.value;
          });
        });
  }

  @override
  void didUpdateWidget(covariant ReconstitutionCalculatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unitLabel != widget.unitLabel) {
      final normalized = _normalizeDoseUnit(
        unit: _doseUnit,
        unitLabel: widget.unitLabel,
      );
      if (normalized != _doseUnit && mounted) {
        setState(() {
          _doseUnit = normalized;
        });
      }
    }
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _transitionController.dispose();
    _doseCtrl.dispose();
    _vialSizeCtrl.dispose();
    _diluentNameCtrl.dispose();
    super.dispose();
  }

  /// Starts repeating increment/decrement when user long-presses the syringe buttons.
  ///
  /// Provides continuous adjustment with an initial delay of 500ms before starting
  /// rapid repeat at 100ms intervals. This allows for precise fine-tuning of values.
  void _startRepeating(bool increment, double min, double max) {
    _isIncrementing = increment;
    // Initial delay before starting rapid repeat
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_repeatTimer == null || !_repeatTimer!.isActive) {
        _repeatTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (mounted) {
            final delta = _isIncrementing ? 1.0 : -1.0; // Change by whole units
            final newValue = (_selectedUnits + delta)
                .clamp(min, max)
                .roundToDouble();
            setState(() {
              _selectedUnits = newValue;
              _selectedOption = null;
            });
          }
        });
      }
    });
  }

  /// Stops the repeating increment/decrement when user releases the long-press.
  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  /// Animates the syringe slider smoothly to a target value.
  ///
  /// Used when selecting preset options (Concentrated, Balanced, Diluted) to provide
  /// visual feedback and smooth transitions between values. Uses easeInOutCubic curve
  /// for natural, professional motion over 400ms.
  void _animateToUnits(double targetValue) {
    _targetUnits = targetValue;
    _unitsAnimation = Tween<double>(begin: _selectedUnits, end: _targetUnits)
        .animate(
          CurvedAnimation(
            parent: _transitionController,
            curve: Curves.easeInOutCubic,
          ),
        );
    _transitionController.reset();
    _transitionController.forward();
  }

  // Helper methods now imported from reconstitution_calculator_helpers.dart
  // - round2() - Round to 2 decimal places
  // - roundToHalfMl() - Round to nearest 0.5 mL
  // - formatDouble() - Format for display (was _fmt)
  // - toBaseMass() - Convert units to mg (was _toBaseMass)

  /// Formats a numeric value removing trailing zeros for cleaner display.
  ///
  /// Examples:
  /// - 10.00 → "10"
  /// - 10.50 → "10.5"
  /// - 10.25 → "10.25"
  String _formatNoTrailing(double value) {
    final str = value.toStringAsFixed(2);
    if (str.contains('.')) {
      return str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return str;
  }

  /// Creates a subtle gradient divider line for visual section separation.
  ///
  /// Uses primary color with opacity fading to transparent on edges for elegant
  /// visual hierarchy without harsh lines.
  Widget _gradientDivider(BuildContext context) {
    return Container(
      height: kReconDividerHeight,
      margin: EdgeInsets.symmetric(vertical: kReconDividerVerticalMargin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: kReconDividerOpacity),
            Colors.transparent,
          ],
          stops: kReconDividerStops,
        ),
      ),
    );
  }

  /// Computes concentration and vial volume for reconstitution based on units.
  ///
  /// This is the core calculation that determines how much diluent to add to achieve
  /// the desired concentration for the target dose.
  ///
  /// Parameters:
  /// - [S]: Total strength in vial (in base mass units, typically mg)
  /// - [D]: Desired dose per injection (in base mass units, typically mg)
  /// - [U]: Insulin syringe units to draw (0-100 scale per mL)
  ///
  /// Formula:
  /// - Vial Volume: V = (S / D) × (U / 100)
  /// - Concentration: C = D × (100 / U)
  ///
  /// Returns a record with:
  /// - [cPerMl]: Concentration per mL
  /// - [vialVolume]: Total volume to add to vial in mL
  ({double cPerMl, double vialVolume}) _computeForUnits({
    required double S,
    required double D,
    required double U,
  }) {
    final c = (100 * D) / max(U, 0.01);
    final v = (S / max(D, 0.000001)) * (U / 100.0);
    return (cPerMl: c, vialVolume: v);
  }

  /// Calculates the three preset syringe unit values for the current syringe size.
  ///
  /// Returns three values representing different reconstitution concentrations:
  /// - Concentrated (5% or min 5 units): Strong, small doses
  /// - Balanced (33%): Medium concentration
  /// - Diluted (80%): Weaker, larger doses
  ///
  /// These presets give users quick options without manual slider adjustment.
  (double, double, double) _presetUnitsRaw() {
    final total = _syringe.totalUnits.toDouble();
    final minU = max(5, (total * 0.05).ceil()).toDouble();
    final midU = round2(total * 0.33);
    final highU = round2(total * 0.80);
    return (minU, midU, highU);
  }

  InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Keep the field readable in both light+dark themes:
    // - Light theme: use surface (typically light)
    // - Dark theme: use a subtle onSurface tint so the field is slightly
    //   lighter than the dark calculator background
    final fill = isDark
        ? cs.onSurface.withValues(alpha: kOpacitySubtleLow)
        : cs.surface;

    return InputDecoration(
      hintText: hint,
      hintStyle: hintTextStyle(context),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          width: kOutlineWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: kFocusedOutlineWidth),
      ),
    );
  }

  Widget _rowLabelField(
    BuildContext context, {
    required String label,
    required Widget field,
  }) {
    // Use unified row with light text for dark background
    return LabelFieldRow(label: label, field: field, lightText: true);
  }

  Widget _helperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 128, bottom: 8, top: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: reconForegroundColor(
            context,
          ).withValues(alpha: kReconTextMediumOpacity),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show calculator content if strength is valid
    if (widget.initialStrengthValue <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fg = reconForegroundColor(context);

    // Keep dose unit valid for the dropdown options.
    // This avoids a common Flutter assertion when the current value is not
    // present in the items list.
    final normalizedDoseUnit = _normalizeDoseUnit(
      unit: _doseUnit,
      unitLabel: widget.unitLabel,
    );
    if (normalizedDoseUnit != _doseUnit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _doseUnit = normalizedDoseUnit;
          });
        }
      });
    }

    // Use strength from parent (already set above)
    final Sraw = widget.initialStrengthValue;
    final Draw = double.tryParse(_doseCtrl.text) ?? 0;

    var S = Sraw;
    var D = Draw;
    if (widget.unitLabel != 'units') {
      final sMg = toBaseMass(Sraw, widget.unitLabel);
      final dMg = toBaseMass(Draw, _doseUnit);
      S = sMg;
      D = dMg;
    }

    final vialMax = double.tryParse(_vialSizeCtrl.text);
    final (minURaw, midURaw, highURaw) = _presetUnitsRaw();

    final totalUnits = _syringe.totalUnits.toDouble();
    var iuMin = minURaw;
    var iuMax = totalUnits;
    if (vialMax != null && vialMax > 0 && S > 0 && D > 0) {
      final uMaxAllowed = (100 * D * vialMax) / S;
      iuMax = uMaxAllowed.clamp(0, totalUnits).toDouble();
      if (iuMax < iuMin) iuMin = iuMax;
    }

    final sliderMin = iuMin;
    final sliderMax = iuMax;
    _selectedUnits = _selectedUnits.clamp(sliderMin, sliderMax);

    final current = _computeForUnits(S: S, D: D, U: _selectedUnits);
    final currentC = round2(current.cPerMl);
    final currentV = current.vialVolume; // Use precise value for live display
    final fitsVial = vialMax == null || currentV <= vialMax + 1e-9;

    // Notify parent of calculation result (use precise value for live display)
    final result = ReconstitutionResult(
      perMlConcentration: currentC,
      solventVolumeMl: currentV, // Use precise value not rounded
      recommendedUnits: _selectedUnits.roundToDouble(), // Round to whole units
      syringeSizeMl: _syringe.ml,
      strengthValueUsed: widget.initialStrengthValue,
      strengthUnitUsed: widget.unitLabel,
      diluentName: _diluentNameCtrl.text.trim().isNotEmpty
          ? _diluentNameCtrl.text.trim()
          : null,
      recommendedDose: Draw,
      doseUnit: _doseUnit,
      maxVialSizeMl: vialMax,
    );
    final isValid = S > 0 && D > 0 && fitsVial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCalculate?.call(result, isValid);
    });

    final u1 = sliderMin;
    final u3 = sliderMax;
    final u2 = sliderMin + (sliderMax - sliderMin) / 2.0;

    final conc = _computeForUnits(S: S, D: D, U: u1);
    final std = _computeForUnits(S: S, D: D, U: u2);
    final dil = _computeForUnits(S: S, D: D, U: u3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        // Strength value made prominent with larger font and bold - centered
        Center(
          child: Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fg.withValues(alpha: kReconTextMediumOpacity),
                  ),
                  children: [
                    const TextSpan(text: 'Using vial strength: '),
                    TextSpan(
                      text:
                          '${formatDouble(widget.initialStrengthValue)} ${widget.unitLabel}',
                      style: reconSummaryStrengthTextStyle(
                        context,
                        compact: true,
                        color: theme.colorScheme.primary,
                        fontWeight: kFontWeightBold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'To adjust, go to Strength section above',
                textAlign: TextAlign.center,
                style: helperTextStyle(context)?.copyWith(
                  color: fg.withValues(alpha: kReconTextMutedOpacity),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'The calculator determines how much diluent to add for correct doses. Enter diluent name (optional), desired dose (D), syringe size, and optional max vial size. Then pick an option below or fine-tune with the slider.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: fg.withValues(alpha: kReconTextMediumOpacity),
            ),
          ),
        ),
        _rowLabelField(
          context,
          label: 'Diluent',
          field: Field36(
            child: TextField(
              controller: _diluentNameCtrl,
              textCapitalization: kTextCapitalizationDefault,
              decoration: _fieldDecoration(
                context,
                hint: 'e.g., Sterile Water',
              ),
              onChanged: (_) => setState(() {}),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        _helperText(
          'Optional label for the mixing liquid (e.g., Sterile Water)',
        ),
        _rowLabelField(
          context,
          label: 'Desired Dose',
          field: StepperRow36(
            controller: _doseCtrl,
            onDec: () {
              final v = double.tryParse(_doseCtrl.text.trim()) ?? 0;
              final newVal = (v - 1).clamp(1, double.infinity);
              setState(() {
                _doseCtrl.text = newVal == newVal.roundToDouble()
                    ? newVal.toInt().toString()
                    : newVal.toString();
              });
            },
            onInc: () {
              final v = double.tryParse(_doseCtrl.text.trim()) ?? 0;
              final newVal = (v + 1).clamp(1, double.infinity);
              setState(() {
                _doseCtrl.text = newVal == newVal.roundToDouble()
                    ? newVal.toInt().toString()
                    : newVal.toString();
              });
            },
            decoration: _fieldDecoration(context, hint: '100'),
          ),
        ),
        _rowLabelField(
          context,
          label: 'Dose Unit',
          field: SmallDropdown36<String>(
            value: _doseUnit,
            items: [
              if (widget.unitLabel == 'units')
                const DropdownMenuItem(
                  value: 'units',
                  child: Center(child: Text('units')),
                ),
              if (widget.unitLabel != 'units') ...const [
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
              ],
            ],
            onChanged: (v) {
              // Don't reset dose value when changing unit
              setState(() => _doseUnit = v!);
            },
            decoration: _fieldDecoration(context),
          ),
        ),
        _helperText(
          'Desired dose (D): amount per injection. Choose the unit that matches your dose.',
        ),
        _rowLabelField(
          context,
          label: 'Syringe Size',
          field: SmallDropdown36<SyringeSizeMl>(
            value: _syringe,
            items: SyringeSizeMl.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Center(child: Text(s.label)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _syringe = v!;
              final total = _syringe.totalUnits.toDouble();
              _selectedUnits = max(
                _selectedUnits,
                max(5, (0.05 * total).ceil()).toDouble(),
              );
            }),
            decoration: _fieldDecoration(context),
          ),
        ),
        _helperText(
          'Sets the syringe markings (100 units = 1.0 mL) and limits the maximum volume.',
        ),
        _rowLabelField(
          context,
          label: 'Max Vial Size',
          field: StepperRow36(
            controller: _vialSizeCtrl,
            onDec: () {
              final v = double.tryParse(_vialSizeCtrl.text.trim()) ?? 0;
              final newVal = (v - 1).clamp(0, 100);
              setState(() {
                _vialSizeCtrl.text = newVal == newVal.roundToDouble()
                    ? newVal.toInt().toString()
                    : newVal.toStringAsFixed(1);
              });
            },
            onInc: () {
              final v = double.tryParse(_vialSizeCtrl.text.trim()) ?? 0;
              final newVal = (v + 1).clamp(0, 100);
              setState(() {
                _vialSizeCtrl.text = newVal == newVal.roundToDouble()
                    ? newVal.toInt().toString()
                    : newVal.toStringAsFixed(1);
              });
            },
            decoration: _fieldDecoration(context, hint: 'mL'),
          ),
        ),
        _helperText(
          'Optional. If set, options requiring more than this vial capacity are disabled.',
        ),
        _gradientDivider(context),
        if (sliderMax > 0 && !sliderMax.isNaN) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Select a reconstitution option',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: kReconTextHighOpacity),
              ),
            ),
          ),
          _buildOptionRow(
            context,
            'Concentrated',
            'concentrated',
            _selectedOption,
            () {
              setState(() {
                _selectedOption = 'concentrated';
              });
              _animateToUnits(u1);
            },
            conc,
            u1,
            isValid: u1 >= sliderMin && u1 <= sliderMax,
          ),
          _buildOptionRow(
            context,
            'Balanced',
            'balanced',
            _selectedOption,
            () {
              setState(() {
                _selectedOption = 'balanced';
              });
              _animateToUnits(u2);
            },
            std,
            u2,
            isValid: u2 >= sliderMin && u2 <= sliderMax,
          ),
          _buildOptionRow(
            context,
            'Diluted',
            'diluted',
            _selectedOption,
            () {
              setState(() {
                _selectedOption = 'diluted';
              });
              _animateToUnits(u3);
            },
            dil,
            u3,
            isValid: u3 >= sliderMin && u3 <= sliderMax,
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No valid options — Check strength, dose, or syringe size',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        _gradientDivider(context),
        // Target Dose heading
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Target Dose',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        // Support text above syringe with U = Units explanation
        Padding(
          padding: const EdgeInsets.symmetric(),
          child: Text(
            'Drag the syringe or use +/- buttons for fine adjustments (U = Units)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: fg.withValues(alpha: kReconTextMediumOpacity),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        // Range limit warning removed - using snackbar only for cleaner UI
        const SizedBox(height: 8),
        // Syringe gauge with fine-tune buttons
        if (S > 0 && D > 0 && !currentV.isNaN && !_selectedUnits.isNaN) ...[
          // Fine-tune buttons with syringe gauge
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Decrement button - original style
              GestureDetector(
                onTap: () {
                  final newValue = (_selectedUnits - 1.0)
                      .clamp(sliderMin, sliderMax)
                      .roundToDouble();
                  setState(() {
                    _selectedUnits = newValue;
                    _selectedOption = null;
                  });
                },
                onLongPressStart: (_) =>
                    _startRepeating(false, sliderMin, sliderMax),
                onLongPressEnd: (_) => _stopRepeating(),
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minHeight: 28,
                      minWidth: 28,
                    ),
                    onPressed: () {
                      final rawValue =
                          _selectedUnits - 1.0; // Decrement by whole unit
                      final newValue = rawValue
                          .clamp(sliderMin, sliderMax)
                          .roundToDouble();

                      // Show snackbar if hitting constraint
                      if (rawValue != newValue) {
                        showAppSnackBar(
                          context,
                          rawValue < sliderMin
                              ? 'Minimum value reached'
                              : (vialMax != null
                                    ? 'Limited by max vial size (${vialMax.toStringAsFixed(1)} mL)'
                                    : 'Limited by syringe capacity'),
                          duration: kAppSnackBarDurationShort,
                        );
                      }

                      setState(() {
                        _selectedUnits = newValue;
                        _selectedOption = null;
                      });
                    },
                    icon: Icon(
                      Icons.remove,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    WhiteSyringeGauge(
                      totalUnits: _syringe.totalUnits.toDouble(),
                      fillUnits: _selectedUnits,
                      interactive: true,
                      maxConstraint: sliderMax,
                      onMaxConstraintHit: () {
                        showAppSnackBar(
                          context,
                          vialMax != null
                              ? 'Limited by max vial size (${vialMax.toStringAsFixed(1)} mL)'
                              : 'Limited by syringe capacity',
                          duration: kAppSnackBarDurationShort,
                        );
                      },
                      onChanged: (newValue) {
                        final clampedValue = newValue
                            .clamp(sliderMin, sliderMax)
                            .roundToDouble(); // Round to whole units
                        setState(() {
                          _selectedUnits = clampedValue;
                          _selectedOption = null;
                        });
                      },
                    ),
                    Positioned(
                      top: -2,
                      right: 0,
                      child: Text(
                        '${_syringe.label} Syringe',
                        style: helperTextStyle(context)?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Increment button - original style
              GestureDetector(
                onTap: () {
                  final newValue = (_selectedUnits + 1.0)
                      .clamp(sliderMin, sliderMax)
                      .roundToDouble();
                  setState(() {
                    _selectedUnits = newValue;
                    _selectedOption = null;
                  });
                },
                onLongPressStart: (_) =>
                    _startRepeating(true, sliderMin, sliderMax),
                onLongPressEnd: (_) => _stopRepeating(),
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minHeight: 28,
                      minWidth: 28,
                    ),
                    onPressed: () {
                      final rawValue =
                          _selectedUnits + 1.0; // Increment by whole unit
                      final newValue = rawValue
                          .clamp(sliderMin, sliderMax)
                          .roundToDouble();

                      // Show snackbar if hitting constraint
                      if (rawValue != newValue) {
                        showAppSnackBar(
                          context,
                          vialMax != null
                              ? 'Limited by max vial size (${vialMax.toStringAsFixed(1)} mL)'
                              : 'Limited by syringe capacity',
                          duration: kAppSnackBarDurationShort,
                        );
                      }

                      setState(() {
                        _selectedUnits = newValue;
                        _selectedOption = null;
                      });
                    },
                    icon: Icon(
                      Icons.add,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Reconstitution summary - featured section with emphasis
          Center(
            child: Container(
              padding: kReconSummaryPadding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(kReconSummaryBorderRadius),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  width: kReconSummaryBorderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.1),
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
                  // Summary header icon
                  Icon(
                    Icons.science_outlined,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  // First line: Reconstitute X of MEDNAME
                  Builder(
                    builder: (context) {
                      final cs = Theme.of(context).colorScheme;
                      final baseTextColor = fg.withValues(
                        alpha: kReconTextHighOpacity,
                      );
                      final baseStyle = reconSummaryBaseTextStyle(
                        context,
                        color: baseTextColor,
                      );
                      final strengthStyle = reconSummaryStrengthTextStyle(
                        context,
                        compact: false,
                        color: cs.primary,
                        fontWeight: kFontWeightExtraBold,
                      );
                      final ofStyle = reconSummaryOfTextStyle(
                        context,
                        compact: false,
                        color: baseTextColor,
                        fontWeight: kFontWeightNormal,
                      );
                      final medicationNameStyle =
                          reconSummaryMedicationNameTextStyle(
                            context,
                            compact: false,
                            color: cs.primary,
                            fontWeight: kFontWeightBold,
                          );
                      final volumeHugeStyle = reconSummaryHugeVolumeTextStyle(
                        context,
                        color: cs.primary,
                        fontWeight: kFontWeightBlack,
                      );
                      final valueStyle = reconSummaryValueTextStyle(
                        context,
                        compact: false,
                        color: cs.primary,
                        fontWeight: kFontWeightBold,
                      );
                      final drawUnitsStyle = reconSummaryDrawUnitsTextStyle(
                        context,
                        color: cs.primary,
                        fontWeight: kFontWeightExtraBold,
                      );

                      final summaryMedicationName =
                          (widget.medicationName ?? '').trim();
                      final hasMedicationName =
                          summaryMedicationName.isNotEmpty;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: baseStyle,
                              children: [
                                const TextSpan(text: 'Reconstitute '),
                                TextSpan(
                                  text:
                                      '${_formatNoTrailing(widget.initialStrengthValue)} ${widget.unitLabel}',
                                  style: strengthStyle,
                                ),
                                if (hasMedicationName) ...[
                                  TextSpan(text: '  of  ', style: ofStyle),
                                  TextSpan(
                                    text: summaryMedicationName,
                                    style: medicationNameStyle,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: baseStyle,
                              children: [
                                const TextSpan(text: 'with '),
                                TextSpan(
                                  text: '${_formatNoTrailing(currentV)} mL',
                                  style: volumeHugeStyle,
                                ),
                                TextSpan(text: '  of  ', style: ofStyle),
                                TextSpan(
                                  text: _diluentNameCtrl.text.trim().isNotEmpty
                                      ? _diluentNameCtrl.text.trim()
                                      : 'diluent',
                                  style: valueStyle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: kReconDividerHeight,
                            margin: EdgeInsets.symmetric(
                              vertical: kReconDividerVerticalMargin,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cs.surface.withValues(
                                    alpha: kOpacityTransparent,
                                  ),
                                  cs.primary.withValues(
                                    alpha: kReconDividerOpacity,
                                  ),
                                  cs.surface.withValues(
                                    alpha: kOpacityTransparent,
                                  ),
                                ],
                                stops: kReconDividerStops,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: baseStyle,
                              children: [
                                const TextSpan(text: 'Draw '),
                                TextSpan(
                                  text: '${_selectedUnits.round()} Units  ',
                                  style: drawUnitsStyle,
                                ),
                                TextSpan(
                                  text:
                                      '${_formatNoTrailing((_selectedUnits / 100) * _syringe.ml)} mL',
                                  style: valueStyle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: baseStyle,
                              children: [
                                const TextSpan(text: 'into a '),
                                TextSpan(
                                  text: _syringe.label,
                                  style: valueStyle,
                                ),
                                const TextSpan(text: ' syringe'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Dose amount on separate line
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: fg.withValues(alpha: kReconTextMediumOpacity),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'for a dose of '),
                        TextSpan(
                          text: '${_formatNoTrailing(Draw)} $_doseUnit',
                          style: reconSummaryValueTextStyle(
                            context,
                            compact: false,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: kFontWeightBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Clarification text
                  Text(
                    'This calculates the reconstitution volume needed to achieve the correct concentration for your target dose. '
                    'This target dose will become your default dose in the schedule screen. '
                    'Doses can be created, adjusted, and tracked on the schedule screen where all medication administration is managed.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fg.withValues(alpha: kReconTextMutedOpacity),
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!fitsVial)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Warning: Computed solvent volume (${currentV.toStringAsFixed(2)} mL) exceeds vial size. Try a more concentrated preset (lower units).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        if (widget.showApplyButton) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: (S > 0 && D > 0 && fitsVial)
                  ? () {
                      final result = ReconstitutionResult(
                        perMlConcentration: currentC,
                        solventVolumeMl: currentV, // Use precise value
                        recommendedUnits: _selectedUnits
                            .roundToDouble(), // Round to whole units
                        syringeSizeMl: _syringe.ml,
                        strengthValueUsed: widget.initialStrengthValue,
                        strengthUnitUsed: widget.unitLabel,
                        diluentName: _diluentNameCtrl.text.trim().isNotEmpty
                            ? _diluentNameCtrl.text.trim()
                            : null,
                        recommendedDose: Draw,
                        doseUnit: _doseUnit,
                        maxVialSizeMl: vialMax,
                      );
                      widget.onApply?.call(result);
                    }
                  : null,
              child: const Text('Save Reconstitution'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionRow(
    BuildContext context,
    String label,
    String optionValue,
    String? selectedValue,
    VoidCallback onTap,
    ({double cPerMl, double vialVolume}) calcResult,
    double units, {
    bool isValid = true,
  }) {
    final selected = selectedValue == optionValue;
    final theme = Theme.of(context);
    final fg = reconForegroundColor(context);
    final roundedVolume = roundToHalfMl(calcResult.vialVolume);
    // Calculate actual mL to draw for the dose
    final mlToDraw = (units / 100) * _syringe.ml;

    // Get explainer text based on label
    String explainerText;
    if (label == 'Concentrated') {
      explainerText = 'High concentration, draw less volume (smaller doses)';
    } else if (label == 'Balanced') {
      explainerText = 'Moderate concentration, balanced draw volume';
    } else if (label == 'Diluted') {
      explainerText = 'Low concentration, draw more volume (larger doses)';
    } else {
      explainerText = '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: isValid ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isValid ? 1.0 : 0.4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              color: selected ? null : fg.withValues(alpha: 0.03),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : fg.withValues(alpha: 0.15),
                width: kReconOptionBorderWidth,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Radio<String>(
                  value: optionValue,
                  groupValue: selectedValue,
                  onChanged: isValid ? (_) => onTap() : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return theme.colorScheme.primary;
                    }
                    return fg.withValues(alpha: 0.5);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: reconCalculatorOptionTitleTextStyle(
                          context,
                          color: selected
                              ? theme.colorScheme.primary
                              : fg.withValues(alpha: kReconTextHighOpacity),
                        ),
                      ),
                      if (explainerText.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          explainerText,
                          style: helperTextStyle(context)?.copyWith(
                            color: fg.withValues(alpha: kReconTextMutedOpacity),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selected
                                ? fg.withValues(alpha: 0.9)
                                : fg.withValues(alpha: 0.7),
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${_diluentNameCtrl.text.trim().isNotEmpty ? _diluentNameCtrl.text.trim() : "Diluent"}: ',
                            ),
                            TextSpan(
                              text: '${formatDouble(roundedVolume)} mL',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selected
                                ? fg.withValues(alpha: kReconTextHighOpacity)
                                : fg.withValues(alpha: kReconTextLowOpacity),
                          ),
                          children: [
                            const TextSpan(text: 'Concentration: '),
                            TextSpan(
                              text:
                                  '${formatDouble(calcResult.cPerMl)} ${widget.unitLabel}/mL',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selected
                                ? fg.withValues(alpha: kReconTextHighOpacity)
                                : fg.withValues(alpha: kReconTextLowOpacity),
                          ),
                          children: [
                            TextSpan(text: 'Syringe (${_syringe.label}): '),
                            TextSpan(
                              text:
                                  '${formatDouble(units)} U / ${formatDouble(mlToDraw)} mL',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
