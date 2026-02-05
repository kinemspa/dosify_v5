import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

enum UnifiedCardVariant { standard, compact, flat, outlined }

class UnifiedCardSurface extends StatelessWidget {
  const UnifiedCardSurface({
    super.key,
    required this.child,
    this.onTap,
    this.variant = UnifiedCardVariant.standard,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final UnifiedCardVariant variant;
  final EdgeInsets? padding;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final resolvedBorderRadius =
        borderRadius ??
        (variant == UnifiedCardVariant.compact
            ? kBorderRadiusMedium
            : kBorderRadiusLarge);

    final resolvedPadding =
        padding ??
        (variant == UnifiedCardVariant.compact
            ? kCompactCardPadding
            : kStandardCardPadding);

    final decoration = switch (variant) {
      UnifiedCardVariant.standard => buildStandardCardDecoration(
        context: context,
        useGradient: false,
        showBorder: true,
        borderRadius: resolvedBorderRadius,
      ),
      UnifiedCardVariant.compact => buildStandardCardDecoration(
        context: context,
        useGradient: false,
        showBorder: true,
        borderRadius: resolvedBorderRadius,
      ),
      UnifiedCardVariant.outlined => BoxDecoration(
        borderRadius: BorderRadius.circular(resolvedBorderRadius),
        color: cs.surface,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
          width: kBorderWidthThin,
        ),
        boxShadow: const [],
      ),
      UnifiedCardVariant.flat => BoxDecoration(
        borderRadius: BorderRadius.circular(resolvedBorderRadius),
        color: cs.surface,
        boxShadow: const [],
      ),
    };

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
