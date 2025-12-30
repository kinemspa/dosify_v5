// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';

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
    final theme = Theme.of(context);

    final isTaken = dose.status == DoseStatus.taken;
    final isOverdue = dose.status == DoseStatus.overdue;
    final isSkipped = dose.status == DoseStatus.skipped;
    final isSnoozed = dose.status == DoseStatus.snoozed;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    final timeStr = DateFormat('h:mm a').format(dose.scheduledTime);

    if (isTaken) {
      statusColor = cs.primary;
      statusIcon = Icons.check_rounded;
      final actionTime = dose.existingLog?.actionTime;
      statusText = actionTime != null
          ? 'Taken at ${DateFormat('h:mm a').format(actionTime)}'
          : 'Taken';
    } else if (isSkipped) {
      statusColor = cs.onSurfaceVariant;
      statusIcon = Icons.block_rounded;
      statusText = 'Skipped';
    } else if (isSnoozed) {
      statusColor = cs.tertiary;
      statusIcon = Icons.snooze_rounded;
      statusText = 'Snoozed';
    } else if (isOverdue) {
      statusColor = cs.error;
      statusIcon = Icons.warning_rounded;
      statusText = 'Missed at $timeStr';
    } else {
      statusColor = cs.primary;
      statusIcon = Icons.notifications_rounded;
      statusText = 'Take at $timeStr';
    }

    final doseInfo = '${_formatNumber(dose.doseValue)} ${dose.doseUnit}';
    final dateStr = DateFormat('E, MMM d').format(dose.scheduledTime);

    final line2 = showMedicationName
        ? '${dose.medicationName} • $doseInfo'
        : doseInfo;

    return Material(
      type: MaterialType.transparency,
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
                    Text(
                      dose.scheduleName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: kFontWeightSemiBold,
                        color: cs.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      line2,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          '$dateStr • ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: kFontWeightMedium,
                            ),
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
