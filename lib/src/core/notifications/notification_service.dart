// Dart imports:
import 'dart:io' show Platform;
import 'dart:ui' show Color;

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

@pragma('vm:entry-point')
void dosifiNotificationTapBackground(NotificationResponse response) {
  debugPrint(
    '[NotificationService] BackgroundNotificationResponse: id=${response.id}, actionId=${response.actionId}, payload=${response.payload}',
  );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _platform = MethodChannel('dosifi/notifications');
  static void _log(String msg) => debugPrint('[NotificationService] $msg');

  static void Function(NotificationResponse response)? _responseHandler;
  static NotificationResponse? _pendingResponse;

  static Future<void>? _tzInitFuture;

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

  static Future<void> _ensureTimeZoneReady() {
    // tz.local is a late-init field; if any scheduling path runs before init
    // completes (or if init is skipped), using tz.local will throw.
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
        // Last-resort fallback.
        _log('Timezone initialization failed; forcing UTC: $e');
        try {
          tz.initializeTimeZones();
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (_) {
          // If even this fails, let scheduling throw; but this should be extremely rare.
        }
      }
    }();
  }

  static int stableIdForKey(String key) => _stableHash31(key);
  // Test hooks: allow overriding scheduling/cancel behavior for tests. When non-null,
  // the overrides will be called in place of the real plugin methods to avoid
  // platform channel invocations during unit/widget tests.
  static Future<void> Function(
    int id,
    DateTime when, {
    required String title,
    required String body,
    String channelId,
  })?
  scheduleAtAlarmClockOverride;

  static Future<void> Function(int id)? cancelOverride;

  static const AndroidNotificationChannel _upcomingDose =
      AndroidNotificationChannel(
        'upcoming_dose',
        'Upcoming Dose',
        description: 'Reminders for upcoming doses',
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

  static Future<void> init() async {
    _log('Initializing NotificationService...');
    const androidInit = AndroidInitializationSettings('ic_stat_notification');
    const initSettings = InitializationSettings(android: androidInit);

    _log('Initializing FlutterLocalNotificationsPlugin...');
    try {
      await _fln
          .initialize(
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
      // Do not block app startup if the notifications plugin is unavailable.
      return;
    }

    try {
      final launchDetails = await _fln.getNotificationAppLaunchDetails();
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

    await _ensureTimeZoneReady();

    final android = _fln
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

    // Do not request notification permissions here to avoid blocking app startup.
    _log('NotificationService initialization complete');
  }

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
      final res = await _platform.invokeMethod<bool>('canScheduleExactAlarms');
      return res ?? false;
    } catch (e) {
      _log('Error canScheduleExactAlarms: $e');
      return false;
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    try {
      final android = _fln
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

  static Future<void> openExactAlarmsSettings() async {
    if (!Platform.isAndroid) return;

    String? pkg;
    try {
      final info = await PackageInfo.fromPlatform();
      pkg = info.packageName;
      _log('Resolved package name: $pkg');
    } catch (e) {
      // If the package_info_plus plugin isn't available (e.g., after hot restart on some devices),
      // fall back to intents that don't require the package name.
      pkg = null;
      _log('PackageInfo.fromPlatform failed: $e');
    }

    final intents = <AndroidIntent>[
      // Android 12+ exact alarms page
      const AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        flags: <int>[268435456], // FLAG_ACTIVITY_NEW_TASK
      ),
      if (pkg != null)
        AndroidIntent(
          action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
          data: 'package:$pkg',
          flags: <int>[268435456],
        ),

      // App notification settings (generic first, then app-specific if we have the package)
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

      // App details page (requires package)
      if (pkg != null)
        AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:$pkg',
          flags: <int>[268435456],
        ),

      // Generic settings as last resort
      const AndroidIntent(
        action: 'android.settings.SETTINGS',
        flags: <int>[268435456],
      ),
    ];

    for (var i = 0; i < intents.length; i++) {
      final intent = intents[i];
      try {
        _log(
          'Launching settings intent #$i: ${intent.action ?? ''} ${intent.data ?? ''}',
        );
        await intent.launch();
        _log('Settings intent #$i launched successfully');
        return;
      } catch (e) {
        _log('Settings intent #$i failed: $e');
        // Try next fallback
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
      // Fallback to general app notification settings
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

  static Future<void> showTest() async {
    _log('showTest() called');

    const title = 'Test Medication';
    const body = '5 mg | 8:00 AM';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'upcoming_dose',
        'Upcoming Dose',
        icon: 'ic_stat_notification',
        largeIcon: DrawableResourceAndroidBitmap('syringe'),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
        actions: upcomingDoseActions,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Take • Snooze • Skip',
        ),
      ),
    );

    await _fln.show(
      1,
      title,
      body,
      details,
      payload: 'dose:test:${DateTime.now().millisecondsSinceEpoch}',
    );
    _log('showTest() completed');
  }

  static Future<void> showTestExpiryReminder() async {
    final id = stableIdForKey('test|expiry');
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'expiry',
        'Expiry',
        icon: 'ic_stat_notification',
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    await _fln.show(
      id,
      'Expiry reminder',
      'A medication is expiring soon',
      details,
    );
  }

  static Future<void> showTestLowStockReminder() async {
    final id = stableIdForKey('test|low_stock');
    await showLowStockAlert(
      id,
      title: 'Low stock',
      body: 'Medication stock is low',
      payload: 'test|low_stock',
    );
  }

  static Future<void> showTestGroupedUpcomingDoseReminders() async {
    const groupKey = 'test_group|upcoming_dose';

    final item1 = stableIdForKey('test_group|dose_1');
    final item2 = stableIdForKey('test_group|dose_2');
    final summary = stableIdForKey('test_group|dose_summary');

    const itemDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'upcoming_dose',
        'Upcoming Dose',
        icon: 'ic_stat_notification',
        largeIcon: DrawableResourceAndroidBitmap('syringe'),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
        groupKey: groupKey,
        actions: upcomingDoseActions,
      ),
    );

    const summaryDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'upcoming_dose',
        'Upcoming Dose',
        icon: 'ic_stat_notification',
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
        groupKey: groupKey,
        setAsGroupSummary: true,
      ),
    );

    await _fln.show(
      item1,
      'Medication A',
      '5 mg | 8:00 AM',
      itemDetails,
      payload: 'dose:test_group_a:${DateTime.now().millisecondsSinceEpoch}',
    );
    await _fln.show(
      item2,
      'Medication B',
      '10 mg | 8:00 PM',
      itemDetails,
      payload: 'dose:test_group_b:${DateTime.now().millisecondsSinceEpoch}',
    );
    await _fln.show(
      summary,
      '2 dose reminders',
      'Open Dosifi to review',
      summaryDetails,
    );
  }

  static Future<void> showDelayed(
    int seconds, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) async {
    // Best-effort backup banner after a short delay (useful for emulator/OEM diagnostics)
    final id = DateTime.now().millisecondsSinceEpoch % 100000000;
    _log('showDelayed in ${seconds}s, id=$id');
    await Future<void>.delayed(Duration(seconds: seconds));
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: 'ic_stat_notification',
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    await _fln.show(id, title, body, details);
  }

  static Future<void> showLowStockAlert(
    int id, {
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'low_stock',
        'Low Stock',
        icon: 'ic_stat_notification',
        // ignore: deprecated_member_use
        priority: Priority.high,
        actions: const [
          AndroidNotificationAction(
            'refill',
            'Refill',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'restock',
            'Restock',
            showsUserInterface: true,
          ),
        ],
      ),
    );
    await _fln.show(id, title, body, details, payload: payload);
  }

  static const List<AndroidNotificationAction> upcomingDoseActions = [
    AndroidNotificationAction(
      'take',
      'Take',
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

  // Schedule using a local DateTime (interpreted in the device's current timezone)
  static Future<void> scheduleAt(
    int id,
    DateTime when, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) async {
    _log('scheduleAt(id=$id, when=${when.toIso8601String()}, title=$title)');
    var tzTime = tz.TZDateTime.from(when, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!tzTime.isAfter(now)) {
      // Ensure in the future to avoid dropped schedules
      tzTime = now.add(const Duration(seconds: 5));
      _log('Adjusted schedule time to future: $tzTime');
    }
    _log('Computed tzTime=$tzTime, now=$now, offset=${tzTime.timeZoneOffset}');

    final exactDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: 'ic_stat_notification',
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      _log('Attempting exact zonedSchedule (local source)');
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        exactDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('Exact zonedSchedule call returned successfully');
    } catch (e) {
      _log(
        'Exact schedule (local source) failed: $e — falling back to inexact',
      );
      // Fallback to inexact scheduling if exact is not permitted
      final fallbackDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          icon: 'ic_stat_notification',
          category: AndroidNotificationCategory.alarm,
        ),
      );
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        fallbackDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('Inexact zonedSchedule call returned successfully');
    }
  }

  static tz.TZDateTime _nextForWeekdayAndMinutes(
    int weekday,
    int minutesOfDay,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    final hour = minutesOfDay ~/ 60;
    final minute = minutesOfDay % 60;
    // Start from today
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // tz weekday: Monday=1..Sunday=7 same as our mapping
    final daysUntil = (weekday - scheduled.weekday) % 7;
    scheduled = scheduled.add(Duration(days: daysUntil));
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }

  static Future<void> scheduleWeeklyAt({
    required int id,
    required int weekday, // 1=Mon..7=Sun
    required int minutesOfDay, // 0..1439
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) async {
    _log(
      'scheduleWeeklyAt(id=$id, weekday=$weekday, minutesOfDay=$minutesOfDay)',
    );
    final tzTime = _nextForWeekdayAndMinutes(weekday, minutesOfDay);
    _log(
      'Computed next weekly tzTime=$tzTime, offset=${tzTime.timeZoneOffset}',
    );

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: 'ic_stat_notification',
        category: AndroidNotificationCategory.alarm,
        // Try to be as precise as allowed by the platform
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      _log('Attempting exact weekly zonedSchedule');
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      _log('Exact weekly zonedSchedule call returned successfully');
    } catch (e) {
      _log('Exact weekly schedule failed: $e — falling back to inexact');
      // Fallback to inexact weekly scheduling
      final fbDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          icon: 'ic_stat_notification',
          category: AndroidNotificationCategory.alarm,
        ),
      );
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        fbDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      _log('Inexact weekly zonedSchedule call returned successfully');
    }
  }

  static Future<void> cancel(int id) async {
    if (cancelOverride != null) {
      await cancelOverride!(id);
      return;
    }
    _log('cancel(id=$id)');
    await _fln.cancel(id);
  }

  static Future<void> cancelAll() async {
    _log('cancelAll()');
    await _fln.cancelAll();
  }

  static Future<void> debugDumpStatus() async {
    _log('--- Notification Debug Dump START ---');
    try {
      final canExact = await _platform.invokeMethod<bool>(
        'canScheduleExactAlarms',
      );
      _log(
        'canScheduleExactAlarms (platform): ${canExact?.toString() ?? 'null'}',
      );
    } catch (e) {
      _log('Error querying canScheduleExactAlarms: $e');
    }
    try {
      final importance = await _platform.invokeMethod<int>(
        'getChannelImportance',
        {'channelId': 'upcoming_dose'},
      );
      _log(
        'Channel "upcoming_dose" importance: ${importance?.toString() ?? 'null'}',
      );
    } catch (e) {
      _log('Error querying channel importance: $e');
    }
    try {
      final android = _fln
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
      final pending = await _fln.pendingNotificationRequests();
      _log('pendingNotificationRequests: ${pending.length}');
      for (final p in pending) {
        _log(
          '  pending -> id=${p.id}, title=${p.title ?? ''}, body=${p.body ?? ''}',
        );
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

  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final res = await _platform.invokeMethod<bool>(
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
      await _platform.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      _log('Error requestIgnoreBatteryOptimizations: $e');
    }
  }

  static Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;
    // Open the general battery optimization settings as a fallback
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

  // Schedule using a UTC DateTime; converts to local tz for the trigger
  static Future<void> scheduleAtUtc(
    int id,
    DateTime whenUtc, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) async {
    _log(
      'scheduleAtUtc(id=$id, whenUtc=${whenUtc.toIso8601String()}, title=$title)',
    );
    var tzTime = tz.TZDateTime.from(whenUtc.toUtc(), tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!tzTime.isAfter(now)) {
      tzTime = now.add(const Duration(seconds: 5));
      _log('Adjusted scheduleAtUtc time to future: $tzTime');
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: 'ic_stat_notification',
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    _log(
      'Computed tzTime(UTC source)->local=$tzTime, now=$now, offset=${tzTime.timeZoneOffset}',
    );
    try {
      _log('Attempting exact zonedSchedule (UTC source)');
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('Exact zonedSchedule (UTC source) returned successfully');
    } catch (e) {
      _log('Exact schedule (UTC source) failed: $e — falling back to inexact');
      final fb = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          icon: 'ic_stat_notification',
          category: AndroidNotificationCategory.alarm,
        ),
      );
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        fb,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('Inexact zonedSchedule (UTC source) returned successfully');
    }
  }

  static Future<void> scheduleAtAlarmClock(
    int id,
    DateTime when, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
    String? groupKey,
    bool setAsGroupSummary = false,
    String? payload,
    List<AndroidNotificationAction>? actions,
    List<String>? expandedLines,
    AndroidBitmap<Object>? bigPicture,
    int? timeoutAfterMs,
  }) async {
    await _ensureTimeZoneReady();
    if (scheduleAtAlarmClockOverride != null) {
      await scheduleAtAlarmClockOverride!(
        id,
        when,
        title: title,
        body: body,
        channelId: channelId,
      );
      return;
    }
    _log(
      'scheduleAtAlarmClock(id=$id, when=${when.toIso8601String()}, title=$title)',
    );
    var tzTime = tz.TZDateTime.from(when, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!tzTime.isAfter(now)) {
      tzTime = now.add(const Duration(seconds: 5));
      _log('Adjusted (alarm clock) time to future: $tzTime');
    }
    final shouldShowSyringeIcon =
        Platform.isAndroid &&
        channelId == _upcomingDose.id &&
        !setAsGroupSummary;
    final shouldUseExpandedStyle = shouldShowSyringeIcon;

    final StyleInformation? styleInformation = shouldUseExpandedStyle
        ? (bigPicture != null
              ? BigPictureStyleInformation(
                  bigPicture,
                  contentTitle: title,
                  summaryText: 'Take • Snooze • Skip',
                  hideExpandedLargeIcon: true,
                )
              : (expandedLines != null && expandedLines.isNotEmpty
                    ? InboxStyleInformation(
                        expandedLines,
                        contentTitle: title,
                        summaryText: 'Take • Snooze • Skip',
                      )
                    : BigTextStyleInformation(
                        body,
                        contentTitle: title,
                        summaryText: 'Take • Snooze • Skip',
                      )))
        : null;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: 'ic_stat_notification',
        largeIcon: shouldShowSyringeIcon
            ? const DrawableResourceAndroidBitmap('syringe')
            : null,
        color: const Color(0xFF09A8BD),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
        groupKey: groupKey,
        setAsGroupSummary: setAsGroupSummary,
        actions: actions,
        styleInformation: styleInformation,
        timeoutAfter: timeoutAfterMs,
      ),
    );
    try {
      final canExact = Platform.isAndroid && await canScheduleExactAlarms();
      final primaryMode = canExact
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexact;

      _log('Attempting zonedSchedule with $primaryMode (local source)');
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: primaryMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      _log('zonedSchedule call returned successfully (local source)');
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        _log(
          'Exact alarms not permitted; falling back to AndroidScheduleMode.inexact (local source)',
        );
        try {
          await _fln.zonedSchedule(
            id,
            title,
            body,
            tzTime,
            details,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
          );
          _log('Inexact fallback zonedSchedule returned successfully');
          return;
        } catch (fallbackError) {
          _log('Inexact fallback schedule failed: $fallbackError');
        }
      }
      _log('AlarmClock schedule (local source) failed: $e');
    } catch (e) {
      _log('AlarmClock schedule (local source) failed: $e');
    }
  }

  // AlarmClock scheduling using a UTC DateTime; converts to local tz for the trigger
  static Future<void> scheduleAtAlarmClockUtc(
    int id,
    DateTime whenUtc, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) async {
    await _ensureTimeZoneReady();
    _log(
      'scheduleAtAlarmClockUtc(id=$id, whenUtc=${whenUtc.toIso8601String()}, title=$title)',
    );
    var tzTime = tz.TZDateTime.from(whenUtc.toUtc(), tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!tzTime.isAfter(now)) {
      tzTime = now.add(const Duration(seconds: 5));
      _log('Adjusted (alarm clock UTC) time to future: $tzTime');
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: 'ic_stat_notification',
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      final canExact = Platform.isAndroid && await canScheduleExactAlarms();
      final primaryMode = canExact
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexact;

      _log('Attempting zonedSchedule with $primaryMode (UTC source)');
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: primaryMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('zonedSchedule call returned successfully (UTC source)');
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        _log(
          'Exact alarms not permitted; falling back to AndroidScheduleMode.inexact (UTC source)',
        );
        try {
          await _fln.zonedSchedule(
            id,
            title,
            body,
            tzTime,
            details,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          _log(
            'Inexact fallback zonedSchedule returned successfully (UTC source)',
          );
          return;
        } catch (fallbackError) {
          _log('Inexact fallback schedule failed (UTC source): $fallbackError');
        }
      }
      _log('AlarmClock schedule (UTC source) failed: $e');
    } catch (e) {
      _log('AlarmClock schedule (UTC source) failed: $e');
    }
  }

  // Simpler exact scheduling using local DateTime without tz (for emulator/vendor quirks)
  static Future<void> scheduleInSecondsExact(
    int id,
    int seconds, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) async {
    await _ensureTimeZoneReady();
    final nowTz = tz.TZDateTime.now(tz.local);
    final tzWhen = nowTz.add(Duration(seconds: seconds));
    _log(
      'scheduleInSecondsExact(id=$id, tzWhen=$tzWhen, offset=${tzWhen.timeZoneOffset})',
    );
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: 'ic_stat_notification',
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('scheduleInSecondsExact scheduled successfully');
    } catch (e) {
      _log('scheduleInSecondsExact failed: $e');
    }
  }

  static Future<void> scheduleInSecondsAlarmClock(
    int id,
    int seconds, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) async {
    await _ensureTimeZoneReady();
    final nowTz = tz.TZDateTime.now(tz.local);
    final tzWhen = nowTz.add(Duration(seconds: seconds));
    _log(
      'scheduleInSecondsAlarmClock(id=$id, tzWhen=$tzWhen, offset=${tzWhen.timeZoneOffset})',
    );
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: 'ic_stat_notification',
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('scheduleInSecondsAlarmClock scheduled successfully');
    } catch (e) {
      _log('scheduleInSecondsAlarmClock failed: $e');
    }
  }

  static int _stableHash31(String input) {
    // Deterministic, platform-independent hash for stable notification IDs.
    // Keeps values within signed 32-bit positive range.
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = 0x1fffffff & hash + unit;
      hash = 0x1fffffff & hash + (0x0007ffff & hash) << 10;
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & hash + (0x03ffffff & hash) << 3;
    hash ^= hash >> 11;
    hash = 0x1fffffff & hash + (0x00003fff & hash) << 15;
    return hash;
  }
}
