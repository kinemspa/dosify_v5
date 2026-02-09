// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/app/theme_mode_controller.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/notifications/dose_timing_settings.dart';
import 'package:dosifi_v5/src/core/notifications/expiry_notification_scheduler.dart';
import 'package:dosifi_v5/src/core/notifications/expiry_notification_settings.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/core/notifications/snooze_settings.dart';
import 'package:dosifi_v5/src/core/ui/experimental_ui_settings.dart';
import 'package:dosifi_v5/src/core/utils/developer_options.dart';
import 'package:dosifi_v5/src/core/utils/datetime_format_settings.dart';
import 'package:dosifi_v5/src/features/settings/data/test_data_seed_service.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const _unlockTapTarget = 7;

  late final Future<PackageInfo> _packageInfo;
  bool _devEnabled = false;
  int _tapCount = 0;
  DateTime? _lastTapAt;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
    _loadDevEnabled();
  }

  Future<void> _loadDevEnabled() async {
    final enabled = await DeveloperOptions.isEnabled();
    if (!mounted) return;
    setState(() => _devEnabled = enabled);
  }

  Future<void> _handleBuildTap(BuildContext context) async {
    if (_devEnabled) {
      showAppSnackBar(context, 'Developer options already enabled');
      return;
    }

    final now = DateTime.now();
    final resetWindowMs = 2000;
    if (_lastTapAt == null ||
        now.difference(_lastTapAt!).inMilliseconds > resetWindowMs) {
      _tapCount = 0;
    }
    _lastTapAt = now;
    _tapCount += 1;

    final remaining = (_unlockTapTarget - _tapCount).clamp(0, _unlockTapTarget);
    if (remaining > 0) {
      showAppSnackBar(
        context,
        'Tap $remaining more time${remaining == 1 ? '' : 's'} to enable developer options',
      );
      return;
    }

    await DeveloperOptions.setEnabled(true);

    // Mirror to prefs directly to avoid any caching surprises.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DeveloperOptions.prefsKey, true);

    if (!mounted) return;
    setState(() => _devEnabled = true);
    showAppSnackBar(context, 'Developer options enabled');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    Future<void> editPercentSetting({
      required String title,
      required String description,
      required int currentValue,
      required ValueChanged<int> onSave,
      int min = 0,
      int max = 100,
      int step = 5,
    }) async {
      var selected = currentValue.clamp(min, max);

      final nextValue = await showModalBottomSheet<int>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(kSpacingM),
              child: StatefulBuilder(
                builder: (context, setState) {
                  final divisions = ((max - min) / step).round();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: cardTitleStyle(
                          context,
                        )?.copyWith(fontWeight: kFontWeightBold),
                      ),
                      const SizedBox(height: kSpacingS),
                      Text(description),
                      const SizedBox(height: kSpacingM),
                      Text(
                        '$selected%',
                        style: cardTitleStyle(context)?.copyWith(
                          color: cs.primary,
                          fontWeight: kFontWeightBold,
                        ),
                      ),
                      Slider(
                        value: selected.toDouble(),
                        min: min.toDouble(),
                        max: max.toDouble(),
                        divisions: divisions,
                        label: '$selected%',
                        onChanged: (v) {
                          setState(() {
                            final snapped = (v / step).round() * step;
                            selected = snapped.clamp(min, max);
                          });
                        },
                      ),
                      const SizedBox(height: kSpacingS),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: kSpacingS),
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(selected),
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );

      if (nextValue == null) return;
      onSave(nextValue);
    }

    Future<void> runNotificationTest(Future<void> Function() action) async {
      final ok = await NotificationService.ensurePermissionGranted();
      if (!ok) {
        if (!context.mounted) return;
        showAppSnackBar(context, 'Notification permission denied');
        return;
      }
      await action();
      if (!context.mounted) return;
      showAppSnackBar(context, 'Test notification sent');
    }

    Future<void> showAbout() async {
      final info = await _packageInfo;
      if (!context.mounted) return;

      final versionText = info.buildNumber.trim().isEmpty
          ? info.version
          : '${info.version} (${info.buildNumber})';

      showAboutDialog(
        context: context,
        applicationName: info.appName,
        applicationVersion: versionText,
        applicationIcon: Image.asset(
          kPrimaryLogoAssetPath,
          height: kAboutDialogLogoSize,
          width: kAboutDialogLogoSize,
          filterQuality: FilterQuality.high,
        ),
      );
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
          const SizedBox(height: kSpacingS),
          ValueListenableBuilder<DateTimeFormatConfig>(
            valueListenable: DateTimeFormatSettings.value,
            builder: (context, config, _) {
              String timeFormatLabel;
              switch (config.timeFormat) {
                case TimeFormat.system:
                  timeFormatLabel = 'System default';
                  break;
                case TimeFormat.hour12:
                  timeFormatLabel = '12-hour (3:45 PM)';
                  break;
                case TimeFormat.hour24:
                  timeFormatLabel = '24-hour (15:45)';
                  break;
              }

              String dateFormatLabel;
              switch (config.dateFormat) {
                case DateFormat.system:
                  dateFormatLabel = 'System default';
                  break;
                case DateFormat.mdy:
                  dateFormatLabel = 'MM/DD/YYYY';
                  break;
                case DateFormat.dmy:
                  dateFormatLabel = 'DD/MM/YYYY';
                  break;
                case DateFormat.ymd:
                  dateFormatLabel = 'YYYY-MM-DD';
                  break;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.access_time_outlined),
                    title: const Text('Time format'),
                    subtitle: Text(timeFormatLabel),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      final format = await showModalBottomSheet<TimeFormat>(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.phone_android),
                                  title: const Text('System default'),
                                  subtitle: const Text(
                                    'Use device time format',
                                  ),
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pop(TimeFormat.system),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.schedule),
                                  title: const Text('12-hour'),
                                  subtitle: const Text('3:45 PM'),
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pop(TimeFormat.hour12),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.access_time),
                                  title: const Text('24-hour'),
                                  subtitle: const Text('15:45'),
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pop(TimeFormat.hour24),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                      if (format != null) {
                        await DateTimeFormatSettings.setTimeFormat(format);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Date format'),
                    subtitle: Text(dateFormatLabel),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      final format = await showModalBottomSheet<DateFormat>(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.phone_android),
                                  title: const Text('System default'),
                                  subtitle: const Text(
                                    'Use device date format',
                                  ),
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pop(DateFormat.system),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.today),
                                  title: const Text('MM/DD/YYYY'),
                                  subtitle: const Text('12/31/2024'),
                                  onTap: () =>
                                      Navigator.of(context).pop(DateFormat.mdy),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.today),
                                  title: const Text('DD/MM/YYYY'),
                                  subtitle: const Text('31/12/2024'),
                                  onTap: () =>
                                      Navigator.of(context).pop(DateFormat.dmy),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.today),
                                  title: const Text('YYYY-MM-DD'),
                                  subtitle: const Text('2024-12-31'),
                                  onTap: () =>
                                      Navigator.of(context).pop(DateFormat.ymd),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                      if (format != null) {
                        await DateTimeFormatSettings.setDateFormat(format);
                      }
                    },
                  ),
                ],
              );
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
          ValueListenableBuilder<ExperimentalUiConfig>(
            valueListenable: ExperimentalUiSettings.value,
            builder: (context, config, _) {
              if (!config.showWideCardSamplesEntry) {
                return const SizedBox.shrink();
              }
              return ListTile(
                leading: const Icon(Icons.view_carousel_outlined),
                title: const Text('Wide Card Samples'),
                subtitle: const Text('Preview large medication card layouts'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.push('/settings/wide-card-samples'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text('Final Card Decisions'),
            subtitle: const Text('View locked-in card concepts for launch'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.push('/settings/final-card-decisions'),
          ),
          const SizedBox(height: kSpacingL),
          if (_devEnabled) ...[
            const SizedBox(height: kSpacingL),
            Text(
              'Developer options',
              style: cardTitleStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
            ),
            const SizedBox(height: kSpacingS),
            Text(
              'Experimental features, diagnostics, and test tools.',
              style: helperTextStyle(context),
            ),
            const SizedBox(height: kSpacingS),
            Text(
              'Experimental',
              style: cardTitleStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
            ),
            const SizedBox(height: kSpacingS),
            ValueListenableBuilder<ExperimentalUiConfig>(
              valueListenable: ExperimentalUiSettings.value,
              builder: (context, config, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.sell_outlined),
                      title: const Text('Medication list status badges'),
                      subtitle: const Text(
                        'Show compact badges like Low stock, Expiring, Fridge, etc.',
                      ),
                      value: config.showMedicationListStatusBadges,
                      onChanged: ExperimentalUiSettings
                          .setShowMedicationListStatusBadges,
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.view_carousel_outlined),
                      title: const Text('Wide Card Samples entry'),
                      subtitle: const Text(
                        'Show the exploratory card mockups page in Settings',
                      ),
                      value: config.showWideCardSamplesEntry,
                      onChanged:
                          ExperimentalUiSettings.setShowWideCardSamplesEntry,
                    ),
                  ],
                );
              },
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
                              showAppSnackBar(context, 'Test data added');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline),
                            title: const Text('Remove test data'),
                            subtitle: const Text(
                              'Deletes the seeded items only',
                            ),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await TestDataSeedService.clear();
                              if (!context.mounted) return;
                              showAppSnackBar(context, 'Test data removed');
                            },
                          ),
                          const SizedBox(height: kSpacingS),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
          const SizedBox(height: kSpacingL),
          Text(
            'Notifications',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ValueListenableBuilder<DoseTimingConfig>(
            valueListenable: DoseTimingSettings.value,
            builder: (context, config, _) {
              final missedSubtitle =
                  '${config.missedGracePercent}% of time until next dose';
              final overdueSubtitle = config.overdueReminderPercent <= 0
                  ? 'Disabled'
                  : '${config.overdueReminderPercent}% of grace window';
              final followUpSubtitle = switch (config.followUpReminderCount) {
                0 => 'Off',
                1 => 'Once',
                2 => 'Twice',
                _ => '${config.followUpReminderCount} times',
              };

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Missed dose grace period'),
                    subtitle: Text(missedSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => editPercentSetting(
                      title: 'Missed dose grace period',
                      description:
                          'How long after the scheduled time a dose stays "Due" before it becomes "Missed" (based on time until the next scheduled dose).',
                      currentValue: config.missedGracePercent,
                      onSave: (v) =>
                          DoseTimingSettings.setMissedGracePercent(v),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_none_outlined),
                    title: const Text('Overdue reminder timing'),
                    subtitle: Text(overdueSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => editPercentSetting(
                      title: 'Overdue reminder timing',
                      description:
                          'Optional reminder after the scheduled time but before a dose is marked missed. Set to 0% to disable.',
                      currentValue: config.overdueReminderPercent,
                      onSave: (v) =>
                          DoseTimingSettings.setOverdueReminderPercent(v),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.repeat_outlined),
                    title: const Text('Follow-up reminders'),
                    subtitle: Text(followUpSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final count = await showModalBottomSheet<int>(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.block_outlined),
                                  title: const Text('Off'),
                                  subtitle: const Text(
                                    'No follow-up reminders',
                                  ),
                                  onTap: () => Navigator.of(context).pop(0),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.looks_one_outlined),
                                  title: const Text('Once'),
                                  subtitle: const Text(
                                    'One follow-up reminder',
                                  ),
                                  onTap: () => Navigator.of(context).pop(1),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.looks_two_outlined),
                                  title: const Text('Twice'),
                                  subtitle: const Text(
                                    'Two follow-up reminders',
                                  ),
                                  onTap: () => Navigator.of(context).pop(2),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          );
                        },
                      );
                      if (count != null) {
                        await DoseTimingSettings.setFollowUpReminderCount(
                          count,
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
          ValueListenableBuilder<SnoozeConfig>(
            valueListenable: SnoozeSettings.value,
            builder: (context, config, _) {
              final pct = config.defaultSnoozePercent;
              final subtitle = '$pct% of time until next scheduled dose';
              return ListTile(
                leading: const Icon(Icons.snooze_outlined),
                title: const Text('Snooze timing (default)'),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => editPercentSetting(
                  title: 'Snooze timing (default)',
                  description:
                      'Sets the default snooze time as a percentage of the window until the next scheduled dose. Snooze will always clamp to before the next dose.',
                  currentValue: pct,
                  onSave: (v) => SnoozeSettings.setDefaultSnoozePercent(v),
                  min: 0,
                  max: 100,
                  step: 5,
                ),
              );
            },
          ),

          ValueListenableBuilder<ExpiryNotificationConfig>(
            valueListenable: ExpiryNotificationSettings.value,
            builder: (context, config, _) {
              return ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: const Text('Expiry reminder timing'),
                subtitle: Text('${config.leadDays} days before'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final selected = await showModalBottomSheet<int>(
                    context: context,
                    builder: (context) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.calendar_view_week),
                              title: const Text('7 days before'),
                              onTap: () => Navigator.of(context).pop(7),
                            ),
                            ListTile(
                              leading: const Icon(Icons.calendar_month),
                              title: const Text('14 days before'),
                              onTap: () => Navigator.of(context).pop(14),
                            ),
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('30 days before'),
                              onTap: () => Navigator.of(context).pop(30),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  );

                  if (selected == null) return;
                  await ExpiryNotificationSettings.setLeadDays(selected);

                  // Best-effort: apply immediately.
                  await ExpiryNotificationScheduler.rescheduleAll();
                },
              );
            },
          ),
          if (_devEnabled) ...[
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
              onTap: () => runNotificationTest(
                NotificationService.showTestExpiryReminder,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug & Diagnostics'),
              subtitle: const Text(
                'Notification testing and system diagnostics',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/debug'),
            ),
          ],

          const SizedBox(height: kSpacingL),
          Text(
            'About',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          FutureBuilder<PackageInfo>(
            future: _packageInfo,
            builder: (context, snapshot) {
              final info = snapshot.data;
              final versionText = info == null
                  ? 'Loading…'
                  : info.buildNumber.trim().isEmpty
                  ? info.version
                  : '${info.version} (${info.buildNumber})';

              final subtitle = _devEnabled
                  ? 'Developer options enabled'
                  : 'Tap 7 times to enable developer options';

              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Build'),
                subtitle: Text('$versionText · $subtitle'),
                onTap: () => _handleBuildTap(context),
              );
            },
          ),
          ListTile(
            leading: Image.asset(
              kPrimaryLogoAssetPath,
              height: kSettingsAboutTileLogoSize,
              width: kSettingsAboutTileLogoSize,
              filterQuality: FilterQuality.high,
            ),
            title: const Text('About Dosifi'),
            subtitle: const Text('App version and licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: showAbout,
          ),
        ],
      ),
    );
  }
}
