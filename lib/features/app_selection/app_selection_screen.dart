import 'dart:convert';
import 'dart:typed_data';

import 'package:control/core/providers.dart';
import 'package:control/data/models/distracting_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSelectionScreen extends ConsumerStatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  ConsumerState<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends ConsumerState<AppSelectionScreen> {
  late final TextEditingController _searchController;

  void _onSearchTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(appSelectionControllerProvider).search,
    );
    _searchController.addListener(_onSearchTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(appSelectionControllerProvider.notifier).ensureFreshData();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appSelectionControllerProvider);
    final controller = ref.read(appSelectionControllerProvider.notifier);
    final bottomPadding = 20 + MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      onRefresh: () => controller.refresh(background: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchHeaderDelegate(
              minExtentValue: 76,
              maxExtentValue: 76,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: controller.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search Instagram, YouTube, Reddit...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              controller.onSearchChanged('');
                            },
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Clear search',
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    filled: true,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
            ),
          ),
          if (state.loading && state.apps.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (state.filtered.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No apps found. Pull to refresh if needed.'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, bottomPadding),
              sliver: SliverList.builder(
                itemCount: state.filtered.length,
                itemBuilder: (context, index) {
                  final app = state.filtered[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _AppTile(app: app),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SearchHeaderDelegate({
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.child,
  });

  final double minExtentValue;
  final double maxExtentValue;
  final Widget child;

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtentValue - minExtentValue)).clamp(0.0, 1.0);
    final elevation = 1.0 + (2.5 * t);
    final top = (4.0 * (1.0 - t));

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? elevation : 0,
      child: Transform.translate(
        offset: Offset(0, top),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return oldDelegate.minExtentValue != minExtentValue ||
        oldDelegate.maxExtentValue != maxExtentValue ||
        oldDelegate.child != child;
  }
}

class _AppTile extends ConsumerWidget {
  const _AppTile({required this.app});

  final DistractingApp app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appSelectionControllerProvider.notifier);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Row(
          children: [
            _AppIcon(iconBase64: app.iconBase64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${app.estimatedUsageMinutes} min today',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Switch(
              value: app.isProtected,
              onChanged: (value) => controller.toggleProtection(app, value),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.iconBase64});

  final String? iconBase64;
  static final Map<String, Uint8List> _iconBytesCache = <String, Uint8List>{};

  @override
  Widget build(BuildContext context) {
    if (iconBase64 == null || iconBase64!.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.apps_rounded));
    }

    try {
      final bytes = _iconBytesCache.putIfAbsent(iconBase64!, () {
        return base64Decode(iconBase64!);
      });
      final image = MemoryImage(bytes);
      return CircleAvatar(backgroundImage: image);
    } catch (_) {
      return const CircleAvatar(child: Icon(Icons.apps_rounded));
    }
  }
}
