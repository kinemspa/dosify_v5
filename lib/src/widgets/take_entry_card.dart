// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/utils/datetime_formatter.dart';
import 'package:skedux/src/features/schedules/domain/calculated_entry.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/widgets/entry_status_ui.dart';
import 'package:skedux/src/widgets/schedule_status_badge.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TakeEntryCard extends StatelessWidget {
  const TakeEntryCard({
    required this.entry,
    required this.medicationName,
    required this.strengthOrConcentrationLabel,
    required this.entryMetrics,
    required this.onTap,
    this.primaryActionLabel,
    this.onPrimaryAction,
    super.key,
  });

  final CalculatedEntry entry;
  final String medicationName;
  final String strengthOrConcentrationLabel;
  final String entryMetrics;
  final VoidCallback onTap;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (statusColor, statusIcon, statusText) = _statusPresentation(
      context,
      entry,
    );

    final localTime = entry.scheduledTime.toLocal();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final weekday = DateFormat.E(localeTag).format(localTime);
    final shortDate = MaterialLocalizations.of(context).formatCompactDate(
      localTime,
    );
    final dateText = '$weekday $shortDate';
    final timeText = DateTimeFormatter.formatTime(context, localTime);

    final schedule = Hive.box<Schedule>('schedules').get(entry.scheduleId);

    final actionLabel = primaryActionLabel ?? _defaultPrimaryActionLabel(entry);

    final baseBody = bodyTextStyle(context);
    final baseHelper = helperTextStyle(context);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingM,
            vertical: kSpacingS,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: kOpacityMinimal),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  size: kIconSizeMedium,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: kSpacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.scheduleName,
                            style: baseBody?.copyWith(
                              fontWeight: kFontWeightSemiBold,
                              color: cs.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (schedule != null && !schedule.isActive) ...[
                          const SizedBox(width: kSpacingXS),
                          ScheduleStatusBadge(schedule: schedule, dense: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: kSpacingXXS),
                    Text(
                      medicationName,
                      style: baseBody,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kSpacingXXS),
                    Text(
                      strengthOrConcentrationLabel,
                      style: baseHelper,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kSpacingXXS),
                    Text(
                      entryMetrics,
                      style: baseBody?.copyWith(color: cs.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kSpacingXS),
                    Row(
                      children: [
                        Icon(
                          entry.status == EntryStatus.logged
                              ? Icons.check_circle_rounded
                              : Icons.event,
                          size: kIconSizeSmall,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: kSpacingXS),
                        Text(dateText, style: baseHelper),
                        const SizedBox(width: kSpacingM),
                        Icon(
                          Icons.schedule,
                          size: kIconSizeSmall,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: kSpacingXS),
                        Expanded(
                          child: Text(
                            timeText,
                            style: baseHelper,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: kSpacingXXS),
                    Text(
                      statusText,
                      style: baseHelper?.copyWith(
                        color: statusColor,
                        fontWeight: kFontWeightMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kSpacingM),
              SizedBox(
                height: kLargeButtonHeight,
                child: FilledButton(
                  onPressed: onPrimaryAction ?? onTap,
                  child: Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _defaultPrimaryActionLabel(CalculatedEntry entry) {
    return 'Actions';
  }

  (Color, IconData, String) _statusPresentation(
    BuildContext context,
    CalculatedEntry entry,
  ) {
    final schedule = Hive.box<Schedule>('schedules').get(entry.scheduleId);
    final disabled = schedule != null && !schedule.isActive;

    final visual = entryStatusVisual(context, entry.status, disabled: disabled);

    if (disabled) {
      return (visual.color, visual.icon, 'Disabled');
    }

    final label = switch (entry.status) {
      EntryStatus.logged => () {
          final actionTime = entry.existingLog?.actionTime;
          return actionTime != null
              ? 'Taken at ${DateTimeFormatter.formatTime(context, actionTime)}'
              : 'Logged';
        }(),
      EntryStatus.skipped => 'Skipped',
      EntryStatus.snoozed => 'Snoozed',
      EntryStatus.due => 'Overdue',
      EntryStatus.overdue => 'Missed',
      EntryStatus.pending => 'Pending',
    };

    return (visual.color, visual.icon, label);
  }
}
