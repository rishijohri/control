import 'package:flutter/services.dart';

class AppInterceptionService {
  static const _channel = MethodChannel('control/app_interception');

  Future<void> requestPermissions() async {
    await _channel.invokeMethod<void>('openPermissionSettings');
  }

  Future<void> allowLaunch(String packageName) async {
    await _channel.invokeMethod<void>('allowLaunch', {'packageName': packageName});
  }
}
