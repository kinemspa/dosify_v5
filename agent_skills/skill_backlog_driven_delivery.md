# Skill: Backlog-driven delivery (backlog/)

## When to use

- Any time the user says “proceed” or “work on the backlog”.
- Any time the requested change maps to an existing backlog item.

## Rules

- `backlog/` is the source of truth.
- Always read the relevant backlog file before implementing.
- When you complete an item, check it off with `- [x]`.
- Preserve all user text; only update checkboxes for items you actually finished.
- Do not delete tasks.

## Procedure

1. Open the relevant backlog markdown
   - Example: feature/screen-specific file in `backlog/`.

2. Implement exactly what the checkbox asks
   - If ambiguous, choose the smallest interpretation or ask 1–3 clarifying questions.

3. Validate + ship
   - Run `flutter analyze`.
   - Commit and push immediately after the logical change.

4. Update backlog checkboxes
   - Check off only the completed item(s).

## Definition of done

- The feature/fix is implemented.
- Analyzer is clean.
- Commit pushed.
- Backlog item marked complete.
