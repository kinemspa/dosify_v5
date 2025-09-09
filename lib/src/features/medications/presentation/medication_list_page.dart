import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MedicationListPage extends StatelessWidget {
  const MedicationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
      ),
      body: Center(
        child: Column(
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/medications/select-type'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

