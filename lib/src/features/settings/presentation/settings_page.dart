import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_v5/src/app/theme_mode_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: const GradientAppBar(title: 'Settings', forceBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('UI Customization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme mode'),
            subtitle: Text(switch (themeMode) { ThemeMode.system => 'System', ThemeMode.light => 'Light', ThemeMode.dark => 'Dark' }),
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
                          onTap: () => Navigator.of(context).pop(ThemeMode.system),
                        ),
                        ListTile(
                          leading: const Icon(Icons.wb_sunny_outlined),
                          title: const Text('Light'),
                          onTap: () => Navigator.of(context).pop(ThemeMode.light),
                        ),
                        ListTile(
                          leading: const Icon(Icons.nights_stay_outlined),
                          title: const Text('Dark'),
                          onTap: () => Navigator.of(context).pop(ThemeMode.dark),
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
          ListTile(
            leading: const Icon(Icons.view_comfortable),
            title: const Text('Large Card Styles'),
            subtitle: const Text('Choose how large medication cards look in lists'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.push('/settings/large-card-styles'),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Strength Input Styles'),
            subtitle: const Text('Style variations for amount stepper + unit dropdown'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.push('/settings/strength-input-styles'),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Form Field Styles'),
            subtitle: const Text('10 distinct styles for add/edit medication input fields'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.push('/settings/form-field-styles'),
          ),
          const SizedBox(height: 24),
          const Text('Navigation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.tab_outlined),
            title: const Text('Bottom navigation tabs'),
            subtitle: const Text('Pick and order 4 tabs to show at the bottom'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.push('/settings/bottom-nav'),
          ),
          const SizedBox(height: 24),
          const Text('Diagnostics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              final ok = await NotificationService.ensurePermissionGranted();
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification permission denied')));
                return;
              }
              await NotificationService.showTest();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test notification sent')));
              }
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Send test notification'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final ok = await NotificationService.ensurePermissionGranted();
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification permission denied')));
                return;
              }
              try {
                final when = DateTime.now().add(const Duration(seconds: 30));
                await NotificationService.scheduleAt(999001, when, title: 'Dosifi test', body: 'This should appear in ~30 seconds');
                if (context.mounted) {
                  final t = TimeOfDay.fromDateTime(when);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scheduled test for ${t.format(context)} (~30s)')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exact alarms not permitted. Open Alarms & reminders settings.')),
                  );
                }
              }
            },
            icon: const Icon(Icons.timer_outlined),
            label: const Text('Schedule test in 30s'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await NotificationService.openExactAlarmsSettings();
            },
            icon: const Icon(Icons.alarm_on_outlined),
            label: const Text('Open Alarms & reminders settings'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await NotificationService.openChannelSettings('upcoming_dose');
            },
            icon: const Icon(Icons.settings_applications_outlined),
            label: const Text('Open "Upcoming Dose" channel settings'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await NotificationService.debugDumpStatus();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dumped notification debug info to console')),
                );
              }
            },
            icon: const Icon(Icons.bug_report_outlined),
            label: const Text('Dump notification debug info'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final when = DateTime.now().add(const Duration(seconds: 30));
              await NotificationService.scheduleAtAlarmClock(999003, when, title: 'Dosifi test (alarm clock)', body: '30s via AlarmClock');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scheduled 30s test via AlarmClock')),
                );
              }
            },
            icon: const Icon(Icons.alarm_on),
            label: const Text('Schedule test in 30s (AlarmClock)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final ignoring = await NotificationService.isIgnoringBatteryOptimizations();
              if (!ignoring) {
                await NotificationService.requestIgnoreBatteryOptimizations();
                // Also open the general settings page as some OEMs/emulators need manual toggle
                await NotificationService.openBatteryOptimizationSettings();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Battery optimizations already ignored')),
                );
              }
            },
            icon: const Icon(Icons.battery_alert_outlined),
            label: const Text('Request battery optimization exemption'),
          ),
        ],
      ),
    );
  }
}

