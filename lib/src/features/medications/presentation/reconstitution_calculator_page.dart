import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/format.dart';
import 'reconstitution_calculator_dialog.dart';

class ReconstitutionCalculatorPage extends StatefulWidget {
  const ReconstitutionCalculatorPage({
    super.key,
    required this.initialStrengthValue,
    required this.unitLabel,
    this.initialDoseValue,
    this.initialDoseUnit,
    this.initialSyringeSize,
    this.initialVialSize,
  });

  final double initialStrengthValue;
  final String unitLabel;
  final double? initialDoseValue;
  final String? initialDoseUnit;
  final SyringeSizeMl? initialSyringeSize;
  final double? initialVialSize;

  @override
  State<ReconstitutionCalculatorPage> createState() => _ReconstitutionCalculatorPageState();
}

class _ReconstitutionCalculatorPageState extends State<ReconstitutionCalculatorPage> {
  // We will embed the same logic as the dialog but with a sticky footer.
  // To avoid duplication here, we instantiate the dialog's stateful widget in a hidden
  // subtree and forward the same params, then mirror its UI with a sticky footer.

  // For simplicity now: open the dialog immediately and replace this page with the result.
  // This preserves navigation and provides a working full-screen route. We keep the
  // sticky footer version on the roadmap if you want a persistent page later.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await showDialog<ReconstitutionResult>(
        context: context,
        builder: (ctx) => ReconstitutionCalculatorDialog(
          initialStrengthValue: widget.initialStrengthValue,
          unitLabel: widget.unitLabel,
          initialDoseValue: widget.initialDoseValue,
          initialDoseUnit: widget.initialDoseUnit,
          initialSyringeSize: widget.initialSyringeSize,
          initialVialSize: widget.initialVialSize,
        ),
      );
      if (!mounted) return;
      context.pop(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

