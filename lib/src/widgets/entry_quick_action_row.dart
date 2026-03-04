import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/widgets/entry_status_ui.dart';

class EntryQuickActionRow extends StatelessWidget {
  const EntryQuickActionRow({required this.onAction, super.key});

  final ValueChanged<EntryStatus> onAction;

  @override
  Widget build(BuildContext context) {
    final takenColor =
      entryStatusVisual(context, EntryStatus.logged, disabled: false).color;
    final snoozedColor =
      entryStatusVisual(context, EntryStatus.snoozed, disabled: false).color;
    final skippedColor =
      entryStatusVisual(context, EntryStatus.skipped, disabled: false).color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuickTextButton(
          label: 'Log',
          backgroundColor: takenColor,
          foregroundColor: statusColorOnPrimary(context, takenColor),
          onPressed: () => onAction(EntryStatus.logged),
        ),
        const SizedBox(width: kSpacingXS),
        _QuickTextButton(
          label: 'Snooze',
          backgroundColor: snoozedColor,
          foregroundColor: statusColorOnPrimary(context, snoozedColor),
          onPressed: () => onAction(EntryStatus.snoozed),
        ),
        const SizedBox(width: kSpacingXS),
        _QuickTextButton(
          label: 'Skip',
          backgroundColor: skippedColor,
          foregroundColor: statusColorOnPrimary(context, skippedColor),
          onPressed: () => onAction(EntryStatus.skipped),
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
