import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

class UnifiedStatusBadge extends StatelessWidget {
  const UnifiedStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.dense = true,
    this.decorate = true,
    this.fixedWidth,
    this.fixedHeight,
    this.textStyle,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool dense;
  final bool decorate;

  final double? fixedWidth;
  final double? fixedHeight;

  final TextStyle? Function(BuildContext context, Color color)? textStyle;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = dense ? kFieldSpacing : kSpacingS;
    final verticalPadding = dense
        ? kDoseStatusBadgeVerticalPadding
        : kSpacingXXS;

    final resolvedTextStyle =
        textStyle?.call(context, color) ??
        microHelperTextStyle(context, color: color);

    final hasWidthConstraint = fixedWidth != null;

    final row = Row(
      mainAxisSize: hasWidthConstraint ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: kIconSizeXXSmall, color: color),
        const SizedBox(width: kSpacingXS),
        if (hasWidthConstraint)
          Expanded(
            child: Text(
              label,
              style: resolvedTextStyle?.copyWith(fontWeight: kFontWeightBold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          Text(
            label,
            style: resolvedTextStyle?.copyWith(fontWeight: kFontWeightBold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );

    final widget = decorate
        ? Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: kOpacitySubtleLow),
              borderRadius: BorderRadius.circular(kBorderRadiusChipTight),
              border: Border.all(
                color: color.withValues(alpha: kOpacityVeryLow),
                width: kBorderWidthThin,
              ),
            ),
            child: row,
          )
        : row;

    if (fixedWidth == null && fixedHeight == null) return widget;

    return SizedBox(
      width: fixedWidth,
      height: fixedHeight,
      child: Center(child: widget),
    );
  }
}
