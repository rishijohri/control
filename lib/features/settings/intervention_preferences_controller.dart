import 'package:control/data/local/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InterventionPreferencesState {
  const InterventionPreferencesState({required this.breathCount});

  final int breathCount;

  InterventionPreferencesState copyWith({int? breathCount}) {
    return InterventionPreferencesState(
      breathCount: breathCount ?? this.breathCount,
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
          ),
        );

  static const String _breathCountKey = 'intervention_breath_count';
  static const int _defaultBreathCount = 3;
  static const int _minBreaths = 1;
  static const int _maxBreaths = 8;

  Future<void> setBreathCount(int value) async {
    final normalized = value.clamp(_minBreaths, _maxBreaths);
    if (normalized == state.breathCount) {
      return;
    }
    state = state.copyWith(breathCount: normalized);
    await LocalStorageService.putSetting(_breathCountKey, normalized);
  }
}
