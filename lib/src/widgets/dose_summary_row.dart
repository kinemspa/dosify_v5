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

class DoseSummaryRow extends StatelessWidget {
  const DoseSummaryRow({
    required this.dose,
    required this.onTap,
    this.showMedicationName = false,
    super.key,
  });

  final CalculatedDose dose;
  final VoidCallback onTap;
  final bool showMedicationName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);
    final disabled = schedule != null && !schedule.isActive;

    final visual = doseStatusVisual(context, dose.status, disabled: disabled);
    final statusColor = visual.color;
    final statusIcon = visual.icon;

    final timeStr = DateTimeFormatter.formatTime(context, dose.scheduledTime);

    final statusText = disabled
        ? 'Disabled'
        : switch (dose.status) {
            DoseStatus.taken => () {
                final actionTime = dose.existingLog?.actionTime;
                return actionTime != null
                    ? 'Taken at ${DateTimeFormatter.formatTime(context, actionTime)}'
                    : 'Taken';
              }(),
            DoseStatus.skipped => 'Skipped',
            DoseStatus.snoozed => 'Snoozed',
            DoseStatus.due => 'Overdue at $timeStr',
            DoseStatus.overdue => 'Missed at $timeStr',
            DoseStatus.pending => 'Take at $timeStr',
          };

    final doseInfo = '${_formatNumber(dose.doseValue)} ${dose.doseUnit}';
    final dateStr = DateFormat('E, MMM d').format(dose.scheduledTime);

    final line2 = showMedicationName
        ? '${dose.medicationName} • $doseInfo'
        : doseInfo;

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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dose.scheduleName,
                            style: bodyTextStyle(context)?.copyWith(
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
                      line2,
                      style: bodyTextStyle(context)?.copyWith(color: cs.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          '$dateStr • ',
                          style: helperTextStyle(
                            context,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            statusText,
                            style: helperTextStyle(
                              context,
                              color: statusColor,
                            )?.copyWith(fontWeight: kFontWeightMedium),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    var str = value.toStringAsFixed(3);
    str = str.replaceAll(RegExp(r'0+$'), '');
    str = str.replaceAll(RegExp(r'\.$'), '');
    return str;
  }
}
