import 'dart:async'; // NEW: For runZonedGuarded (error handling to MCP)

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:dosifi_v5/src/app/app.dart';
import 'package:dosifi_v5/src/app/notification_deep_link_handler.dart';
import 'package:dosifi_v5/src/core/hive/hive_bootstrap.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';

import 'package:mcp_toolkit/mcp_toolkit.dart'; // NEW: For MCP bridge to enable inspections/screenshots

Future<void> main() async {
  runZonedGuarded(
    // NEW: Wraps app init for MCP error reporting
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      print('Dosifi: WidgetsFlutterBinding initialized');

      print('Dosifi: Initializing Hive...');
      await HiveBootstrap.init();
      print('Dosifi: Hive initialized');

      print('Dosifi: Initializing MCPToolkit...');
      MCPToolkitBinding.instance
        ..initialize() // NEW: Initializes MCP bridge
        ..initializeFlutterToolkit(); // NEW: Hooks Flutter inspector for widget trees/screenshots
      print('Dosifi: MCPToolkit initialized');

      print('Dosifi: Running App...');
      runApp(const ProviderScope(child: DosifiApp()));

      NotificationService.setNotificationResponseHandler(
        NotificationDeepLinkHandler.handle,
      );

      // Initialize notifications + reschedule in the background.
      // This must never block app startup (some devices can hang on plugin init).
      // ignore: unawaited_futures
      () async {
        try {
          print('Dosifi: Initializing NotificationService (background)...');
          await NotificationService.init().timeout(const Duration(seconds: 4));
          print('Dosifi: NotificationService initialized');

          NotificationDeepLinkHandler.flushPendingIfAny();

          await ScheduleScheduler.rescheduleAllActiveIfStale();
        } catch (e) {
          print('Dosifi: Notification init/reschedule skipped: $e');
        }
      }();
    },
    MCPToolkitBinding.instance.handleZoneError,
  );
}