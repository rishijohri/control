import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/app_selection/app_selection_screen.dart';

class ControlApp extends StatelessWidget {
  const ControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AppSelectionScreen(),
    );
  }
}
