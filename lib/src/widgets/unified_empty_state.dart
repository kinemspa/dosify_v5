import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

class UnifiedEmptyState extends StatelessWidget {
  const UnifiedEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onAction,
    this.actionLabel,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  final VoidCallback? onAction;
  final String? actionLabel;

  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final resolvedPadding = padding ?? kUnifiedEmptyStatePadding;

    return Padding(
      padding: resolvedPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: kIconSizeLarge,
              color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
            ),
            const SizedBox(height: kSpacingS),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: cardTitleStyle(context),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: kSpacingXS),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: helperTextStyle(context),
            ),
          ],
          if (onAction != null && actionLabel != null && actionLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: kSpacingM),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
