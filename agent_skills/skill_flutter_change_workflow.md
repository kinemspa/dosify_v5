# Skill: Flutter change workflow

## When to use

- Any time you’re asked to implement a feature/fix in this repo.
- Especially for UI work (widgets/layout) or cross-screen changes.

## Goal

Make a focused change without breaking build, UI consistency, or workflow expectations.

## Steps

1. Identify the work item
   - Prefer starting from the relevant file in `backlog/`.
   - Confirm acceptance criteria (what should change vs what must not).

2. Find the right “central” building blocks first
   - Check `lib/src/core/design_system.dart` for spacing/radii/opacity/text styles.
   - Check `lib/src/widgets/` for reusable widgets/layout helpers.
   - If a pattern does not exist, add it centrally first, then consume it.

3. Implement minimal, surgical code changes
   - Respect the “Don’t Touch It” rule: don’t reformat or refactor adjacent UI unless required.
   - Avoid duplicating widget structures across screens; extract shared widgets if needed.

4. Validate
   - Run `flutter analyze` and fix anything relevant before proceeding.

5. Commit & push (mandatory)
   - `git add .`
   - `git commit -m "Fix: <short description>"`
   - `git push`

## Common pitfalls to avoid

- Hardcoding spacing/color/typography instead of using the design system.
- “Small cleanup” refactors that change unrelated layouts.
- Skipping `flutter analyze` before committing.

## Quick command set

- `flutter analyze`
- `git add .`
- `git commit -m "Fix: ..."`
- `git push`
