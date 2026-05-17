import 'package:control/core/providers.dart';
import 'package:control/services/permissions_service.dart';
import 'package:control/services/native_bridge_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermissionsOnboardingScreen extends ConsumerWidget {
  const PermissionsOnboardingScreen({
    super.key,
    this.compactWhenReady = false,
  });

  final bool compactWhenReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(permissionsStatusProvider);
    final status = state.latestStatus ??
        PermissionsStatus(
          accessibility: state.effectiveReady,
          usageAccess: state.effectiveReady,
          batteryOptimizationIgnored: state.effectiveReady,
        );

    final allReady = state.effectiveReady;

    if (allReady && compactWhenReady) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.verified_rounded, color: Colors.green),
          title: const Text('Permissions configured'),
          subtitle: const Text('Accessibility and usage access are active.'),
          trailing: TextButton(
            onPressed: NativeBridgeService.openAccessibilitySettings,
            child: const Text('Manage'),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [Color(0xFF1A2E45), Color(0xFF102236)]
              : const [Color(0xFFDDF4EE), Color(0xFFCDE8FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            allReady ? 'Protection is active' : 'Enable critical permissions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            allReady
                ? 'You are ready. Manage permission details in Settings at any time.'
                : 'Control stays fully offline. Permissions are only used to detect launches and show mindful pauses.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _PermissionRow(
            label: 'Accessibility service',
            granted: status.accessibility,
            onTap: NativeBridgeService.openAccessibilitySettings,
          ),
          const SizedBox(height: 10),
          _PermissionRow(
            label: 'Usage access',
            granted: status.usageAccess,
            onTap: NativeBridgeService.openUsageAccessSettings,
          ),
          const SizedBox(height: 10),
          _PermissionRow(
            label: 'Battery optimization (recommended)',
            granted: status.batteryOptimizationIgnored,
            onTap: NativeBridgeService.openBatteryOptimizationSettings,
          ),
          if (!allReady) ...[
            const SizedBox(height: 14),
            Text(
              state.refreshing
                  ? 'Checking permission state in the background.'
                  : 'After enabling a permission, return to the app and status updates automatically.',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
          if (allReady) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: NativeBridgeService.openAccessibilitySettings,
                child: const Text('Manage permissions'),
              ),
            ),
          ],
          if (!allReady)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.onTap,
  });

  final String label;
  final bool granted;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.06 : 0.46),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(label),
        trailing: granted
            ? const Icon(Icons.check_circle_rounded, color: Colors.green)
            : TextButton(onPressed: onTap, child: const Text('Enable')),
      ),
    );
  }
}
