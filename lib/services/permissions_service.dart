import 'dart:async';

import 'package:control/data/local/local_storage_service.dart';
import 'package:control/services/native_bridge_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermissionsStatus {
  const PermissionsStatus({
    required this.accessibility,
    required this.usageAccess,
    required this.batteryOptimizationIgnored,
  });

  final bool accessibility;
  final bool usageAccess;
  final bool batteryOptimizationIgnored;

  bool get ready => accessibility && usageAccess;
}

class PermissionsService {
  Future<PermissionsStatus> fetchStatus() async {
    final results = await Future.wait<bool>([
      NativeBridgeService.isAccessibilityEnabled(),
      NativeBridgeService.isUsageAccessGranted(),
      NativeBridgeService.isIgnoringBatteryOptimizations(),
    ]);

    return PermissionsStatus(
      accessibility: results[0],
      usageAccess: results[1],
      batteryOptimizationIgnored: results[2],
    );
  }
}

class PermissionsState {
  const PermissionsState({
    required this.hasGrantedOnce,
    required this.refreshing,
    this.latestStatus,
  });

  final bool hasGrantedOnce;
  final bool refreshing;
  final PermissionsStatus? latestStatus;

  bool get actualReady => latestStatus?.ready ?? false;

  bool get effectiveReady => hasGrantedOnce || actualReady;

  bool get hasFreshStatus => latestStatus != null;

  PermissionsState copyWith({
    bool? hasGrantedOnce,
    bool? refreshing,
    PermissionsStatus? latestStatus,
  }) {
    return PermissionsState(
      hasGrantedOnce: hasGrantedOnce ?? this.hasGrantedOnce,
      refreshing: refreshing ?? this.refreshing,
      latestStatus: latestStatus ?? this.latestStatus,
    );
  }

  static PermissionsState initial() {
    return PermissionsState(
      hasGrantedOnce: LocalStorageService.hasGrantedPermissionsOnce(),
      refreshing: false,
    );
  }
}

class PermissionsController extends StateNotifier<PermissionsState> {
  PermissionsController(this._service) : super(PermissionsState.initial()) {
    unawaited(refresh(background: true));
  }

  final PermissionsService _service;

  Future<void> refresh({bool background = false}) async {
    if (!background) {
      state = state.copyWith(refreshing: true);
    }

    final status = await _service.fetchStatus();
    var hasGrantedOnce = state.hasGrantedOnce;

    if (status.ready && !hasGrantedOnce) {
      hasGrantedOnce = true;
      await LocalStorageService.markPermissionsGrantedOnce();
    }

    state = state.copyWith(
      latestStatus: status,
      hasGrantedOnce: hasGrantedOnce,
      refreshing: false,
    );
  }
}
