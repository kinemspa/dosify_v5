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
        _QuickIconButton(
          tooltip: 'Take',
          icon: Icons.check_rounded,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          onPressed: () => onAction(DoseStatus.taken),
        ),
        const SizedBox(width: kSpacingXS),
        _QuickIconButton(
          tooltip: 'Snooze',
          icon: Icons.snooze_rounded,
          backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
          onPressed: () => onAction(DoseStatus.snoozed),
        ),
        const SizedBox(width: kSpacingXS),
        _QuickIconButton(
          tooltip: 'Skip',
          icon: Icons.block_rounded,
          backgroundColor: cs.error,
          foregroundColor: cs.onError,
          onPressed: () => onAction(DoseStatus.skipped),
        ),
      ],
    );
  }
}

class _QuickIconButton extends StatelessWidget {
  const _QuickIconButton({
    required this.tooltip,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: kIconSizeSmall),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: kCompactButtonPadding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(kIconButtonSize, kIconButtonSize),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        ),
      ),
      constraints: kTightIconButtonConstraints,
    );
  }
}
