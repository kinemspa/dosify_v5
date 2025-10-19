// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_widget.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class ReconstitutionCalculatorPage extends StatefulWidget {
  const ReconstitutionCalculatorPage({
    required this.initialStrengthValue, required this.unitLabel, super.key,
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
  State<ReconstitutionCalculatorPage> createState() => _ReconstitutionCalculatorPageState();
}

class _ReconstitutionCalculatorPageState extends State<ReconstitutionCalculatorPage> {
  late final TextEditingController _strengthCtrl;
  late final TextEditingController _medNameCtrl;
  late String _selectedUnit; // Track selected unit
  ReconstitutionResult? _lastResult;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _strengthCtrl = TextEditingController(
      text: widget.initialStrengthValue > 0
          ? (widget.initialStrengthValue == widget.initialStrengthValue.roundToDouble()
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
    setState(() {
      _lastResult = result;
      _canSubmit = isValid;
    });
  }

  InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5), width: 0.75),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
    );
  }

  InputDecoration _dropdownDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5), width: 0.75),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strengthValue = double.tryParse(_strengthCtrl.text) ?? 0;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Reconstitution Calculator'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Medication name input (optional)
          LabelFieldRow(
            label: 'Medication',
            field: Field36(
              child: TextField(
                controller: _medNameCtrl,
                decoration: _fieldDecoration(context, hint: 'Optional'),
                onChanged: (_) => setState(() {}),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 128, bottom: 12, top: 2),
            child: Text(
              'Enter the medication name (optional, for context)',
              style: kMutedLabelStyle(context),
            ),
          ),
          // Unit dropdown
          LabelFieldRow(
            label: 'Strength Unit',
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
              decoration: _dropdownDecoration(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 128, bottom: 12, top: 2),
            child: Text('Select the unit for vial strength', style: kMutedLabelStyle(context)),
          ),
          // Strength input row
          LabelFieldRow(
            label: 'Vial Strength',
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
              decoration: _fieldDecoration(context, hint: widget.unitLabel),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 128, bottom: 16, top: 2),
            child: Text(
              'Total drug amount in the vial (before reconstitution)',
              style: kMutedLabelStyle(context),
            ),
          ),
          // Divider
          Divider(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
          const SizedBox(height: 12),
          // Embedded calculator widget
          if (strengthValue > 0)
            ReconstitutionCalculatorWidget(
              initialStrengthValue: strengthValue,
              unitLabel: _selectedUnit,
              medicationName: _medNameCtrl.text.trim().isNotEmpty ? _medNameCtrl.text.trim() : null,
              initialDoseValue: widget.initialDoseValue,
              initialDoseUnit: widget.initialDoseUnit,
              initialSyringeSize: widget.initialSyringeSize,
              initialVialSize: widget.initialVialSize,
              showSummary: false,
              onCalculate: _onCalculation,
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Please enter the vial strength above to use the calculator',
                style: kMutedLabelStyle(context),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
