import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:flutter/material.dart';

/// Shared "glass" card surface with soft gradient and halo shadow.
///
/// Wraps content with the concept 9 styling so feature code can focus on
/// composing the inner layout.
class GlassCardSurface extends StatelessWidget {
  const GlassCardSurface({
    required this.child,
    this.onTap,
    this.useGradient = true,
    this.padding = const EdgeInsets.all(kCardPadding),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool useGradient;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(kBorderRadiusLarge);

    final card = Container(
      decoration: buildStandardCardDecoration(
        context: context,
        useGradient: useGradient,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: card),
    );
  }
}
