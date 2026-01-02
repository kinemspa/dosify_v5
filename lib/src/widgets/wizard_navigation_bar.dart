import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:flutter/material.dart';

class WizardNavigationBar extends StatelessWidget {
  const WizardNavigationBar({
    required this.currentStep,
    required this.stepCount,
    required this.canProceed,
    required this.onBack,
    required this.onContinue,
    required this.onSave,
    required this.saveLabel,
    this.continueLabel = 'Continue',
    this.nextLabel = 'Next',
    super.key,
  });

  final int currentStep;
  final int stepCount;
  final bool canProceed;
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final VoidCallback onSave;
  final String saveLabel;
  final String continueLabel;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep >= stepCount - 1;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // While the keyboard is open, prefer a "Next" affordance to move focus
    // through the current step without forcing the user to dismiss the keyboard.
    final showNextMode = keyboardOpen && !isLastStep && !canProceed;

    final primaryLabel = isLastStep
        ? saveLabel
        : (showNextMode ? nextLabel : continueLabel);

    final VoidCallback? primaryAction;
    if (isLastStep) {
      primaryAction = canProceed ? onSave : null;
    } else if (showNextMode) {
      primaryAction = () {
        final moved = FocusScope.of(context).nextFocus();
        if (!moved) {
          FocusScope.of(context).unfocus();
        }
      };
    } else {
      primaryAction = canProceed ? onContinue : null;
    }

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
          if (onBack != null)
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                child: const Text('Back'),
              ),
            ),
          if (onBack != null) const SizedBox(width: kSpacingM),
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
