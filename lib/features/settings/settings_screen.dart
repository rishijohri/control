import 'package:flutter/material.dart';

import '../../widgets/primary_nav_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryNavShell(
      selectedIndex: 4,
      body: SafeArea(
        child: ListView(
          children: const [
            ListTile(
              title: Text('Randomized delay'),
              subtitle: Text('Use +-20% dynamic delay variation'),
            ),
            ListTile(
              title: Text('Emergency bypass count'),
              subtitle: Text('3 per day with cooldown'),
            ),
            ListTile(
              title: Text('Weekend profile'),
              subtitle: Text('Use lighter rules on weekends'),
            ),
          ],
        ),
      ),
    );
  }
}
