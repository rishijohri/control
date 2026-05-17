import 'package:flutter/material.dart';

import '../features/analytics/analytics_screen.dart';
import '../features/app_selection/app_selection_screen.dart';
import '../features/focus_modes/focus_modes_screen.dart';
import '../features/settings/settings_screen.dart';

class PrimaryNavShell extends StatelessWidget {
  const PrimaryNavShell({
    super.key,
    required this.body,
    required this.selectedIndex,
  });

  final Widget body;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.apps), label: 'Apps'),
          NavigationDestination(icon: Icon(Icons.spa), label: 'Pause'),
          NavigationDestination(icon: Icon(Icons.query_stats), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.timelapse), label: 'Modes'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onDestinationSelected: (index) {
          final pages = [
            const AppSelectionScreen(),
            const SizedBox.shrink(),
            const AnalyticsScreen(),
            const FocusModesScreen(),
            const SettingsScreen(),
          ];
          if (index == 1) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => pages[index]),
          );
        },
      ),
    );
  }
}
