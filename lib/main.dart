import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_v5/src/app/app.dart';
import 'package:dosifi_v5/src/core/hive/hive_bootstrap.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBootstrap.init();
  await NotificationService.init();
  runApp(const ProviderScope(child: DosifiApp()));
  // Kick off rescheduling in the background so startup isn't blocked
  // ignore: unawaited_futures
  ScheduleScheduler.rescheduleAllActive().catchError((_) {});
}
