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
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        children: const [
          _TypeTile(icon: Icons.medication, title: 'Tablet'),
          SizedBox(height: 12),
          _TypeTile(icon: Icons.medication_liquid, title: 'Capsule'),
          SizedBox(height: 12),
          _TypeTile(icon: Icons.vaccines, title: 'Injection'),
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
  const _TypeTile({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (title == 'Tablet') {
            // Navigate to Add Tablet screen using go_router
            context.push('/medications/add/tablet');
          } else if (title == 'Capsule') {
            context.push('/medications/add/capsule');
          } else if (title == 'Injection') {
            context.push('/medications/select-injection-type');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

