import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

class SelectInjectionTypePage extends StatelessWidget {
  const SelectInjectionTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Select Injection Type', forceBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Tile(
            title: 'Pre-Filled Syringe',
            subtitle: 'Ready to use single dose syringe',
            onTap: () => context.push('/medications/add/injection/pfs'),
          ),
          _Tile(
            title: 'Single Dose Vial',
            subtitle: 'One time use vial',
            onTap: () => context.push('/medications/add/injection/single'),
          ),
          _Tile(
            title: 'Multi Dose Vial',
            subtitle: 'Liquid vial for multiple doses',
            onTap: () => context.push('/medications/add/injection/multi'),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

