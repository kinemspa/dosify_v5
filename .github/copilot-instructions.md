# Dosifi v5 — Copilot Instructions

## Agent mode
When in agent mode, for multi-step tasks or plans, execute all steps in sequence without pausing to announce next actions or seek confirmation, unless a critical error occurs or user input is explicitly required. Proceed autonomously, apply code edits directly, and only stop if the entire task is complete or blocked. I authorize all non-destructive file changes and tool usages in this session.

---

## Big picture
- Flutter (Android-first) app using **feature-first** modules under `lib/src/features/*` with `data/`, `domain/`, `presentation/` layers (see `docs/technical.md`).
- **State:** Riverpod (`flutter_riverpod`). **Routing:** `go_router` (`lib/src/app/router.dart`).
- **Persistence:** Hive boxes (e.g. `medications`, `schedules`, `dose_logs`). Adapters/serialization via `build_runner`.
- **Time/notifications:** schedule logic is **UTC-first**, converting to local tz at runtime (see `docs/technical.md`, `docs/NOTIFICATIONS.md`).

---

## Non‑negotiable UI rules (central design system)

**EVERYTHING must be centrally coded from a constant.** This applies to EVERY change. No exceptions.

### Centralization Principle
- Treat `lib/src/core/design_system.dart` as the **single source of truth** for spacing, radii, opacity, typography, decorations, sizing.
- Before writing UI, check `lib/src/widgets/` for existing reusable building blocks (especially `lib/src/widgets/unified_form.dart`).
- If a token/widget doesn't exist, **add it centrally first**, then use it from feature code.
- Styling must be defined via central constants or helpers — never ad‑hoc in feature code.

### Check Existing Centralized Code FIRST
- `lib/src/core/design_system.dart` — spacing, radii, opacity, colors, text styles, shared layout helpers.
- `lib/src/widgets/` — reusable widgets (cards, buttons, scaffolds, forms, common rows/sections).
- `lib/src/widgets/detail_page_scaffold.dart` — detail page layouts.
- `lib/src/widgets/unified_form.dart` — form layouts.

### If It Doesn't Exist, CREATE It Centrally FIRST
- Add spacing constants to `design_system.dart` (never inline `EdgeInsets` in feature code).
- Add color constants to `design_system.dart` (never inline `Color(0xFF...)` or `Colors.*`).
- Add text styles to `design_system.dart` instead of specifying `TextStyle` directly in features.
- Create reusable widgets in `lib/src/widgets/` (cards, rows, chips, badges, icon+label patterns).
- THEN use those constants/widgets from your feature implementation.

### FORBIDDEN — Never Do This In Feature Code
- ❌ `Colors.blue`, `Color(0xFF...)` — use colors from `design_system.dart`.
- ❌ `Colors.black`, `Colors.black87`, or any hardcoded "black text" color — always use `Theme.of(context).colorScheme.*`.
- ❌ `EdgeInsets.all(12)` — use `kSpacingS`, `kSpacingM`, etc.
- ❌ `BorderRadius.circular(8)` — use `kBorderRadiusS`, `kBorderRadiusM`, etc.
- ❌ Hardcoded `TextStyle(...)` — use `bodyTextStyle`, `helperTextStyle`, `cardTitleStyle`, or add a new style centrally.
- ❌ Material 3 container colors like `primaryContainer`, `secondaryContainer`, `surfaceContainerHighest` for ad-hoc styling.
- ❌ Duplicate widget structures across files — create ONE centralized version and reuse it.
- ❌ Inline `Container` decorations that represent a reusable pattern — extract a central card/button/badge widget.
- ❌ Hardcoded border widths (e.g. `width: 0.5` or `width: 1.0`) — use `kBorderWidthThin`, `kBorderWidthMedium`, etc.

### Correct Pattern
- ✅ Import design system: `import 'package:dosifi_v5/src/core/design_system.dart';`.
- ✅ Use spacing constants: `padding: EdgeInsets.all(kSpacingM)`.
- ✅ Use radius constants: `borderRadius: BorderRadius.circular(kBorderRadiusM)`.
- ✅ Use design-system text styles: e.g., `style: bodyTextStyle(context)`.
- ✅ Use theme colors only through centrally defined helpers or constants.
- ✅ For "primary chips/badges": background `colorScheme.primary`, content `colorScheme.onPrimary` (text + icons).
- ✅ Import widgets: `import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';`.
- ✅ Reuse widgets: `DetailPageScaffold(...)`, `buildDetailInfoRow(...)`, and any central card/row widgets.
- ✅ Use border width constants: `width: kBorderWidthThin`.

### Preferred form/layout primitives
- `SectionFormCard`, `CollapsibleSectionFormCard`, `LabelFieldRow` (`lib/src/widgets/unified_form.dart`)
- `Field36` + `buildFieldDecoration(...)` (`lib/src/widgets/field36.dart`, `lib/src/core/design_system.dart`)
- `StepperRow36`, `SmallDropdown36`, `DateButton36` (`lib/src/widgets/unified_form.dart`)

### Typography Rules
- **Always** use the text styles defined in `lib/src/core/design_system.dart` (e.g., `bodyTextStyle`, `helperTextStyle`, `cardTitleStyle`).
- If a required font style does not exist, add it to `design_system.dart` first, following the existing naming conventions and opacity rules, and then consume it from feature code.
- Never pull typography directly from `Theme.of(context).textTheme.*` or hardcode font sizes/weights in feature widgets if an equivalent helper already exists in the design system.

