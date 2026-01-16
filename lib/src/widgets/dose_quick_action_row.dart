import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';

class DoseQuickActionRow extends StatelessWidget {
  const DoseQuickActionRow({required this.onAction, super.key});

  final ValueChanged<DoseStatus> onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuickTextButton(
          label: 'Take',
          backgroundColor: kDoseStatusTakenGreen,
          foregroundColor: statusColorOnPrimary(context, kDoseStatusTakenGreen),
          onPressed: () => onAction(DoseStatus.taken),
        ),
        const SizedBox(width: kSpacingXS),
        _QuickTextButton(
          label: 'Snooze',
          backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
          onPressed: () => onAction(DoseStatus.snoozed),
        ),
        const SizedBox(width: kSpacingXS),
        _QuickTextButton(
          label: 'Skip',
          backgroundColor: cs.error,
          foregroundColor: cs.onError,
          onPressed: () => onAction(DoseStatus.skipped),
        ),
      ],
    );
  }
}

class _QuickTextButton extends StatelessWidget {
  const _QuickTextButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kStandardButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: kCompactButtonPadding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size(kIconButtonSize, kStandardButtonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        ),
        ),
        child: Text(label),
      ),
    );
  }
}
