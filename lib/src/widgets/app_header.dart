// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';

/// Simplified, unified app header with clean design
/// - Uses consistent gradient colors with medication detail page
/// - No popup menu (use bottom navigation instead)
/// - Consistent elevation and styling
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    required this.title,
    super.key,
    this.actions,
    this.forceBackButton = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool forceBackButton;

  @override
  Widget build(BuildContext context) {
    final showBack = Navigator.of(context).canPop() || forceBackButton;

    final effectiveActions = <Widget>[
      ...?actions,
      PopupMenuButton<String>(
        tooltip: 'Menu',
        icon: const Icon(Icons.menu),
        onSelected: (value) {
          switch (value) {
            case 'home':
              context.go('/');
            case 'medications':
              context.go('/medications');
            case 'supplies':
              context.go('/supplies');
            case 'schedules':
              context.go('/schedules');
            case 'calendar':
              context.go('/calendar');
            case 'reconstitution':
              context.push('/medications/reconstitution');
            case 'analytics':
              context.go('/analytics');
            case 'settings':
              context.go('/settings');
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'home', child: Text('Home')),
          PopupMenuItem(value: 'medications', child: Text('Medications')),
          PopupMenuItem(value: 'supplies', child: Text('Supplies')),
          PopupMenuItem(value: 'schedules', child: Text('Schedules')),
          PopupMenuItem(value: 'calendar', child: Text('Calendar')),
          PopupMenuItem(
            value: 'reconstitution',
            child: Text('Reconstitution Calculator'),
          ),
          PopupMenuItem(value: 'analytics', child: Text('Analytics')),
          PopupMenuItem(value: 'settings', child: Text('Settings')),
        ],
      ),
    ];

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kMedicationDetailGradientStart, // Use same colors as medication detail
              kMedicationDetailGradientEnd,
            ],
          ),
        ),
      ),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      actions: effectiveActions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
