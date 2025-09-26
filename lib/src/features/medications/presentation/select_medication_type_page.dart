import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

class SelectMedicationTypePage extends StatelessWidget {
  const SelectMedicationTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: const GradientAppBar(title: 'Select Medication Type', forceBackButton: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 28),
        children: const [
          _TypeTile(title: 'Tablet', subtitle: 'Solid pill dosage form'),
          SizedBox(height: 16),
          _TypeTile(title: 'Capsule', subtitle: 'Powder or pellets in a gelatin shell'),
          SizedBox(height: 16),
          _TypeTile(title: 'Injection', subtitle: 'Pre-filled syringes or vials'),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 4),
                child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 15, color: theme.colorScheme.primary)),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          ...children,
        ]),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (title == 'Tablet') {
            context.push('/medications/add/tablet');
          } else if (title == 'Capsule') {
            context.push('/medications/add/capsule');
          } else if (title == 'Injection') {
            context.push('/medications/select-injection-type');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

