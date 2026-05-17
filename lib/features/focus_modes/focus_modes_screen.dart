import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../core/models/focus_mode.dart';
import '../../core/repositories/focus_mode_repository.dart';
import '../../widgets/primary_nav_shell.dart';

class FocusModesScreen extends StatefulWidget {
  const FocusModesScreen({super.key});

  @override
  State<FocusModesScreen> createState() => _FocusModesScreenState();
}

class _FocusModesScreenState extends State<FocusModesScreen> {
  late final FocusModeRepository _repo;
  late final List<FocusMode> _modes;

  @override
  void initState() {
    super.initState();
    _repo = FocusModeRepository(Hive.box<Map>(FocusModeRepository.boxName));
    _modes = _repo.load();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryNavShell(
      selectedIndex: 3,
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _modes.length,
          itemBuilder: (context, index) {
            final mode = _modes[index];
            return Card(
              child: SwitchListTile(
                title: Text(mode.name),
                subtitle: Text(mode.protectedCategories.join(', ')),
                value: mode.active,
                onChanged: (value) async {
                  setState(() {
                    _modes[index] = mode.copyWith(active: value);
                  });
                  await _repo.save(_modes);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
