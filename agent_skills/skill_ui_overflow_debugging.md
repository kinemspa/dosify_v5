# Skill: UI overflow / constraint debugging (Flutter)

## When to use

- `RenderFlex overflowed by ... pixels` errors.
- Layout exceptions that only happen on small screens, split panes, or tight containers.

## Goal

Fix layout robustness without changing the intended UI design.

## Checklist

1. Confirm where constraints are coming from
   - Identify the widget giving tight height/width (e.g. grid cell, list row, bottom sheet).

2. Prefer minimal, local fixes first
   - Use `LayoutBuilder` to adapt rendering to available size.
   - Replace rigid layouts with `Flexible`/`Expanded` (carefully) or conditional rendering.
   - Consider `ClipRect` when content must not paint outside bounds.

3. Preserve design system rules
   - Do not introduce new padding/radii/colors ad-hoc.
   - Use existing design tokens and typography helpers.

4. Avoid “fixes” that hide real problems globally
   - Don’t blanket-wrap the whole page in scroll views unless that’s the UX.
   - Prefer making the specific component resilient.

## Common patterns

- Conditional UI when height is too small (e.g. show header only).
- Replace multi-line text with `maxLines: 1` + ellipsis.
- Use `FittedBox` only for small, bounded elements (icons/badges), not entire cards.

## Validate

- Reproduce the original overflow scenario.
- Run `flutter analyze`.
