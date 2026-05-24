import 'dart:async';

import 'package:control/core/providers.dart';
import 'package:control/data/models/intervention_event.dart';
import 'package:control/features/analytics/analytics_dashboard_screen.dart';
import 'package:control/features/app_selection/app_selection_screen.dart';
import 'package:control/features/intervention/intervention_screen.dart';
import 'package:control/features/settings/settings_screen.dart';
import 'package:control/services/native_bridge_service.dart';
import 'package:control/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ControlApp extends StatelessWidget {
  const ControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        ref.read(appSelectionControllerProvider.notifier).ensureFreshData(background: true),
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(permissionsStatusProvider.notifier).refresh(background: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(permissionsStatusProvider);
    final isReady = permissionState.effectiveReady;
    final breathCount = ref.watch(interventionPreferencesProvider).breathCount;

    ref.listen(permissionsStatusProvider, (previous, next) {
      final wasReady = previous?.effectiveReady ?? false;
      final nowReady = next.effectiveReady;
      if (!wasReady && nowReady) {
        if (mounted && _index == 2) {
          setState(() => _index = 0);
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
        unawaited(
          ref.read(appSelectionControllerProvider.notifier).refresh(
                background: true,
                force: true,
              ),
        );
      }
    });

    if (!isReady && _index != 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _index = 2);
          _pageController.jumpToPage(2);
        }
      });
    }

    ref.listen(interventionControllerProvider, (previous, next) async {
      if (next == null || !mounted) {
        return;
      }

      final result = await Navigator.of(context).push<InterventionResult>(
        PageRouteBuilder(
          opaque: true,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, __, ___) => InterventionScreen(
            appLabel: next.label,
            delaySeconds: next.delaySeconds,
            opensToday: next.opensToday,
            minutesToday: next.minutesToday,
            breathTarget: breathCount,
          ),
          transitionsBuilder: (_, __, ___, child) => child,
        ),
      );

      if (result == null) {
        ref.read(interventionControllerProvider.notifier).dismissWithoutAction();
        return;
      }

      await ref.read(interventionControllerProvider.notifier).complete(
            intent: result.intent,
            outcome: result.continueToTarget
                ? InterventionOutcome.mindfulOpen
                : InterventionOutcome.dropped,
            continueToTarget: result.continueToTarget,
          );

      if (!result.continueToTarget) {
        await NativeBridgeService.goToDeviceHome();
      }

      ref.read(analyticsControllerProvider.notifier).refresh();
    });

    final screens = const [
      _HomeScreen(),
      AnalyticsDashboardScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (value) {
          if (_index != value && mounted) {
            setState(() => _index = value);
          }
        },
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: isReady ? _index : 2,
        onDestinationSelected: (value) {
          if (!isReady && value != 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Grant required permissions first in Settings.'),
                duration: Duration(seconds: 2),
              ),
            );
            setState(() => _index = 2);
            _pageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
            );
            return;
          }
          setState(() => _index = value);
          _pageController.animateToPage(
            value,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Protect'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Control',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Expanded(child: AppSelectionScreen()),
        ],
      ),
    );
  }
}
