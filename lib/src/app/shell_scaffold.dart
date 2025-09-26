import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nav_items.dart';

final bottomNavIdsProvider =
    StateNotifierProvider<BottomNavIdsController, List<String>>((ref) {
      return BottomNavIdsController()..load();
    });

class BottomNavIdsController extends StateNotifier<List<String>> {
  BottomNavIdsController() : super(const []);
  static const _prefsKey = 'bottom_nav_ids_v1';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey);
    if (ids == null || ids.length != 4) {
      state = const ['home', 'medications', 'schedules', 'calendar'];
      await prefs.setStringList(_prefsKey, state);
    } else {
      state = ids;
    }
  }
}

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.child});
  final Widget child;

  int _locationToIndex(String location, List<NavItemConfig> items) {
    // Find the first item whose location is a prefix of the current location
    final index = items.indexWhere(
      (e) => location == e.location || location.startsWith(e.location + '/'),
    );
    return index == -1 ? 0 : index;
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
