import 'dart:math';

import 'package:collection/collection.dart';
import 'package:control/data/local/local_storage_service.dart';
import 'package:control/data/models/distracting_app.dart';
import 'package:control/data/models/focus_mode.dart';
import 'package:control/data/models/intervention_event.dart';
import 'package:control/services/native_bridge_service.dart';

class AppRepository {
  Future<List<DistractingApp>> refreshInstalledApps({
    bool includeIcons = false,
    bool syncConfig = true,
  }) async {
    final installedRaw = await NativeBridgeService.getInstalledApps(includeIcons: includeIcons);
    final usageStats = await NativeBridgeService.getUsageStats();
    final existing = {for (final app in LocalStorageService.getApps()) app.packageName: app};

    final merged = installedRaw.map((raw) {
      final package = raw['packageName']?.toString() ?? '';
      final current = existing[package];
      return DistractingApp(
        packageName: package,
        label: raw['label']?.toString() ?? package,
        iconBase64: raw['iconBase64']?.toString() ?? current?.iconBase64,
        isProtected: current?.isProtected ?? false,
        category: current?.category ?? 'General',
        delaySeconds: current?.delaySeconds ?? 8,
        randomizedDelay: current?.randomizedDelay ?? false,
        estimatedUsageMinutes: usageStats[package] ?? current?.estimatedUsageMinutes ?? 0,
      );
    }).toList(growable: false)
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    await LocalStorageService.upsertApps(merged);
    if (syncConfig) {
      await syncProtectionConfig(merged);
    }
    return merged;
  }

  List<DistractingApp> loadApps() {
    return LocalStorageService.getApps();
  }

  Future<void> saveApp(DistractingApp app) async {
    await LocalStorageService.upsertApp(app);
    await syncProtectionConfig(LocalStorageService.getApps());
  }

  Future<void> syncProtectionConfig(List<DistractingApp> apps) async {
    final config = {
      for (final app in apps.where((item) => item.isProtected))
        app.packageName: {
          'delaySeconds': app.delaySeconds,
          'randomizedDelay': app.randomizedDelay,
        },
    };
    await NativeBridgeService.syncProtectionConfig(config);
  }

  Future<void> addEvent(InterventionEvent event) async {
    await LocalStorageService.addInterventionEvent(event);
  }

  List<InterventionEvent> loadEvents() {
    return LocalStorageService.getInterventionEvents();
  }

  List<FocusMode> loadFocusModes() {
    final modes = LocalStorageService.getFocusModes();
    if (modes.isNotEmpty) {
      return modes;
    }
    return const <FocusMode>[
      FocusMode(id: 'work', name: 'Work', protectedPackages: <String>[], active: false),
      FocusMode(id: 'study', name: 'Study', protectedPackages: <String>[], active: false),
      FocusMode(id: 'sleep', name: 'Sleep', protectedPackages: <String>[], active: false, startHour: 22, endHour: 7),
      FocusMode(id: 'deep', name: 'Deep Focus', protectedPackages: <String>[], active: false),
    ];
  }

  Future<void> saveFocusMode(FocusMode mode) async {
    await LocalStorageService.upsertFocusMode(mode);
  }

  int resolveDelay(DistractingApp app) {
    if (!app.randomizedDelay) {
      return app.delaySeconds;
    }
    final random = Random();
    final min = max(3, app.delaySeconds - 3);
    final maxValue = app.delaySeconds + 5;
    return min + random.nextInt(maxValue - min + 1);
  }

  DistractingApp? findByPackage(String packageName) {
    return LocalStorageService
        .getApps()
        .firstWhereOrNull((app) => app.packageName == packageName);
  }

  ({int opensToday, int minutesToday}) getTodayQuickMetrics(String packageName) {
    final now = DateTime.now();
    final opensToday = LocalStorageService.getInterventionEvents().where((event) {
      final ts = event.timestamp;
      return event.packageName == packageName &&
          ts.year == now.year &&
          ts.month == now.month &&
          ts.day == now.day;
    }).length;

    final minutesToday =
        findByPackage(packageName)?.estimatedUsageMinutes ?? 0;

    return (opensToday: opensToday, minutesToday: minutesToday);
  }
}
