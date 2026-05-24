import 'dart:async';

import 'package:flutter/services.dart';

class NativeBridgeService {
  NativeBridgeService._();

  static const MethodChannel _methodChannel = MethodChannel('control/native');
  static const EventChannel _eventChannel = EventChannel('control/app_detection_events');

  static Stream<Map<String, dynamic>> appLaunchEvents() {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final raw = (event as Map?) ?? const <Object?, Object?>{};
      return raw.map((key, value) => MapEntry('$key', value));
    });
  }

  static Future<List<Map<String, dynamic>>> getInstalledApps({
    bool includeIcons = false,
  }) async {
    final List<dynamic> response =
        await _methodChannel.invokeMethod<List<dynamic>>('getInstalledApps', {
              'includeIcons': includeIcons,
            }) ??
            const <dynamic>[];
    return response
        .whereType<Map>()
        .map((entry) => entry.map((key, value) => MapEntry('$key', value)))
        .toList(growable: false);
  }

  static Future<Map<String, int>> getUsageStats() async {
    final Map<dynamic, dynamic> response =
        await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getUsageStats') ??
            const <dynamic, dynamic>{};
    return response.map((key, value) => MapEntry('$key', (value as num).toInt()));
  }

  static Future<void> openAccessibilitySettings() async {
    await _methodChannel.invokeMethod<void>('openAccessibilitySettings');
  }

  static Future<void> openUsageAccessSettings() async {
    await _methodChannel.invokeMethod<void>('openUsageAccessSettings');
  }

  static Future<void> openBatteryOptimizationSettings() async {
    await _methodChannel.invokeMethod<void>('openBatteryOptimizationSettings');
  }

  static Future<bool> isAccessibilityEnabled() async {
    return (await _methodChannel.invokeMethod<bool>('isAccessibilityEnabled')) ?? false;
  }

  static Future<bool> isUsageAccessGranted() async {
    return (await _methodChannel.invokeMethod<bool>('isUsageAccessGranted')) ?? false;
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    return (await _methodChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations')) ?? false;
  }

  static Future<void> launchApp(String packageName) async {
    await _methodChannel.invokeMethod<void>('launchApp', {'packageName': packageName});
  }

  static Future<void> goToDeviceHome() async {
    await _methodChannel.invokeMethod<void>('goToDeviceHome');
  }

  static Future<void> recordBypass(String packageName) async {
    await _methodChannel.invokeMethod<void>('recordBypass', {
      'packageName': packageName,
      'timestampMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> syncProtectionConfig(
    Map<String, Map<String, dynamic>> config,
  ) async {
    await _methodChannel.invokeMethod<void>('syncProtectionConfig', {'config': config});
  }

  static Future<void> syncInterventionSettings({
    required bool shortFormDetectionEnabled,
    required int shortFormInterruptionAfterSeconds,
  }) async {
    await _methodChannel.invokeMethod<void>('syncInterventionSettings', {
      'shortFormDetectionEnabled': shortFormDetectionEnabled,
      'shortFormInterruptionAfterSeconds': shortFormInterruptionAfterSeconds,
    });
  }
}
