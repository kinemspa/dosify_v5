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
    this.dense = false,
  });

  final Widget leading;
  final Widget trailing;
  final Widget? footer;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final padding = dense ? kSpacingS : kCardPadding;
    final leadingTrailingGap = dense ? kSpacingM : kSpacingL;
    final footerGap = dense ? kSpacingS : kSectionSpacing;

    final card = Container(
      decoration: buildStandardCardDecoration(context: context),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leading),
              SizedBox(width: leadingTrailingGap),
              trailing,
            ],
          ),
          if (footer != null) ...[SizedBox(height: footerGap), footer!],
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
