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
    this.titleMaxLines = 1,
    this.compactTitle = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool forceBackButton;
  final int titleMaxLines;
  final bool compactTitle;

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
            case 'inventory':
              context.go('/inventory');
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
          PopupMenuItem(value: 'inventory', child: Text('Inventory')),
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
          : Padding(
              padding: const EdgeInsets.only(left: kSpacingS),
              child: Image.asset(
                kWhiteLogoAssetPath,
                height: kAppBarLogoHeight,
                width: kAppBarLogoWidth,
                filterQuality: FilterQuality.high,
              ),
            ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: titleMaxLines,
              softWrap: titleMaxLines > 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: kFontWeightSemiBold,
                letterSpacing: 0.5,
                fontSize: compactTitle ? kFontSizeLarge : null,
                height: compactTitle ? kLineHeightTight : null,
              ),
            ),
          ),
        ],
      ),
      actions: effectiveActions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
