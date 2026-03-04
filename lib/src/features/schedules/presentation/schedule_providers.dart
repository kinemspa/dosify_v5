import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/hive/hive_watch.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

final schedulesBoxProvider = Provider<Box<Schedule>>((ref) {
  return Hive.box<Schedule>('schedules');
});

final schedulesBoxChangesProvider = StreamProvider<int>((ref) {
  final box = ref.watch(schedulesBoxProvider);
  return watchBoxChanges(box);
});

final entryLogsBoxProvider = Provider<Box<EntryLog>>((ref) {
  return Hive.box<EntryLog>('entry_logs');
});

final entryLogsBoxChangesProvider = StreamProvider<int>((ref) {
  final box = ref.watch(entryLogsBoxProvider);
  return watchBoxChanges(box);
});
