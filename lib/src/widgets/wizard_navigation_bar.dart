import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:flutter/material.dart';

class WizardNavigationBar extends StatefulWidget {
  const WizardNavigationBar({
    required this.currentStep,
    required this.stepCount,
    required this.canProceed,
    required this.onBack,
    required this.onContinue,
    required this.onSave,
    required this.saveLabel,
    this.fieldFocusScope,
    this.continueLabel = 'Continue',
    this.nextLabel = 'Next',
    this.nextPageLabel = 'Next Page',
    super.key,
  });

  final int currentStep;
  final int stepCount;
  final bool canProceed;
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final Future<void> Function() onSave;
  final String saveLabel;
  final FocusScopeNode? fieldFocusScope;
  final String continueLabel;
  final String nextLabel;
  final String nextPageLabel;

  @override
  State<WizardNavigationBar> createState() => _WizardNavigationBarState();
}

class _WizardNavigationBarState extends State<WizardNavigationBar> {
  bool _isSaving = false;

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSave().timeout(const Duration(seconds: 20));
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save did not complete'),
          content: Text(
            'The save action did not finish successfully.\n\nDetails: $e',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = widget.currentStep >= widget.stepCount - 1;

    final primaryLabel = isLastStep
        ? (_isSaving ? 'Saving...' : widget.saveLabel)
        : widget.continueLabel;
    final scope = widget.fieldFocusScope ?? FocusScope.of(context);

    final VoidCallback? primaryAction = isLastStep
        ? (widget.canProceed && !_isSaving
              ? () {
                  scope.unfocus();
                  _handleSave();
                }
              : null)
        : (widget.canProceed && !_isSaving
              ? () {
                  scope.unfocus();
                  widget.onContinue();
                }
              : null);

    return Container(
      padding: const EdgeInsets.all(kSpacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: kBorderWidthThin,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : widget.onBack,
                child: const Text('Back'),
              ),
            ),
          if (widget.onBack != null) const SizedBox(width: kSpacingM),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: primaryAction,
              child: Text(primaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
