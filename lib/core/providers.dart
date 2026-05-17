import 'package:control/data/app_repository.dart';
import 'package:control/features/analytics/analytics_controller.dart';
import 'package:control/features/app_selection/app_selection_controller.dart';
import 'package:control/features/intervention/intervention_controller.dart';
import 'package:control/features/settings/intervention_preferences_controller.dart';
import 'package:control/services/permissions_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository();
});

final appSelectionControllerProvider =
    StateNotifierProvider<AppSelectionController, AppSelectionState>((ref) {
  return AppSelectionController(ref.read(appRepositoryProvider));
});

final interventionControllerProvider =
    StateNotifierProvider<InterventionController, InterventionRequest?>((ref) {
  return InterventionController(ref.read(appRepositoryProvider));
});

final analyticsControllerProvider =
    StateNotifierProvider<AnalyticsController, AnalyticsSnapshot>((ref) {
  return AnalyticsController(ref.read(appRepositoryProvider));
});

final permissionsServiceProvider = Provider<PermissionsService>((ref) {
  return PermissionsService();
});

final permissionsStatusProvider =
    StateNotifierProvider<PermissionsController, PermissionsState>((ref) {
  return PermissionsController(ref.read(permissionsServiceProvider));
});

final interventionPreferencesProvider =
    StateNotifierProvider<InterventionPreferencesController, InterventionPreferencesState>((ref) {
      return InterventionPreferencesController();
    });
