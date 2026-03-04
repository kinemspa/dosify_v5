import 'package:flutter/material.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/utils/datetime_formatter.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';

class NextEntryRow extends StatelessWidget {
  const NextEntryRow({
    required this.schedule,
    required this.nextEntry,
    this.dense = false,
    super.key,
  });

  final Schedule schedule;
  final DateTime? nextEntry;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final labelStyle = dense
        ? microHelperTextStyle(context)
        : helperTextStyle(context);
    final valueStyleBase = dense
        ? microHelperTextStyle(context)
        : helperTextStyle(context);

    final primaryValue = _primaryValueText(context);
    final secondaryLine = _secondaryLineText(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.event_outlined,
              size: kIconSizeSmall,
              color: cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
            ),
            const SizedBox(width: kSpacingXS),
            Text(
              'Next entry',
              style: labelStyle?.copyWith(
                color: cs.onSurfaceVariant.withValues(
                  alpha: kOpacityMediumHigh,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: kSpacingS),
            Expanded(
              child: Text(
                primaryValue,
                style: valueStyleBase?.copyWith(
                  fontWeight: kFontWeightSemiBold,
                  color: cs.onSurfaceVariant.withValues(
                    alpha: kOpacityMediumHigh,
                  ),
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (secondaryLine != null) ...[
          const SizedBox(height: kSpacingXXS),
          Padding(
            padding: const EdgeInsets.only(left: kNextEntryRowSecondaryIndent),
            child: Text(
              secondaryLine,
              style:
                  (dense
                          ? microHelperTextStyle(context)
                          : helperTextStyle(context))
                      ?.copyWith(
                        color: cs.onSurfaceVariant.withValues(
                          alpha: kOpacityMedium,
                        ),
                      ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  String _primaryValueText(BuildContext context) {
    if (!schedule.isActive) return '—';
    final dt = nextEntry;
    if (dt == null) return '—';
    return _formatNextEntry(context, dt);
  }

  String? _secondaryLineText(BuildContext context) {
    switch (schedule.status) {
      case ScheduleStatus.active:
        return null;
      case ScheduleStatus.paused:
        final until = schedule.pausedUntil;
        if (until == null) return 'Paused';
        return 'Paused until ${_formatPausedUntil(context, until)}';
      case ScheduleStatus.disabled:
        return 'Disabled';
      case ScheduleStatus.completed:
        return 'Completed';
    }
  }

  String _formatNextEntry(BuildContext context, DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();

    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    final dateText = isToday
        ? 'Today'
        : MaterialLocalizations.of(context).formatShortMonthDay(local);

    final timeText = DateTimeFormatter.formatTime(context, local);

    return '$dateText | $timeText';
  }

  String _formatPausedUntil(BuildContext context, DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();

    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    final dateText = isToday
        ? 'Today'
        : MaterialLocalizations.of(context).formatShortMonthDay(local);

    final timeText = DateTimeFormatter.formatTime(context, local);

    return '$dateText | $timeText';
  }
}
