import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

class SelectMedicationForSchedulePage extends StatelessWidget {
  const SelectMedicationForSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Medication>('medications');
    final meds = box.values.toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Select medication')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: meds.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final m = meds[i];
          String subtitle = '';
          subtitle = '${m.strengthValue} ${m.strengthUnit.name}';
          return ListTile(
            title: Text(m.name),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pop(m),
          );
        },
      ),
    );
  }
}
