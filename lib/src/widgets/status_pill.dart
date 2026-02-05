import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = true,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = dense ? kSpacingXXS : kSpacingS;
    final verticalPadding = dense ? kSpacingXXS : kSpacingXS;
    final borderRadius = dense ? kBorderRadiusChipTight : kBorderRadiusChip;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: kOpacityMinimal),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(alpha: kOpacityMedium),
          width: kBorderWidthThin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: kIconSizeXSmall, color: color),
            const SizedBox(width: kSpacingXXS),
          ],
          Text(
            label,
            style: (dense
                    ? microHelperTextStyle(context, color: color)
                    : smallHelperTextStyle(context, color: color))
                ?.copyWith(fontWeight: kFontWeightSemiBold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
