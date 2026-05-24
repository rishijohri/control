import 'dart:async';

import 'package:control/data/local/local_storage_service.dart';
import 'package:control/services/native_bridge_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InterventionPreferencesState {
  const InterventionPreferencesState({
    required this.breathCount,
    required this.shortFormDetectionEnabled,
    required this.shortFormInterruptionAfterSeconds,
  });

  final int breathCount;
  final bool shortFormDetectionEnabled;
  final int shortFormInterruptionAfterSeconds;

  InterventionPreferencesState copyWith({
    int? breathCount,
    bool? shortFormDetectionEnabled,
    int? shortFormInterruptionAfterSeconds,
  }) {
    return InterventionPreferencesState(
      breathCount: breathCount ?? this.breathCount,
      shortFormDetectionEnabled:
          shortFormDetectionEnabled ?? this.shortFormDetectionEnabled,
      shortFormInterruptionAfterSeconds:
          shortFormInterruptionAfterSeconds ??
          this.shortFormInterruptionAfterSeconds,
    );
  }
}

class InterventionPreferencesController
    extends StateNotifier<InterventionPreferencesState> {
  InterventionPreferencesController()
      : super(
          InterventionPreferencesState(
            breathCount: LocalStorageService.getSetting<int>(
              _breathCountKey,
              _defaultBreathCount,
            ).clamp(_minBreaths, _maxBreaths),
            shortFormDetectionEnabled: LocalStorageService.getSetting<bool>(
              _shortFormDetectionEnabledKey,
              _defaultShortFormDetectionEnabled,
            ),
            shortFormInterruptionAfterSeconds:
                LocalStorageService.getSetting<int>(
                  _shortFormInterruptionAfterSecondsKey,
                  _defaultShortFormInterruptionAfterSeconds,
                ).clamp(
                  _minShortFormInterruptionAfterSeconds,
                  _maxShortFormInterruptionAfterSeconds,
                ),
          ),
        ) {
    unawaited(_syncNativeSettings());
  }

  static const String _breathCountKey = 'intervention_breath_count';
  static const String _shortFormDetectionEnabledKey =
      'intervention_short_form_detection_enabled';
  static const String _shortFormInterruptionAfterSecondsKey =
      'intervention_short_form_interruption_after_seconds';

  static const int _defaultBreathCount = 3;
  static const bool _defaultShortFormDetectionEnabled = false;
  static const int _defaultShortFormInterruptionAfterSeconds = 30;

  static const int _minBreaths = 1;
  static const int _maxBreaths = 8;
  static const int _minShortFormInterruptionAfterSeconds = 10;
  static const int _maxShortFormInterruptionAfterSeconds = 120;

  Future<void> setBreathCount(int value) async {
    final normalized = value.clamp(_minBreaths, _maxBreaths);
    if (normalized == state.breathCount) {
      return;
    }
    state = state.copyWith(breathCount: normalized);
    await LocalStorageService.putSetting(_breathCountKey, normalized);
  }

  Future<void> setShortFormDetectionEnabled(bool enabled) async {
    if (enabled == state.shortFormDetectionEnabled) {
      return;
    }

    state = state.copyWith(shortFormDetectionEnabled: enabled);
    await LocalStorageService.putSetting(_shortFormDetectionEnabledKey, enabled);
    await _syncNativeSettings();
  }

  Future<void> setShortFormInterruptionAfterSeconds(int seconds) async {
    final normalized = seconds.clamp(
      _minShortFormInterruptionAfterSeconds,
      _maxShortFormInterruptionAfterSeconds,
    );
    if (normalized == state.shortFormInterruptionAfterSeconds) {
      return;
    }

    state = state.copyWith(shortFormInterruptionAfterSeconds: normalized);
    await LocalStorageService.putSetting(
      _shortFormInterruptionAfterSecondsKey,
      normalized,
    );
    await _syncNativeSettings();
  }

  Future<void> _syncNativeSettings() async {
    await NativeBridgeService.syncInterventionSettings(
      shortFormDetectionEnabled: state.shortFormDetectionEnabled,
      shortFormInterruptionAfterSeconds:
          state.shortFormInterruptionAfterSeconds,
    );
  }
}
