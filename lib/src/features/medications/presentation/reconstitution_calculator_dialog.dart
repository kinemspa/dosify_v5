import 'package:flutter/material.dart';
import 'reconstitution_calculator_widget.dart';

enum SyringeSizeMl { ml0_3, ml0_5, ml1, ml3, ml5 }

extension SyringeSizeX on SyringeSizeMl {
  double get ml => switch (this) {
    SyringeSizeMl.ml0_3 => 0.3,
    SyringeSizeMl.ml0_5 => 0.5,
    SyringeSizeMl.ml1 => 1.0,
    SyringeSizeMl.ml3 => 3.0,
    SyringeSizeMl.ml5 => 5.0,
  };

  int get totalUnits => (ml * 100).round(); // assume 100 IU per mL mapping

  String get label => '${ml.toStringAsFixed(1)} mL';
}

class ReconstitutionResult {
  const ReconstitutionResult({
    required this.perMlConcentration,
    required this.solventVolumeMl,
    required this.recommendedUnits,
    required this.syringeSizeMl,
    this.diluentName,
  });

  final double perMlConcentration; // same base unit as dose/strength (per mL)
  final double solventVolumeMl; // mL to add to vial
  final double recommendedUnits; // IU fill for the dose
  final double syringeSizeMl; // chosen syringe size mL
  final String? diluentName; // name of diluent fluid (e.g., 'Sterile Water')
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
    return AlertDialog(
      title: const Text('Reconstitution Calculator'),
      content: SingleChildScrollView(
        child: ReconstitutionCalculatorWidget(
          initialStrengthValue: widget.initialStrengthValue,
          unitLabel: widget.unitLabel,
          initialDoseValue: widget.initialDoseValue,
          initialDoseUnit: widget.initialDoseUnit,
          initialSyringeSize: widget.initialSyringeSize,
          initialVialSize: widget.initialVialSize,
          showSummary: true,
          showApplyButton: false,
          onCalculate: _onCalculation,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<ReconstitutionResult>(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSubmit
              ? () {
                  Navigator.of(context).pop(_lastResult);
                }
              : null,
          child: const Text('Save Reconstitution'),
        ),
      ],
    );
  }
}
