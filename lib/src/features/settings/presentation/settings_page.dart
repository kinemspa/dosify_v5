import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/app/theme_mode_controller.dart';
import 'package:dosifi_v5/src/core/backup/backup_models.dart';
import 'package:dosifi_v5/src/core/backup/google_drive_backup_service.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/legal/disclaimer_settings.dart';
import 'package:dosifi_v5/src/core/legal/disclaimer_strings.dart';
import 'package:dosifi_v5/src/core/monetization/billing_service.dart';
import 'package:dosifi_v5/src/core/monetization/entitlement_service.dart';
import 'package:dosifi_v5/src/core/monetization/monetization_metrics_service.dart';
import 'package:dosifi_v5/src/core/notifications/dose_timing_settings.dart';
import 'package:dosifi_v5/src/core/notifications/expiry_notification_scheduler.dart';
import 'package:dosifi_v5/src/core/notifications/expiry_notification_settings.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/core/notifications/snooze_settings.dart';
import 'package:dosifi_v5/src/core/ui/experimental_ui_settings.dart';
import 'package:dosifi_v5/src/core/ui/onboarding_settings.dart';
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
  static const _unlockTapTarget = 5;

  late final Future<PackageInfo> _packageInfo;
  late final GoogleDriveBackupService _backupService;
  bool _devEnabled = false;
  int _tapCount = 0;
  DateTime? _lastTapAt;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
    _backupService = GoogleDriveBackupService();
    _loadDevEnabled();
  }

  Future<void> _loadDevEnabled() async {
    final enabled = await DeveloperOptions.isEnabled();
    if (!mounted) return;
    setState(() => _devEnabled = enabled);
  }

  Future<void> _handleBuildTap(BuildContext context) async {
    final now = DateTime.now();
    final resetWindowMs = 2000;
    if (_lastTapAt == null ||
        now.difference(_lastTapAt!).inMilliseconds > resetWindowMs) {
      _tapCount = 0;
    }
    _lastTapAt = now;
    _tapCount += 1;

    if (_tapCount < _unlockTapTarget) {
      return;
    }

    final nextEnabled = !_devEnabled;
    await DeveloperOptions.setEnabled(nextEnabled);

    // Mirror to prefs directly to avoid any caching surprises.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DeveloperOptions.prefsKey, nextEnabled);

    if (!mounted) return;
    setState(() => _devEnabled = nextEnabled);
    showAppSnackBar(
      context,
      nextEnabled ? 'Developer options enabled' : 'Developer options disabled',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final entitlement = ref.watch(entitlementServiceProvider);
    final billing = ref.watch(billingServiceProvider);

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

    Future<T?> runWithBusyDialog<T>(
      String title,
      Future<T> Function() action,
    ) async {
      // Capture the dialog's own BuildContext so we can dismiss it reliably
      // even if the outer `context` becomes unmounted (e.g. after Google Sign-In
      // platform activity returns and Flutter briefly pauses the widget tree).
      BuildContext? dialogContext;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return AlertDialog(
            title: Text(title),
            content: const Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: kSpacingM),
                Expanded(child: Text('Please wait…')),
              ],
            ),
          );
        },
      );

      void dismiss() {
        final ctx = dialogContext;
        if (ctx != null && ctx.mounted) {
          Navigator.of(ctx).pop();
        } else if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }

      try {
        final result = await action();
        dismiss();
        return result;
      } catch (_) {
        dismiss();
        rethrow;
      }
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
            'Onboarding',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: const Icon(Icons.tips_and_updates_outlined),
            title: const Text('Replay onboarding'),
            subtitle: const Text('Show welcome splash and quick tips again'),
            onTap: () async {
              await OnboardingSettings.replay();
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
                        'Shows quick badges on medication cards (for example: Low stock, Expiring, Fridge/Freezer, and other status indicators).',
                      ),
                      value: config.showMedicationListStatusBadges,
                      onChanged: ExperimentalUiSettings
                          .setShowMedicationListStatusBadges,
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
            // ⚠️ REMOVE BEFORE PRODUCTION — debug-only Pro unlock toggle
            Container(
              margin: const EdgeInsets.symmetric(vertical: kSpacingS),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                border: Border.all(color: Colors.amber, width: kBorderWidthMedium),
                borderRadius: BorderRadius.circular(kBorderRadiusMedium),
              ),
              child: SwitchListTile(
                secondary: Icon(
                  Icons.workspace_premium,
                  color: Colors.amber.shade700,
                ),
                title: Text(
                  '⚠️ DEBUG: Toggle Pro',
                  style: TextStyle(
                    color: Colors.amber.shade800,
                    fontWeight: kFontWeightBold,
                  ),
                ),
                subtitle: Text(
                  entitlement.isPro ? 'Currently: PRO — remove this before production!' : 'Currently: FREE — remove this before production!',
                  style: TextStyle(color: Colors.amber.shade700),
                ),
                value: entitlement.isPro,
                activeColor: Colors.amber.shade700,
                onChanged: (value) async {
                  await ref
                      .read(entitlementServiceProvider.notifier)
                      .setPro(value);
                  if (!context.mounted) return;
                  showAppSnackBar(
                    context,
                    value ? 'DEBUG: Pro enabled' : 'DEBUG: Pro disabled',
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingM,
                vertical: kSpacingS,
              ),
              child: Text(
                'Developer tools can trigger test alerts and data mutations. Use only for testing.',
                style: helperTextStyle(context),
              ),
            ),
          ],
          const SizedBox(height: kSpacingL),
          Text(
            'Purchases & Pro',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(entitlement.isPro ? 'Pro unlocked' : 'Free tier'),
            subtitle: Text(
              entitlement.isPro
                  ? 'Unlimited medications and no ads'
                  : billing.product != null
                  ? 'Up to $kFreeTierMedicationLimit medications + ads • Pro: ${billing.product!.price}'
                  : 'Up to $kFreeTierMedicationLimit medications + ads',
            ),
          ),
          if (!entitlement.isPro)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Pro benefits'),
              subtitle: const Text('Unlimited medications + no ads'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await MonetizationMetricsService.trackPaywallShown();
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Go Pro'),
                      content: Text(
                        'Unlock unlimited medications and remove ads from safe screens. Purchases are linked to your Google Play account and can be restored on reinstall/new device.',
                        style: bodyTextStyle(dialogContext),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Not now'),
                        ),
                        FilledButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            final started = await ref
                                .read(billingServiceProvider.notifier)
                                .buyProLifetime();
                            if (!context.mounted || !started) return;
                            showAppSnackBar(
                              context,
                              'Purchase flow started. Complete checkout in Google Play.',
                            );
                          },
                          child: const Text('Buy Pro'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          if (!entitlement.isPro)
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Buy Pro (lifetime)'),
              subtitle: Text(
                billing.product?.price ?? 'Fetches product from Google Play',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: billing.isLoading
                  ? null
                  : () async {
                      final started = await ref
                          .read(billingServiceProvider.notifier)
                          .buyProLifetime();
                      if (!context.mounted || !started) return;
                      showAppSnackBar(
                        context,
                        'Purchase flow started. Complete checkout in Google Play.',
                      );
                    },
            ),
          ListTile(
            leading: const Icon(Icons.restore_rounded),
            title: const Text('Restore purchases'),
            subtitle: const Text('Refresh Pro entitlement on this device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await ref
                  .read(billingServiceProvider.notifier)
                  .restorePurchases();
              await ref.read(entitlementServiceProvider.notifier).restore();
              if (!context.mounted) return;
              final isProNow = ref.read(entitlementServiceProvider).isPro;
              showAppSnackBar(
                context,
                isProNow
                    ? 'Pro entitlement restored'
                    : 'No Pro entitlement found for this device/account',
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kSpacingM,
              vertical: kSpacingXS,
            ),
            child: Text(
              'Billing FAQ: Pro unlock is tied to your Play account. Use Restore purchases after reinstall or device change.',
              style: helperTextStyle(context),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('Manage purchases'),
            subtitle: const Text('Open Google Play purchases/subscriptions'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              await ref
                  .read(billingServiceProvider.notifier)
                  .openManagePurchases();
            },
          ),
          if (billing.lastError != null && billing.lastError!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingM,
                vertical: kSpacingXS,
              ),
              child: Text(
                billing.lastError!,
                style: helperTextStyle(context, color: cs.error),
              ),
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
            leading: const Icon(Icons.settings_applications_outlined),
            title: const Text('Open OS notification permissions'),
            subtitle: const Text(
              'Check app notification access and exact alarm permissions in system settings',
            ),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              await NotificationService.openExactAlarmsSettings();
              if (!context.mounted) return;
              showAppSnackBar(context, 'Opened system notification settings');
            },
          ),
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
                          'Sends an overdue reminder between the scheduled time and the missed threshold. 0% disables this reminder. Example: 50% sends halfway through the due-to-missed window.',
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
                      'Sets default snooze as a percentage of the remaining time until the next scheduled dose. Example: 25% means snooze for one-quarter of the remaining window, and it will never pass the next dose time.',
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
          const SizedBox(height: kSpacingL),
          Text(
            'Backup & Restore',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Backup to Google Drive'),
            subtitle: const Text('Saves a copy of your app data'),
            trailing: const Icon(Icons.play_arrow_rounded),
            onTap: () async {
              try {
                final result = await runWithBusyDialog(
                  'Backing up…',
                  () => _backupService.backupToDrive().timeout(
                    const Duration(seconds: 45),
                  ),
                );
                if (!context.mounted || result == null) return;
                showAppSnackBar(
                  context,
                  'Backup complete (${result.hiveBoxesIncluded} boxes, ${result.sharedPrefsKeysIncluded} settings)',
                );
              } on TimeoutException {
                if (!context.mounted) return;
                showAppSnackBar(
                  context,
                  'Backup timed out while waiting for Google Drive. Please retry.',
                );
              } on BackupFormatException catch (e) {
                if (!context.mounted) return;
                showAppSnackBar(context, e.message);
              } catch (e) {
                if (!context.mounted) return;
                showAppSnackBar(context, 'Backup failed: $e');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Restore from Google Drive'),
            subtitle: const Text('Overwrites local data with your backup'),
            trailing: const Icon(Icons.warning_amber_rounded),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Restore backup?'),
                    content: const Text(
                      'This will overwrite your local app data with the latest Google Drive backup.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Restore'),
                      ),
                    ],
                  );
                },
              );

              if (confirmed != true) return;

              try {
                final result = await runWithBusyDialog(
                  'Restoring…',
                  () => _backupService.restoreLatestFromDrive().timeout(
                    const Duration(seconds: 45),
                  ),
                );
                if (!context.mounted || result == null) return;

                final missing = result.hiveBoxesMissing.isEmpty
                    ? ''
                    : ' Missing: ${result.hiveBoxesMissing.join(', ')}.';

                showAppSnackBar(
                  context,
                  'Restore complete (${result.hiveBoxesRestored} boxes, ${result.sharedPrefsKeysRestored} settings). Restart app for full refresh.$missing',
                );
              } on TimeoutException {
                if (!context.mounted) return;
                showAppSnackBar(
                  context,
                  'Restore timed out while waiting for Google Drive. Please retry.',
                );
              } on BackupFormatException catch (e) {
                if (!context.mounted) return;
                showAppSnackBar(context, e.message);
              } catch (e) {
                if (!context.mounted) return;
                showAppSnackBar(context, 'Restore failed: $e');
              }
            },
          ),

          const SizedBox(height: kSpacingL),
          Text(
            'Legal',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Disclaimer'),
            subtitle: const Text('View full in-app legal disclaimer'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Disclaimer'),
                content: SingleChildScrollView(
                  child: Text(
                    DisclaimerStrings.full,
                    style: bodyTextStyle(dialogContext),
                  ),
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.replay_outlined),
            title: const Text('Re-show disclaimer'),
            subtitle: const Text(
              'Reset acceptance so the disclaimer appears on next launch',
            ),
            onTap: () async {
              await DisclaimerSettings.reset();
              if (!context.mounted) return;
              showAppSnackBar(
                context,
                'Disclaimer reset — will appear on next app launch',
              );
            },
          ),
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
                  : 'Version information';

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
