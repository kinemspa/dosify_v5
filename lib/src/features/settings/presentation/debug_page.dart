// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

/// Debug page for notification testing and diagnostics
class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Debug & Diagnostics',
        forceBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Notification Testing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final ok = await NotificationService.ensurePermissionGranted();
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification permission denied'),
                  ),
                );
                return;
              }
              await NotificationService.showTest();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent')),
                );
              }
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Send test notification'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await NotificationService.cancelAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cancelled all scheduled notifications'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.cancel_schedule_send_outlined),
            label: const Text('Cancel all scheduled notifications'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final ok = await NotificationService.ensurePermissionGranted();
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification permission denied'),
                  ),
                );
                return;
              }

              // Preflight checks to avoid silent drops
              final enabled =
                  await NotificationService.areNotificationsEnabled();
              final canExact =
                  await NotificationService.canScheduleExactAlarms();
              if (!enabled || !canExact) {
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Allow reminders'),
                    content: Text(
                      !enabled
                          ? 'Notifications are disabled for Dosifi. Enable notifications to receive the test reminder.'
                          : 'Android restricts exact alarms. Enable \"Alarms & reminders\" for Dosifi to deliver the test at the exact time.',
                    ),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Later'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          if (!enabled) {
                            await NotificationService.openChannelSettings(
                              'upcoming_dose',
                            );
                          }
                          if (!canExact) {
                            await NotificationService.openExactAlarmsSettings();
                          }
                        },
                        child: const Text('Open settings'),
                      ),
                    ],
                  ),
                );
                return;
              }

              // Use a unique id to avoid overwriting or colliding with pending requests from earlier tests
              final id =
                  DateTime.now().millisecondsSinceEpoch %
                  100000000; // <= 8 digits
              await NotificationService.scheduleInSecondsExact(
                id,
                30,
                title: 'Dosifi test',
                body: 'This should appear in ~30 seconds',
              );
              if (!context.mounted) return;
              final t = TimeOfDay.fromDateTime(
                DateTime.now().add(const Duration(seconds: 30)),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Scheduled test for ${t.format(context)} (~30s, exactAllowWhileIdle)',
                  ),
                ),
              );
              // Dump state to console right after scheduling for diagnostics
              await NotificationService.debugDumpStatus();
            },
            icon: const Icon(Icons.timer_outlined),
            label: const Text('Schedule test in 30s'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              // Ladder: T+5 exact, T+6 alarmClock, T+7 backup banner — all on test_alarm channel
              final base =
                  DateTime.now().millisecondsSinceEpoch %
                  100000000; // <= 8 digits
              await NotificationService.scheduleInSecondsExact(
                base,
                5,
                title: 'Dosifi test (exact)',
                body: 'Exact in ~5s',
                channelId: 'test_alarm',
              );
              await NotificationService.scheduleInSecondsAlarmClock(
                base + 1,
                6,
                title: 'Dosifi test (alarm)',
                body: 'AlarmClock in ~6s',
                channelId: 'test_alarm',
              );
              // Backup banner in case OEM suppresses scheduled delivery
              // ignore: unawaited_futures
              NotificationService.showDelayed(
                7,
                title: 'Dosifi test (backup)',
                body: 'Backup banner after 7s',
                channelId: 'test_alarm',
              );
              if (!context.mounted) return;
              final t5 = TimeOfDay.fromDateTime(
                DateTime.now().add(const Duration(seconds: 5)),
              );
              final t6 = TimeOfDay.fromDateTime(
                DateTime.now().add(const Duration(seconds: 6)),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Scheduled: exact @ ${t5.format(context)}, alarm @ ${t6.format(context)}, backup @ +7s',
                  ),
                ),
              );
              await NotificationService.debugDumpStatus();
            },
            icon: const Icon(Icons.timer_outlined),
            label: const Text('Schedule test in 5s (exact)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              // Ladder: T+5 alarmClock, T+6 exact, T+7 backup banner — all on test_alarm channel
              final base = DateTime.now().millisecondsSinceEpoch % 100000000;
              await NotificationService.scheduleInSecondsAlarmClock(
                base,
                5,
                title: 'Dosifi test (alarm)',
                body: 'AlarmClock in ~5s',
                channelId: 'test_alarm',
              );
              await NotificationService.scheduleInSecondsExact(
                base + 1,
                6,
                title: 'Dosifi test (exact)',
                body: 'Exact in ~6s',
                channelId: 'test_alarm',
              );
              // Backup banner in case OEM suppresses scheduled delivery
              // ignore: unawaited_futures
              NotificationService.showDelayed(
                7,
                title: 'Dosifi test (backup)',
                body: 'Backup banner after 7s',
                channelId: 'test_alarm',
              );
              if (context.mounted) {
                final t5 = TimeOfDay.fromDateTime(
                  DateTime.now().add(const Duration(seconds: 5)),
                );
                final t6 = TimeOfDay.fromDateTime(
                  DateTime.now().add(const Duration(seconds: 6)),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Scheduled: alarm @ ${t5.format(context)}, exact @ ${t6.format(context)}, backup @ +7s',
                    ),
                  ),
                );
              }
              await NotificationService.debugDumpStatus();
            },
            icon: const Icon(Icons.alarm_on),
            label: const Text('Schedule test in 5s (AlarmClock)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              // Direct, no-schedule 5s test on test_alarm channel (diagnostics only)
              // ignore: unawaited_futures
              NotificationService.showDelayed(
                5,
                title: 'Dosifi test (direct)',
                body: 'Direct show after 5s',
                channelId: 'test_alarm',
              );
              if (context.mounted) {
                final t = TimeOfDay.fromDateTime(
                  DateTime.now().add(const Duration(seconds: 5)),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Direct (no schedule) test will show at ${t.format(context)}',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.timer),
            label: const Text('Direct test in 5s (no scheduling)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final id = DateTime.now().millisecondsSinceEpoch % 100000000;
              await NotificationService.scheduleInSecondsAlarmClock(
                id,
                120,
                title: 'Dosifi test (alarm clock)',
                body: '2m via AlarmClock',
                channelId: 'test_alarm',
              );
              if (context.mounted) {
                final t = TimeOfDay.fromDateTime(
                  DateTime.now().add(const Duration(minutes: 2)),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Scheduled 2m AlarmClock test for ${t.format(context)} (test_alarm channel)',
                    ),
                  ),
                );
              }
              // Dump state to console right after scheduling for diagnostics
              await NotificationService.debugDumpStatus();
            },
            icon: const Icon(Icons.schedule_send),
            label: const Text('Schedule test in 2m (AlarmClock)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final id = DateTime.now().millisecondsSinceEpoch % 100000000;
              await NotificationService.scheduleInSecondsExact(
                id,
                120,
                title: 'Dosifi test (exact)',
                body: '2m exact',
                channelId: 'test_alarm',
              );
              if (context.mounted) {
                final t = TimeOfDay.fromDateTime(
                  DateTime.now().add(const Duration(minutes: 2)),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Scheduled 2m exact test for ${t.format(context)} (test_alarm channel)',
                    ),
                  ),
                );
              }
              await NotificationService.debugDumpStatus();
            },
            icon: const Icon(Icons.timer_10),
            label: const Text('Schedule test in 2m (exact)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final id = DateTime.now().millisecondsSinceEpoch % 100000000;
              await NotificationService.scheduleInSecondsAlarmClock(
                id,
                30,
                title: 'Dosifi test (alarm clock)',
                body: '30s via AlarmClock',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Scheduled 30s test via AlarmClock (local, non-tz)',
                    ),
                  ),
                );
              }
              // Dump state to console right after scheduling for diagnostics
              await NotificationService.debugDumpStatus();
            },
            icon: const Icon(Icons.alarm_on),
            label: const Text('Schedule test in 30s (AlarmClock)'),
          ),
          const SizedBox(height: 24),
          const Text(
            'System Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
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
            label: const Text('Open \"Upcoming Dose\" channel settings'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await NotificationService.debugDumpStatus();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dumped notification debug info to console'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.bug_report_outlined),
            label: const Text('Dump notification debug info'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final ignoring =
                  await NotificationService.isIgnoringBatteryOptimizations();
              if (!ignoring) {
                await NotificationService.requestIgnoreBatteryOptimizations();
                // Also open the general settings page as some OEMs/emulators need manual toggle
                await NotificationService.openBatteryOptimizationSettings();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Battery optimizations already ignored'),
                  ),
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
