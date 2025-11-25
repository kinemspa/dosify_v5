import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

/// Base large card used across medications, schedules, and doses.
class LargeCard extends StatelessWidget {
  const LargeCard({
    super.key,
    required this.leading,
    required this.trailing,
    this.footer,
    this.onTap,
  });

  final Widget leading;
  final Widget trailing;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(kCardBorderOpacity),
          width: kBorderWidthThin,
        ),
      ),
      padding: const EdgeInsets.all(kCardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leading),
              const SizedBox(width: kSpacingL),
              trailing,
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: kSectionSpacing),
            footer!,
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusLarge),
      child: card,
    );
  }
}
