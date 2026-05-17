import 'package:control/core/repositories/analytics_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('records prevented opens per day', () async {
    Hive.init('.dart_tool/test_hive');
    final box = await Hive.openBox<Map>('analytics_test');
    final repo = AnalyticsRepository(box);

    final now = DateTime(2026, 1, 1);
    await repo.recordPreventedOpen(now);
    await repo.recordPreventedOpen(now);

    expect(repo.totalPrevented(), 2);

    await box.deleteFromDisk();
  });
}
