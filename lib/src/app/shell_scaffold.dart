import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.child});
  final Widget child;

  static const _items = [
    _NavItem(label: 'Home', icon: Icons.home, location: '/'),
    _NavItem(label: 'Medications', icon: Icons.medication, location: '/medications'),
    _NavItem(label: 'Supplies', icon: Icons.inventory_2, location: '/supplies'),
    _NavItem(label: 'Calendar', icon: Icons.calendar_month, location: '/calendar'),
    _NavItem(label: 'Settings', icon: Icons.settings, location: '/settings'),
  ];

  int _locationToIndex(String location) {
    // Find the first item whose location is a prefix of the current location
    final index = _items.indexWhere((e) => location == e.location || location.startsWith(e.location + '/'));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final target = _items[index].location;
          if (target != location) {
            // Use go for tab switches so it replaces the stack
            context.go(target);
          }
        },
        destinations: _items
            .map((e) => NavigationDestination(icon: Icon(e.icon), label: e.label))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.location});
  final String label;
  final IconData icon;
  final String location;
}

