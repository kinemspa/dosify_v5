import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/glass_card_surface.dart';
import 'package:flutter/material.dart';

class SelectionHeaderCard extends StatelessWidget {
  const SelectionHeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Header should not look like a selectable card.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kCardPadding,
        vertical: kSpacingL,
      ),
      decoration: buildInsetSectionDecoration(
        context: context,
        backgroundOpacity: 0.85,
      ),
      child: Row(
        children: [
          Container(
            width: kLargeButtonHeight,
            height: kLargeButtonHeight,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: kOpacitySubtle),
              borderRadius: BorderRadius.circular(kBorderRadiusMedium),
            ),
            child: Icon(icon, color: cs.primary, size: kIconSizeLarge),
          ),
          const SizedBox(width: kSpacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: bodyTextStyle(
                    context,
                  )?.copyWith(fontWeight: kFontWeightBold),
                ),
                const SizedBox(height: kSpacingXS),
                Text(subtitle, style: mutedTextStyle(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SelectionOptionCard extends StatelessWidget {
  const SelectionOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassCardSurface(
      onTap: onTap,
      useGradient: false,
      padding: const EdgeInsets.symmetric(
        horizontal: kCardPadding,
        vertical: kSpacingL,
      ),
      child: Row(
        children: [
          Container(
            width: kStandardFieldHeight,
            height: kStandardFieldHeight,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: kOpacitySubtle),
              borderRadius: BorderRadius.circular(kBorderRadiusMedium),
            ),
            child: Icon(icon, color: cs.primary, size: kIconSizeMedium),
          ),
          const SizedBox(width: kSpacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: bodyTextStyle(
                    context,
                  )?.copyWith(fontWeight: kFontWeightBold),
                ),
                const SizedBox(height: kSpacingXS),
                Text(subtitle, style: mutedTextStyle(context)),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
          ),
        ],
      ),
    );
  }
}

class SelectableOptionCard extends StatelessWidget {
  const SelectableOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final foreground = enabled
        ? cs.onSurface
        : cs.onSurface.withValues(alpha: kOpacityMedium);
    final subtitleColor = enabled
        ? cs.onSurface.withValues(alpha: kOpacityMedium)
        : cs.onSurface.withValues(alpha: kOpacityLow);

    return GlassCardSurface(
      onTap: enabled ? onTap : null,
      useGradient: false,
      padding: const EdgeInsets.symmetric(
        horizontal: kCardPadding,
        vertical: kSpacingM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: kStandardFieldHeight,
            height: kStandardFieldHeight,
            decoration: BoxDecoration(
              color: cs.primary.withValues(
                alpha: enabled ? kOpacitySubtle : kOpacityLow,
              ),
              borderRadius: BorderRadius.circular(kBorderRadiusMedium),
            ),
            child: Icon(
              icon,
              color: enabled
                  ? cs.primary
                  : cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
              size: kIconSizeMedium,
            ),
          ),
          const SizedBox(width: kSpacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: bodyTextStyle(context)?.copyWith(
                    fontWeight: kFontWeightBold,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: kSpacingXS),
                Text(
                  subtitle,
                  style: mutedTextStyle(context)?.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: kSpacingS),
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected
                ? cs.primary
                : cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
            size: kIconSizeMedium,
          ),
        ],
      ),
    );
  }
}
