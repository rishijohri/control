import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/models/protected_app.dart';
import '../../core/repositories/protected_apps_repository.dart';

final appSelectionProvider =
    NotifierProvider<AppSelectionController, List<ProtectedApp>>(
  AppSelectionController.new,
);

class AppSelectionController extends Notifier<List<ProtectedApp>> {
  late final ProtectedAppsRepository _repo;

  @override
  List<ProtectedApp> build() {
    _repo = ProtectedAppsRepository(Hive.box<Map>(ProtectedAppsRepository.boxName));
    return _repo.loadAll();
  }

  Future<void> toggleProtection(String packageName, bool value) async {
    state = [
      for (final app in state)
        if (app.packageName == packageName) app.copyWith(isProtected: value) else app,
    ];
    await _repo.saveAll(state);
  }

  Future<void> updateCategory(String packageName, String category) async {
    state = [
      for (final app in state)
        if (app.packageName == packageName) app.copyWith(category: category) else app,
    ];
    await _repo.saveAll(state);
  }

  Future<void> updateDelay(String packageName, int delaySeconds) async {
    state = [
      for (final app in state)
        if (app.packageName == packageName)
          app.copyWith(delaySeconds: delaySeconds)
        else
          app,
    ];
    await _repo.saveAll(state);
  }
}
