# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project: Dosifi v5 (Flutter)
Platform: Android-first (Windows + PowerShell)

Standing rules
- Always commit to the local git.
- Always update the technical documentation.

Essential commands (PowerShell)
- Setup/verify
```sh path=null start=null
flutter --version
flutter pub get
```
- Code generation (Hive/Freezed/JSON adapters)
```sh path=null start=null
flutter packages pub run build_runner build --delete-conflicting-outputs
```
- Lint and format
```sh path=null start=null
dart format .
flutter analyze
```
- Run
```sh path=null start=null
flutter run            # debug on attached device/emulator
flutter run --release  # release mode
```
- Build artifacts
```sh path=null start=null
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```
- Tests
```sh path=null start=null
flutter test                              # all tests
flutter test test/widget_test.dart        # single file
flutter test --plain-name "name fragment" # filter by test name substring
flutter test -n "Exact test name" test/widget_test.dart
```
- Useful helper
```sh path=null start=null
.\scripts\dev\status.ps1
```

High-level architecture (big picture)
- App bootstrapping
  - lib/main.dart initializes Hive and NotificationService, then runs the app inside a Riverpod ProviderScope.
  - lib/src/app/app.dart defines Material 3 theming (brand primary pinned) and configures the router.
- Routing (go_router)
  - lib/src/app/router.dart uses a ShellRoute to keep a persistent bottom navigation bar and defines named routes for Home, Medications, Calendar, Schedules, Supplies, Settings, and Analytics.
  - Medication and Schedule edit/detail routes load initial data from Hive boxes (e.g., 'medications', 'schedules'); specific routes are ordered before the dynamic '/medications/:id' catch-all.
- State management
  - Riverpod providers and notifiers for app/state; example: themeModeProvider in lib/src/app/theme_mode_controller.dart.
- Persistence and time
  - Hive for local storage with generated adapters; timezone and flutter_timezone for tz-aware logic.
- Structure
  - lib/src/app: app scaffold, router, theme, controllers.
  - lib/src/core: cross-cutting utilities (Hive bootstrap, notifications, prefs, formatting).
  - lib/src/features: feature-first modules (medications, schedules, calendar, supplies, analytics) split into data/domain/presentation.

Android specifics (from android/app/build.gradle.kts)
- applicationId: com.dosifi.app
- namespace: com.dosifi.dosifi_v5
- minSdk: 24, targetSdk: 36, compileSdk: 36

Notifications status (docs/NOTIFICATIONS.md)
- Immediate notifications work.
- Scheduled notifications (exact/inexact/AlarmClock) are created but not delivered in tested environments; feature is de‑prioritized for now. Diagnostic helpers and permissions are in place for future investigation.

Key docs
- README: project quickstart and decisions (Riverpod, go_router, Hive, notifications, lint).
- Technical overview: docs/technical.md (architecture, tooling, conventions).
- Product design: docs/product-design.md (UI/UX spec and module specs).
- Notifications: docs/NOTIFICATIONS.md (current behavior and findings).
