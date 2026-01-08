<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

---

# CRITICAL DEVELOPMENT RULE: CENTRALIZED DESIGN SYSTEM (OPTION B)

## **EVERYTHING must be centrally coded from a constant**

For any new code you create (widgets, styling, layout, logic that has a visual representation), you must treat the design system and central widgets as the single source of truth.

### 1. Centralization Principle
- If a widget does something (layout pattern, padding scheme, border radii, background treatment, typography combination), that pattern must live in a centralized place and be reused.
- Styling must be defined via central constants or helpers – never ad‑hoc in feature code.
- Font styles must be defined centrally and reused, not re-specified ad hoc.

### 2. Check Existing Centralized Code FIRST
- `lib/src/core/design_system.dart` – spacing, radii, opacity, colors, text styles, shared layout helpers.
- `lib/src/widgets/` – reusable widgets (cards, buttons, scaffolds, forms, common rows/sections).
- `lib/src/widgets/detail_page_scaffold.dart` – detail page layouts.
- `lib/src/widgets/unified_form.dart` – form layouts.

### 3. If It Doesn't Exist, CREATE It Centrally FIRST
- Add spacing constants to `design_system.dart` (never inline `EdgeInsets` in feature code).
- Add color constants to `design_system.dart` (never inline `Color(0xFF...)` or `Colors.*`).
- Add text styles to `design_system.dart` instead of specifying `TextStyle` directly in features.
- Create reusable widgets in `lib/src/widgets/` (cards, rows, chips, badges, icon+label patterns).
- THEN use those constants/widgets from your feature implementation.

### 4. FORBIDDEN – Never Do This In Feature Code
- ❌ `Colors.blue`, `Color(0xFF...)` – use colors from `design_system.dart`.
- ❌ `Colors.black`, `Colors.black87`, or any hardcoded “black text” color – always use `Theme.of(context).colorScheme.*`.
- ❌ `EdgeInsets.all(12)` – use `kSpacingS`, `kSpacingM`, etc.
- ❌ `BorderRadius.circular(8)` – use `kBorderRadiusS`, `kBorderRadiusM`, etc.
- ❌ Hardcoded `TextStyle(...)` – use `bodyTextStyle`, `helperTextStyle`, `cardTitleStyle`, or add a new style centrally.
- ❌ Material 3 container colors like `primaryContainer`, `secondaryContainer`, `surfaceContainerHighest` for ad-hoc styling.
- ❌ Duplicate widget structures across files – create ONE centralized version and reuse it.
- ❌ Inline `Container` decorations that represent a reusable pattern – extract a central card/button/badge widget.
- ❌ Hardcoded border widths (e.g. `width: 0.5` or `width: 1.0`) – use `kBorderWidthThin`, `kBorderWidthMedium`, etc.

### 5. Correct Pattern
- ✅ Import design system: `import 'package:dosifi_v5/src/core/design_system.dart';`.
- ✅ Use spacing constants: `padding: EdgeInsets.all(kSpacingM)`.
- ✅ Use radius constants: `borderRadius: BorderRadius.circular(kBorderRadiusM)`.
- ✅ Use design-system text styles: e.g., `style: bodyTextStyle(context)`.
- ✅ Use theme colors only through centrally defined helpers or constants.
- ✅ For “primary chips/badges”: background `colorScheme.primary`, content `colorScheme.onPrimary` (text + icons).
- ✅ Import widgets: `import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';`.
- ✅ Reuse widgets: `DetailPageScaffold(...)`, `buildDetailInfoRow(...)`, and any central card/row widgets.
- ✅ Use border width constants: `width: kBorderWidthThin`.

## **This applies to EVERY change. No exceptions.**

---

## Typography Rules

- **Always** use the text styles defined in `lib/src/core/design_system.dart` (e.g., `bodyTextStyle`, `helperTextStyle`, `cardTitleStyle`).
- If a required font style does not exist, add it to `design_system.dart` first, following the existing naming conventions and opacity rules, and then consume it from feature code.
- Never pull typography directly from `Theme.of(context).textTheme.*` or hardcode font sizes/weights in feature widgets if an equivalent helper already exists in the design system.

## Git Process For Every Change

## Terminal Rule

- You are always defaulted in the repo root: `F:\Android Apps\dosifi_v5`.
- Do NOT run any commands that change directories (`cd`, `pushd`, `popd`, etc.).
- Do NOT use `git -C ...`.
- Run commands assuming the working directory is already `F:\Android Apps\dosifi_v5`.

1. **Analyze Build**: Before committing, ALWAYS run `dart analyze` (or `flutter analyze`) to ensure there are no build errors or fatal warnings.
2. **Commit & Push Every Change**:
   - After *every single* logical change (even small ones), you must commit and push.
   - `git add .`
   - `git commit -m "Fix: <description>"`
   - `git push`
   - **Do not batch changes.** Push immediately to the remote repository.
3. **Validation**:
   - If `dart analyze` fails, FIX IT before pushing.
   - Do not push broken code.

## Refactoring & Regression Prevention

### 1. Mandatory Checkpoint Before Refactoring
- **Rule**: Before starting any significant refactor, UI overhaul, or complex logic change, **ask the user** if they want to commit the current state.
- **Why**: This creates a clean "Undo" point (rollback) if the new direction fails or breaks existing functionality.
- **Action**: "I am about to refactor X. Shall I commit the current state first so we have a safe rollback point?"

### 2. Respect Existing Layouts (The "Don't Touch It" Rule)
- **Rule**: When asked to modify a specific section of a page (e.g., "update the body card"), **DO NOT** modify, reformat, or "optimize" unrelated sections (e.g., "the header", "the navigation bar") unless explicitly instructed.
- **Constraint**: If you must modify a surrounding widget to make the code compile, you must ensure the **visual output remains identical** to the previous state.
- **Recovery**: If a regression occurs, use `git show HEAD:path/to/file` to retrieve the exact original code for the unaffected sections and restore it immediately.

### 3. Visual Verification
- **Rule**: After applying a UI change, explicitly verify that:
    - The target change is correct.
    - **Surrounding elements** (headers, footers, adjacent cards) have NOT changed style, order, or content.

---

# Task Tracking Workflow (backlog/)

`backlog/` is the single source of truth for work requests.

- **Always read the relevant file in `backlog/` before starting new work** (e.g., the screen/widget you are about to change).
- **When a task is implemented**, mark it as completed in that same file by checking the checkbox (`- [x]`).
- **Do not delete tasks** from these files (the user will confirm completion or delete them).
- **If the user says a task is not completed as desired**, the user will uncheck the box (`- [ ]`) and may add notes; treat that as the authoritative re-opened requirement.
- **Keep edits minimal**: only touch the specific bullets you completed and do not rewrite sections or reformat the file.