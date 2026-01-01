// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_widget.dart';

enum SyringeSizeMl { ml0_3, ml0_5, ml1, ml3, ml5 }

extension SyringeSizeX on SyringeSizeMl {
  double get ml => switch (this) {
    SyringeSizeMl.ml0_3 => 0.3,
    SyringeSizeMl.ml0_5 => 0.5,
    SyringeSizeMl.ml1 => 1.0,
    SyringeSizeMl.ml3 => 3.0,
    SyringeSizeMl.ml5 => 5.0,
  };

  int get totalUnits => (ml * 100).round(); // assume 100 units per mL mapping

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
}

class ReconstitutionCalculatorDialog extends StatefulWidget {
  const ReconstitutionCalculatorDialog({
    super.key,
    required this.initialStrengthValue,
    required this.unitLabel, // e.g., mg, mcg, g, units
    this.initialDoseValue,
    this.initialDoseUnit,
    this.initialSyringeSize,
    this.initialVialSize,
  });

  final double initialStrengthValue; // total quantity in the vial (S)
  final String unitLabel;
  final double? initialDoseValue;
  final String? initialDoseUnit; // 'mcg'|'mg'|'g'|'units'
  final SyringeSizeMl? initialSyringeSize;
  final double? initialVialSize; // mL

  @override
  State<ReconstitutionCalculatorDialog> createState() =>
      _ReconstitutionCalculatorDialogState();
}

class _ReconstitutionCalculatorDialogState
    extends State<ReconstitutionCalculatorDialog> {
  ReconstitutionResult? _lastResult;
  bool _canSubmit = false;

  void _onCalculation(ReconstitutionResult result, bool isValid) {
    setState(() {
      _lastResult = result;
      _canSubmit = isValid;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white.withValues(alpha: 0.3),
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
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Reconstitution Calculator',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ReconstitutionCalculatorWidget(
                initialStrengthValue: widget.initialStrengthValue,
                unitLabel: widget.unitLabel,
                initialDoseValue: widget.initialDoseValue,
                initialDoseUnit: widget.initialDoseUnit,
                initialSyringeSize: widget.initialSyringeSize,
                initialVialSize: widget.initialVialSize,
                onCalculate: _onCalculation,
              ),
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
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
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
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
