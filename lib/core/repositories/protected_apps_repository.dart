import 'package:hive/hive.dart';

import '../models/protected_app.dart';

class ProtectedAppsRepository {
  ProtectedAppsRepository(this._box);

  static const boxName = 'protected_apps';
  final Box<Map> _box;

  List<ProtectedApp> loadAll() {
    final values = _box.values.map(ProtectedApp.fromJson).toList();
    if (values.isNotEmpty) return values;
    return const [
      ProtectedApp(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        iconHint: 'IG',
        dailyUsageMinutes: 49,
      ),
      ProtectedApp(
        packageName: 'com.google.android.youtube',
        appName: 'YouTube',
        iconHint: 'YT',
        dailyUsageMinutes: 74,
      ),
      ProtectedApp(
        packageName: 'com.reddit.frontpage',
        appName: 'Reddit',
        iconHint: 'R',
        dailyUsageMinutes: 38,
      ),
      ProtectedApp(
        packageName: 'com.twitter.android',
        appName: 'X',
        iconHint: 'X',
        dailyUsageMinutes: 32,
      ),
    ];
  }

  Future<void> saveAll(List<ProtectedApp> apps) async {
    await _box.clear();
    for (final app in apps) {
      await _box.put(app.packageName, app.toJson());
    }
  }
}
