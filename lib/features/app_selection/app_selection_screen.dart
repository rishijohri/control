import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/protected_app.dart';
import '../../features/intervention/intervention_screen.dart';
import '../../features/permissions/permissions_onboarding_screen.dart';
import '../../widgets/primary_nav_shell.dart';
import 'app_selection_controller.dart';

class AppSelectionScreen extends ConsumerStatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  ConsumerState<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends ConsumerState<AppSelectionScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(appSelectionProvider);
    final filtered = apps
        .where((app) => app.appName.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return PrimaryNavShell(
      selectedIndex: 0,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Protected apps',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PermissionsOnboardingScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('Permissions'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search apps',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final app = filtered[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(app.iconHint)),
                      title: Text(app.appName),
                      subtitle: Text(
                        '${app.category} • ${app.dailyUsageMinutes ?? 0}m/day • ${app.delaySeconds}s delay',
                      ),
                      onTap: () => _showRuleEditor(context, app),
                      trailing: Switch(
                        value: app.isProtected,
                        onChanged: (value) => ref
                            .read(appSelectionProvider.notifier)
                            .toggleProtection(app.packageName, value),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRuleEditor(BuildContext context, ProtectedApp app) async {
    final categories = ['General', 'Social', 'Video', 'News', 'Messaging'];
    var localDelay = app.delaySeconds as int;
    var localCategory = app.category as String;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.appName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: localCategory,
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(value: category, child: Text(category)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => localCategory = value);
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 8),
                  Text('Delay: ${localDelay}s'),
                  Slider(
                    min: 3,
                    max: 30,
                    divisions: 27,
                    value: localDelay.toDouble(),
                    onChanged: (value) =>
                        setSheetState(() => localDelay = value.round()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => InterventionScreen(
                                  targetApp: app.appName,
                                  delaySeconds: localDelay,
                                  onContinue: () => Navigator.of(context).pop(),
                                ),
                              ),
                            );
                          },
                          child: const Text('Preview intervention'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          await ref
                              .read(appSelectionProvider.notifier)
                              .updateCategory(app.packageName, localCategory);
                          await ref
                              .read(appSelectionProvider.notifier)
                              .updateDelay(app.packageName, localDelay);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
