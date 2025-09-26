import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Dosifi v5'),
      // Logo moved to body header to avoid duplicate appBar
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/logo/dosifi-high-resolution-logo-transparent.png',
                  height: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Welcome to Dosifi v5',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This is a starter scaffold. From here you can add medications and schedules.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/medications'),
                  icon: const Icon(Icons.medication),
                  label: const Text('Medications'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
