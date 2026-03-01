// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/dose_status_badge.dart';
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
    this.detailLines,
    this.footer,
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
  final List<Widget>? detailLines;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final radius = compact ? kBorderRadiusSmall : kBorderRadiusMedium;
    final contentPadding = doseCardContentPadding(compact: compact);
    final columnGap = doseCardColumnGap(compact: compact);

    final effectiveStatus = statusOverride ?? dose.status;
    final disabled = !isActive;
    final statusVisual = doseStatusVisual(
      context,
      effectiveStatus,
      disabled: disabled,
    );
    final statusColor = statusVisual.color;

    // Note: label/icon are rendered via the status chip/action button widgets.

    final primaryTitleStyle = doseCardPrimaryTitleTextStyle(
      context,
      color: statusColor,
    );

    final secondaryTitleStyle = doseCardSecondaryTitleTextStyle(
      context,
      color: isActive
          ? cs.onSurface.withValues(alpha: kOpacityMediumHigh)
          : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
    );

    final takeText = doseMetrics;
    final takeColor = isActive
        ? statusColor.withValues(alpha: kOpacityFull)
        : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow);

    final normalizedDetailLines = (detailLines ?? const <Widget>[])
        .where((w) => w is! SizedBox)
        .toList();
    final hasDetails = normalizedDetailLines.isNotEmpty;
    final hasFooter = footer != null;

    return Container(
      decoration: buildDoseCardDecoration(
        context: context,
        borderRadius: radius,
      ),
      child: Material(
        color: kColorTransparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: contentPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NextDoseDateBadge(
                          nextDose: dose.scheduledTime,
                          isActive: isActive,
                          dense: true,
                          activeColor: statusColor,
                          denseContent: NextDoseBadgeDenseContent.time,
                          showNextLabel: false,
                          showTodayIcon: true,
                        ),
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
                                  medicationName,
                                  style: primaryTitleStyle,
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
                          Text(
                            dose.scheduleName,
                            style: secondaryTitleStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            takeText,
                            style: doseCardTakeMetricsTextStyle(
                              context,
                              color: takeColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasDetails) ...[
                            const SizedBox(height: kSpacingXXS),
                            ...normalizedDetailLines,
                          ],
                        ],
                      ),
                    ),
                    if (showActions) ...[
                      SizedBox(width: columnGap),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DoseCardStatusChip(
                            status: effectiveStatus,
                            disabled: disabled,
                            compact: compact,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (hasFooter) ...[const SizedBox(height: kSpacingS), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
