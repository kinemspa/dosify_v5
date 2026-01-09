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

  List<FocusNode> _focusableFields(FocusScopeNode scope) {
    return scope.traversalDescendants
        .where((node) => node.canRequestFocus && !node.skipTraversal)
        .toList(growable: false);
  }

  bool _hasAnyFocusableField(FocusScopeNode scope) {
    return _focusableFields(scope).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep >= stepCount - 1;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnimatedBuilder(
      animation: FocusManager.instance,
      builder: (context, _) {
        final scope = fieldFocusScope ?? FocusScope.of(context);

        // While the keyboard is open, the primary action should advance through
        // fields (not wizard steps) as long as there are focusable fields.
        final showNextMode =
            keyboardOpen && !isLastStep && _hasAnyFocusableField(scope);

        final primaryLabel = isLastStep
            ? saveLabel
            : (showNextMode ? nextLabel : continueLabel);

        final VoidCallback? primaryAction;
        if (isLastStep) {
          primaryAction = canProceed ? onSave : null;
        } else if (showNextMode) {
          primaryAction = () {
            final focusables = _focusableFields(scope);
            if (focusables.isEmpty) {
              if (canProceed) {
                onContinue();
                return;
              }
              scope.unfocus();
              return;
            }

            final focused = scope.focusedChild;
            final focusedIndex = focused == null
                ? -1
                : focusables.indexOf(focused);

            if (focusedIndex == -1) {
              focusables.first.requestFocus();
              return;
            }

            if (focusedIndex < focusables.length - 1) {
              focusables[focusedIndex + 1].requestFocus();
              return;
            }

            // Last field on this step; proceed if allowed.
            if (canProceed) {
              onContinue();
              return;
            }

            scope.unfocus();
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
      },
    );
  }
}
