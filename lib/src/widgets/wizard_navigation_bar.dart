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
        // Some editable fields use focus nodes that are marked skipTraversal.
        // We still want to treat them as “a field is focused” for the
        // Next/Continue label logic.
        .where((node) => node.canRequestFocus)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep >= stepCount - 1;

    return AnimatedBuilder(
      animation: FocusManager.instance,
      builder: (context, _) {
        final scope = fieldFocusScope ?? FocusScope.of(context);

        final focusables = _focusableFields(scope);
        final focused = FocusManager.instance.primaryFocus;
        final focusedIndex = focused == null ? -1 : focusables.indexOf(focused);
        final hasMoreFieldToFocus =
            focusedIndex >= 0 && focusedIndex < focusables.length - 1;

        // When a field is focused, use the primary action to move through
        // fields first (Next), and only advance the wizard when there are no
        // more focusable fields.
        final showFieldNext = focusedIndex >= 0 && !isLastStep;

        final primaryLabel = isLastStep
            ? saveLabel
            : (showFieldNext
                  ? (hasMoreFieldToFocus ? nextLabel : nextPageLabel)
                  : continueLabel);

        final VoidCallback? primaryAction;
        if (isLastStep) {
          primaryAction = canProceed ? onSave : null;
        } else if (showFieldNext) {
          primaryAction = () {
            final moved = scope.nextFocus();
            if (moved) return;
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
