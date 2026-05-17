import 'package:control/core/models/protected_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProtectedApp serializes and deserializes safely', () {
    const app = ProtectedApp(
      packageName: 'com.example',
      appName: 'Example',
      iconHint: 'E',
      isProtected: true,
      category: 'Social',
      delaySeconds: 10,
      dailyUsageMinutes: 12,
    );

    final decoded = ProtectedApp.fromJson(app.toJson());

    expect(decoded.packageName, app.packageName);
    expect(decoded.isProtected, isTrue);
    expect(decoded.delaySeconds, 10);
  });
}
