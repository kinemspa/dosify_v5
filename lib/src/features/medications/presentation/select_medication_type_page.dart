import 'package:flutter/material.dart';

class SelectMedicationTypePage extends StatelessWidget {
  const SelectMedicationTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Medication Type'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TypeTile(icon: Icons.medication, title: 'Tablet'),
          _TypeTile(icon: Icons.medication_liquid, title: 'Capsule'),
          _TypeTile(icon: Icons.vaccines, title: 'Injection'),
        ],
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
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (title == 'Tablet') {
            // Navigate to Add Tablet screen
            Navigator.of(context).pushNamed('/medications/add/tablet');
          }
        },
      ),
    );
  }
}

