# Technical Overview — Dosifi v5

Architecture
- Flutter (Dart 3.x) mobile app, Android-first
- State management: Riverpod
- Navigation: go_router
- Local storage: Hive (adapters via build_runner)
- Notifications: flutter_local_notifications (+ timezone)
- Styling: Material 3, Google Fonts (primary gradient #09A8BD → #18537D)

Structure (selected)
- lib/src/app: app scaffold, router, theming
- lib/src/core: cross-cutting util (formatting, prefs, hive bootstrap, notifications)
- lib/src/features: feature-oriented modules (medications, schedules, calendar, etc.)

Medications module (in-progress)
- Tablet screens:
  - add_edit_tablet_page.dart (primary/hybrid WIP)
  - add_edit_tablet_hybrid_page.dart (hybrid detailed form)
  - add_edit_tablet_details_style_page.dart (details-style form)
- Shared components: FormFieldStyler, StrengthInput, AppHeader
- Design spec reference: docs/product-design.md (section: Add/Edit Medication – Tablet)

Conventions
- Use package: imports for files under lib/
- Keep sections ordered: General → Strength → Inventory → Storage
- Provide a live summary block that updates from form input
- Prefer unified input widgets for numeric steppers and dropdowns

Build & tooling
- flutter pub get
- Codegen: flutter packages pub run build_runner build --delete-conflicting-outputs
- Analyze: flutter analyze (very_good_analysis configured)
- Format: dart format .

Android specifics
- applicationId: com.dosifi.app
- namespace: com.dosifi.dosifi_v5
- compileSdk/targetSdk as in android/app/build.gradle.kts

Notifications (architecture and delivery)
- Library: flutter_local_notifications ^17.x with timezone support
- Storage model: we save schedule times as UTC minutes (and UTC weekdays) and convert to local tz when scheduling; this avoids DST and timezone drift.
- Scheduling strategy:
  - Cycle (every N days): schedule one-shot occurrences for the next ~30 cycle days (UTC-safe), AlarmClock mode for delivery.
  - Weekly: schedule one-shot occurrences for the next 60 days (UTC-safe), AlarmClock mode for delivery (preferred for OEM reliability).
  - Cancel logic removes those one-shot IDs for both cycle and weekly.
- AndroidManifest receivers (Android 12+/OEM reliability):
  - com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver (exported=true)
  - com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver (exported=true) with intent-filter for BOOT_COMPLETED and MY_PACKAGE_REPLACED
  - com.dexterous.flutterlocalnotifications.ScheduledNotificationTimeZoneChangeReceiver (exported=true) with TIME_CHANGED, TIME_SET, TIMEZONE_CHANGED
  - Permissions include POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
- In-app preflight checks at save time: ensure POST_NOTIFICATIONS granted; check areNotificationsEnabled and canScheduleExactAlarms; offer settings intents for remediation.
- Diagnostics (Settings > Diagnostics):
  - 5s ladder test (T+5 exact, T+6 AlarmClock, T+7 backup show) on high-importance test_alarm channel
  - Direct 5s (no scheduling) on test_alarm channel to validate UX/timing in foreground
  - 2-minute tests (AlarmClock and exact) on test_alarm channel
  - Debug dump prints tz.local, offsets, pendingNotificationRequests, areNotificationsEnabled, canScheduleExactAlarms
- Channels:
  - upcoming_dose (High) for production reminders
  - low_stock, expiry (Default)
  - test_alarm (Max) for diagnostics with short delays

Notes & next steps
- Many analyzer infos/warnings are style/order issues; plan a cleanup pass after UI layout is stabilized.
- Ensure every file ends with a newline (eol_at_end_of_file) and prefer package imports.

UI Blueprint Adoption
- Add Capsule screen now mirrors the Add Tablet blueprint:
  - 36px field height via Field36 and per-field InputDecoration constraints
  - Sections and rows: General → Strength → Inventory → Storage
  - Helper texts on their own rows (centered for dual-field rows, left for single-field)
  - Centered pill-style Save FAB
  - Storage toggles (Refrigerate/Freeze/Dark) with helpers
- Apply the same pattern for all medication forms going forward.

Dropdown alignment
- Unit and quantity dropdowns are centered within a 120px-wide box with a 36px control height, matching the integer fields. Do not use manual pixel padding for alignment; rely on center alignment inside the fixed-width box instead.

Surfaced validation in helper rows (with touched gating)
- Default InputDecoration error line is hidden to preserve the 36px control height.
- Validation messages are surfaced in the helper row beneath the field.
- Errors are only shown AFTER a field has been interacted with (touched) or after an attempted form submit. This prevents red "Required" messages on initial load.
- Implementation: per-field flags like _touchedName and a form-level _submitted gate the display of helper errors.

Checkbox tone and long-label behavior
- Checkbox labels use kCheckboxLabelStyle(context) (darker than support text but lighter than primary labels).
- When a checkbox is disabled by another control (e.g., Refrigerate disabled when Freeze is ON), render its label with kMutedLabelStyle(context) to visually indicate it isn't available.
- Long checkbox labels (e.g., "Enable alert when stock is low") must be wrapped with Expanded and allow softWrap to avoid overflow on small screens.

Theme-only fonts (no inline sizes)
- All text sizing is sourced from ThemeData and InputDecorationTheme; no inline copyWith(fontSize: …) on pages.
- Key sizes (subject to design updates):
  - textTheme.bodyMedium = 12sp (input text, dropdown text, regular labels)
  - textTheme.bodySmall = 11sp (helper texts, compact secondary text)
  - textTheme.titleSmall = 15sp (section titles)
  - textTheme.labelLarge = 12sp (button labels)
- Hint and helper colors derive from the theme:
  - hintStyle: from textTheme.bodyMedium with onSurfaceVariant tint
  - helperStyle: from textTheme.bodySmall with onSurfaceVariant tint
- Checkbox "muted" labels derive from textTheme.bodyMedium with onSurfaceVariant color via kMutedLabelStyle(context).
- If a visual adjustment is needed, update the shared theme in lib/src/app/app.dart rather than setting sizes locally.

Reconstitution Calculator Formula
- Implementation: ReconstitutionCalculatorWidget in lib/src/features/medications/presentation/
- Core calculation formula:
  - Vial Volume (V) = (S / D) × (U / 100)
  - Concentration (C) = D × (100 / U)
  - Where:
    - S = total strength in vial (mg, converted to base units)
    - D = desired dose per injection (mg, converted to base units)
    - U = IU units to draw from syringe (based on syringe capacity: 0.3mL=30IU, 0.5mL=50IU, 1mL=100IU, etc.)
    - V = vial volume in mL (solvent to add for reconstitution)
    - C = concentration per mL after reconstitution
- Unit conversion via _toBaseMass(): g→mg (*1000), mcg→mg (/1000), mg→mg (1:1)
- Preset generation: calculator provides 3 preset options (Concentrated/Standard/Diluted) using 5%, 33%, 80% of syringe capacity
- Validation examples (all verified):
  - Strength 5mg, Dose 250mcg, 5 IU → 1mL vial
  - Strength 5mg, Dose 250mcg, 15 IU → 3mL vial
  - Strength 5mg, Dose 250mcg, 25 IU → 5mL vial
  - Strength 5mg, Dose 500mcg, 20 IU → 2mL vial
  - Strength 5mg, Dose 500mcg, 90 IU → 9mL vial
