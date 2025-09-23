import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

class SelectInjectionTypePage extends StatelessWidget {
  const SelectInjectionTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const GradientAppBar(title: 'Select Injection Type', forceBackButton: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        children: const [
          _Tile(title: 'Pre-Filled Syringe', subtitle: 'Ready to use single dose syringe', route: '/medications/add/injection/pfs'),
          _Tile(title: 'Single Dose Vial', subtitle: 'One time use vial', route: '/medications/add/injection/single'),
          _Tile(title: 'Multi Dose Vial', subtitle: 'Liquid vial for multiple doses', route: '/medications/add/injection/multi'),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.subtitle, required this.route});
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
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

