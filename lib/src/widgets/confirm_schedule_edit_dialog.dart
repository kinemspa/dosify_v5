import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

Future<bool> showConfirmEditScheduleDialog(BuildContext context) async {
  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final cs = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            titleTextStyle: cardTitleStyle(
              dialogContext,
            )?.copyWith(color: cs.primary),
            contentTextStyle: bodyTextStyle(dialogContext),
            title: const Text('Edit schedule?'),
            content: const Text('This will open the schedule editor.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Edit'),
              ),
            ],
          );
        },
      ) ??
      false;

  return confirmed;
}
