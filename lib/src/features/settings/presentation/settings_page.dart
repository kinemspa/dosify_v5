import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:skedux/src/app/theme_mode_controller.dart';
import 'package:skedux/src/core/app_restart_service.dart';
import 'package:skedux/src/core/backup/backup_models.dart';
import 'package:skedux/src/core/backup/pending_backup_restore_service.dart';
import 'package:skedux/src/core/backup/backup_zip_codec.dart';
import 'package:skedux/src/core/backup/google_drive_backup_service.dart';
import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/monetization/entitlement_service.dart';
import 'package:skedux/src/core/notifications/entry_timing_settings.dart';
import 'package:skedux/src/core/notifications/expiry_notification_scheduler.dart';
import 'package:skedux/src/core/notifications/expiry_notification_settings.dart';
import 'package:skedux/src/core/notifications/notification_service.dart';
import 'package:skedux/src/core/notifications/notification_action_settings.dart';
import 'package:skedux/src/core/notifications/snooze_settings.dart';
import 'package:skedux/src/core/ui/experimental_ui_settings.dart';
import 'package:skedux/src/core/ui/onboarding_settings.dart';
import 'package:skedux/src/core/utils/developer_options.dart';
import 'package:skedux/src/core/utils/datetime_format_settings.dart';
import 'package:skedux/src/features/settings/data/test_data_seed_service.dart';
import 'package:skedux/src/widgets/app_header.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const _unlockTapTarget = 10;
  static const _restartSnackBarDuration = Duration(days: 1);
  static const _minimumBackupPasswordLength = 8;

  bool _devEnabled = false;
  int _tapCount = 0;
  DateTime? _lastTapAt;

  @override
  void initState() {
    super.initState();
    _loadDevEnabled();
  }

  Future<void> _loadDevEnabled() async {
    final enabled = await DeveloperOptions.isEnabled();
    if (!mounted) return;
    setState(() => _devEnabled = enabled);
  }

  Future<void> _handleLogoTap(BuildContext context) async {
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
    _tapCount = 0;
    showAppSnackBar(
      context,
      nextEnabled ? 'Developer options enabled' : 'Developer options disabled',
    );
  }

  String _formatBackupRecordSummary(Map<String, int> recordCountsByBox) {
    const labels = <String, String>{
      'medications': 'meds',
      'schedules': 'schedules',
      'entry_logs': 'dose logs',
      'entry_status_change_logs': 'status logs',
      'supplies': 'supplies',
      'stock_movements': 'stock moves',
      'inventory_logs': 'inventory logs',
      'saved_reconstitutions': 'saved recons',
    };

    final parts = recordCountsByBox.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${labels[entry.key] ?? entry.key}: ${entry.value}')
        .toList(growable: false);

    return parts.isEmpty ? 'No backed-up records' : parts.join(' · ');
  }

  void _showQueuedRestoreSnackBar(BuildContext context, BackupPreview preview) {
    showAppSnackBar(
      context,
      'Restore queued for ${preview.totalRecordCount} records. Tap Restart to apply it now.',
      duration: _restartSnackBarDuration,
      actionLabel: 'Restart',
      onAction: AppRestartService.restart,
    );
  }

  Future<({bool encrypt, String? password})?> _promptBackupProtectionChoice(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final encrypt = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kSpacingM,
                  kSpacingM,
                  kSpacingM,
                  kSpacingS,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: cardTitleStyle(
                        context,
                      )?.copyWith(fontWeight: kFontWeightBold),
                    ),
                    const SizedBox(height: kSpacingXS),
                    Text(message, style: bodyTextStyle(context)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock_open_outlined),
                title: const Text('Standard portable backup'),
                subtitle: const Text(
                  'No password. Easier to restore, but anyone with the file can open it.',
                ),
                onTap: () => Navigator.of(context).pop(false),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Password-protected backup'),
                subtitle: const Text(
                  'Encrypt the backup before export or upload. Skedux cannot recover a forgotten password.',
                ),
                onTap: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: kSpacingS),
            ],
          ),
        );
      },
    );

    if (encrypt == null) return null;
    if (!encrypt) {
      return (encrypt: false, password: null);
    }

    final password = await _promptBackupPassword(
      context,
      title: 'Set backup password',
      message:
          'Create a password for this backup. You will need the same password to restore it later.',
      confirmPassword: true,
      confirmLabel: 'Confirm password',
      submitLabel: 'Encrypt backup',
    );
    if (password == null) return null;
    return (encrypt: true, password: password);
  }

  Future<String?> _promptBackupPassword(
    BuildContext context, {
    required String title,
    required String message,
    required bool confirmPassword,
    required String submitLabel,
    String confirmLabel = 'Confirm',
  }) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? result;

    await showDialog<void>(
      context: context,
      builder: (context) {
        var obscurePassword = true;
        var obscureConfirm = true;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message, style: bodyTextStyle(context)),
                    const SizedBox(height: kSpacingM),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      autofillHints: confirmPassword
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        errorText: errorText,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (confirmPassword) ...[
                      const SizedBox(height: kSpacingM),
                      TextField(
                        controller: confirmController,
                        obscureText: obscureConfirm,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: confirmLabel,
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => obscureConfirm = !obscureConfirm,
                            ),
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: kSpacingS),
                    Text(
                      'Use at least $_minimumBackupPasswordLength characters. Skedux cannot recover a forgotten backup password.',
                      style: helperTextStyle(context),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final password = passwordController.text.trim();
                    final confirmation = confirmController.text.trim();
                    if (password.length < _minimumBackupPasswordLength) {
                      setState(
                        () => errorText =
                            'Use at least $_minimumBackupPasswordLength characters.',
                      );
                      return;
                    }
                    if (confirmPassword && password != confirmation) {
                      setState(() => errorText = 'Passwords do not match.');
                      return;
                    }

                    result = password;
                    Navigator.of(context).pop();
                  },
                  child: Text(submitLabel),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final entitlement = ref.watch(entitlementServiceProvider);

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
      showAppSnackBar(context, 'Diagnostics notification sent');
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
                Expanded(child: Text('Please wait...')),
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

    Future<({BackupPreview preview, Uint8List restoreBytes})?>
    prepareRestoreFromBytes(Uint8List sourceBytes) async {
      Uint8List restoreBytes;
      try {
        final prepared = await runWithBusyDialog(
          'Reading backup…',
          () => const BackupZipCodec().prepareRestoreZipBytes(sourceBytes),
        );
        if (prepared == null) return null;
        restoreBytes = prepared;
      } on BackupPasswordRequiredException {
        final password = await _promptBackupPassword(
          context,
          title: 'Enter backup password',
          message:
              'This backup is password-protected. Enter the password to decrypt and validate it before restore.',
          confirmPassword: false,
          submitLabel: 'Unlock backup',
        );
        if (password == null) return null;

        final prepared = await runWithBusyDialog(
          'Decrypting backup…',
          () => const BackupZipCodec().prepareRestoreZipBytes(
            sourceBytes,
            password: password,
          ),
        );
        if (prepared == null) return null;
        restoreBytes = prepared;
      }

      final preview = await runWithBusyDialog(
        'Validating backup…',
        () => const BackupZipCodec().validateBackupZip(restoreBytes),
      );
      if (preview == null) return null;

      return (preview: preview, restoreBytes: restoreBytes);
    }

    return Scaffold(
      appBar: const GradientAppBar(title: 'Settings', forceBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(kSpacingM),
        children: [
          if (!entitlement.isPro) ...[
            Text(
              'Purchases & Pro',
              style: cardTitleStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
            ),
            const SizedBox(height: kSpacingS),
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Upgrade to Pro'),
              subtitle: const Text('Manage purchases, restore, and upgrade'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/purchases'),
            ),
            const SizedBox(height: kSpacingL),
          ],
          Text(
            'UI Customization',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: Text(switch (themeMode) {
              ThemeMode.system => 'System default',
              ThemeMode.light => 'Light',
              ThemeMode.dark => 'Dark',
            }),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final mode = await showModalBottomSheet<ThemeMode>(
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.brightness_auto_outlined),
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
              'Experimental features, diagnostics, and preview tools.',
              style: helperTextStyle(context),
            ),
            const SizedBox(height: kSpacingM),
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
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Simulate Pro entitlement'),
              subtitle: Text(
                entitlement.isPro
                    ? 'Pro is ON - tap to revoke'
                    : 'Free tier - tap to grant Pro',
              ),
              trailing: Switch(
                value: entitlement.isPro,
                onChanged: (v) =>
                    ref.read(entitlementServiceProvider.notifier).setPro(v),
              ),
              tileColor: Colors.amber.withValues(alpha: 0.18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                side: const BorderSide(color: Colors.amber, width: 1.5),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Preview Data'),
              subtitle: const Text(
                'Add or remove preview medications and schedules',
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
                            title: const Text('Add preview data'),
                            subtitle: const Text(
                              'Creates 5 medications and 5 schedules',
                            ),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await TestDataSeedService.seed();
                              if (!context.mounted) return;
                              showAppSnackBar(context, 'Preview data added');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline),
                            title: const Text('Remove preview data'),
                            subtitle: const Text(
                              'Deletes the seeded items only',
                            ),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await TestDataSeedService.clear();
                              if (!context.mounted) return;
                              showAppSnackBar(context, 'Preview data removed');
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
              title: const Text('Preview entry reminder'),
              subtitle: const Text(
                'Fires exactly at each scheduled entry time',
              ),
              trailing: const Icon(Icons.play_arrow_rounded),
              onTap: () => runNotificationTest(NotificationService.showTest),
            ),
            ListTile(
              leading: const Icon(Icons.stacked_bar_chart_outlined),
              title: const Text('Preview grouped reminders'),
              subtitle: const Text(
                'When multiple entries are due at the same time they appear as a group',
              ),
              trailing: const Icon(Icons.play_arrow_rounded),
              onTap: () => runNotificationTest(
                NotificationService.showTestGroupedUpcomingEntryReminders,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Preview low stock reminder'),
              subtitle: const Text('Preview Refill/Restock actions'),
              trailing: const Icon(Icons.play_arrow_rounded),
              onTap: () => runNotificationTest(
                NotificationService.showTestLowStockReminder,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event_busy_outlined),
              title: const Text('Preview expiry reminder'),
              subtitle: const Text('Preview an Expiry notification'),
              trailing: const Icon(Icons.play_arrow_rounded),
              onTap: () => runNotificationTest(
                NotificationService.showTestExpiryReminder,
              ),
            ),
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Debug & Diagnostics'),
                subtitle: const Text(
                  'Notification previews and system diagnostics',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/debug'),
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
          ValueListenableBuilder<EntryTimingConfig>(
            valueListenable: EntryTimingSettings.value,
            builder: (context, config, _) {
              final missedSubtitle =
                  '${config.missedGracePercent}% of time until next entry';
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
                    title: const Text('Missed entry grace period'),
                    subtitle: Text(missedSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => editPercentSetting(
                      title: 'Missed entry grace period',
                      description:
                          'How long after the scheduled time a entry stays "Due" before it becomes "Missed" (based on time until the next scheduled entry).',
                      currentValue: config.missedGracePercent,
                      onSave: (v) =>
                          EntryTimingSettings.setMissedGracePercent(v),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_none_outlined),
                    title: const Text('Missed log reminder timing'),
                    subtitle: Text(overdueSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => editPercentSetting(
                      title: 'Missed log reminder timing',
                      description:
                        'Sends a reminder between the scheduled time and the missed threshold to prompt manual logging. This is an organizational reminder only and should not be used as clinical guidance. 0% disables this reminder. Example: 50% sends halfway through the due-to-missed window.',
                      currentValue: config.overdueReminderPercent,
                      onSave: (v) =>
                          EntryTimingSettings.setOverdueReminderPercent(v),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.repeat_outlined),
                    title: const Text('Follow-up reminders'),
                    subtitle: Text(followUpSubtitle),
                    // Clarifies this is a logging prompt, not a clinical alert
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
                        await EntryTimingSettings.setFollowUpReminderCount(
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
              final subtitle = '$pct% of time until next scheduled entry';
              return ListTile(
                leading: const Icon(Icons.snooze_outlined),
                title: const Text('Snooze timing (default)'),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => editPercentSetting(
                  title: 'Snooze timing (default)',
                  description:
                      'Sets default snooze as a percentage of the remaining time until the next scheduled entry. Example: 25% means snooze for one-quarter of the remaining window, and it will never pass the next entry time.',
                  currentValue: pct,
                  onSave: (v) => SnoozeSettings.setDefaultSnoozePercent(v),
                  min: 0,
                  max: 100,
                  step: 5,
                ),
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: NotificationActionSettings.quickLogEnabled,
            builder: (context, quickLog, _) {
              return SwitchListTile(
                secondary: const Icon(Icons.bolt_outlined),
                title: const Text('Quick-log from notification'),
                subtitle: const Text(
                  'Tapping "Log" on a reminder records the entry immediately without opening the app. '
                  'Turn off to open the log sheet instead.',
                ),
                value: quickLog,
                onChanged: NotificationActionSettings.setQuickLogEnabled,
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
          if (GoogleDriveBackupService.isEnabledInThisBuild)
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Back up to Google Drive'),
              subtitle: const Text(
                'Saves a portable backup to Skedux app backup storage in Google Drive. You can optionally password-protect it before upload. New backups are not tied to this device encryption key and will not appear in My Drive files.',
              ),
              trailing: const Icon(Icons.play_arrow_rounded),
              onTap: () async {
                try {
                  final protection = await _promptBackupProtectionChoice(
                    context,
                    title: 'Protect Google Drive backup',
                    message:
                        'Choose whether this Google Drive backup should be standard or password-protected.',
                  );
                  if (protection == null) return;

                  final result = await runWithBusyDialog(
                    'Uploading backup…',
                    () => GoogleDriveBackupService().backupToDrive(
                      password: protection.password,
                    ),
                  );
                  if (!context.mounted || result == null) return;
                  showAppSnackBar(
                    context,
                    '${protection.encrypt ? 'Encrypted' : 'Backup'} saved to Google Drive: ${result.totalRecordsIncluded} records across ${result.hiveBoxesIncluded} boxes. ${_formatBackupRecordSummary(result.recordCountsByBox)}.',
                  );
                } on BackupFormatException catch (e) {
                  if (!context.mounted) return;
                  showAppSnackBar(context, e.message);
                } catch (e) {
                  if (!context.mounted) return;
                  showAppSnackBar(context, 'Google Drive backup failed: $e');
                }
              },
            ),
          if (GoogleDriveBackupService.isEnabledInThisBuild)
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Restore from Google Drive backup'),
              subtitle: const Text(
                'Choose a backup from Skedux app backup storage in Google Drive and queue it for restore. Older backups from before the portable update may still be install-bound.',
              ),
              trailing: const Icon(Icons.warning_amber_rounded),
              onTap: () async {
                try {
                  final backups = await runWithBusyDialog(
                    'Checking Google Drive…',
                    () => GoogleDriveBackupService().listBackups(),
                  );
                  if (!context.mounted || backups == null || backups.isEmpty) {
                    if (context.mounted) {
                      showAppSnackBar(
                        context,
                        'No Skedux Google Drive backups were found.',
                      );
                    }
                    return;
                  }

                  final selectedBackup =
                      await showModalBottomSheet<DriveBackupEntry>(
                        context: context,
                        builder: (sheetContext) {
                          final timestampFormat = intl.DateFormat(
                            'yyyy-MM-dd HH:mm',
                          );
                          return SafeArea(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    kSpacingM,
                                    kSpacingM,
                                    kSpacingM,
                                    kSpacingS,
                                  ),
                                  child: Text(
                                    'Choose a backup',
                                    style: cardTitleStyle(
                                      sheetContext,
                                    )?.copyWith(fontWeight: kFontWeightBold),
                                  ),
                                ),
                                for (final backup in backups)
                                  ListTile(
                                    leading: const Icon(
                                      Icons.cloud_done_outlined,
                                    ),
                                    title: Text(
                                      backup.createdAtUtc == null
                                          ? backup.name
                                          : timestampFormat.format(
                                              backup.createdAtUtc!.toLocal(),
                                            ),
                                    ),
                                    subtitle: Text(
                                      backup.sizeBytes == null
                                          ? backup.name
                                          : '${backup.name} · ${backup.sizeBytes} bytes',
                                    ),
                                    onTap: () =>
                                        Navigator.of(sheetContext).pop(backup),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                  if (!context.mounted || selectedBackup == null) return;

                  final bytes = await runWithBusyDialog(
                    'Downloading backup…',
                    () => GoogleDriveBackupService().downloadBackupZipById(
                      selectedBackup.id,
                    ),
                  );
                  if (!context.mounted || bytes == null) return;

                  final prepared = await prepareRestoreFromBytes(bytes);
                  if (!context.mounted || prepared == null) return;
                  final preview = prepared.preview;

                  if (preview.totalRecordCount == 0) {
                    showAppSnackBar(
                      context,
                      'The selected backup appears empty and was not restored.',
                    );
                    return;
                  }

                  await runWithBusyDialog(
                    'Preparing restore…',
                    () => PendingBackupRestoreService.stageRestore(
                      prepared.restoreBytes,
                    ),
                  );
                  if (!context.mounted) return;
                  _showQueuedRestoreSnackBar(context, preview);
                } on BackupFormatException catch (e) {
                  if (!context.mounted) return;
                  showAppSnackBar(context, e.message);
                } catch (e) {
                  if (!context.mounted) return;
                  showAppSnackBar(context, 'Google Drive restore failed: $e');
                }
              },
            ),
          if (GoogleDriveBackupService.isEnabledInThisBuild)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete Google Drive backups'),
              subtitle: const Text(
                'Review and delete uploaded backups stored in Skedux app backup storage in Google Drive.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                try {
                  final listedBackups = await runWithBusyDialog(
                    'Checking Google Drive…',
                    () => GoogleDriveBackupService().listBackups(),
                  );
                  if (!context.mounted || listedBackups == null) return;
                  if (listedBackups.isEmpty) {
                    showAppSnackBar(
                      context,
                      'No Skedux Google Drive backups were found.',
                    );
                    return;
                  }

                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (sheetContext) {
                      final timestampFormat = intl.DateFormat(
                        'yyyy-MM-dd HH:mm',
                      );
                      var visibleBackups = List<DriveBackupEntry>.of(
                        listedBackups,
                      );

                      return StatefulBuilder(
                        builder: (sheetContext, setSheetState) {
                          Future<void> deleteBackup(
                            DriveBackupEntry backup,
                          ) async {
                            final confirmed = await showDialog<bool>(
                              context: sheetContext,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Delete backup?'),
                                content: Text(
                                  'Delete ${backup.name} from Skedux app backup storage in Google Drive? This does not affect your current local app data.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;

                            try {
                              await runWithBusyDialog(
                                'Deleting backup…',
                                () => GoogleDriveBackupService().deleteBackupById(
                                  backup.id,
                                ),
                              );
                              if (!context.mounted || !sheetContext.mounted) {
                                return;
                              }

                              setSheetState(() {
                                visibleBackups = visibleBackups
                                    .where((entry) => entry.id != backup.id)
                                    .toList(growable: false);
                              });
                              showAppSnackBar(
                                context,
                                'Deleted Google Drive backup: ${backup.name}',
                              );
                            } on BackupFormatException catch (e) {
                              if (!context.mounted) return;
                              showAppSnackBar(context, e.message);
                            } catch (e) {
                              if (!context.mounted) return;
                              showAppSnackBar(
                                context,
                                'Google Drive backup deletion failed: $e',
                              );
                            }
                          }

                          return SafeArea(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(sheetContext).size.height *
                                    0.75,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      kSpacingM,
                                      kSpacingM,
                                      kSpacingM,
                                      kSpacingS,
                                    ),
                                    child: Text(
                                      'Manage Google Drive backups',
                                      style: cardTitleStyle(
                                        sheetContext,
                                      )?.copyWith(
                                        fontWeight: kFontWeightBold,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: visibleBackups.isEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              kSpacingM,
                                              kSpacingS,
                                              kSpacingM,
                                              kSpacingM,
                                            ),
                                            child: Text(
                                              'No Google Drive backups remain.',
                                              style: helperTextStyle(
                                                sheetContext,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        : ListView(
                                            shrinkWrap: true,
                                            children: [
                                              for (final backup
                                                  in visibleBackups)
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.cloud_done_outlined,
                                                  ),
                                                  title: Text(
                                                    backup.createdAtUtc == null
                                                        ? backup.name
                                                        : timestampFormat
                                                              .format(
                                                                backup
                                                                    .createdAtUtc!
                                                                    .toLocal(),
                                                              ),
                                                  ),
                                                  subtitle: Text(
                                                    backup.sizeBytes == null
                                                        ? backup.name
                                                        : '${backup.name} · ${backup.sizeBytes} bytes',
                                                  ),
                                                  trailing: IconButton(
                                                    tooltip: 'Delete backup',
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                    ),
                                                    onPressed: () =>
                                                        deleteBackup(backup),
                                                  ),
                                                ),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(height: kSpacingS),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                } on BackupFormatException catch (e) {
                  if (!context.mounted) return;
                  showAppSnackBar(context, e.message);
                } catch (e) {
                  if (!context.mounted) return;
                  showAppSnackBar(
                    context,
                    'Google Drive backup management failed: $e',
                  );
                }
              },
            ),
          ListTile(
            leading: const Icon(Icons.save_alt_outlined),
            title: const Text('Export Backup'),
            subtitle: const Text(
              'Creates a portable backup you can keep and restore after reinstalling Skedux. You can optionally password-protect it. New exports are not tied to this device encryption key.',
            ),
            trailing: const Icon(Icons.play_arrow_rounded),
            onTap: () async {
              try {
                final protection = await _promptBackupProtectionChoice(
                  context,
                  title: 'Protect exported backup',
                  message:
                      'Choose whether this exported backup should be standard or password-protected.',
                );
                if (protection == null) return;

                final created = await runWithBusyDialog(
                  'Creating backup…',
                  () => const BackupZipCodec().createBackupZip(
                    password: protection.password,
                  ),
                );
                if (!context.mounted || created == null) return;

                final ts = created.result.createdAtUtc
                    .toIso8601String()
                    .replaceAll(':', '-')
                    .replaceAll('.', '-');
                final extension = created.isEncrypted ? 'skbackup' : 'zip';
                final fileName = 'skedux_backup_$ts.$extension';
                final tmpDir = await getTemporaryDirectory();
                final tmpFile = File('${tmpDir.path}/$fileName');
                await tmpFile.writeAsBytes(created.zipBytes);

                await Share.shareXFiles([
                  XFile(
                    tmpFile.path,
                    mimeType: created.isEncrypted
                        ? 'application/octet-stream'
                        : 'application/zip',
                  ),
                ], subject: 'Skedux Backup');
                if (!context.mounted) return;
                showAppSnackBar(
                  context,
                  '${created.isEncrypted ? 'Encrypted backup' : 'Backup'} exported: ${created.result.totalRecordsIncluded} records across ${created.result.hiveBoxesIncluded} boxes. ${_formatBackupRecordSummary(created.result.recordCountsByBox)}.',
                );
              } on BackupFormatException catch (e) {
                if (!context.mounted) return;
                showAppSnackBar(context, e.message);
              } catch (e) {
                if (!context.mounted) return;
                showAppSnackBar(context, 'Export failed: $e');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Restore Backup'),
            subtitle: const Text(
              'Use this for a backup file you already saved locally or received via share/import. Password-protected backups are supported. Google Drive backups should use the dedicated restore option above.',
            ),
            trailing: const Icon(Icons.warning_amber_rounded),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Restore from file?'),
                  content: const Text(
                    'This will overwrite your local app data with the selected backup. '
                    'The restore will be queued and applied the next time you reopen the app. '
                    'New portable backups are not tied to this install encryption key. Older backups created before the portable backup update may still be install-bound.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Choose file'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              try {
                final pick = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: const ['zip', 'skbackup'],
                  withData: true,
                );
                if (pick == null || pick.files.isEmpty) return;

                final bytes = pick.files.first.bytes;
                if (bytes == null) {
                  if (context.mounted) {
                    showAppSnackBar(
                      context,
                      'Could not read the selected file. Try again.',
                    );
                  }
                  return;
                }

                final prepared = await prepareRestoreFromBytes(bytes);
                if (!context.mounted || prepared == null) return;
                final preview = prepared.preview;

                if (preview.totalRecordCount == 0) {
                  showAppSnackBar(
                    context,
                    'The selected backup appears empty and was not restored.',
                  );
                  return;
                }

                await runWithBusyDialog(
                  'Preparing restore…',
                  () => PendingBackupRestoreService.stageRestore(
                    prepared.restoreBytes,
                  ),
                );
                if (!context.mounted) return;
                _showQueuedRestoreSnackBar(context, preview);
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
            'About',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleLogoTap(context),
              child: Image.asset(
                kPrimaryLogoAssetPath,
                height: kSettingsAboutTileLogoSize,
                width: kSettingsAboutTileLogoSize,
                filterQuality: FilterQuality.high,
              ),
            ),
            title: const Text('About & Legal'),
            subtitle: Text(
              _devEnabled
                  ? 'Developer options enabled - tap logo to toggle'
                  : 'Tap logo 10x to unlock developer options',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await context.push('/settings/about');
              // Reload dev flag - user may have toggled it on the About /
              // Licenses screen while away.
              await _loadDevEnabled();
            },
          ),
          if (entitlement.isPro) ...[
            const SizedBox(height: kSpacingL),
            Text(
              'Purchases & Pro',
              style: cardTitleStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
            ),
            const SizedBox(height: kSpacingS),
            ListTile(
              leading: Icon(Icons.workspace_premium, color: cs.primary),
              title: const Text('Pro - Unlocked'),
              subtitle: const Text('Unlimited medications and no ads'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/purchases'),
            ),
          ],
        ],
      ),
    );
  }
}
