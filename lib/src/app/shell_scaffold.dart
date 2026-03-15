// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:skedux/src/app/nav_items.dart';
import 'package:skedux/src/core/app_restart_service.dart';
import 'package:skedux/src/core/backup/pending_backup_restore_service.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';
import 'package:skedux/src/widgets/onboarding/onboarding_gate.dart';

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

class ShellScaffold extends ConsumerStatefulWidget {
  const ShellScaffold({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  static const _restartSnackBarDuration = Duration(days: 1);
  bool _restoreNoticeChecked = false;

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

  Future<void> _maybeShowRestoreNotice(BuildContext context) async {
    if (_restoreNoticeChecked) return;
    _restoreNoticeChecked = true;

    final notice = await PendingBackupRestoreService.consumeLastRestoreNotice();
    if (!mounted || notice == null) {
      return;
    }

    showAppSnackBar(
      context,
      notice.message,
      duration: notice.isError
          ? const Duration(seconds: 4)
          : _restartSnackBarDuration,
      actionLabel: notice.isError ? null : 'Restart',
      onAction: notice.isError ? null : AppRestartService.restart,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowRestoreNotice(context);
    });

    final ids = ref.watch(bottomNavIdsProvider);
    final items = ids.map((id) => findNavItem(id)!).toList(growable: false);
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _locationToIndex(location, items);

    // If bottom nav hasn't loaded yet or is misconfigured, render without it to avoid assertion.
    if (items.length < 2) {
      return PopScope(
        canPop: location == '/',
        onPopInvoked: (didPop) {
          if (!didPop && location != '/') context.go('/');
        },
        child: Scaffold(body: OnboardingGate(child: widget.child)),
      );
    }

    return PopScope(
      // Intercept Android back: if we are not at root, go home instead of exiting.
      canPop: location == '/',
      onPopInvoked: (didPop) {
        if (!didPop && location != '/') {
          context.go('/');
        }
      },
      child: Scaffold(
        body: OnboardingGate(child: widget.child),
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
                (e) =>
                    NavigationDestination(icon: Icon(e.icon), label: e.label),
              )
              .toList(),
        ),
      ),
    );
  }
}
