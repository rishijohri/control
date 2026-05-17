import 'package:control/data/models/distracting_app.dart';
import 'package:control/data/models/focus_mode.dart';
import 'package:control/data/models/intervention_event.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  LocalStorageService._();

  static const String _appsBoxName = 'apps';
  static const String _eventsBoxName = 'events';
  static const String _settingsBoxName = 'settings';
  static const String _focusModesBoxName = 'focus_modes';
  static const String _permissionsGrantedOnceKey = 'permissions_granted_once';

  static late Box<Map> _appsBox;
  static late Box<Map> _eventsBox;
  static late Box<Map> _focusModesBox;
  static late Box _settingsBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _appsBox = await Hive.openBox<Map>(_appsBoxName);
    _eventsBox = await Hive.openBox<Map>(_eventsBoxName);
    _focusModesBox = await Hive.openBox<Map>(_focusModesBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  static List<DistractingApp> getApps() {
    return _appsBox.values
        .map((entry) => DistractingApp.fromMap(entry))
        .where((app) => app.packageName.isNotEmpty)
        .toList(growable: false);
  }

  static Future<void> upsertApps(List<DistractingApp> apps) async {
    final Map<String, Map<String, dynamic>> entries = {
      for (final app in apps) app.packageName: app.toMap(),
    };
    await _appsBox.putAll(entries);
  }

  static Future<void> upsertApp(DistractingApp app) async {
    await _appsBox.put(app.packageName, app.toMap());
  }

  static List<InterventionEvent> getInterventionEvents() {
    final values = _eventsBox.values
        .map((entry) => InterventionEvent.fromMap(entry))
        .toList(growable: false);
    values.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return values;
  }

  static Future<void> addInterventionEvent(InterventionEvent event) async {
    final key = '${event.timestamp.microsecondsSinceEpoch}_${event.packageName}';
    await _eventsBox.put(key, event.toMap());
  }

  static List<FocusMode> getFocusModes() {
    return _focusModesBox.values
        .map((entry) => FocusMode.fromMap(entry))
        .where((mode) => mode.id.isNotEmpty)
        .toList(growable: false);
  }

  static Future<void> upsertFocusMode(FocusMode mode) async {
    await _focusModesBox.put(mode.id, mode.toMap());
  }

  static Future<void> putSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static T getSetting<T>(String key, T fallback) {
    final value = _settingsBox.get(key);
    if (value is T) {
      return value;
    }
    return fallback;
  }

  static bool hasGrantedPermissionsOnce() {
    return getSetting<bool>(_permissionsGrantedOnceKey, false);
  }

  static Future<void> markPermissionsGrantedOnce() async {
    await putSetting(_permissionsGrantedOnceKey, true);
  }
}
