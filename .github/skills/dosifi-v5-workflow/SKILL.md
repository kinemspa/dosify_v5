---
name: dosifi-v5-workflow
description: Repo-specific workflow for Dosifi v5 (Flutter). Use when implementing features/fixes or debugging UI. Enforces centralized design system usage, backlog-driven delivery, and the required analyze→commit→push loop.
---

# Dosifi v5 workflow skill

## When to use

- Any request that involves changing Dart/Flutter code in this repository.
- Any request that touches UI/widgets/layout/styling.
- Any request that says “proceed” or implies backlog-driven work.
- Any request that requires debugging runtime UI errors (e.g., RenderFlex overflow).

## Non-negotiable repo rules

### Centralized design system (Option B)

For any new code that has a visual representation (widgets/layout/styling), treat the design system and central widgets as the single source of truth.

- Check first:
  - `lib/src/core/design_system.dart` for spacing, radii, opacity, colors, text styles, shared layout helpers.
  - `lib/src/widgets/` for reusable widgets (cards, scaffolds, forms, row patterns).

- If a token/pattern doesn’t exist, create it centrally first (in `design_system.dart` or `lib/src/widgets/`), then consume it.

Forbidden in feature code:
- `Colors.*` or `Color(0x...)`
- inline `EdgeInsets.*` with arbitrary numbers
- `BorderRadius.circular(...)` with arbitrary numbers
- `TextStyle(...)` hardcoded in features

### Backlog is source of truth

- Always read the relevant `backlog/*.md` file before starting new work for that area.
- Mark completed tasks by checking their box (`- [x]`).
- Preserve user edits; only touch the checkboxes you actually completed.
- Do not delete tasks.

### Git + validation process (mandatory)

Before pushing, always run analysis:
- `dart analyze` or `flutter analyze`

After every single logical change (even small ones), you must commit and push immediately:
- `git add .`
- `git commit -m "Fix: <description>"` (or `Docs: ...` when purely documentation)
- `git push`

If analysis fails, fix it before pushing.

### Terminal rule

- Assume the working directory is already the repo root: `F:\Android Apps\dosifi_v5`.
- Do NOT run commands that change directories (`cd`, `pushd`, `popd`, etc.).

## Implementation checklist

1. Identify the exact request scope
   - What must change?
   - What must not change (adjacent layout, behavior, API)?

2. Find/extend central primitives first
   - Add missing tokens/styles to `design_system.dart`.
   - Add reusable widgets/patterns to `lib/src/widgets/`.

3. Implement minimal, surgical changes
   - Follow the “Don’t Touch It” rule: avoid unrelated refactors/formatting.
   - Keep public APIs stable unless explicitly requested.

4. Validate
   - Run `flutter analyze`.

5. Ship
   - Commit + push.

6. Backlog bookkeeping
   - Check off only completed items.

## Debugging UI overflows (quick playbook)

- First identify the constraint source (grid cell, row, bottom sheet, etc.).
- Prefer component-level resilience:
  - `LayoutBuilder` + conditional rendering based on available size.
  - `Flexible`/`Expanded` where appropriate (avoid unbounded growth).
  - `ClipRect` when content should not paint outside bounds.
- Avoid global “fixes” that change UX (e.g., wrapping whole screens in scroll views) unless required by spec.

## Examples

### Example: Add a new spacing value

- Add a constant to `lib/src/core/design_system.dart`.
- Use it in feature widgets; do not inline `EdgeInsets.all(13)`.

### Example: Deliver a backlog item

- Open the relevant `backlog/<feature>.md`.
- Implement exactly the checkbox requirement.
- `flutter analyze` → commit → push.
- Mark the checkbox as completed.
