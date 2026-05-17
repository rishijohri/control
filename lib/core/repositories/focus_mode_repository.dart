import 'package:hive/hive.dart';

import '../models/focus_mode.dart';

class FocusModeRepository {
  FocusModeRepository(this._box);

  static const boxName = 'focus_modes';
  final Box<Map> _box;

  List<FocusMode> load() {
    final stored = _box.values.map(FocusMode.fromJson).toList();
    if (stored.isNotEmpty) return stored;
    return const [
      FocusMode(name: 'Work', protectedCategories: ['Social']),
      FocusMode(name: 'Study', protectedCategories: ['Social', 'Video']),
      FocusMode(name: 'Sleep', protectedCategories: ['Social', 'News', 'Video']),
      FocusMode(name: 'Deep Focus', protectedCategories: ['Social', 'Video', 'News']),
    ];
  }

  Future<void> save(List<FocusMode> modes) async {
    await _box.clear();
    for (final mode in modes) {
      await _box.put(mode.name, mode.toJson());
    }
  }
}
