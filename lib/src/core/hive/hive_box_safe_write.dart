import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

const Duration kHiveWebWriteTimeout = Duration(seconds: 8);
const Duration kHiveWebFlushTimeout = Duration(milliseconds: 300);

Future<void> _maybeFlush(BoxBase<dynamic> box) async {
  if (kIsWeb) {
    // On web, IndexedDB commits are managed by Hive/browser. Explicit flush can
    // be slow or stall, so skip it to keep UI writes responsive.
    return;
  }

  // `Box.flush()` exists in Hive on some platforms/versions, but to avoid
  // compile-time coupling we call it via `dynamic` and ignore if unavailable.
  try {
    final dynamic dyn = box;
    final result = dyn.flush();
    if (result is Future) {
      await result.timeout(kHiveWebFlushTimeout);
    }
  } catch (_) {
    // Best-effort.
  }
}

extension HiveBoxSafeWriteX<T> on Box<T> {
  Future<void> putSafe(dynamic key, T value) async {
    if (!kIsWeb) {
      await put(key, value);
      return;
    }

    final sw = Stopwatch()..start();
    try {
      await put(key, value).timeout(kHiveWebWriteTimeout);
      await _maybeFlush(this);

      if (kDebugMode) {
        debugPrint(
          'HiveBoxSafeWrite: put("$name", key=$key) ok in ${sw.elapsedMilliseconds}ms',
        );
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'HiveBoxSafeWrite: put("$name", key=$key) TIMEOUT after ${sw.elapsedMilliseconds}ms: $e',
        );
      }
      rethrow;
    }
  }

  Future<void> deleteSafe(dynamic key) async {
    if (!kIsWeb) {
      await delete(key);
      return;
    }

    final sw = Stopwatch()..start();
    try {
      await delete(key).timeout(kHiveWebWriteTimeout);
      await _maybeFlush(this);

      if (kDebugMode) {
        debugPrint(
          'HiveBoxSafeWrite: delete("$name", key=$key) ok in ${sw.elapsedMilliseconds}ms',
        );
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'HiveBoxSafeWrite: delete("$name", key=$key) TIMEOUT after ${sw.elapsedMilliseconds}ms: $e',
        );
      }
      rethrow;
    }
  }
}
