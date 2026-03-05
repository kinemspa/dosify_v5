// Copilot coding agent test - safe to remove
import 'dart:async'; // NEW: For runZonedGuarded (error handling to MCP)

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:skedux/src/app/app.dart';
import 'package:skedux/src/app/notification_deep_link_handler.dart';
import 'package:skedux/src/app/router.dart' show disclaimerNotifier;
import 'package:skedux/src/core/hive/hive_bootstrap.dart';
import 'package:skedux/src/core/notifications/entry_timing_settings.dart';
import 'package:skedux/src/core/notifications/expiry_notification_scheduler.dart';
import 'package:skedux/src/core/notifications/expiry_notification_settings.dart';
import 'package:skedux/src/core/notifications/snooze_settings.dart';
import 'package:skedux/src/core/notifications/notification_service.dart';
import 'package:skedux/src/core/ui/experimental_ui_settings.dart';
import 'package:skedux/src/core/utils/datetime_format_settings.dart';
import 'package:skedux/src/features/schedules/data/schedule_scheduler.dart';

import 'package:mcp_toolkit/mcp_toolkit.dart'; // NEW: For MCP bridge to enable inspections/screenshots

Future<void> main() async {
  runZonedGuarded(
    // NEW: Wraps app init for MCP error reporting
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      print('Skedux: WidgetsFlutterBinding initialized');

      print('Skedux: Initializing Hive...');
      await HiveBootstrap.init();
      print('Skedux: Hive initialized');

      print('Skedux: Initializing MCPToolkit...');
      MCPToolkitBinding.instance
        ..initialize() // NEW: Initializes MCP bridge
        ..initializeFlutterToolkit(); // NEW: Hooks Flutter inspector for widget trees/screenshots
      print('Skedux: MCPToolkit initialized');

      print('Skedux: Running App...');
      await disclaimerNotifier.load();
      runApp(const ProviderScope(child: SkeduxApp()));

      NotificationService.setNotificationResponseHandler(
        NotificationDeepLinkHandler.handle,
      );

      // Initialize notifications + reschedule in the background.
      // This must never block app startup (some devices can hang on plugin init).
      // ignore: unawaited_futures
      () async {
        try {
          print('Skedux: Initializing NotificationService (background)...');
          await NotificationService.init().timeout(const Duration(seconds: 30));
          print('Skedux: NotificationService initialized');

          await EntryTimingSettings.load();
          await ExperimentalUiSettings.load();
          await SnoozeSettings.load();
          await DateTimeFormatSettings.load();
          await ExpiryNotificationSettings.load();

          NotificationDeepLinkHandler.flushPendingIfAny();

          await ScheduleScheduler.rescheduleAllActiveIfStale();
          await ExpiryNotificationScheduler.rescheduleAll();
        } catch (e) {
          print('Skedux: Notification init/reschedule skipped: $e');
        }
      }();
    },
    MCPToolkitBinding.instance.handleZoneError,
  );
}