---

## Domain rules to preserve
- Deleting a medication must **cascade delete linked schedules** and cancel their notifications (see `docs/APP-RULES.md`).
- Dose history (`DoseLog`) is designed to **preserve history even after deletes**; avoid deleting logs (see `lib/src/features/schedules/domain/dose_log.dart`, `docs/technical.md`).
- Multi‑Dose Vial (MDV) inventory semantics: `activeVialVolume` is current open vial mL; `stockValue` is reserve sealed vial count (see `docs/technical.md`).

---

## App startup / notifications
- `lib/main.dart` initializes Hive first, then runs the app; notification init + rescheduling happens **in the background** and must not block startup.
- Notification deep links are handled via `NotificationService.setNotificationResponseHandler(...)` + `NotificationDeepLinkHandler`.

## Agent tooling (MCP)
- `lib/main.dart` initializes `mcp_toolkit` (`MCPToolkitBinding.instance.initialize()` + `initializeFlutterToolkit()`) to enable inspector/widget-tree/screenshot tooling for automation/debugging.
- App init is wrapped in `runZonedGuarded(..., MCPToolkitBinding.instance.handleZoneError)` so runtime errors are surfaced through the MCP bridge.

---

## Workflow (commands)
- Setup: `flutter pub get`
- Analyze (required before commit): `flutter analyze`
- Codegen: `flutter packages pub run build_runner build --delete-conflicting-outputs`
- Run: `flutter run`
- Build: `flutter build apk --debug|--release` / `flutter build appbundle --release`

---

## Terminal Rule
- You are always defaulted in the repo root: `F:\Android Apps\dosifi_v5`.
- Do NOT run any commands that change directories (`cd`, `pushd`, `popd`, etc.).
- Do NOT use `git -C ...`.
- Run commands assuming the working directory is already `F:\Android Apps\dosifi_v5`.

---

## Git Process — For Every Change

0. **Sync Latest `main` (required at session start / before any work)**:
   - `git status -sb` (if not clean, commit or stash before pulling)
   - `git fetch origin`
   - `git pull --ff-only origin main`

1. **Analyze Build**: Before committing, ALWAYS run `flutter analyze` to ensure there are no build errors or fatal warnings.
2. **Commit & Push Every Change**:
   - After *every single* logical change (even small ones), you must commit and push.
   - `git add .`
   - `git commit -m "Fix: <description>"`
   - `git push`
   - **Do not batch changes.** Push immediately to the remote repository.
3. **Validation**:
   - If `flutter analyze` fails, FIX IT before pushing.
   - Do not push broken code.

---

## Refactoring & Regression Prevention

### 1. Mandatory Checkpoint Before Refactoring
- **Rule**: Before starting any significant refactor, UI overhaul, or complex logic change, **ask the user** if they want to commit the current state.
- **Action**: "I am about to refactor X. Shall I commit the current state first so we have a safe rollback point?"

### 2. Respect Existing Layouts (The "Don't Touch It" Rule)
- **Rule**: When asked to modify a specific section of a page, **DO NOT** modify, reformat, or "optimize" unrelated sections unless explicitly instructed.
- **Constraint**: If you must modify a surrounding widget to make the code compile, you must ensure the **visual output remains identical** to the previous state.
- **Recovery**: If a regression occurs, use `git show HEAD:path/to/file` to retrieve the exact original code for the unaffected sections and restore it immediately.

### 3. Visual Verification
- After applying a UI change, verify that:
  - The target change is correct.
  - **Surrounding elements** (headers, footers, adjacent cards) have NOT changed style, order, or content.

---

## Runtime Verification (required for all tasks)

For every task (especially UI work), perform this runtime verification workflow:

### On session start:
1. **Check for an Android emulator/device**: `list_devices` (MCP).
2. If an emulator/device is available, **launch the app**: `launch_app` (MCP) or `flutter run` in background.
3. Keep the app running throughout the session for hot-reload testing.

### After each code change:
1. **Hot reload** the running app: `hot_reload` (MCP).
2. **Check for runtime errors**: `get_runtime_errors` (MCP).
3. **Navigate to changed screens** (if applicable) and confirm:
   - No crashes / red screens.
   - No obvious layout overflows.
   - The target UI change looks correct.

### If no emulator/device is available:
- Explicitly note the limitation.
- Fall back to `flutter analyze` + `flutter build apk --debug` as minimum safety bar.

---

## Task Tracking Workflow (GitHub Issues)

**GitHub Issues** are the single source of truth for all work requests.

### When the user reports a bug or requests a change:
1. **Create a GitHub Issue first** — `gh issue create --title "..." --body "..." --label "..."`.
2. **Fix it** in code.
3. **Commit with Issue reference** — `git commit -m "Fix: <description> Fixes #XX"` so the Issue auto-closes.
4. **Push** — `git push`.

This ensures every change is tracked with a full audit trail in GitHub.

### When working from an existing Issue:
- Read the Issue to understand requirements: `gh issue view <number>`.
- Reference the Issue in commits/PRs (e.g., "Fixes #XX").
- Use `gh issue list` to see open work.

### Labels:
- `bug` — something broken
- `enhancement` — new feature
- `ui` — visual/styling change
- `refactor` — code cleanup without behavior change
