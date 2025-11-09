// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

/// Action types for notification buttons
enum NotificationActionType { take, snooze, skip, takeAll, snoozeAll, openApp }

/// Handles notification action button presses
///
/// This service processes actions like Take, Snooze, and Skip
/// without requiring the app to be opened.
class NotificationActionHandler {
  /// Generates a unique ID for dose logs
  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  /// Processes a notification action
  ///
  /// Called when user taps an action button on a notification.
  /// Works in background without opening the app.
  static Future<void> handleAction({
    required String actionId,
    required String? payload,
  }) async {
    debugPrint(
      '[NotificationActionHandler] Handling action: $actionId, payload: $payload',
    );

    try {
      // Parse action type from actionId
      final action = _parseActionType(actionId);
      if (action == null) {
        debugPrint('[NotificationActionHandler] Unknown action: $actionId');
        return;
      }

      // Parse payload to get schedule information
      final data = _parsePayload(payload);
      if (data == null) {
        debugPrint('[NotificationActionHandler] Invalid payload');
        return;
      }

      // Ensure Hive is initialized (for background isolate)
      if (!Hive.isBoxOpen('schedules')) {
        await _initializeHiveInBackground();
      }

      // Process the action
      switch (action) {
        case NotificationActionType.take:
          await _handleTake(data);
          break;
        case NotificationActionType.snooze:
          await _handleSnooze(data);
          break;
        case NotificationActionType.skip:
          await _handleSkip(data);
          break;
        case NotificationActionType.takeAll:
          await _handleTakeAll(data);
          break;
        case NotificationActionType.snoozeAll:
          await _handleSnoozeAll(data);
          break;
        case NotificationActionType.openApp:
          // No action needed - notification tap will open app
          break;
      }

      debugPrint('[NotificationActionHandler] Action completed successfully');
    } catch (e, stack) {
      debugPrint('[NotificationActionHandler] Error handling action: $e');
      debugPrint('[NotificationActionHandler] Stack trace: $stack');
    }
  }

  /// Handles "Take" action
  static Future<void> _handleTake(Map<String, dynamic> data) async {
    final scheduleId = data['scheduleId'] as String;
    final scheduledTime = DateTime.parse(data['scheduledTime'] as String);

    await _recordDoseLog(
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      action: DoseAction.taken,
    );

    // Cancel the notification
    final notificationId = data['notificationId'] as int?;
    if (notificationId != null) {
      await NotificationService.cancel(notificationId);
    }

    // Show feedback (if app is in foreground)
    _showToast('Dose taken');
  }

  /// Handles "Snooze" action (reschedule for +15 minutes)
  static Future<void> _handleSnooze(Map<String, dynamic> data) async {
    final scheduleId = data['scheduleId'] as String;
    final scheduledTime = DateTime.parse(data['scheduledTime'] as String);
    final notificationId = data['notificationId'] as int?;

    await _recordDoseLog(
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      action: DoseAction.snoozed,
    );

    // Reschedule notification for 15 minutes later
    if (notificationId != null) {
      final newTime = DateTime.now().add(const Duration(minutes: 15));

      // Cancel original
      await NotificationService.cancel(notificationId);

      // Schedule new notification with same ID but different time
      final scheduleName = data['scheduleName'] as String?;
      if (scheduleName != null) {
        await NotificationService.scheduleAtAlarmClock(
          notificationId,
          newTime,
          title: scheduleName,
          body: 'Snoozed dose - take now',
        );
      }
    }

    _showToast('Snoozed for 15 minutes');
  }

  /// Handles "Skip" action
  static Future<void> _handleSkip(Map<String, dynamic> data) async {
    final scheduleId = data['scheduleId'] as String;
    final scheduledTime = DateTime.parse(data['scheduledTime'] as String);

    await _recordDoseLog(
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      action: DoseAction.skipped,
    );

    // Cancel the notification
    final notificationId = data['notificationId'] as int?;
    if (notificationId != null) {
      await NotificationService.cancel(notificationId);
    }

    _showToast('Dose skipped');
  }

  /// Handles "Take All" action (for grouped notifications)
  static Future<void> _handleTakeAll(Map<String, dynamic> data) async {
    final scheduleIds = (data['scheduleIds'] as List).cast<String>();
    final scheduledTime = DateTime.parse(data['scheduledTime'] as String);

    // Record all as taken
    for (final scheduleId in scheduleIds) {
      await _recordDoseLog(
        scheduleId: scheduleId,
        scheduledTime: scheduledTime,
        action: DoseAction.taken,
      );
    }

    // Cancel the grouped notification
    final notificationId = data['notificationId'] as int?;
    if (notificationId != null) {
      await NotificationService.cancel(notificationId);
    }

    _showToast('All doses taken');
  }

