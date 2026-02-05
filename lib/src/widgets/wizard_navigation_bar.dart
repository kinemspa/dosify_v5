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

  void _flashFocusRect(BuildContext context, BuildContext? targetContext) {
    if (targetContext == null) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final topLeft = renderObject.localToGlobal(Offset.zero);
    final rect = topLeft & renderObject.size;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 180),
                  builder: (context, t, child) {
                    // Quick pulse: fade in then out.
                    final alpha = (t <= 0.5) ? (t * 2) : ((1 - t) * 2);
                    return Opacity(opacity: alpha, child: child);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kBorderRadiusMedium),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.85),
                        width: kBorderWidthThin,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      entry.remove();
    });
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
            // Move through fields first, but only when we *know* there is
            // another field to focus. Avoid `nextFocus()` wrapping and
            // preventing step navigation.
            if (hasMoreFieldToFocus && focusedIndex >= 0) {
              final nextNode = focusables[focusedIndex + 1];
              nextNode.requestFocus();
              _flashFocusRect(context, nextNode.context);
              return;
            }

            if (canProceed) {
              scope.unfocus();
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
