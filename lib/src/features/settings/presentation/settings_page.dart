// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Project imports:
import 'package:dosifi_v5/src/app/theme_mode_controller.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/settings/data/test_data_seed_service.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    Future<void> runNotificationTest(Future<void> Function() action) async {
      final ok = await NotificationService.ensurePermissionGranted();
      if (!ok) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission denied')),
        );
        return;
      }
      await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Test notification sent')));
    }

    return Scaffold(
      appBar: const GradientAppBar(title: 'Settings', forceBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(kSpacingM),
        children: [
          Text(
            'UI Customization',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme mode'),
            subtitle: Text(switch (themeMode) {
              ThemeMode.system => 'System',
              ThemeMode.light => 'Light',
              ThemeMode.dark => 'Dark',
            }),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final mode = await showModalBottomSheet<ThemeMode>(
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.phone_android),
                          title: const Text('System'),
                          onTap: () =>
                              Navigator.of(context).pop(ThemeMode.system),
                        ),
                        ListTile(
                          leading: const Icon(Icons.wb_sunny_outlined),
                          title: const Text('Light'),
                          onTap: () =>
                              Navigator.of(context).pop(ThemeMode.light),
                        ),
                        ListTile(
                          leading: const Icon(Icons.nights_stay_outlined),
                          title: const Text('Dark'),
                          onTap: () =>
                              Navigator.of(context).pop(ThemeMode.dark),
                        ),
                      ],
                    ),
                  );
                },
              );
              if (mode != null) {
                await ref.read(themeModeProvider.notifier).setThemeMode(mode);
              }
            },
          ),
          const SizedBox(height: kSpacingL),
          Text(
            'Navigation',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: const Icon(Icons.tab_outlined),
            title: const Text('Bottom navigation tabs'),
            subtitle: const Text('Pick and order 4 tabs to show at the bottom'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.push('/settings/bottom-nav'),
          ),
          const SizedBox(height: kSpacingL),
          Text(
            'UI Components',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: const Icon(Icons.view_carousel_outlined),
            title: const Text('Wide Card Samples'),
            subtitle: const Text('Preview large medication card layouts'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.push('/settings/wide-card-samples'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text('Final Card Decisions'),
            subtitle: const Text('View locked-in card concepts for launch'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.push('/settings/final-card-decisions'),
          ),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Test Data'),
            subtitle: const Text(
              'Add or remove sample medications & schedules',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              if (!context.mounted) return;
              await showModalBottomSheet<void>(
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.add_circle_outline),
                          title: const Text('Add test data'),
                          subtitle: const Text(
                            'Creates 5 medications and 5 schedules',
                          ),
                          onTap: () async {
                            Navigator.of(context).pop();
                            await TestDataSeedService.seed();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Test data added')),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text('Remove test data'),
                          subtitle: const Text('Deletes the seeded items only'),
                          onTap: () async {
                            Navigator.of(context).pop();
                            await TestDataSeedService.clear();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Test data removed'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: kSpacingL),
          Text(
            'Notifications',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Show test dose reminder'),
            subtitle: const Text('Preview the Upcoming Dose notification'),
            trailing: const Icon(Icons.play_arrow_rounded),
            onTap: () => runNotificationTest(NotificationService.showTest),
          ),
          ListTile(
            leading: const Icon(Icons.stacked_bar_chart_outlined),
            title: const Text('Show test grouped reminders'),
            subtitle: const Text('Preview grouped upcoming doses'),
            trailing: const Icon(Icons.play_arrow_rounded),
            onTap: () => runNotificationTest(
              NotificationService.showTestGroupedUpcomingDoseReminders,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Show test low stock'),
            subtitle: const Text('Preview Refill/Restock actions'),
            trailing: const Icon(Icons.play_arrow_rounded),
            onTap: () => runNotificationTest(
              NotificationService.showTestLowStockReminder,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_busy_outlined),
            title: const Text('Show test expiry reminder'),
            subtitle: const Text('Preview an Expiry notification'),
            trailing: const Icon(Icons.play_arrow_rounded),
            onTap: () =>
                runNotificationTest(NotificationService.showTestExpiryReminder),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Debug & Diagnostics'),
            subtitle: const Text('Notification testing and system diagnostics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/debug'),
          ),
        ],
      ),
    );
  }
}
