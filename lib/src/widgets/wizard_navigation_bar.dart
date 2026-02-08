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
  final VoidCallback onSave;
  final String saveLabel;
  final FocusScopeNode? fieldFocusScope;
  final String continueLabel;
  final String nextLabel;
  final String nextPageLabel;

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep >= stepCount - 1;

    final primaryLabel = isLastStep ? saveLabel : continueLabel;
    final scope = fieldFocusScope ?? FocusScope.of(context);

    final VoidCallback? primaryAction = isLastStep
        ? (canProceed ? onSave : null)
        : (canProceed
              ? () {
                  scope.unfocus();
                  onContinue();
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
