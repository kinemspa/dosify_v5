// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/dose_quick_action_row.dart';
import 'package:dosifi_v5/src/widgets/dose_status_ui.dart';
import 'package:dosifi_v5/src/widgets/next_dose_date_badge.dart';

class DoseCard extends StatelessWidget {
  const DoseCard({
    required this.dose,
    required this.medicationName,
    required this.strengthOrConcentrationLabel,
    required this.doseMetrics,
    required this.onTap,
    this.isActive = true,
    this.compact = false,
    this.doseNumber,
    this.medicationFormIcon,
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
  final bool compact;
  final int? doseNumber;
  final IconData? medicationFormIcon;
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

    final radius = compact ? kBorderRadiusSmall : kBorderRadiusMedium;
    final horizontalPadding = compact ? kSpacingS : kSpacingM;
    final verticalPadding = compact ? kSpacingXXS : kSpacingXS;
    final columnGap = compact ? kSpacingS : kSpacingM;

    final effectiveStatus = statusOverride ?? dose.status;
    final disabled = !isActive;
    final statusColor =
        doseStatusVisual(context, effectiveStatus, disabled: disabled).color;

    final statusLabel = doseStatusLabel(effectiveStatus, disabled: disabled);

    final timeText = DateFormat('h:mm a').format(dose.scheduledTime);

    final titleStyle = cardTitleStyle(
      context,
    )?.copyWith(fontWeight: kFontWeightSemiBold, color: statusColor);

    final baseBody = bodyTextStyle(context);

    final actionLabel = primaryActionLabel ?? 'Actions';
    final hasQuickActions = onQuickAction != null;

    final takeText = 'Take $doseMetrics';
    final takeColor = isActive
        ? statusColor.withValues(alpha: kOpacityFull)
        : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow);

    return Container(
      decoration: buildDoseCardDecoration(
        context: context,
        borderRadius: radius,
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
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
                    if (doseNumber != null) ...[
                      const SizedBox(height: kSpacingXXS),
                      Text(
                        'Dose $doseNumber',
                        style: helperTextStyle(
                          context,
                          color: isActive
                              ? statusColor.withValues(alpha: kOpacityFull)
                              : cs.onSurfaceVariant.withValues(
                                  alpha: kOpacityMediumLow,
                                ),
                        )?.copyWith(fontSize: kFontSizeXXSmall),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (leadingFooter != null) ...[
                      const SizedBox(height: kSpacingXS),
                      leadingFooter!,
                    ],
                  ],
                ),
                SizedBox(width: columnGap),
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
                      if (medicationFormIcon != null)
                        Row(
                          children: [
                            Icon(
                              medicationFormIcon,
                              size: kIconSizeSmall,
                              color: takeColor,
                            ),
                            const SizedBox(width: kSpacingXS),
                            Expanded(
                              child: Text(
                                takeText,
                                style: baseBody?.copyWith(
                                  color: takeColor,
                                  fontWeight: kFontWeightSemiBold,
                                  fontSize: kFontSizeSmall,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          takeText,
                          style: baseBody?.copyWith(
                            color: takeColor,
                            fontWeight: kFontWeightSemiBold,
                            fontSize: kFontSizeSmall,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (showActions) ...[
                  SizedBox(width: columnGap),
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
                      if (hasQuickActions)
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
      ),
    );
  }

  
}
