// Dart imports:
import 'dart:io' show Platform;

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Entry point for background notification taps.
@pragma('vm:entry-point')
void dosifiNotificationTapBackground(NotificationResponse response) {
  debugPrint(
    '[NotificationService] BackgroundNotificationResponse: id=${response.id}, actionId=${response.actionId}, payload=${response.payload}',
  );
}

/// Handles one-time plugin initialisation, Android channel creation,
/// runtime permission management, and deep-link response dispatch.
///
/// All members are static so the class has no instance state.
/// [NotificationScheduler] consumes [plugin] and [canScheduleExactAlarms].
class NotificationChannelService {
  // ── Shared plugin & platform channel ─────────────────────────────────────
  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel platform = MethodChannel('dosifi/notifications');

  static void _log(String msg) => debugPrint('[NotificationService] $msg');

  // ── Notification-response dispatch ────────────────────────────────────────
  static void Function(NotificationResponse)? _responseHandler;
  static NotificationResponse? _pendingResponse;

  static void setNotificationResponseHandler(
    void Function(NotificationResponse response) handler,
  ) {
    _responseHandler = handler;
    final pending = _pendingResponse;
    if (pending != null) {
      _pendingResponse = null;
      handler(pending);
    }
  }

  static void _dispatchNotificationResponse(NotificationResponse response) {
    final handler = _responseHandler;
    if (handler == null) {
      _pendingResponse = response;
      return;
    }
    handler(response);
  }

  // ── Android notification channels ─────────────────────────────────────────
  static const AndroidNotificationChannel _upcomingDose =
      AndroidNotificationChannel(
        'upcoming_dose',
        'Dose Reminders',
        description: 'Alerts sent at each scheduled dose time requiring action',
        importance: Importance.high,
      );
  static const AndroidNotificationChannel _lowStock =
      AndroidNotificationChannel(
        'low_stock',
        'Low Stock',
        description: 'Alerts for low medication stock',
      );
  static const AndroidNotificationChannel _expiry = AndroidNotificationChannel(
    'expiry',
    'Expiry',
    description: 'Alerts for medication expiry',
  );
  static const AndroidNotificationChannel _testAlarm =
      AndroidNotificationChannel(
        'test_alarm',
        'Test Alarm (Diagnostics)',
        description: 'Diagnostics channel for short-delay notification tests',
        importance: Importance.max,
      );

  /// Action buttons shown on upcoming-dose notifications.
  static const List<AndroidNotificationAction> upcomingDoseActions = [
    AndroidNotificationAction(
      'log',
      'Log',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'snooze',
      'Snooze',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'skip',
      'Skip',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // ── Timezone initialisation ───────────────────────────────────────────────
  // Kept here so init() can call it synchronously before channel creation.
  static Future<void>? _tzInitFuture;

  static Future<void> ensureTimeZoneReady() {
    return _tzInitFuture ??= () async {
      _log('Ensuring TimeZones are initialized...');
      try {
        tz.initializeTimeZones();

        String localTz;
        try {
          localTz = await FlutterTimezone.getLocalTimezone().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              _log('Timeout getting local timezone (ensure)');
              return 'UTC';
            },
          );
          _log('Resolved local timezone (ensure): $localTz');
        } catch (e) {
          localTz = 'UTC';
          _log('Failed to resolve timezone (ensure), defaulting to UTC: $e');
        }

        try {
          tz.setLocalLocation(tz.getLocation(localTz));
        } catch (e) {
          _log('Unknown/invalid timezone "$localTz"; falling back to UTC: $e');
          tz.setLocalLocation(tz.getLocation('UTC'));
        }

        final now = tz.TZDateTime.now(tz.local);
        _log(
          'tz.local ready: ${tz.local.name}, now=$now, offset=${now.timeZoneOffset}',
        );
      } catch (e) {
        _log('Timezone initialization failed; forcing UTC: $e');
        try {
          tz.initializeTimeZones();
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (_) {}
      }
    }();
  }

  // ── Initialisation ────────────────────────────────────────────────────────
  static Future<void> init() async {
    _log('Initializing NotificationService...');
    const androidInit = AndroidInitializationSettings('ic_stat_notification');
    const initSettings = InitializationSettings(android: androidInit);

    _log('Initializing FlutterLocalNotificationsPlugin...');
    try {
      await plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          _log(
            'NotificationResponse: id=${response.id}, actionId=${response.actionId}, payload=${response.payload}',
          );
          _dispatchNotificationResponse(response);
        },
        onDidReceiveBackgroundNotificationResponse:
            dosifiNotificationTapBackground,
      );
    } catch (e) {
      _log('FlutterLocalNotificationsPlugin.initialize failed: $e');
      return;
    }

