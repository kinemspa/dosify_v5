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
