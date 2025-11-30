// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class SelectInjectionTypePage extends StatelessWidget {
  const SelectInjectionTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Select Injection Type',
        forceBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 28),
        children: const [
          _ScreenHeader(
            icon: Icons.vaccines,
            title: 'Select injection type',
            subtitle: 'We’ll tailor fields for the syringe or vial you use',
          ),
          SizedBox(height: 16),
          _Tile(
            icon: Icons.colorize,
            title: 'Pre-Filled Syringe',
            subtitle: 'Ready to use single dose syringe',
            route: '/medications/add/injection/pfs',
          ),
          SizedBox(height: 16),
          _Tile(
            icon: Icons.local_drink,
            title: 'Single Dose Vial',
            subtitle: 'One time use vial',
            route: '/medications/add/injection/single',
          ),
          SizedBox(height: 16),
          _Tile(
            icon: Icons.addchart,
            title: 'Multi Dose Vial',
            subtitle: 'Step-by-step guided setup for reconstitution',
            route: '/medications/add/injection/multi',
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool primary = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPrimary = primary;
    final tileBg = isPrimary ? cs.primary : cs.surfaceContainerLowest;
    final titleColor = isPrimary ? cs.onPrimary : cs.onSurface;
    final subtitleColor = isPrimary ? cs.onPrimary : cs.onSurfaceVariant;
    final badgeBg = isPrimary
        ? cs.onPrimary.withValues(alpha: 0.15)
        : cs.primary.withValues(alpha: 0.12);
    final badgeIconColor = isPrimary ? cs.onPrimary : cs.primary;
    final chevronColor = isPrimary ? cs.onPrimary : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(route),
        child: AnimatedScale(
          scale: 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: isPrimary
                ? BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(12),
                  )
                : softWhiteCardDecoration(context),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: badgeIconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: bodyTextStyle(context)?.copyWith(
                          fontWeight: kFontWeightBold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: mutedTextStyle(
                          context,
                        )?.copyWith(color: subtitleColor),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: chevronColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.onPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: bodyTextStyle(
                    context,
                  )?.copyWith(fontWeight: kFontWeightBold, color: cs.onPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: mutedTextStyle(context)?.copyWith(color: cs.onPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
