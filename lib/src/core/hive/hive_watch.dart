import 'package:hive_flutter/hive_flutter.dart';

/// Emits immediately, then emits again for every Hive box change.
///
/// Useful to drive Riverpod rebuilds without `ValueListenableBuilder`.
Stream<int> watchBoxChanges(Box<dynamic> box) async* {
  var tick = 0;
  yield tick;
  await for (final _ in box.watch()) {
    tick++;
    yield tick;
  }
}
