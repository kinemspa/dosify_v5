import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

/// Shared card surface for places that need a subtle tinted background and
/// optional accent border (e.g. action/timeline cards).
class UnifiedTintedCardSurface extends StatelessWidget {
  const UnifiedTintedCardSurface({
    super.key,
    required this.child,
    this.accentColor,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.tintOpacity,
  });

  final Widget child;

  /// When provided, the card will render with a subtle background tint and a
  /// stronger border using this color.
  final Color? accentColor;

  final VoidCallback? onTap;

  final EdgeInsets? padding;
  final double? borderRadius;

  /// Optional override for the accent tint strength.
  final double? tintOpacity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final resolvedBorderRadius = borderRadius ?? kBorderRadiusSmall;
    final resolvedPadding = padding ?? kStandardCardPadding;

    final isAccented = accentColor != null;
    final resolvedTintOpacity = tintOpacity ?? kOpacitySubtleLow;

    final background = isAccented
        ? accentColor!.withValues(alpha: resolvedTintOpacity)
        : cs.surfaceContainerHighest.withValues(alpha: kOpacityMediumLow);

    final borderColor = isAccented
        ? accentColor!
        : cs.outline.withValues(alpha: kOpacityMinimal);

    final borderWidth = isAccented ? kBorderWidthEmphasis : kBorderWidthThin;

    final decoration = BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(resolvedBorderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(resolvedBorderRadius),
    );

    final content = Padding(padding: resolvedPadding, child: child);

    return Container(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(resolvedBorderRadius),
                child: content,
              ),
      ),
    );
  }
}
