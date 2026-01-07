// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/next_dose_date_badge.dart';

class DoseCard extends StatelessWidget {
  const DoseCard({
    required this.dose,
    required this.medicationName,
    required this.strengthOrConcentrationLabel,
    required this.doseMetrics,
    required this.onTap,
    this.isActive = true,
    this.statusOverride,
    this.titleTrailing,
    this.primaryActionLabel,
    this.onPrimaryAction,
    super.key,
  });

  final CalculatedDose dose;
  final String medicationName;
  final String strengthOrConcentrationLabel;
  final String doseMetrics;
  final VoidCallback onTap;
  final bool isActive;
  final DoseStatus? statusOverride;
  final Widget? titleTrailing;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final effectiveStatus = statusOverride ?? dose.status;
    final (statusColor, statusIcon) = _statusPresentation(
      context,
      effectiveStatus,
    );

    final timeText = DateFormat('h:mm a').format(dose.scheduledTime);

    final titleStyle = cardTitleStyle(
      context,
    )?.copyWith(fontWeight: kFontWeightSemiBold, color: cs.primary);

    final baseBody = bodyTextStyle(context);
    final baseHelper = helperTextStyle(context);

    final actionLabel = primaryActionLabel ?? 'Actions';

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
            vertical: kSpacingXS,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NextDoseDateBadge(
                    nextDose: dose.scheduledTime,
                    isActive: isActive,
                    dense: true,
                    showNextLabel: false,
                    showTodayIcon: true,
                  ),
                ],
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
                            style: titleStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (titleTrailing != null) ...[
                          const SizedBox(width: kSpacingS),
                          titleTrailing!,
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
                      'Take $doseMetrics at $timeText',
                      style: baseBody?.copyWith(color: cs.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kSpacingM),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: kLargeButtonHeight,
                    height: kLargeButtonHeight,
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
                  const SizedBox(height: kSpacingXS),
                  SizedBox(
                    height: kStandardButtonHeight,
                    child: FilledButton(
                      onPressed: onPrimaryAction ?? onTap,
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, IconData) _statusPresentation(
    BuildContext context,
    DoseStatus status,
  ) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case DoseStatus.taken:
        return (cs.primary, Icons.check_rounded);
      case DoseStatus.skipped:
        return (cs.onSurfaceVariant, Icons.block_rounded);
      case DoseStatus.snoozed:
        return (cs.tertiary, Icons.snooze_rounded);
      case DoseStatus.overdue:
        return (cs.error, Icons.warning_rounded);
      case DoseStatus.pending:
        return (cs.primary, Icons.notifications_rounded);
    }
  }
}
