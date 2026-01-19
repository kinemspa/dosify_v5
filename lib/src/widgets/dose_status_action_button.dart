import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/dose_status_ui.dart';

class DoseStatusActionButton extends StatelessWidget {
  const DoseStatusActionButton({
    required this.currentStatus,
    required this.onSelect,
    required this.isActive,
    required this.compact,
    super.key,
  });

  final DoseStatus currentStatus;
  final ValueChanged<DoseStatus> onSelect;
  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final disabled = !isActive;

    final visual = doseStatusVisual(context, currentStatus, disabled: disabled);
    final label = doseStatusLabel(currentStatus, disabled: disabled);

    return PopupMenuButton<DoseStatus>(
      tooltip: 'Change status',
      onSelected: onSelect,
      itemBuilder: (context) => [
        _buildItem(context, DoseStatus.taken, enabled: !disabled),
        _buildItem(context, DoseStatus.snoozed, enabled: !disabled),
        _buildItem(context, DoseStatus.skipped, enabled: !disabled),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingS,
          vertical: kSpacingXXS,
        ),
        decoration: BoxDecoration(
          color: visual.color.withValues(alpha: kOpacityMinimal),
          borderRadius: BorderRadius.circular(kBorderRadiusChip),
          border: Border.all(
            color: visual.color.withValues(alpha: kOpacityMediumLow),
            width: kBorderWidthThin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              visual.icon,
              size: compact
                  ? kDoseCardStatusIconSizeCompact
                  : kDoseCardStatusIconSize,
              color: visual.color,
            ),
            const SizedBox(width: kSpacingXXS),
            Text(
              label,
              style: helperTextStyle(context, color: visual.color)?.copyWith(
                fontSize: kFontSizeXXSmall,
                fontWeight: kFontWeightExtraBold,
                height: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<DoseStatus> _buildItem(
    BuildContext context,
    DoseStatus status, {
    required bool enabled,
  }) {
    final visual = doseStatusVisual(context, status, disabled: !enabled);
    final label = doseStatusLabel(status, disabled: !enabled);

    return PopupMenuItem<DoseStatus>(
      value: status,
      enabled: enabled,
      child: Row(
        children: [
          Icon(visual.icon, size: kIconSizeMedium, color: visual.color),
          const SizedBox(width: kSpacingS),
          Text(label, style: bodyTextStyle(context)),
        ],
      ),
    );
  }
}
