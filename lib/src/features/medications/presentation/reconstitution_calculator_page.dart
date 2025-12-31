// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_widget.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
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

  void _onCalculation(ReconstitutionResult result, bool isValid) {
    // Results handled by calculator widget
  }

  @override
  Widget build(BuildContext context) {
    final strengthValue = double.tryParse(_strengthCtrl.text) ?? 0;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Reconstitution Calculator'),
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
          if (strengthValue > 0)
            ReconstitutionCalculatorWidget(
              initialStrengthValue: strengthValue,
              unitLabel: _selectedUnit,
              medicationName: _medNameCtrl.text.trim().isNotEmpty
                  ? _medNameCtrl.text.trim()
                  : null,
              initialDoseValue: widget.initialDoseValue,
              initialDoseUnit: widget.initialDoseUnit,
              initialSyringeSize: widget.initialSyringeSize,
              initialVialSize: widget.initialVialSize,
              showSummary: true,
              onCalculate: _onCalculation,
            )
          else
            SectionFormCard(
              title: 'Calculator',
              neutral: true,
              children: [
                Text(
                  'Enter the vial strength above to use the calculator',
                  style: helperTextStyle(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
