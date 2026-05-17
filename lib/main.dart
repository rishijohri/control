import 'package:control/app/app.dart';
import 'package:control/data/local/local_storage_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.initialize();
  runApp(const ProviderScope(child: ControlApp()));
}
