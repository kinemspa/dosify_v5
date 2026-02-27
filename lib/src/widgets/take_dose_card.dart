// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/dose_status_ui.dart';
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

    final localTime = dose.scheduledTime.toLocal();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final weekday = DateFormat.E(localeTag).format(localTime);
    final shortDate = MaterialLocalizations.of(context).formatCompactDate(
      localTime,
    );
    final dateText = '$weekday $shortDate';
    final timeText = DateTimeFormatter.formatTime(context, localTime);

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
                      doseMetrics,
                      style: baseBody?.copyWith(color: cs.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kSpacingXS),
                    Row(
                      children: [
                        Icon(
                          dose.status == DoseStatus.logged
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

  String _defaultPrimaryActionLabel(CalculatedDose dose) {
    return 'Actions';
  }

  (Color, IconData, String) _statusPresentation(
    BuildContext context,
    CalculatedDose dose,
  ) {
    final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);
    final disabled = schedule != null && !schedule.isActive;

    final visual = doseStatusVisual(context, dose.status, disabled: disabled);

    if (disabled) {
      return (visual.color, visual.icon, 'Disabled');
    }

    final label = switch (dose.status) {
      DoseStatus.logged => () {
          final actionTime = dose.existingLog?.actionTime;
          return actionTime != null
              ? 'Taken at ${DateTimeFormatter.formatTime(context, actionTime)}'
              : 'Logged';
        }(),
      DoseStatus.skipped => 'Skipped',
      DoseStatus.snoozed => 'Snoozed',
      DoseStatus.due => 'Overdue',
      DoseStatus.overdue => 'Missed',
      DoseStatus.pending => 'Pending',
    };

    return (visual.color, visual.icon, label);
  }
}
