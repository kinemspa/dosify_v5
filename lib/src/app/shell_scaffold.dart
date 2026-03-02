// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/app/nav_items.dart';

final bottomNavIdsProvider =
    StateNotifierProvider<BottomNavIdsController, List<String>>((ref) {
      return BottomNavIdsController()..load();
    });

class BottomNavIdsController extends StateNotifier<List<String>> {
  BottomNavIdsController() : super(const []);
  static const _prefsKey = 'bottom_nav_ids_v1';
  static const _defaultIds = <String>[
    'home',
    'medications',
    'schedules',
    'calendar',
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey);
    final allowedIds = allNavItems.map((e) => e.id).toSet();
    final normalized = <String>[];
    final seen = <String>{};
    if (ids != null) {
      for (final id in ids) {
        if (!allowedIds.contains(id) || !seen.add(id)) continue;
        normalized.add(id);
      }
    }

    if (normalized.length != 4) {
      state = _defaultIds;
      await prefs.setStringList(_prefsKey, state);
    } else {
      state = normalized;
    }
  }
}

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({required this.child, super.key});
  final Widget child;

  int _locationToIndex(String location, List<NavItemConfig> items) {
    // Choose the most specific match (longest location prefix).
    // This prevents routes like '/medications/reconstitution' from matching
    // '/medications' when both tabs are present.
    var bestIndex = -1;
    var bestLength = -1;

    for (var i = 0; i < items.length; i++) {
      final candidate = items[i].location;
      final matches =
          location == candidate || location.startsWith('$candidate/');
      if (!matches) continue;

      if (candidate.length > bestLength) {
        bestLength = candidate.length;
        bestIndex = i;
      }
    }

    return bestIndex == -1 ? 0 : bestIndex;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(bottomNavIdsProvider);
    final items = ids.map((id) => findNavItem(id)!).toList(growable: false);
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _locationToIndex(location, items);

    // If bottom nav hasn't loaded yet or is misconfigured, render without it to avoid assertion.
    if (items.length < 2) {
      return Scaffold(body: child);
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final target = items[index].location;
          if (target != location) {
            context.go(target);
          }
        },
        destinations: items
            .map(
              (e) => NavigationDestination(icon: Icon(e.icon), label: e.label),
            )
            .toList(),
      ),
    );
  }
}
