import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:package_info_plus/package_info_plus.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  static const MethodChannel _platform = MethodChannel('dosifi/notifications');
  static void _log(String msg) => debugPrint('[NotificationService] ' + msg);

  static const AndroidNotificationChannel _upcomingDose = AndroidNotificationChannel(
    'upcoming_dose', 'Upcoming Dose',
    description: 'Reminders for upcoming doses', importance: Importance.high,
  );
  static const AndroidNotificationChannel _lowStock = AndroidNotificationChannel(
    'low_stock', 'Low Stock',
    description: 'Alerts for low medication stock', importance: Importance.defaultImportance,
  );
  static const AndroidNotificationChannel _expiry = AndroidNotificationChannel(
    'expiry', 'Expiry',
    description: 'Alerts for medication expiry', importance: Importance.defaultImportance,
  );

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _fln.initialize(initSettings);

    // Timezone for scheduled notifications
    tz.initializeTimeZones();
    String localTz;
    try {
      localTz = await FlutterTimezone.getLocalTimezone();
      _log('Resolved local timezone via flutter_timezone: ' + localTz);
    } catch (e) {
      // Fallback to system default if plugin fails
      localTz = 'UTC';
      _log('Failed to resolve timezone via plugin, defaulting to UTC. Error: ' + e.toString());
    }
    tz.setLocalLocation(tz.getLocation(localTz));
    final now = tz.TZDateTime.now(tz.local);
    _log('tz.local set to ' + tz.local.name + ', now=' + now.toString() + ', offset=' + now.timeZoneOffset.toString());

    final android = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      _log('Creating Android notification channels');
      await android.createNotificationChannel(_upcomingDose);
      await android.createNotificationChannel(_lowStock);
      await android.createNotificationChannel(_expiry);
    } else {
      _log('Android-specific FLN implementation not available');
    }

    // Do not request notification permissions here to avoid blocking app startup.
  }

  static Future<bool> ensurePermissionGranted() async {
    final status = await Permission.notification.status;
    _log('Notification permission status before request: ' + status.toString());
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    _log('Notification permission result: ' + result.toString());
    return result.isGranted;
  }

  static Future<void> openExactAlarmsSettings() async {
    if (!Platform.isAndroid) return;

    String? pkg;
    try {
      final info = await PackageInfo.fromPlatform();
      pkg = info.packageName;
      _log('Resolved package name: ' + pkg);
    } catch (e) {
      // If the package_info_plus plugin isn't available (e.g., after hot restart on some devices),
      // fall back to intents that don't require the package name.
      pkg = null;
      _log('PackageInfo.fromPlatform failed: ' + e.toString());
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
        _log('Launching settings intent #' + i.toString() + ': ' + (intent.action ?? '') + ' ' + (intent.data ?? ''));
        await intent.launch();
        _log('Settings intent #' + i.toString() + ' launched successfully');
        return;
      } catch (e) {
        _log('Settings intent #' + i.toString() + ' failed: ' + e.toString());
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
      _log('Resolved package name for channel settings: ' + pkg);
    } catch (e) {
      _log('PackageInfo.fromPlatform failed: ' + e.toString());
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
        _log('Launching channel settings intent #' + i.toString());
        await intents[i].launch();
        return;
      } catch (e) {
        _log('Channel settings intent #' + i.toString() + ' failed: ' + e.toString());
      }
    }
  }

  static Future<void> showTest() async {
    _log('showTest() called');
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'upcoming_dose',
        'Upcoming Dose',
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    await _fln.show(1, 'Dosifi v5', 'Notifications initialized', details);
    _log('showTest() completed');
  }

  static Future<void> scheduleAt(int id, DateTime when, {required String title, required String body, String channelId = 'upcoming_dose'}) async {
    _log('scheduleAt(id=' + id.toString() + ', when=' + when.toIso8601String() + ', title=' + title + ')');
    var tzTime = tz.TZDateTime.from(when, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!tzTime.isAfter(now)) {
      // Ensure in the future to avoid dropped schedules
      tzTime = now.add(const Duration(seconds: 5));
      _log('Adjusted schedule time to future: ' + tzTime.toString());
    }
    _log('Computed tzTime=' + tzTime.toString() + ', now=' + now.toString() + ', offset=' + tzTime.timeZoneOffset.toString());

    final exactDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      _log('Attempting exact zonedSchedule');
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        exactDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('Exact zonedSchedule call returned successfully');
    } catch (e) {
      _log('Exact schedule failed: ' + e.toString() + ' — falling back to inexact');
      // Fallback to inexact scheduling if exact is not permitted
      final fallbackDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          icon: '@mipmap/ic_launcher',
          category: AndroidNotificationCategory.alarm,
        ),
      );
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        fallbackDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('Inexact zonedSchedule call returned successfully');
    }
  }

  static tz.TZDateTime _nextForWeekdayAndMinutes(int weekday, int minutesOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    final hour = minutesOfDay ~/ 60;
    final minute = minutesOfDay % 60;
    // Start from today
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
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
    _log('scheduleWeeklyAt(id=' + id.toString() + ', weekday=' + weekday.toString() + ', minutesOfDay=' + minutesOfDay.toString() + ')');
    final tzTime = _nextForWeekdayAndMinutes(weekday, minutesOfDay);
    _log('Computed next weekly tzTime=' + tzTime.toString() + ', offset=' + tzTime.timeZoneOffset.toString());

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: '@mipmap/ic_launcher',
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
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      _log('Exact weekly zonedSchedule call returned successfully');
    } catch (e) {
      _log('Exact weekly schedule failed: ' + e.toString() + ' — falling back to inexact');
      // Fallback to inexact weekly scheduling
      final fbDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          icon: '@mipmap/ic_launcher',
          category: AndroidNotificationCategory.alarm,
        ),
      );
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        fbDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      _log('Inexact weekly zonedSchedule call returned successfully');
    }
  }

  static Future<void> cancel(int id) async {
    _log('cancel(id=' + id.toString() + ')');
    await _fln.cancel(id);
  }

  static Future<void> debugDumpStatus() async {
    _log('--- Notification Debug Dump START ---');
    try {
      final canExact = await _platform.invokeMethod<bool>('canScheduleExactAlarms');
      _log('canScheduleExactAlarms (platform): ' + (canExact?.toString() ?? 'null'));
    } catch (e) {
      _log('Error querying canScheduleExactAlarms: ' + e.toString());
    }
    try {
      final importance = await _platform.invokeMethod<int>('getChannelImportance', {'channelId': 'upcoming_dose'});
      _log('Channel "upcoming_dose" importance: ' + (importance?.toString() ?? 'null'));
    } catch (e) {
      _log('Error querying channel importance: ' + e.toString());
    }
    try {
      final android = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final enabled = await android.areNotificationsEnabled();
        _log('areNotificationsEnabled: ' + enabled.toString());
      } else {
        _log('Android-specific plugin not available');
      }
    } catch (e) {
      _log('Error checking areNotificationsEnabled: ' + e.toString());
    }
    try {
      final pending = await _fln.pendingNotificationRequests();
      _log('pendingNotificationRequests: ' + pending.length.toString());
      for (final p in pending) {
        _log('  pending -> id=' + p.id.toString() + ', title=' + (p.title ?? '') + ', body=' + (p.body ?? ''));
      }
    } catch (e) {
      _log('Error fetching pending notifications: ' + e.toString());
    }
    try {
      final now = tz.TZDateTime.now(tz.local);
      _log('tz.local=' + tz.local.name + ', now=' + now.toString() + ', offset=' + now.timeZoneOffset.toString());
    } catch (e) {
      _log('Error reading timezone data: ' + e.toString());
    }
    try {
      _log('Platform=' + Platform.operatingSystem + ', version=' + Platform.version + ', osVersion=' + Platform.operatingSystemVersion);
    } catch (_) {}
    _log('--- Notification Debug Dump END ---');
  }
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final res = await _platform.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return res == true;
    } catch (e) {
      _log('Error isIgnoringBatteryOptimizations: ' + e.toString());
      return false;
    }
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _platform.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      _log('Error requestIgnoreBatteryOptimizations: ' + e.toString());
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
      _log('Failed to launch battery optimization settings: ' + e.toString());
    }
  }
  static Future<void> scheduleAtAlarmClock(int id, DateTime when, {required String title, required String body, String channelId = 'upcoming_dose'}) async {
    _log('scheduleAtAlarmClock(id=' + id.toString() + ', when=' + when.toIso8601String() + ', title=' + title + ')');
    var tzTime = tz.TZDateTime.from(when, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!tzTime.isAfter(now)) {
      tzTime = now.add(const Duration(seconds: 5));
      _log('Adjusted (alarm clock) time to future: ' + tzTime.toString());
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      _log('Attempting zonedSchedule with AndroidScheduleMode.alarmClock');
      await _fln.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('AlarmClock zonedSchedule call returned successfully');
    } catch (e) {
      _log('AlarmClock schedule failed: ' + e.toString());
    }
  }
}

