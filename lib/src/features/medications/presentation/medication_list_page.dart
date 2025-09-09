import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/format.dart';
import '../domain/medication.dart';

class MedicationListPage extends ConsumerWidget {
  const MedicationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = Hive.box<Medication>('medications');

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Medications'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Medication> b, _) {
          final items = b.values.toList(growable: false);
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.medication, size: 48),
                  const SizedBox(height: 12),
                  const Text('Add a medication to begin tracking'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push('/medications/select-type'),
                    child: const Text('Add Medication'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final m = items[index];
              return ListTile(
                title: Text(m.name),
                subtitle: Text('${fmt2(m.strengthValue)} ${m.strengthUnit.name} • Stock: ${fmt2(m.stockValue)} ${m.stockUnit.name}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/medications/select-type'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

