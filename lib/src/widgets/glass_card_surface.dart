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
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(kBorderRadiusLarge);

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: useGradient ? null : cs.surface.withValues(alpha: 0.95),
        gradient: useGradient
            ? LinearGradient(
                colors: [
                  cs.surface.withValues(alpha: 0.92),
                  cs.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(kCardPadding), child: child),
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
