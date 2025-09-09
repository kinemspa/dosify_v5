import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers.dart';

class MedicationListPage extends ConsumerWidget {
  const MedicationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(medicationsListProvider);

    Widget content;
    if (items.isEmpty) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.medication, size: 48),
          const SizedBox(height: 12),
          const Text('Add a medication to begin tracking'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/medications/select-type'),
            child: const Text('Add Medication'),
          ),
        ],
      );
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final m = items[index];
          return ListTile(
            title: Text(m.name),
            subtitle: Text('${m.strengthValue} ${m.strengthUnit.name} • Stock: ${m.stockValue} ${m.stockUnit.name}'),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
      ),
      body: Center(child: content),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/medications/select-type'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

