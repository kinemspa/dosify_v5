// Package imports:
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Project imports:
import 'package:dosifi_v5/src/core/notifications/notification_channel_service.dart';
import 'package:dosifi_v5/src/core/notifications/notification_scheduler.dart';

export 'package:dosifi_v5/src/core/notifications/notification_channel_service.dart'
    show dosifiNotificationTapBackground;

/// Thin public facade over [NotificationChannelService] and
/// [NotificationScheduler]. All existing call sites (main.dart,
/// ScheduleScheduler, etc.) continue to use `NotificationService.*`
/// with no change.
class NotificationService {
  // ── Initialisation ────────────────────────────────────────────────────────
  static Future<void> init() => NotificationChannelService.init();

  static void setNotificationResponseHandler(
    void Function(NotificationResponse response) handler,
  ) => NotificationChannelService.setNotificationResponseHandler(handler);

  // ── Permission & status ───────────────────────────────────────────────────
  static Future<bool> ensurePermissionGranted() =>
      NotificationChannelService.ensurePermissionGranted();

  static Future<bool> isPermissionGranted() =>
      NotificationChannelService.isPermissionGranted();

  static Future<bool> canScheduleExactAlarms() =>
      NotificationChannelService.canScheduleExactAlarms();

  static Future<bool> areNotificationsEnabled() =>
      NotificationChannelService.areNotificationsEnabled();

  // ── Settings launchers ────────────────────────────────────────────────────
  static Future<void> openExactAlarmsSettings() =>
      NotificationChannelService.openExactAlarmsSettings();

  static Future<void> openChannelSettings(String channelId) =>
      NotificationChannelService.openChannelSettings(channelId);

  static Future<bool> isIgnoringBatteryOptimizations() =>
      NotificationChannelService.isIgnoringBatteryOptimizations();

  static Future<void> requestIgnoreBatteryOptimizations() =>
      NotificationChannelService.requestIgnoreBatteryOptimizations();

  static Future<void> openBatteryOptimizationSettings() =>
      NotificationChannelService.openBatteryOptimizationSettings();

  // ── Debug ─────────────────────────────────────────────────────────────────
  static Future<void> debugDumpStatus() =>
      NotificationChannelService.debugDumpStatus();

  // ── Stable ID ─────────────────────────────────────────────────────────────
  static int stableIdForKey(String key) =>
      NotificationScheduler.stableIdForKey(key);

  // ── Test hooks (preserve existing test API) ───────────────────────────────
  static Future<void> Function(
    int id,
    DateTime when, {
    required String title,
    required String body,
    String channelId,
  })?
  get scheduleAtAlarmClockOverride =>
      NotificationScheduler.scheduleAtAlarmClockOverride;

  static set scheduleAtAlarmClockOverride(
    Future<void> Function(
      int id,
      DateTime when, {
      required String title,
      required String body,
      String channelId,
    })?
    fn,
  ) => NotificationScheduler.scheduleAtAlarmClockOverride = fn;

  static Future<void> Function(int id)? get cancelOverride =>
      NotificationScheduler.cancelOverride;

  static set cancelOverride(Future<void> Function(int id)? fn) =>
      NotificationScheduler.cancelOverride = fn;

  // ── Scheduling ────────────────────────────────────────────────────────────
  static Future<void> scheduleAt(
    int id,
    DateTime when, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) => NotificationScheduler.scheduleAt(
    id,
    when,
    title: title,
    body: body,
    channelId: channelId,
  );

  static Future<void> scheduleAtUtc(
    int id,
    DateTime whenUtc, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) => NotificationScheduler.scheduleAtUtc(
    id,
    whenUtc,
    title: title,
    body: body,
    channelId: channelId,
  );

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
  }) => NotificationScheduler.scheduleAtAlarmClock(
    id,
    when,
    title: title,
    body: body,
    channelId: channelId,
    groupKey: groupKey,
    setAsGroupSummary: setAsGroupSummary,
    payload: payload,
    actions: actions,
    expandedLines: expandedLines,
    bigPicture: bigPicture,
    timeoutAfterMs: timeoutAfterMs,
  );

  static Future<void> scheduleAtAlarmClockUtc(
    int id,
    DateTime whenUtc, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) => NotificationScheduler.scheduleAtAlarmClockUtc(
    id,
    whenUtc,
    title: title,
    body: body,
    channelId: channelId,
  );

  static Future<void> scheduleWeeklyAt({
    required int id,
    required int weekday,
    required int minutesOfDay,
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) => NotificationScheduler.scheduleWeeklyAt(
    id: id,
    weekday: weekday,
    minutesOfDay: minutesOfDay,
    title: title,
    body: body,
    channelId: channelId,
  );

  static Future<void> scheduleInSecondsExact(
    int id,
    int seconds, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) => NotificationScheduler.scheduleInSecondsExact(
    id,
    seconds,
    title: title,
    body: body,
    channelId: channelId,
  );

  static Future<void> scheduleInSecondsAlarmClock(
    int id,
    int seconds, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) => NotificationScheduler.scheduleInSecondsAlarmClock(
    id,
    seconds,
    title: title,
    body: body,
    channelId: channelId,
  );

  // ── Cancellation ──────────────────────────────────────────────────────────
  static Future<void> cancel(int id) => NotificationScheduler.cancel(id);

  static Future<void> cancelAll() => NotificationScheduler.cancelAll();

  // ── Immediate show helpers ────────────────────────────────────────────────
  static Future<void> showTest() => NotificationScheduler.showTest();

  static Future<void> showTestExpiryReminder() =>
      NotificationScheduler.showTestExpiryReminder();

  static Future<void> showTestLowStockReminder() =>
      NotificationScheduler.showTestLowStockReminder();

  static Future<void> showTestGroupedUpcomingDoseReminders() =>
      NotificationScheduler.showTestGroupedUpcomingDoseReminders();

  static Future<void> showDelayed(
    int seconds, {
    required String title,
    required String body,
    String channelId = 'upcoming_dose',
  }) => NotificationScheduler.showDelayed(
    seconds,
    title: title,
    body: body,
    channelId: channelId,
  );

  static Future<void> showLowStockAlert(
    int id, {
    required String title,
    required String body,
    String? payload,
  }) => NotificationScheduler.showLowStockAlert(
    id,
    title: title,
    body: body,
    payload: payload,
  );

  // ── Forwarded constants ───────────────────────────────────────────────────
  static List<AndroidNotificationAction> get upcomingDoseActions =>
      NotificationChannelService.upcomingDoseActions;
}
