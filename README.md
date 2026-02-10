# Dosifi v5

An Android Flutter app for medication tracking with a modern Material 3 UI. Android-only at present.

Status: Actively developed. Notifications: Immediate notifications work; scheduled delivery is de‑prioritized pending OS/AlarmManager behavior investigation (see docs/NOTIFICATIONS.md).

Quickstart (Windows PowerShell)
- Verify Flutter/Dart: flutter --version (tested with Flutter 3.24.x, Dart 3.8.x)
- Install deps: flutter pub get
- Static checks: flutter analyze
- Run on device/emulator: flutter run

Web smoke testing (Chrome)
- Run on Chrome with persistence across restarts: `scripts/dev/run_chrome.ps1`
	- Notes: Web persistence depends on BOTH a stable origin (host+port) and a stable Chrome user profile.

Build
- Debug APK: flutter build apk --debug
- Release APK: flutter build apk --release
- Play Store bundle: flutter build appbundle --release

Key decisions
- State: Riverpod
- Routing: go_router
- Storage: Hive (+ adapters)
- Notifications: flutter_local_notifications (+ permission_handler); scheduled delivery currently paused
- Linting: very_good_analysis

Design tokens
- Primary gradient: #09A8BD → #18537D
- Secondary: #EC873F

Android identifiers
- applicationId: com.dosifi.app
- namespace: com.dosifi.dosifi_v5
- minSdk: 24, targetSdk: 35
- Permissions: POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS (see android/app/src/main/AndroidManifest.xml)

Architecture overview
- Feature-first structure with layers per feature: data, domain, presentation
- Navigation via go_router
- State via Riverpod Notifiers and local widget state where appropriate
- Persistence via Hive boxes (e.g., medications, schedules, supplies)
- Time zone–aware schedule handling (UTC fields mapped to local at runtime)
- UI follows Material 3; shared components for inputs, headers, and strength/stock controls

Major modules
- Medications: Add/Edit for Tablet, Capsule, Injection variants; list with search, filter, sort, and responsive cards
- Schedules: Weekly, multi-time support with UTC mapping and stable IDs
- Calendar: Agenda-first views aligned with Schedules (progressive enhancement)
- Supplies: Track consumables with stock movements and low-stock indicators
- Reconstitution Calculator: Calculates doses/volumes for multi-dose vials

Documentation (canonical)
- CHANGELOG: docs/CHANGELOG.md (all release notes and technical updates)
- Product design: docs/product-design.md (full UI/UX spec, consolidated module specs)
- Notifications: docs/NOTIFICATIONS.md (scheduling behavior, diagnostics, current status)
- Archive: removed (legacy progress notes were consolidated and deleted)
- Screenshots: docs/assets/

Notes
- Dependency versions: see pubspec.yaml
- If you change priorities or scope, update docs/CHANGELOG.md and the top of this README accordingly.
