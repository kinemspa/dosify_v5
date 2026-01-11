// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/dose_quick_action_row.dart';
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
    this.leadingFooter,
    this.showActions = true,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.onQuickAction,
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
  final Widget? leadingFooter;
  final bool showActions;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final ValueChanged<DoseStatus>? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final effectiveStatus = statusOverride ?? dose.status;
    final disabled = !isActive;
    final (statusColor, statusIcon) = _statusPresentation(
      context,
      effectiveStatus,
      disabled: disabled,
    );

    final statusLabel = _statusLabel(effectiveStatus, disabled: disabled);

    final timeText = DateFormat('h:mm a').format(dose.scheduledTime);

    final titleStyle = cardTitleStyle(
      context,
    )?.copyWith(fontWeight: kFontWeightSemiBold, color: cs.primary);

    final baseBody = bodyTextStyle(context);
    final baseHelper = helperTextStyle(context);

    final actionLabel = primaryActionLabel ?? 'Actions';
    final hasQuickActions = onQuickAction != null;
    final showEditOnly = effectiveStatus != DoseStatus.pending;

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
                    activeColor: statusColor,
                    showNextLabel: false,
                    showTodayIcon: true,
                  ),
                  const SizedBox(height: kSpacingXS),
                  Text(
                    timeText,
                    style: helperTextStyle(
                      context,
                      color: isActive
                          ? statusColor.withValues(alpha: kOpacityFull)
                          : cs.onSurfaceVariant.withValues(
                              alpha: kOpacityMediumLow,
                            ),
                    )?.copyWith(fontSize: kFontSizeXSmall),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (leadingFooter != null) ...[
                    const SizedBox(height: kSpacingXS),
                    leadingFooter!,
                  ],
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
                      style: baseHelper?.copyWith(fontSize: kFontSizeXSmall),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kSpacingXXS),
                    Text(
                      'Take $doseMetrics',
                      style: baseBody?.copyWith(
                        color: isActive
                            ? statusColor.withValues(alpha: kOpacityFull)
                            : cs.onSurfaceVariant.withValues(
                                alpha: kOpacityMediumLow,
                              ),
                        fontWeight: kFontWeightSemiBold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showActions) ...[
                const SizedBox(width: kSpacingM),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSpacingS,
                        vertical: kSpacingXXS,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: kOpacityMinimal),
                        borderRadius: BorderRadius.circular(kBorderRadiusChip),
                        border: Border.all(
                          color: statusColor.withValues(
                            alpha: kOpacityMediumLow,
                          ),
                          width: kBorderWidthThin,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          statusLabel,
                          style: helperTextStyle(context, color: statusColor)
                              ?.copyWith(
                                fontSize: kFontSizeXXSmall,
                                fontWeight: kFontWeightExtraBold,
                                height: 1,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: kSpacingXS),
                    if (showEditOnly)
                      SizedBox(
                        height: kStandardButtonHeight,
                        child: OutlinedButton.icon(
                          onPressed: onPrimaryAction ?? onTap,
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit'),
                        ),
                      )
                    else if (hasQuickActions)
                      DoseQuickActionRow(onAction: onQuickAction!)
                    else
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
            ],
          ),
        ),
      ),
    );
  }

  (Color, IconData) _statusPresentation(
    BuildContext context,
    DoseStatus status, {
    required bool disabled,
  }) {
    final cs = Theme.of(context).colorScheme;

    if (disabled) {
      return (
        cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
        Icons.do_not_disturb_on_rounded,
      );
    }
    switch (status) {
      case DoseStatus.taken:
        return (kDoseStatusTakenGreen, Icons.check_rounded);
      case DoseStatus.skipped:
        return (cs.error, Icons.block_rounded);
      case DoseStatus.snoozed:
        return (kDoseStatusSnoozedOrange, Icons.snooze_rounded);
      case DoseStatus.overdue:
        return (kDoseStatusMissedDarkRed, Icons.warning_rounded);
      case DoseStatus.pending:
        return (cs.primary, Icons.notifications_rounded);
    }
  }

  String _statusLabel(DoseStatus status, {required bool disabled}) {
    if (disabled) return 'DISABLED';
    switch (status) {
      case DoseStatus.taken:
        return 'TAKEN';
      case DoseStatus.skipped:
        return 'SKIPPED';
      case DoseStatus.snoozed:
        return 'SNOOZED';
      case DoseStatus.overdue:
        return 'MISSED';
      case DoseStatus.pending:
        return 'PENDING';
    }
  }
}
