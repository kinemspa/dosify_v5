import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/dose_status_ui.dart';

class DoseStatusBadge extends StatelessWidget {
  const DoseStatusBadge({
    super.key,
    required this.status,
    required this.disabled,
    this.dense = true,
    this.showPending = false,
  });

  final DoseStatus status;
  final bool disabled;
  final bool dense;
  final bool showPending;

  @override
  Widget build(BuildContext context) {
    if (!disabled && status == DoseStatus.pending && !showPending) {
      return const SizedBox.shrink();
    }

    final visual = doseStatusVisual(context, status, disabled: disabled);
    final label = doseStatusLabel(status, disabled: disabled);

    final horizontalPadding = dense ? kFieldSpacing : kSpacingS;
    final verticalPadding = dense ? kDoseStatusBadgeVerticalPadding : kSpacingXXS;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: kOpacitySubtleLow),
        borderRadius: BorderRadius.circular(kBorderRadiusChipTight),
        border: Border.all(
          color: visual.color.withValues(alpha: kOpacityVeryLow),
          width: kBorderWidthThin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: kIconSizeXXSmall, color: visual.color),
          const SizedBox(width: kSpacingXS),
          Text(
            label,
            style: microHelperTextStyle(context, color: visual.color)?.copyWith(
              fontWeight: kFontWeightBold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed-size status chip used by [DoseCard] when quick-actions are disabled.
///
/// This keeps all states visually consistent (same width/height/padding) and
/// prevents off-center rendering when labels differ.
class DoseCardStatusChip extends StatelessWidget {
  const DoseCardStatusChip({
    super.key,
    required this.status,
    required this.disabled,
    required this.compact,
  });

  final DoseStatus status;
  final bool disabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visual = doseStatusVisual(context, status, disabled: disabled);
    final label = doseStatusLabel(status, disabled: disabled);

    final width = compact
        ? kDoseCardStatusChipWidthCompact
        : kDoseCardStatusChipWidth;
    final height = compact
        ? kDoseCardStatusChipHeightCompact
        : kDoseCardStatusChipHeight;
    final iconSize = compact
        ? kDoseCardStatusIconSizeCompact
        : kDoseCardStatusIconSize;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: visual.color.withValues(alpha: kOpacityMinimal),
          borderRadius: BorderRadius.circular(kBorderRadiusChip),
          border: Border.all(
            color: visual.color.withValues(alpha: kOpacityMediumLow),
            width: kBorderWidthThin,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? kSpacingXS : kSpacingS,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(visual.icon, size: iconSize, color: visual.color),
                const SizedBox(width: kSpacingXXS),
                Flexible(
                  child: Text(
                    label,
                    style: doseCardStatusChipLabelTextStyle(
                      context,
                      color: visual.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
