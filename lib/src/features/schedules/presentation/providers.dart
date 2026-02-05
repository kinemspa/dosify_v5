import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/hive/hive_watch.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

final schedulesBoxProvider = Provider<Box<Schedule>>((ref) {
  return Hive.box<Schedule>('schedules');
});

final schedulesBoxChangesProvider = StreamProvider<int>((ref) {
  final box = ref.watch(schedulesBoxProvider);
  return watchBoxChanges(box);
});

final doseLogsBoxProvider = Provider<Box<DoseLog>>((ref) {
  return Hive.box<DoseLog>('dose_logs');
});

final doseLogsBoxChangesProvider = StreamProvider<int>((ref) {
  final box = ref.watch(doseLogsBoxProvider);
  return watchBoxChanges(box);
});
