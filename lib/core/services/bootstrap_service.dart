import 'package:hive_flutter/hive_flutter.dart';

import '../repositories/analytics_repository.dart';
import '../repositories/focus_mode_repository.dart';
import '../repositories/protected_apps_repository.dart';

class BootstrapService {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(ProtectedAppsRepository.boxName);
    await Hive.openBox<Map>(AnalyticsRepository.boxName);
    await Hive.openBox<Map>(FocusModeRepository.boxName);
  }
}
