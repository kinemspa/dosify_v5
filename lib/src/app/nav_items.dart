import 'package:flutter/material.dart';

class NavItemConfig {
  const NavItemConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.location,
  });
  final String id; // stable id for prefs
  final String label;
  final IconData icon;
  final String location;
}

// All available app-level destinations
const allNavItems = <NavItemConfig>[
  NavItemConfig(id: 'home', label: 'Home', icon: Icons.home, location: '/'),
  NavItemConfig(
    id: 'medications',
    label: 'Medications',
    icon: Icons.medication,
    location: '/medications',
  ),
  NavItemConfig(
    id: 'supplies',
    label: 'Supplies',
    icon: Icons.inventory_2,
    location: '/supplies',
  ),
  NavItemConfig(
    id: 'schedules',
    label: 'Schedules',
    icon: Icons.alarm,
    location: '/schedules',
  ),
  NavItemConfig(
    id: 'calendar',
    label: 'Calendar',
    icon: Icons.calendar_month,
    location: '/calendar',
  ),
  NavItemConfig(
    id: 'reconstitution',
    label: 'Reconstitution',
    icon: Icons.science,
    location: '/medications/reconstitution',
  ),
  NavItemConfig(
    id: 'analytics',
    label: 'Analytics',
    icon: Icons.insights,
    location: '/analytics',
  ),
  NavItemConfig(
    id: 'settings',
    label: 'Settings',
    icon: Icons.settings,
    location: '/settings',
  ),
];

NavItemConfig? findNavItem(String id) => allNavItems.firstWhere(
  (e) => e.id == id,
  orElse: () => const NavItemConfig(
    id: 'home',
    label: 'Home',
    icon: Icons.home,
    location: '/',
  ),
);