  /// Handles "Snooze All" action (for grouped notifications)
  static Future<void> _handleSnoozeAll(Map<String, dynamic> data) async {
    final scheduleIds = (data['scheduleIds'] as List).cast<String>();
    final scheduledTime = DateTime.parse(data['scheduledTime'] as String);

    // Record all as snoozed
    for (final scheduleId in scheduleIds) {
      await _recordDoseLog(
        scheduleId: scheduleId,
        scheduledTime: scheduledTime,
        action: DoseAction.snoozed,
      );
    }

    // Reschedule grouped notification for 15 minutes
    final notificationId = data['notificationId'] as int?;
    if (notificationId != null) {
      final newTime = DateTime.now().add(const Duration(minutes: 15));

      await NotificationService.cancel(notificationId);

      final count = scheduleIds.length;
      await NotificationService.scheduleAtAlarmClock(
        notificationId,
        newTime,
        title: '$count Medications - Snoozed',
        body: 'Time to take your medications',
      );
    }

    _showToast('All doses snoozed for 15 minutes');
  }

  /// Records a dose log entry
  static Future<void> _recordDoseLog({
    required String scheduleId,
    required DateTime scheduledTime,
    required DoseAction action,
    String? notes,
  }) async {
    try {
      // Get schedule details
      final schedulesBox = Hive.box<Schedule>('schedules');
      final schedule = schedulesBox.get(scheduleId);

      if (schedule == null) {
        debugPrint(
          '[NotificationActionHandler] Schedule not found: $scheduleId',
        );
        return;
      }

      // Create dose log
      final doseLog = DoseLog(
        id: _generateId(),
        scheduleId: scheduleId,
        scheduleName: schedule.name,
        medicationId: schedule.medicationId ?? '',
        medicationName: schedule.medicationName,
        scheduledTime: scheduledTime,
        actionTime: DateTime.now(),
        doseValue: schedule.doseValue,
        doseUnit: schedule.doseUnit,
        action: action,
        notes: notes,
      );

      // Save to Hive
      final logsBox = Hive.box<DoseLog>('dose_logs');
      await logsBox.put(doseLog.id, doseLog);

      debugPrint(
        '[NotificationActionHandler] Recorded dose log: ${schedule.name} - $action',
      );
    } catch (e) {
      debugPrint('[NotificationActionHandler] Error recording dose log: $e');
      rethrow;
    }
  }

  /// Parses action type from action ID
  static NotificationActionType? _parseActionType(String actionId) {
    if (actionId.startsWith('take_all')) {
      return NotificationActionType.takeAll;
    } else if (actionId.startsWith('snooze_all')) {
      return NotificationActionType.snoozeAll;
    } else if (actionId.startsWith('take_')) {
      return NotificationActionType.take;
    } else if (actionId.startsWith('snooze_')) {
      return NotificationActionType.snooze;
    } else if (actionId.startsWith('skip_')) {
      return NotificationActionType.skip;
    } else if (actionId == 'open_app') {
      return NotificationActionType.openApp;
    }
    return null;
  }

  /// Parses JSON payload from notification
  static Map<String, dynamic>? _parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      // TODO: Implement proper JSON parsing
      // For now, return a basic map
      // In production, payload should be JSON string
      return {};
    } catch (e) {
      debugPrint('[NotificationActionHandler] Error parsing payload: $e');
      return null;
    }
  }

  /// Initializes Hive in background isolate
  static Future<void> _initializeHiveInBackground() async {
    try {
      // Initialize Hive (lightweight init for background)
      await Hive.initFlutter();

      // Register adapters if needed
      if (!Hive.isAdapterRegistered(40)) {
        Hive.registerAdapter(ScheduleAdapter());
      }
      if (!Hive.isAdapterRegistered(41)) {
        Hive.registerAdapter(DoseLogAdapter());
      }
      if (!Hive.isAdapterRegistered(42)) {
        Hive.registerAdapter(DoseActionAdapter());
      }

      // Open boxes
      if (!Hive.isBoxOpen('schedules')) {
        await Hive.openBox<Schedule>('schedules');
      }
      if (!Hive.isBoxOpen('dose_logs')) {
        await Hive.openBox<DoseLog>('dose_logs');
      }

      debugPrint('[NotificationActionHandler] Hive initialized in background');
    } catch (e) {
      debugPrint('[NotificationActionHandler] Error initializing Hive: $e');
      rethrow;
    }
  }

  /// Shows a toast message (if app is in foreground)
  static void _showToast(String message) {
    debugPrint('[NotificationActionHandler] Toast: $message');
    // TODO: Implement actual toast using platform channels
    // For now, just log the message
  }

  /// Generates notification payload with schedule data
  static String generatePayload({
    required String scheduleId,
    required String scheduleName,
    required DateTime scheduledTime,
    required int notificationId,
  }) {
    // TODO: Implement proper JSON encoding
    // For now, return simple format
    return '$scheduleId|$scheduleName|${scheduledTime.toIso8601String()}|$notificationId';
  }

  /// Generates notification payload for grouped notifications
  static String generateGroupedPayload({
    required List<String> scheduleIds,
    required DateTime scheduledTime,
    required int notificationId,
  }) {
    // TODO: Implement proper JSON encoding
    return '${scheduleIds.join(',')}|${scheduledTime.toIso8601String()}|$notificationId';
  }
}
