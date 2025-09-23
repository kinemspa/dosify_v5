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
- Checkbox “muted” labels derive from textTheme.bodyMedium with onSurfaceVariant color via kMutedLabelStyle(context).
- If a visual adjustment is needed, update the shared theme in lib/src/app/app.dart rather than setting sizes locally.
