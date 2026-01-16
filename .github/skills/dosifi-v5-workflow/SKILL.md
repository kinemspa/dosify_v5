---
name: dosifi-v5-workflow
description: Repo-specific workflow for Dosifi v5 (Flutter). Use when implementing features/fixes or debugging UI. Enforces centralized design system usage, backlog-driven delivery, and the required analyze→commit→push loop.
---

# Dosifi v5 workflow skill

## Professional standard (how to work)

Operate like a highly experienced Flutter engineer and UI/UX designer:

- Prefer clean structure over cleverness; keep widgets small and composable.
- Take pride in formatting and readability; make diffs easy to review.
- Be explicit about intent and edge-cases; avoid “mystery meat” behavior.
- Design for clarity and low cognitive load; avoid UI that surprises users.
- Prioritize responsive, resilient layouts that behave well across screen sizes,
   text scaling, and tight constraints.

Responsive layout expectations (Android-first):

- Assume different device sizes and aspect ratios; avoid brittle fixed heights.
- Treat system text scaling as real; keep layouts stable within the app’s guardrails.
- Use constraint-aware layouts (`LayoutBuilder`, `Flexible`, `Expanded`) when needed.
- Fix overflows at the component level; don’t paper over them with global scroll views
   unless that’s the intended UX.

## Centralization rule (strict)

Everything visual must be centrally defined and reused.

- If any UI element/pattern is coded twice (or is likely to be used in more than one place),
   it must be moved into the centralized system.
- Centralize *tokens* (spacing, radii, border widths, opacity, typography, sizes) in
   `lib/src/core/design_system.dart`.
- Centralize *patterns/widgets* (cards, rows, icon+label, chips/badges, buttons, form sections,
   reusable containers) in `lib/src/widgets/`.

This includes (non-exhaustive):
- Borders (color, width, style)
- Border radius
- Typography (font sizes, weights, styles)
- Font/text colors (use theme colorScheme + helpers; do not hardcode)
- Buttons
- Chips/badges
- Common paddings/margins/layout patterns

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

### Checkpoint commits before refactors

- Before any significant refactor, UI overhaul, or complex logic change, ask whether to create a checkpoint commit.
- If confirmed, commit and push the current state before starting the refactor.

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

## Quality gates (before you say “done”)

- No hardcoded visual values in feature code (colors, padding, radii, border widths, text styles).
- Any repeated visual element/pattern is centralized ("coded twice" rule).
- No layout overflows in the modified area; layouts are constraint-aware where needed.
- Diff is minimal and reviewable; unrelated UI remains visually identical.
- `flutter analyze` is clean.
- Commit + push completed.

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
