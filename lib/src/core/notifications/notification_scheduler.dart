// Dart imports:
import 'dart:io' show Platform;

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// Project imports:
import 'package:dosifi_v5/src/core/notifications/notification_channel_service.dart';

/// Handles creating, updating, and cancelling individual dose notifications.
///
/// Depends on [NotificationChannelService] for the shared plugin instance,
/// timezone readiness, and [canScheduleExactAlarms].
class NotificationScheduler {
  static void _log(String msg) => debugPrint('[NotificationService] $msg');

  // ── Timezone gate ─────────────────────────────────────────────────────────
  /// Delegates timezone initialisation to [NotificationChannelService].
  static Future<void> _ensureTimeZoneReady() =>
      NotificationChannelService.ensureTimeZoneReady();

  // ── Stable notification ID ────────────────────────────────────────────────
  static int stableIdForKey(String key) => _stableHash31(key);

  static int _stableHash31(String input) {
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

  // ── Test hooks ────────────────────────────────────────────────────────────
  static Future<void> Function(
    int id,
    DateTime when, {
    required String title,
    required String body,
    String channelId,
  })?
  scheduleAtAlarmClockOverride;

  static Future<void> Function(int id)? cancelOverride;

  // ── Simple scheduling ─────────────────────────────────────────────────────
  /// Schedule using a local [DateTime] (interpreted in device timezone).
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
      tzTime = now.add(const Duration(seconds: 5));
      _log('Adjusted schedule time to future: $tzTime');
    }
    _log('Computed tzTime=$tzTime, now=$now, offset=${tzTime.timeZoneOffset}');

