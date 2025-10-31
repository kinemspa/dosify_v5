// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class SelectMedicationTypePage extends StatelessWidget {
  const SelectMedicationTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Medication Type',
        forceBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 28),
        children: const [
          _ScreenHeader(
            icon: Icons.add_circle_outline,
            title: 'Choose medication type',
            subtitle: 'We’ll tailor the fields for your choice',
          ),
          SizedBox(height: 16),
          _TypeTile(
            icon: Icons.add_circle,
            title: 'Tablet',
            subtitle: 'Solid pill dosage form',
          ),
          SizedBox(height: 16),
          _TypeTile(
            icon: Icons
                .medication, // placeholder, overridden in widget with MDI when available
            title: 'Capsule',
            subtitle: 'Powder or pellets in a gelatin shell',
          ),
          SizedBox(height: 16),
          _TypeTile(
            icon: Icons.colorize,
            title: 'Injection',
            subtitle: 'Pre-filled syringes or vials',
          ),
        ],
      ),
    );
  }
}

class _TypeTile extends StatefulWidget {
  const _TypeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool primary = false;

  @override
  State<_TypeTile> createState() => _TypeTileState();
}

class _TypeTileState extends State<_TypeTile> {
  bool _pressed = false;
  IconData _effectiveIcon() {
    if (widget.title == 'Capsule') return MdiIcons.pill;
    if (widget.title == 'Tablet') return Icons.add_circle;
    return Icons.colorize;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final onPrimary = cs.onPrimary;
    final primaryBg = cs.primary;
    final isPrimary = widget.primary;
    final tileBg = isPrimary ? primaryBg : cs.surfaceContainerLowest;
    // Use consistent colors with proper opacity for readability
    final titleColor = isPrimary
        ? onPrimary
        : cs.onSurface.withValues(alpha: kOpacityHigh);
    final subtitleColor = isPrimary
        ? onPrimary
        : cs.onSurfaceVariant.withValues(alpha: kOpacityMedium);
    final badgeBg = isPrimary
        ? onPrimary.withValues(alpha: 0.15)
        : primaryBg.withValues(alpha: 0.12);
    final badgeIconColor = isPrimary ? onPrimary : primaryBg;
    final chevronColor = isPrimary ? onPrimary : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (widget.title == 'Tablet') {
            context.push('/medications/add/tablet');
          } else if (widget.title == 'Capsule') {
            context.push('/medications/add/capsule');
          } else if (widget.title == 'Injection') {
            context.push('/medications/select-injection-type');
          } else if (widget.title == 'Editor Template (Preview)') {
            context.push('/medications/add/template');
          }
        },
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            decoration: isPrimary
                ? BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(12),
                  )
                : softWhiteCardDecoration(context),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                // Leading icon badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _effectiveIcon(),
                    color: badgeIconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: bodyTextStyle(context)?.copyWith(
                          fontWeight: kFontWeightBold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
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
