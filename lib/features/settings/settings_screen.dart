import 'package:control/core/providers.dart';
import 'package:control/features/onboarding/permissions_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(appSelectionControllerProvider).apps;
    final protectedCount = apps.where((app) => app.isProtected).length;
    final bottomPadding = 20 + MediaQuery.paddingOf(context).bottom;
    final permissionsState = ref.watch(permissionsStatusProvider);
    final isReady = permissionsState.effectiveReady;
    final interventionPrefs = ref.watch(interventionPreferencesProvider);

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
        children: [
          PermissionsOnboardingScreen(compactWhenReady: isReady),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              title: const Text('Protected apps'),
              subtitle: const Text('Apps currently guarded by interventions'),
              trailing: Text('$protectedCount'),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              title: Text('Privacy-first'),
              subtitle: Text('All analytics remain on-device. No ads, no tracking.'),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Intervention style',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Breathing first, then intent selection and hold confirmation.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Breaths before intent unlock',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        '${interventionPrefs.breathCount}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Slider(
                    value: interventionPrefs.breathCount.toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    label: '${interventionPrefs.breathCount} breaths',
                    onChanged: (value) {
                      ref
                          .read(interventionPreferencesProvider.notifier)
                          .setBreathCount(value.round());
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
