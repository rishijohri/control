import 'package:hive/hive.dart';

import '../models/analytics_point.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._box);

  static const boxName = 'analytics';
  final Box<Map> _box;

  Future<void> recordPreventedOpen(DateTime when) async {
    final key = _keyForDay(when);
    final existing = _box.get(key, defaultValue: {'count': 0})!;
    final count = (existing['count'] as int? ?? 0) + 1;
    await _box.put(key, {'count': count});
  }

  List<AnalyticsPoint> weeklyTrend() {
    final now = DateTime.now();
    return List.generate(7, (idx) {
      final day = DateTime(now.year, now.month, now.day - (6 - idx));
      final key = _keyForDay(day);
      final count = (_box.get(key, defaultValue: {'count': 0})!['count'] as int?) ?? 0;
      return AnalyticsPoint(day: day, preventedOpens: count);
    });
  }

  int totalPrevented() {
    return _box.values.fold(0, (sum, item) => sum + (item['count'] as int? ?? 0));
  }

  String _keyForDay(DateTime date) => '${date.year}-${date.month}-${date.day}';
}
