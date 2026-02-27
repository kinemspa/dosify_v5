import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';

/// Which permission issue is detected.
enum _BannerIssue { noPermission, noExactAlarm }

/// Inline warning banner shown on the home page when the user's device is
/// missing a notification-related permission that would prevent scheduled dose
/// reminders from arriving.
///
/// Two cases are handled:
/// - **Notifications disabled** (`areNotificationsEnabled = false`) — shown on
///   all Android versions when the user has revoked the notification
///   permission or disabled the channel.
/// - **Exact alarms disabled** (`canScheduleExactAlarms = false`) — shown on
///   Android 12+ when "Schedule exact alarms" has not been granted, causing
///   alarms to fire late or not at all.
///
/// The banner auto-hides when permissions are already OK, and re-checks every
/// time the app returns to the foreground (e.g. after the user visits Settings).
/// The user can also dismiss it for the current session via the close button.
class NotificationPermissionBanner extends StatefulWidget {
  const NotificationPermissionBanner({super.key});

  @override
  State<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends State<NotificationPermissionBanner>
    with WidgetsBindingObserver {
  _BannerIssue? _issue;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check each time the user comes back from the OS Settings page so
      // the banner disappears as soon as the permission is granted.
      setState(() => _dismissed = false);
      unawaited(_check());
    }
  }

  Future<void> _check() async {
    // Standard notification permission (Android 13+ POST_NOTIFICATIONS or
    // legacy channel-level toggle).
    final notifOk = await NotificationService.areNotificationsEnabled();
    if (!mounted) return;
    if (!notifOk) {
      setState(() => _issue = _BannerIssue.noPermission);
      return;
    }

    // Exact-alarm scheduling permission (Android 12+ SCHEDULE_EXACT_ALARM).
    final exactOk = await NotificationService.canScheduleExactAlarms();
    if (!mounted) return;
    setState(() => _issue = exactOk ? null : _BannerIssue.noExactAlarm);
  }

  Future<void> _onFixTap() async {
    if (_issue == _BannerIssue.noPermission) {
      await NotificationService.ensurePermissionGranted();
    } else {
      await NotificationService.openExactAlarmsSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _issue == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final isExact = _issue == _BannerIssue.noExactAlarm;

    final message = isExact
        ? 'Scheduled dose reminders need the "Schedule exact alarms" '
            'permission to fire on time.'
        : 'Notification permission is off — dose reminders cannot be '
            'delivered.';
    final actionLabel = isExact ? 'Enable Alarms' : 'Allow Notifications';

    return Container(
      margin: const EdgeInsets.only(bottom: kSpacingM),
      padding: const EdgeInsets.fromLTRB(
        kPageHorizontalPadding,
        kSpacingS,
        kSpacingXS,
        kSpacingS,
      ),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_amber_rounded,
              color: cs.onErrorContainer,
              size: kIconSizeSmall,
            ),
          ),
          const SizedBox(width: kSpacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onErrorContainer,
                  ),
                ),
                const SizedBox(height: kSpacingXS),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onErrorContainer,
                    side: BorderSide(
                      color: cs.onErrorContainer.withValues(
                        alpha: kOpacityMediumHigh,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: kSpacingM,
                      vertical: kSpacingXS,
                    ),
                  ),
                  onPressed: _onFixTap,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            iconSize: kIconSizeSmall,
            color: cs.onErrorContainer.withValues(alpha: kOpacityMediumHigh),
            onPressed: () => setState(() => _dismissed = true),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
