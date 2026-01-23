# Dosifi v5 — Copilot Instructions

## Big picture
- Flutter (Android-first) app using **feature-first** modules under `lib/src/features/*` with `data/`, `domain/`, `presentation/` layers (see `docs/technical.md`).
- **State:** Riverpod (`flutter_riverpod`). **Routing:** `go_router` (`lib/src/app/router.dart`).
- **Persistence:** Hive boxes (e.g. `medications`, `schedules`, `dose_logs`). Adapters/serialization via `build_runner`.
- **Time/notifications:** schedule logic is **UTC-first**, converting to local tz at runtime (see `docs/technical.md`, `docs/NOTIFICATIONS.md`).

## Non‑negotiable UI rules (central design system)
- Treat `lib/src/core/design_system.dart` as the **single source of truth** for spacing, radii, opacity, typography, decorations, sizing.
- Before writing UI, check `lib/src/widgets/` for existing reusable building blocks (especially `lib/src/widgets/unified_form.dart`).
- If a token/widget doesn’t exist, **add it centrally first**, then use it from feature code.
- Do **not** hardcode: `Colors.*`, `Color(0xFF...)`, `EdgeInsets.*`, `BorderRadius.circular(...)`, ad-hoc `TextStyle(...)` in feature screens.
- Prefer the form/layout primitives used across add/edit flows:
  - `SectionFormCard`, `CollapsibleSectionFormCard`, `LabelFieldRow` (`lib/src/widgets/unified_form.dart`)
  - `Field36` + `buildFieldDecoration(...)` (`lib/src/widgets/field36.dart`, `lib/src/core/design_system.dart`)
  - `StepperRow36`, `SmallDropdown36`, `DateButton36` (`lib/src/widgets/unified_form.dart`)

## Domain rules to preserve
- Deleting a medication must **cascade delete linked schedules** and cancel their notifications (see `docs/APP-RULES.md`).
- Dose history (`DoseLog`) is designed to **preserve history even after deletes**; avoid deleting logs (see `lib/src/features/schedules/domain/dose_log.dart`, `docs/technical.md`).
- Multi‑Dose Vial (MDV) inventory semantics: `activeVialVolume` is current open vial mL; `stockValue` is reserve sealed vial count (see `docs/technical.md`).

## App startup / notifications
- `lib/main.dart` initializes Hive first, then runs the app; notification init + rescheduling happens **in the background** and must not block startup.
- Notification deep links are handled via `NotificationService.setNotificationResponseHandler(...)` + `NotificationDeepLinkHandler`.

## Agent tooling (MCP)
- `lib/main.dart` initializes `mcp_toolkit` (`MCPToolkitBinding.instance.initialize()` + `initializeFlutterToolkit()`) to enable inspector/widget-tree/screenshot tooling for automation/debugging.
- App init is wrapped in `runZonedGuarded(..., MCPToolkitBinding.instance.handleZoneError)` so runtime errors are surfaced through the MCP bridge.

## Workflow (commands)
- Setup: `flutter pub get`
- Analyze (required before commit): `flutter analyze`
- Codegen: `flutter packages pub run build_runner build --delete-conflicting-outputs`
- Run: `flutter run`
- Build: `flutter build apk --debug|--release` / `flutter build appbundle --release`

## Repo process constraints (agent mode)
- Terminal is assumed at repo root; **do not** use `cd`, `pushd/popd`, or `git -C ...` (see `AGENTS.md`).
- After each logical change: run analyze, then `git add . && git commit -m "Fix: <description>" && git push`.

## Task tracking
- `backlog/` is the source of truth for work requests. Read the relevant `backlog/*.md` before coding and mark completed items by checking `- [x]` only (preserve user edits).
