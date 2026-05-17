import 'package:flutter/material.dart';

import '../../core/services/app_interception_service.dart';

class PermissionsOnboardingScreen extends StatelessWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AppInterceptionService();
    return Scaffold(
      appBar: AppBar(title: const Text('Enable protections')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _StepCard(
            title: 'Accessibility access',
            body:
                'Needed to detect foreground app changes with minimal polling.',
          ),
          const _StepCard(
            title: 'Usage access',
            body: 'Used to improve app stats and edge-case recovery.',
          ),
          const _StepCard(
            title: 'Battery optimization exclusion',
            body: 'Helps keep detection reliable across OEM restrictions.',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: service.requestPermissions,
            child: const Text('Open Android permission setup'),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(body),
      ),
    );
  }
}
