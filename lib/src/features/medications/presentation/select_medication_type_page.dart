import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SelectMedicationTypePage extends StatelessWidget {
  const SelectMedicationTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Medication Type',
        forceBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 28),
        children: [
const _ScreenHeader(
            icon: Icons.add_circle_outline,
            title: 'Choose medication type',
            subtitle: 'We’ll tailor the fields for your choice',
          ),
          const SizedBox(height: 16),
          const _TypeTile(
            icon: Icons.add_circle,
            title: 'Tablet',
            subtitle: 'Solid pill dosage form',
          ),
          const SizedBox(height: 16),
const _TypeTile(
            icon: Icons.medication, // placeholder, overridden in widget with MDI when available
            title: 'Capsule',
            subtitle: 'Powder or pellets in a gelatin shell',
          ),
          const SizedBox(height: 16),
          const _TypeTile(
            icon: Icons.colorize,
            title: 'Injection',
            subtitle: 'Pre-filled syringes or vials',
          ),
          const SizedBox(height: 16),
          const _TypeTile(
            icon: Icons.description,
            title: 'Editor Template (Preview)',
            subtitle: 'Open the template-based editor',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...children,
            const SizedBox(height: 16),
            // Template preview entry to verify layout parity on-device
            _TypeTile(
              icon: Icons.description,
              title: 'Editor Template (Preview)'.toString(),
              subtitle: 'Open the template-based editor to verify exact layout',
              primary: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatefulWidget {
  const _TypeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.primary = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool primary;

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
    final tileBorder = isPrimary ? null : Border.all(color: cs.outlineVariant);
    final titleColor = isPrimary ? onPrimary : cs.onSurface;
    final subtitleColor = isPrimary ? onPrimary : cs.onSurfaceVariant;
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
child: Icon(_effectiveIcon(), color: badgeIconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                        ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
