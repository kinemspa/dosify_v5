import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

enum SchedulePauseDialogChoice { resume, pauseUntilDate, pauseIndefinitely }

Future<SchedulePauseDialogChoice?> showSchedulePauseDialog(
  BuildContext context, {
  required Schedule schedule,
}) async {
  if (schedule.isCompleted) return null;

  final title = schedule.isActive
      ? 'Pause schedule'
      : schedule.isPaused
      ? 'Paused schedule'
      : 'Disabled schedule';

  return showDialog<SchedulePauseDialogChoice>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return SimpleDialog(
        titleTextStyle: dialogTitleTextStyle(ctx),
        title: Text(title),
        contentPadding: const EdgeInsets.fromLTRB(
          kSpacingL,
          kSpacingS,
          kSpacingL,
          kSpacingL,
        ),
        children: [
          if (!schedule.isActive)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(ctx).pop(SchedulePauseDialogChoice.resume),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resume', style: bodyTextStyle(ctx)),
                  const SizedBox(height: kSpacingXS),
                  Text(
                    'Re-enable the schedule and notifications.',
                    style: helperTextStyle(ctx),
                  ),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(ctx).pop(SchedulePauseDialogChoice.pauseUntilDate),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pause until date', style: bodyTextStyle(ctx)),
                const SizedBox(height: kSpacingXS),
                Text(
                  'Stops notifications until the chosen date, then auto-resumes.',
                  style: helperTextStyle(ctx),
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(
              ctx,
            ).pop(SchedulePauseDialogChoice.pauseIndefinitely),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pause indefinitely', style: bodyTextStyle(ctx)),
                const SizedBox(height: kSpacingXS),
                Text(
                  'Stops notifications until you resume manually.',
                  style: helperTextStyle(ctx),
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              'Cancel',
              style: bodyTextStyle(ctx)?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    },
  );
}
