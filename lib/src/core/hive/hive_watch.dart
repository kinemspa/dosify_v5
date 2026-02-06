import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

/// Emits immediately, then debounces subsequent Hive box changes so that
/// rapid-fire mutations (e.g. batch scheduling, multiple dose logs) are
/// coalesced into a single downstream rebuild instead of N individual ones.
///
/// The [debounce] duration defaults to 200 ms – long enough to collapse a
/// burst of writes but short enough to feel instant to the user.
Stream<int> watchBoxChanges(
  Box<dynamic> box, {
  Duration debounce = const Duration(milliseconds: 200),
}) async* {
  var tick = 0;
  yield tick;

  Timer? timer;
  final controller = StreamController<int>();

  final subscription = box.watch().listen((_) {
    timer?.cancel();
    timer = Timer(debounce, () {
      tick++;
      controller.add(tick);
    });
  });

  yield* controller.stream;

  // Cleanup when the stream is cancelled.
  timer?.cancel();
  await subscription.cancel();
  await controller.close();
}