    final exactDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: 'ic_stat_notification',
        color: const Color(0xFF09A8BD),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      _log('Attempting exact zonedSchedule (local source)');
      await NotificationChannelService.plugin.zonedSchedule(
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
      _log('Exact schedule (local source) failed: $e — falling back to inexact');
      final fallbackDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          icon: 'ic_stat_notification',
          color: const Color(0xFF09A8BD),
          category: AndroidNotificationCategory.alarm,
        ),
      );
      await NotificationChannelService.plugin.zonedSchedule(
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

  // ── UTC scheduling ────────────────────────────────────────────────────────
  /// Schedule using a UTC [DateTime]; converts to local tz for the trigger.
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
        color: const Color(0xFF09A8BD),
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
      await NotificationChannelService.plugin.zonedSchedule(
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
          color: const Color(0xFF09A8BD),
          category: AndroidNotificationCategory.alarm,
        ),
      );
      await NotificationChannelService.plugin.zonedSchedule(
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

  // ── AlarmClock scheduling ─────────────────────────────────────────────────
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
    final shouldUseExpandedStyle =
        Platform.isAndroid && channelId == 'upcoming_dose' && !setAsGroupSummary;

    final StyleInformation? styleInformation = shouldUseExpandedStyle
        ? (bigPicture != null
              ? BigPictureStyleInformation(
                  bigPicture,
                  contentTitle: title,
                  summaryText: 'Log  Snooze  Skip',
                  hideExpandedLargeIcon: true,
                )
              : (expandedLines != null && expandedLines.isNotEmpty
                    ? InboxStyleInformation(
                        expandedLines,
                        contentTitle: title,
                        summaryText: 'Log  Snooze  Skip',
                      )
                    : BigTextStyleInformation(
                        body,
                        contentTitle: title,
                        summaryText: 'Log  Snooze  Skip',
                      )))
        : null;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: 'ic_stat_notification',
        largeIcon: null,
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
      final canExact =
          Platform.isAndroid &&
          await NotificationChannelService.canScheduleExactAlarms();
      final primaryMode = canExact
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexact;

      _log('Attempting zonedSchedule with $primaryMode (local source)');
      await NotificationChannelService.plugin.zonedSchedule(
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
          await NotificationChannelService.plugin.zonedSchedule(
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

  /// AlarmClock scheduling using a UTC [DateTime].
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
        color: const Color(0xFF09A8BD),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      final canExact =
          Platform.isAndroid &&
          await NotificationChannelService.canScheduleExactAlarms();
      final primaryMode = canExact
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexact;

      _log('Attempting zonedSchedule with $primaryMode (UTC source)');
      await NotificationChannelService.plugin.zonedSchedule(
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
          await NotificationChannelService.plugin.zonedSchedule(
            id,
            title,
            body,
            tzTime,
            details,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          _log('Inexact fallback zonedSchedule returned successfully (UTC source)');
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

  // ── Relative-time helpers ─────────────────────────────────────────────────
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
        color: const Color(0xFF09A8BD),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      await NotificationChannelService.plugin.zonedSchedule(
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
        color: const Color(0xFF09A8BD),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      await NotificationChannelService.plugin.zonedSchedule(
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

  // ── Weekly recurring scheduling ───────────────────────────────────────────
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
        color: const Color(0xFF09A8BD),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    try {
      _log('Attempting exact weekly zonedSchedule');
      await NotificationChannelService.plugin.zonedSchedule(
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
      final fbDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          icon: 'ic_stat_notification',
          color: const Color(0xFF09A8BD),
          category: AndroidNotificationCategory.alarm,
        ),
      );
      await NotificationChannelService.plugin.zonedSchedule(
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

  static tz.TZDateTime _nextForWeekdayAndMinutes(
    int weekday,
    int minutesOfDay,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    final hour = minutesOfDay ~/ 60;
    final minute = minutesOfDay % 60;
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    final daysUntil = (weekday - scheduled.weekday) % 7;
    scheduled = scheduled.add(Duration(days: daysUntil));
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }

  // ── Cancellation ──────────────────────────────────────────────────────────
  static Future<void> cancel(int id) async {
    if (cancelOverride != null) {
      await cancelOverride!(id);
      return;
    }
    _log('cancel(id=$id)');
    await NotificationChannelService.plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    _log('cancelAll()');
    await NotificationChannelService.plugin.cancelAll();
  }

  // ── Immediate show helpers ─────────────────────────────────────────────────
  static Future<void> showTest() async {
    _log('showTest() called');

    const title = 'Test Medication';
    const body = '5 mg | 8:00 AM';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'upcoming_dose',
        'Upcoming Dose',
        icon: 'ic_stat_notification',
        color: Color(0xFF09A8BD),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
        actions: NotificationChannelService.upcomingDoseActions,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Log  Snooze  Skip',
        ),
      ),
    );

    await NotificationChannelService.plugin.show(
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
        color: Color(0xFF09A8BD),
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    await NotificationChannelService.plugin.show(
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
        color: Color(0xFF09A8BD),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
        groupKey: groupKey,
        actions: NotificationChannelService.upcomingDoseActions,
      ),
    );

    const summaryDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'upcoming_dose',
        'Upcoming Dose',
        icon: 'ic_stat_notification',
        color: Color(0xFF09A8BD),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
        groupKey: groupKey,
        setAsGroupSummary: true,
      ),
    );

    await NotificationChannelService.plugin.show(
      item1,
      'Medication A',
      '5 mg | 8:00 AM',
      itemDetails,
      payload: 'dose:test_group_a:${DateTime.now().millisecondsSinceEpoch}',
    );
    await NotificationChannelService.plugin.show(
      item2,
      'Medication B',
      '10 mg | 8:00 PM',
      itemDetails,
      payload: 'dose:test_group_b:${DateTime.now().millisecondsSinceEpoch}',
    );
    await NotificationChannelService.plugin.show(
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
    final id = DateTime.now().millisecondsSinceEpoch % 100000000;
    _log('showDelayed in ${seconds}s, id=$id');
    await Future<void>.delayed(Duration(seconds: seconds));
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        icon: 'ic_stat_notification',
        color: const Color(0xFF09A8BD),
        category: AndroidNotificationCategory.alarm,
        // ignore: deprecated_member_use
        priority: Priority.high,
      ),
    );
    await NotificationChannelService.plugin.show(id, title, body, details);
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
        color: const Color(0xFF09A8BD),
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
    await NotificationChannelService.plugin.show(id, title, body, details, payload: payload);
  }
}
