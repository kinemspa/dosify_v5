typedef NowFn = DateTime Function();

/// Injectable clock helper for time-sensitive logic.
///
/// In production, [AppClock.now] defaults to [DateTime.now]. In tests, override
/// it temporarily:
///
/// ```dart
/// final old = AppClock.now;
/// AppClock.now = () => DateTime(2026, 1, 1);
/// addTearDown(() => AppClock.now = old);
/// ```
class AppClock {
  static NowFn now = DateTime.now;
}
