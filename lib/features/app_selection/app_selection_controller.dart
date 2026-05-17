import 'dart:async';

import 'package:control/data/app_repository.dart';
import 'package:control/data/models/distracting_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSelectionState {
  const AppSelectionState({
    required this.apps,
    required this.filtered,
    required this.search,
    required this.loading,
  });

  final List<DistractingApp> apps;
  final List<DistractingApp> filtered;
  final String search;
  final bool loading;

  AppSelectionState copyWith({
    List<DistractingApp>? apps,
    List<DistractingApp>? filtered,
    String? search,
    bool? loading,
  }) {
    return AppSelectionState(
      apps: apps ?? this.apps,
      filtered: filtered ?? this.filtered,
      search: search ?? this.search,
      loading: loading ?? this.loading,
    );
  }

  static const empty = AppSelectionState(
    apps: <DistractingApp>[],
    filtered: <DistractingApp>[],
    search: '',
    loading: true,
  );
}

class AppSelectionController extends StateNotifier<AppSelectionState> {
  AppSelectionController(this._repository) : super(AppSelectionState.empty) {
    final local = _repository.loadApps();
    state = state.copyWith(
      apps: local,
      filtered: local,
      loading: false,
    );
  }

  final AppRepository _repository;
  bool _hasRefreshed = false;
  bool _iconHydrationInFlight = false;

  Future<void> ensureFreshData({bool background = true}) async {
    if (_hasRefreshed) {
      return;
    }
    _hasRefreshed = true;
    await refresh(background: background);
  }

  Future<void> refresh({bool background = false, bool force = false}) async {
    if (force) {
      _hasRefreshed = true;
    }

    final hadApps = state.apps.isNotEmpty;
    final showBlockingLoader = !background || !hadApps;

    if (showBlockingLoader) {
      state = state.copyWith(loading: true);
    }

    final includeIcons = !hadApps && !background;
    final apps = await _repository.refreshInstalledApps(
      includeIcons: includeIcons,
      syncConfig: false,
    );

    state = state.copyWith(
      apps: apps,
      filtered: _applyFilter(apps, state.search),
      loading: false,
    );

    unawaited(_repository.syncProtectionConfig(apps));

    if (!includeIcons && apps.any((app) => (app.iconBase64 ?? '').isEmpty)) {
      unawaited(_hydrateIconsInBackground());
    }
  }

  Future<void> _hydrateIconsInBackground() async {
    if (_iconHydrationInFlight) {
      return;
    }
    _iconHydrationInFlight = true;
    try {
      final appsWithIcons = await _repository.refreshInstalledApps(
        includeIcons: true,
        syncConfig: false,
      );
      state = state.copyWith(
        apps: appsWithIcons,
        filtered: _applyFilter(appsWithIcons, state.search),
      );
    } finally {
      _iconHydrationInFlight = false;
    }
  }

  Future<void> toggleProtection(DistractingApp app, bool enabled) async {
    final updated = app.copyWith(isProtected: enabled);
    await _repository.saveApp(updated);
    _replaceApp(updated);
  }

  Future<void> updateRule(
    DistractingApp app, {
    int? delaySeconds,
    bool? randomizedDelay,
    String? category,
  }) async {
    final updated = app.copyWith(
      delaySeconds: delaySeconds,
      randomizedDelay: randomizedDelay,
      category: category,
    );
    await _repository.saveApp(updated);
    _replaceApp(updated);
  }

  void onSearchChanged(String value) {
    state = state.copyWith(
      search: value,
      filtered: _applyFilter(state.apps, value),
    );
  }

  List<DistractingApp> _applyFilter(List<DistractingApp> input, String search) {
    if (search.trim().isEmpty) {
      return input;
    }
    final query = search.toLowerCase();
    return input
        .where(
          (app) =>
              app.label.toLowerCase().contains(query) ||
              app.packageName.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  void _replaceApp(DistractingApp updated) {
    final apps = state.apps
        .map((app) => app.packageName == updated.packageName ? updated : app)
        .toList(growable: false);
    state = state.copyWith(apps: apps, filtered: _applyFilter(apps, state.search));
  }
}
