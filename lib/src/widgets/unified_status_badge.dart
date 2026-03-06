import 'package:flutter/material.dart';

import 'package:skedux/src/core/design_system.dart';

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
    final baseHorizontalPadding = dense ? kFieldSpacing : kSpacingS;
    final verticalPadding = dense
        ? kEntryStatusBadgeVerticalPadding
        : kSpacingXXS;

    final resolvedTextStyle =
        textStyle?.call(context, color) ??
        microHelperTextStyle(context, color: color);

    final hasExplicitWidth = fixedWidth != null;

    // When we're inside a fixed-width chip (e.g., EntryCard status), keep padding
    // tight so the icon + label can always fit without overflow.
    final horizontalPadding = hasExplicitWidth
        ? kSpacingXXS
        : baseHorizontalPadding;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: kIconSizeXXSmall, color: color),
        const SizedBox(width: kSpacingXS),
        Flexible(
          child: Text(
            label,
            // height: 1.0 removes the extra line-height padding above/below the
            // glyph so CrossAxisAlignment.center visually aligns the text cap
            // with the icon center (icon is 12dp; text base size is 9dp).
            style: resolvedTextStyle?.copyWith(
              fontWeight: kFontWeightBold,
              height: 1.0,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
