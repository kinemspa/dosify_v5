# Dosifi v5 — Copilot Instructions

## Big picture
- Flutter Android-first app with feature-first modules in `lib/src/features/*`.
- Typical feature layout: `data/`, `domain/`, `presentation/` (see `medications`, `schedules`, `supplies`).
- State management: Riverpod. Routing: `go_router` in `lib/src/app/router.dart`.
- Persistence: Hive boxes initialized in `lib/src/core/hive/hive_bootstrap.dart`.
- Startup order in `lib/main.dart`: Hive init → runApp → notification/deep-link setup in background.

## Data + service boundaries
- Hive is encrypted: key from `HiveEncryptionKeyService`, then boxes opened with `encryptionCipher`.
- One-time plaintext→encrypted migration is handled in `HiveBootstrap._migrateToEncryptedIfNeeded`.
- Cross-feature links: schedules reference medications; delete flows must keep storage + notifications consistent.
- Notifications are coordinated through `NotificationService`, `ScheduleScheduler`, and deep-link handler wiring in `main.dart`.

## Non-negotiable UI conventions
- Use `lib/src/core/design_system.dart` as the single source of visual tokens.
- Reuse shared widgets in `lib/src/widgets/` before creating feature-local UI patterns.
- If a token/pattern is missing, add it centrally first, then consume it in feature code.
- Do not hardcode `Colors.*`, `Color(...)`, ad-hoc `EdgeInsets`, `BorderRadius`, or feature-level `TextStyle(...)`.
- Preferred form primitives: `SectionFormCard`, `LabelFieldRow`, `StepperRow36`, `SmallDropdown36`, `DateButton36`, `Field36`.

## Domain invariants to preserve
- Deleting a medication must cascade-delete linked schedules and cancel their notifications.
- `DoseLog` history is intentionally retained even after schedule/medication deletion.
- MDV semantics: `activeVialVolume` = open vial mL, `stockValue` = sealed reserve vial count.
- Schedule timing is UTC-first; convert to local timezone only when scheduling/displaying.

## Workflow that matches this repo
- Always run from repo root `F:\Android Apps\dosifi_v5` (no `cd`/`pushd`/`popd`).
- Session sync: `git status -sb` → `git fetch origin` → `git pull --ff-only origin main`.
- Core validation: `flutter analyze`.
- Codegen when models/adapters change: `flutter packages pub run build_runner build --delete-conflicting-outputs`.
- Build checks: `flutter build apk --debug` (or release/appbundle as needed).

## Runtime/debug expectations
- Prefer MCP runtime loop when available: `list_devices` → launch app → `hot_reload` + `get_runtime_errors` after edits.
- If no Android device/emulator exists, report limitation and use analyze + debug APK build as fallback.
- `mcp_toolkit` is initialized in `main.dart`; runtime errors are surfaced via `runZonedGuarded`.

## Delivery conventions
- GitHub Issues are the source of truth for requested work; reference issue IDs in commits when applicable.
- Keep changes surgical: do not refactor unrelated UI/layout while implementing a focused request.
- Preserve package imports for files under `lib/` and follow existing naming/structure patterns.
