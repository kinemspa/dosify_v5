import 'dart:async'; // NEW: For runZonedGuarded (error handling to MCP)

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:dosifi_v5/src/app/app.dart';
import 'package:dosifi_v5/src/core/hive/hive_bootstrap.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';

import 'package:mcp_toolkit/mcp_toolkit.dart'; // NEW: For MCP bridge to enable inspections/screenshots

Future<void> main() async {
  runZonedGuarded(
    // NEW: Wraps app init for MCP error reporting
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await HiveBootstrap.init();
      await NotificationService.init();
      MCPToolkitBinding.instance
        ..initialize() // NEW: Initializes MCP bridge
        ..initializeFlutterToolkit(); // NEW: Hooks Flutter inspector for widget trees/screenshots
      runApp(const ProviderScope(child: DosifiApp()));
      // Kick off rescheduling in the background so startup isn't blocked
      // ignore: unawaited_futures
      ScheduleScheduler.rescheduleAllActive().catchError((_) {});
    },
    MCPToolkitBinding.instance.handleZoneError,
  );
}
