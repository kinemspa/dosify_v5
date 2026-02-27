# Notifications — Scheduling Investigation and Current Status

Last updated: 2025-09-17

Summary
- Immediate notifications work reliably.
- Scheduled notifications (one-shot ~30s and weekly), including AlarmClock mode, previously appeared created but often were not delivered due to OS restrictions and timezone edge cases. The Settings 30s tests now:
  - perform permission and exact-alarm preflight checks,
  - use unique IDs to avoid collisions,
  - schedule from a UTC source time and convert to local tz for the trigger to avoid DST/offset bugs.
- The feature is de‑prioritized until core UX modules are complete.

Environment (reference)
- Flutter SDK: 3.24.x on Windows (Dart 3.8.x)
- Android: Emulator API 34 (x86_64) and Samsung SM S906E (Android 15, API 35)
- App package: com.dosifi.app
- Plugin: flutter_local_notifications ^17.2.x
- Time zone: Australia/Sydney (UTC+10)

Observed behavior
- Immediate notification posts as expected.
- Scheduling calls report success for exactAllowWhileIdle and alarmClock.
- pendingNotificationRequests still list scheduled tests after their fire time.
- No alarm icon and next_alarm_formatted=null after AlarmClock scheduling on emulator.

Diagnostics (highlights)
- dumpsys alarm shows RTC_WAKEUP alarms for ScheduledNotificationReceiver targeting our app.
- deviceidle reports ACTIVE and the app is on the doze whitelist.
- appops reports SCHEDULE_EXACT_ALARM: allow.
- dumpsys notification shows immediate posts to channel upcoming_dose (category alarm, importance high).
- No OS-level next alarm registered for AlarmClock path on emulator.

Changes in app code (summary)
- Robust timezone setup and logging around permission status, intents, tz offsets, scheduling success/failure.
- Weekly schedules now schedule one-shot notifications for the next 60 days (per day/time), avoiding repeating weeklies which some devices suppress. They use AlarmClock mode (preferred for OEM reliability), and exactAllowWhileIdle/inexact remain as code paths for tests.
- One-shot schedules use exactAllowWhileIdle with fallback.
- AlarmClock test path exists but system UI remains unaware (no icon/next alarm).
- Native helpers via platform channel: canScheduleExactAlarms, getChannelImportance, isIgnoringBatteryOptimizations, requestIgnoreBatteryOptimizations.
- AndroidManifest permissions added for notifications, exact alarms, and battery optimizations.

What works
- Immediate notification posting
- Settings intents for Alarms & reminders and Channel settings
- Battery optimization exemption request + fallback
- Delete schedules cancels notifications

What doesn’t (current)
- Delivery of scheduled notifications (exact/inexact/AlarmClock) in tested environments

Preflight checks (implemented)
- Before scheduling, the app now proactively checks:
  - Android exact alarms capability (via platform AlarmManager.canScheduleExactAlarms)
  - Whether notifications are enabled for the app/channel
- If either check fails, a centered dialog offers to open the relevant Settings pages (Channel/Notifications and Alarms & reminders) so the user can enable them.

Next steps (when resuming)
1) Validate in alternate environments (different emulator image/vendor; a stock Google device on Android 13/14).
2) Native AlarmManager probe: minimal BroadcastReceiver with setExactAndAllowWhileIdle and setAlarmClock. If delivery still fails, it indicates environment-level suppression.
3) Foreground timer diagnostic for a short delay path.
4) Consider WorkManager/JobScheduler for long delays (≥15m) where appropriate.
5) Try plugin pin/downgrade (e.g., 17.0.x) to rule out regressions.
6) ✅ In-app guardrails: `NotificationPermissionBanner` on home page surfaces a warning when exact alarms or notification permission are insufficient, with a direct "Fix" button to the relevant OS settings page.

References
- Original detailed investigation content was consolidated here from docs/notification_scheduling_investigation.md.
