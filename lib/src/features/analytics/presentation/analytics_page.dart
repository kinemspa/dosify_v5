import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Analytics', forceBackButton: true),
      body: const Center(
        child: Text('Analytics coming soon'),
      ),
    );
  }
}
