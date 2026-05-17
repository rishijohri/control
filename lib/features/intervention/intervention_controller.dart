import 'dart:async';

import 'package:control/data/app_repository.dart';
import 'package:control/data/models/intervention_event.dart';
import 'package:control/services/native_bridge_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InterventionRequest {
  const InterventionRequest({
    required this.packageName,
    required this.label,
    required this.delaySeconds,
    required this.opensToday,
    required this.minutesToday,
  });

  final String packageName;
  final String label;
  final int delaySeconds;
  final int opensToday;
  final int minutesToday;
}

class InterventionController extends StateNotifier<InterventionRequest?> {
  InterventionController(this._repository) : super(null) {
    _subscription = NativeBridgeService.appLaunchEvents().listen(_onEvent);
  }

  final AppRepository _repository;
  late final StreamSubscription<Map<String, dynamic>> _subscription;

  void _onEvent(Map<String, dynamic> event) {
    final packageName = event['packageName']?.toString() ?? '';
    if (packageName.isEmpty) {
      return;
    }
    if (state?.packageName == packageName) {
      return;
    }
    final app = _repository.findByPackage(packageName);
    if (app == null || !app.isProtected) {
      return;
    }
    final metrics = _repository.getTodayQuickMetrics(packageName);
    state = InterventionRequest(
      packageName: packageName,
      label: app.label,
      delaySeconds: _repository.resolveDelay(app),
      opensToday: metrics.opensToday,
      minutesToday: metrics.minutesToday,
    );
  }

  Future<void> complete({
    required String intent,
    required InterventionOutcome outcome,
    required bool continueToTarget,
  }) async {
    final request = state;
    if (request == null) {
      return;
    }

    // Clear current request early to avoid duplicate modal loops while
    // continuing to the target app.
    state = null;

    await _repository.addEvent(
      InterventionEvent(
        packageName: request.packageName,
        appLabel: request.label,
        intent: intent,
        outcome: outcome,
        timestamp: DateTime.now(),
        delaySeconds: request.delaySeconds,
      ),
    );

    if (continueToTarget) {
      await NativeBridgeService.launchApp(request.packageName);
    }
  }

  void dismissWithoutAction() {
    state = null;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
