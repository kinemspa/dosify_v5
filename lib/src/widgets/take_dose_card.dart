// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/schedule_status_badge.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TakeDoseCard extends StatelessWidget {
  const TakeDoseCard({
    required this.dose,
    required this.medicationName,
    required this.strengthOrConcentrationLabel,
    required this.doseMetrics,
    required this.onTap,
    this.primaryActionLabel,
    this.onPrimaryAction,
    super.key,
  });

  final CalculatedDose dose;
  final String medicationName;
  final String strengthOrConcentrationLabel;
  final String doseMetrics;
  final VoidCallback onTap;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (statusColor, statusIcon, statusText) = _statusPresentation(
      context,
      dose,
    );

    final dateText = DateFormat('E, MMM d').format(dose.scheduledTime);
    final timeText = DateFormat('h:mm a').format(dose.scheduledTime);

    final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);

    final actionLabel = primaryActionLabel ?? _defaultPrimaryActionLabel(dose);

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
                            dose.scheduleName,
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
                    const SizedBox(height: 2),
                    Text(
                      medicationName,
                      style: baseBody,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strengthOrConcentrationLabel,
                      style: baseHelper,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doseMetrics,
                      style: baseBody?.copyWith(color: cs.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kSpacingXS),
                    Row(
                      children: [
                        Icon(
                          Icons.event,
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
                    const SizedBox(height: 2),
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

  String _defaultPrimaryActionLabel(CalculatedDose dose) {
    return 'Actions';
  }

  (Color, IconData, String) _statusPresentation(
    BuildContext context,
    CalculatedDose dose,
  ) {
    final cs = Theme.of(context).colorScheme;

    final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);
    if (schedule != null && !schedule.isActive) {
      final disabledColor = cs.onSurfaceVariant.withValues(
        alpha: kOpacityMediumHigh,
      );
      return (disabledColor, Icons.do_not_disturb_on_rounded, 'Disabled');
    }

    switch (dose.status) {
      case DoseStatus.taken:
        final actionTime = dose.existingLog?.actionTime;
        final label = actionTime != null
            ? 'Taken at ${DateFormat('h:mm a').format(actionTime)}'
            : 'Taken';
        return (cs.primary, Icons.check_rounded, label);
      case DoseStatus.skipped:
        return (cs.onSurfaceVariant, Icons.block_rounded, 'Skipped');
      case DoseStatus.snoozed:
        return (cs.tertiary, Icons.snooze_rounded, 'Snoozed');
      case DoseStatus.overdue:
        // Time is already shown in the Date/Time row.
        return (cs.error, Icons.warning_rounded, 'Missed');
      case DoseStatus.pending:
        // Time is already shown in the Date/Time row.
        return (cs.primary, Icons.notifications_rounded, 'Pending');
    }
  }
}
