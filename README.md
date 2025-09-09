# Dosifi v5

An Android-only Flutter app scaffold for medication tracking with a modern Material 3 UI.

Status: Actively developed. See docs for final design and implementation details. This README is a quick entry point; the docs are the source of truth.

Getting started (Windows PowerShell)
- Ensure Flutter is installed: `flutter --version`
- Fetch packages: `flutter pub get`
- Run on device/emulator: `flutter run`

Key decisions
- State management: Riverpod
- Routing: go_router
- Local storage: Hive (planned)
- Notifications: flutter_local_notifications (planned)
- Linting: very_good_analysis

Design tokens
- Primary gradient: #09A8BD → #18537D
- Secondary: #EC873F

App IDs
- Android applicationId: com.dosifi.app
- Android namespace: com.dosifi.dosifi_v5

Docs
- See docs/architecture.md and docs/ux-guidelines.md (placeholders for now).