    try {
      final launchDetails = await plugin.getNotificationAppLaunchDetails();
      final launched = launchDetails?.didNotificationLaunchApp ?? false;
      final response = launchDetails?.notificationResponse;
      if (launched && response != null) {
        _log(
          'App launched from notification: id=${response.id}, actionId=${response.actionId}, payload=${response.payload}',
        );
        _dispatchNotificationResponse(response);
      }
    } catch (e) {
      _log('getNotificationAppLaunchDetails failed: $e');
    }

    await ensureTimeZoneReady();

    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      _log('Creating Android notification channels');
      await android.createNotificationChannel(_upcomingDose);
      await android.createNotificationChannel(_lowStock);
      await android.createNotificationChannel(_expiry);
      await android.createNotificationChannel(_testAlarm);
    } else {
      _log('Android-specific FLN implementation not available');
    }

    _log('NotificationService initialization complete');
  }

  // ── Permission helpers ────────────────────────────────────────────────────
  static Future<bool> ensurePermissionGranted() async {
    final status = await Permission.notification.status;
    _log('Notification permission status before request: $status');
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    _log('Notification permission result: $result');
    return result.isGranted;
  }

  static Future<bool> isPermissionGranted() async {
    try {
      final status = await Permission.notification.status;
      _log('Notification permission status (no prompt): $status');
      return status.isGranted;
    } catch (e) {
      _log('Error checking notification permission status: $e');
      return false;
    }
  }

  static Future<bool> canScheduleExactAlarms() async {
    try {
      final res = await platform.invokeMethod<bool>('canScheduleExactAlarms');
      return res ?? false;
    } catch (e) {
      _log('Error canScheduleExactAlarms: $e');
      return false;
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    try {
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      return false;
    } catch (e) {
      _log('Error areNotificationsEnabled: $e');
      return false;
    }
  }

  // ── Settings launchers ────────────────────────────────────────────────────
  static Future<void> openExactAlarmsSettings() async {
    if (!Platform.isAndroid) return;

    String? pkg;
    try {
      final info = await PackageInfo.fromPlatform();
      pkg = info.packageName;
      _log('Resolved package name: $pkg');
    } catch (e) {
      pkg = null;
      _log('PackageInfo.fromPlatform failed: $e');
    }

    final intents = <AndroidIntent>[
      const AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        flags: <int>[268435456],
      ),
      if (pkg != null)
        AndroidIntent(
          action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
          data: 'package:$pkg',
          flags: <int>[268435456],
        ),
      const AndroidIntent(
        action: 'android.settings.APP_NOTIFICATION_SETTINGS',
        flags: <int>[268435456],
      ),
      if (pkg != null)
        AndroidIntent(
          action: 'android.settings.APP_NOTIFICATION_SETTINGS',
          arguments: {
            'android.provider.extra.APP_PACKAGE': pkg,
            'app_package': pkg,
          },
          flags: <int>[268435456],
        ),
      if (pkg != null)
        AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:$pkg',
          flags: <int>[268435456],
        ),
      const AndroidIntent(
        action: 'android.settings.SETTINGS',
        flags: <int>[268435456],
      ),
    ];

    for (var i = 0; i < intents.length; i++) {
      final intent = intents[i];
      try {
        _log('Launching settings intent #$i: ${intent.action ?? ''} ${intent.data ?? ''}');
        await intent.launch();
        _log('Settings intent #$i launched successfully');
        return;
      } catch (e) {
        _log('Settings intent #$i failed: $e');
        continue;
      }
    }
    _log('All settings intents failed to launch');
  }

  static Future<void> openChannelSettings(String channelId) async {
    if (!Platform.isAndroid) return;
    String? pkg;
    try {
      final info = await PackageInfo.fromPlatform();
      pkg = info.packageName;
      _log('Resolved package name for channel settings: $pkg');
    } catch (e) {
      _log('PackageInfo.fromPlatform failed: $e');
      pkg = null;
    }
    final intents = <AndroidIntent>[
      if (pkg != null)
        AndroidIntent(
          action: 'android.settings.CHANNEL_NOTIFICATION_SETTINGS',
          arguments: {
            'android.provider.extra.APP_PACKAGE': pkg,
            'android.provider.extra.CHANNEL_ID': channelId,
          },
          flags: <int>[268435456],
        ),
      const AndroidIntent(
        action: 'android.settings.APP_NOTIFICATION_SETTINGS',
        flags: <int>[268435456],
      ),
    ];
    for (var i = 0; i < intents.length; i++) {
      try {
        _log('Launching channel settings intent #$i');
        await intents[i].launch();
        return;
      } catch (e) {
        _log('Channel settings intent #$i failed: $e');
      }
    }
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final res = await platform.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return res ?? false;
    } catch (e) {
      _log('Error isIgnoringBatteryOptimizations: $e');
      return false;
    }
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await platform.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      _log('Error requestIgnoreBatteryOptimizations: $e');
    }
  }

  static Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;
    const intent = AndroidIntent(
      action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      flags: <int>[268435456],
    );
    try {
      _log('Launching IGNORE_BATTERY_OPTIMIZATION_SETTINGS');
      await intent.launch();
    } catch (e) {
      _log('Failed to launch battery optimization settings: $e');
    }
  }

  // ── Debug helpers ─────────────────────────────────────────────────────────
  static Future<void> debugDumpStatus() async {
    _log('--- Notification Debug Dump START ---');
    try {
      final canExact = await platform.invokeMethod<bool>(
        'canScheduleExactAlarms',
      );
      _log('canScheduleExactAlarms (platform): ${canExact?.toString() ?? 'null'}');
    } catch (e) {
      _log('Error querying canScheduleExactAlarms: $e');
    }
    try {
      final importance = await platform.invokeMethod<int>(
        'getChannelImportance',
        {'channelId': 'upcoming_dose'},
      );
      _log('Channel "upcoming_dose" importance: ${importance?.toString() ?? 'null'}');
    } catch (e) {
      _log('Error querying channel importance: $e');
    }
    try {
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final enabled = await android.areNotificationsEnabled();
        _log('areNotificationsEnabled: $enabled');
      } else {
        _log('Android-specific plugin not available');
      }
    } catch (e) {
      _log('Error checking areNotificationsEnabled: $e');
    }
    try {
      final pending = await plugin.pendingNotificationRequests();
      _log('pendingNotificationRequests: ${pending.length}');
      for (final p in pending) {
        _log('  pending -> id=${p.id}, title=${p.title ?? ''}, body=${p.body ?? ''}');
      }
    } catch (e) {
      _log('Error fetching pending notifications: $e');
    }
    try {
      final now = tz.TZDateTime.now(tz.local);
      _log('tz.local=${tz.local.name}, now=$now, offset=${now.timeZoneOffset}');
    } catch (e) {
      _log('Error reading timezone data: $e');
    }
    try {
      _log(
        'Platform=${Platform.operatingSystem}, version=${Platform.version}, osVersion=${Platform.operatingSystemVersion}',
      );
    } catch (_) {}
    _log('--- Notification Debug Dump END ---');
  }
}
