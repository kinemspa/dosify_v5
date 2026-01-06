import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

class CompactStorageLine extends StatelessWidget {
  const CompactStorageLine({
    super.key,
    required this.icons,
    required this.label,
    required this.location,
    required this.createdAt,
    required this.expiry,
    this.trailing,
    this.iconColor,
    this.textColor,
    this.onPrimaryBackground = false,
  });

  final List<IconData> icons;
  final String label;
  final String? location;
  final DateTime? createdAt;
  final DateTime? expiry;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final bool onPrimaryBackground;

  String _formatExpiryShort(BuildContext context, DateTime expiry) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final usesDayMonth = locale.toLowerCase().startsWith('en-gb');
    return usesDayMonth
        ? DateFormat('dd/MM', locale).format(expiry)
        : DateFormat('MM/dd', locale).format(expiry);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final resolvedTextColor = textColor ?? cs.onSurface;
    final baseStyle =
        helperTextStyle(context)?.copyWith(
          fontSize: kFontSizeXSmall,
          fontWeight: FontWeight.w600,
          color: resolvedTextColor.withValues(alpha: kOpacityMediumHigh),
        ) ??
        TextStyle(
          fontSize: kFontSizeXSmall,
          fontWeight: FontWeight.w600,
          color: resolvedTextColor.withValues(alpha: kOpacityMediumHigh),
        );

    final createdAtValue = createdAt;
    final expiryValue = expiry;
    String? expiryText;
    Color? expiryColor;
    if (createdAtValue != null && expiryValue != null) {
      expiryText = 'Exp ${_formatExpiryShort(context, expiryValue)}';
      final effectiveNow = DateTime.now();
      final remainingRatio = expiryRemainingRatio(
        createdAt: createdAtValue,
        expiry: expiryValue,
        now: effectiveNow,
      );

      final isExpiredOrWarning =
          !expiryValue.isAfter(effectiveNow) ||
          remainingRatio <= kExpiryWarningRemainingRatio;

      if (onPrimaryBackground && !isExpiredOrWarning) {
        // On primary backgrounds, the neutral (non-warning) expiry label should
        // stay readable; avoid using a dark neutral tone.
        expiryColor = resolvedTextColor.withValues(alpha: kOpacityMediumHigh);
      } else {
        expiryColor = expiryStatusColor(
          context,
          createdAt: createdAtValue,
          expiry: expiryValue,
          now: effectiveNow,
        );
        if (onPrimaryBackground) {
          expiryColor = statusColorOnPrimary(context, expiryColor);
        }
      }
    }

    final spans = <TextSpan>[
      TextSpan(
        text: label,
        style: const TextStyle(fontWeight: kFontWeightSemiBold),
      ),
      if (location != null) TextSpan(text: ' · $location'),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: kSpacingXS,
                runSpacing: kSpacingXS,
                children: [
                  for (final icon in icons)
                    Icon(
                      icon,
                      size: kIconSizeSmall,
                      color: iconColor ?? cs.primary,
                    ),
                ],
              ),
              if (expiryText != null) ...[
                const SizedBox(width: kSpacingXS),
                Text(
                  expiryText,
                  style: baseStyle.copyWith(color: expiryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(width: kSpacingXS),
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(style: baseStyle, children: spans),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: kSpacingS), trailing!],
      ],
    );
  }
}
