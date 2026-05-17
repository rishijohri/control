import 'package:collection/collection.dart';
import 'package:control/data/app_repository.dart';
import 'package:control/data/local/local_storage_service.dart';
import 'package:control/data/models/intervention_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AnalyticsGranularity {
  hourly,
  daily,
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.totalInterventions,
    required this.mindfulOpens,
    required this.bypasses,
    required this.estimatedMinutesSaved,
    required this.granularity,
    required this.selectedApp,
    required this.availableApps,
    required this.hourlyCounts,
    required this.dailyCounts,
    required this.topApps,
    required this.reasonCounts,
  });

  final int totalInterventions;
  final int mindfulOpens;
  final int bypasses;
  final int estimatedMinutesSaved;
  final AnalyticsGranularity granularity;
  final String selectedApp;
  final List<String> availableApps;
  final Map<DateTime, int> hourlyCounts;
  final Map<DateTime, int> dailyCounts;
  final Map<String, int> topApps;
  final Map<String, int> reasonCounts;

  AnalyticsSnapshot copyWith({
    int? totalInterventions,
    int? mindfulOpens,
    int? bypasses,
    int? estimatedMinutesSaved,
    AnalyticsGranularity? granularity,
    String? selectedApp,
    List<String>? availableApps,
    Map<DateTime, int>? hourlyCounts,
    Map<DateTime, int>? dailyCounts,
    Map<String, int>? topApps,
    Map<String, int>? reasonCounts,
  }) {
    return AnalyticsSnapshot(
      totalInterventions: totalInterventions ?? this.totalInterventions,
      mindfulOpens: mindfulOpens ?? this.mindfulOpens,
      bypasses: bypasses ?? this.bypasses,
      estimatedMinutesSaved: estimatedMinutesSaved ?? this.estimatedMinutesSaved,
      granularity: granularity ?? this.granularity,
      selectedApp: selectedApp ?? this.selectedApp,
      availableApps: availableApps ?? this.availableApps,
      hourlyCounts: hourlyCounts ?? this.hourlyCounts,
      dailyCounts: dailyCounts ?? this.dailyCounts,
      topApps: topApps ?? this.topApps,
      reasonCounts: reasonCounts ?? this.reasonCounts,
    );
  }
}

class AnalyticsController extends StateNotifier<AnalyticsSnapshot> {
  AnalyticsController(this._repository)
      : super(
          const AnalyticsSnapshot(
            totalInterventions: 0,
            mindfulOpens: 0,
            bypasses: 0,
            estimatedMinutesSaved: 0,
            granularity: AnalyticsGranularity.hourly,
            selectedApp: '',
            availableApps: <String>[],
            hourlyCounts: <DateTime, int>{},
            dailyCounts: <DateTime, int>{},
            topApps: <String, int>{},
            reasonCounts: <String, int>{},
          ),
        ) {
    final useHourly = LocalStorageService.getSetting<bool>('analytics_use_hourly', true);
    final selectedApp = LocalStorageService.getSetting<String>('analytics_selected_app', '');
    state = state.copyWith(
      granularity: useHourly ? AnalyticsGranularity.hourly : AnalyticsGranularity.daily,
      selectedApp: selectedApp,
    );
    refresh();
  }

  final AppRepository _repository;

  Future<void> setGranularity(AnalyticsGranularity granularity) async {
    state = state.copyWith(granularity: granularity);
    await LocalStorageService.putSetting(
      'analytics_use_hourly',
      granularity == AnalyticsGranularity.hourly,
    );
  }

  Future<void> setSelectedApp(String value) async {
    final normalized = value.trim();
    state = state.copyWith(selectedApp: normalized);
    await LocalStorageService.putSetting('analytics_selected_app', normalized);
    refresh();
  }

  void refresh() {
    final events = _repository.loadEvents();
    final apps = events
        .map((event) => event.appLabel)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final selectedApp = apps.contains(state.selectedApp) ? state.selectedApp : '';
    final filtered = selectedApp.isEmpty
        ? events
        : events.where((event) => event.appLabel == selectedApp).toList(growable: false);

    final mindful = filtered.where((e) => e.outcome == InterventionOutcome.mindfulOpen).length;
    final bypasses = filtered.where((e) => e.outcome == InterventionOutcome.bypass).length;

    final hourly = <DateTime, int>{};
    for (final event in filtered) {
      final key = DateTime(
        event.timestamp.year,
        event.timestamp.month,
        event.timestamp.day,
        event.timestamp.hour,
      );
      hourly.update(key, (value) => value + 1, ifAbsent: () => 1);
    }

    final daily = <DateTime, int>{};
    for (final event in filtered) {
      final key = DateTime(event.timestamp.year, event.timestamp.month, event.timestamp.day);
      daily.update(key, (value) => value + 1, ifAbsent: () => 1);
    }

    final groupedApps = groupBy(events, (InterventionEvent item) => item.appLabel);
    final topApps = <String, int>{
      for (final entry in groupedApps.entries) entry.key: entry.value.length,
    };

    final groupedReasons = groupBy(filtered, (InterventionEvent item) => item.intent);
    final reasonCounts = <String, int>{
      for (final entry in groupedReasons.entries)
        (entry.key.trim().isEmpty ? 'Unspecified' : entry.key): entry.value.length,
    };

    final estimatedMinutes = (mindful * 4) + (bypasses * 1);

    state = AnalyticsSnapshot(
      totalInterventions: filtered.length,
      mindfulOpens: mindful,
      bypasses: bypasses,
      estimatedMinutesSaved: estimatedMinutes,
      granularity: state.granularity,
      selectedApp: selectedApp,
      availableApps: apps,
      hourlyCounts: hourly,
      dailyCounts: daily,
      topApps: topApps,
      reasonCounts: reasonCounts,
    );
  }
}
