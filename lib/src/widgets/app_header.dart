// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    required this.title, super.key,
    this.actions,
    this.forceBackButton = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool forceBackButton;

  @override
  Widget build(BuildContext context) {
    final showBack = Navigator.of(context).canPop() || forceBackButton;
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
            colors: [Color(0xFF09A8BD), Color(0xFF18537D)],
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
      title: Text(title, style: const TextStyle(color: Colors.white)),
      actions: [
        if (actions != null) ...actions!,
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.white),
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
                // Calculator is nested under medications; push so back returns to current
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
            PopupMenuItem(value: 'reconstitution', child: Text('Reconstitution Calculator')),
            PopupMenuItem(value: 'analytics', child: Text('Analytics')),
            PopupMenuItem(value: 'settings', child: Text('Settings')),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
