# Skill: Design system compliance (centralized styling)

## When to use

- Any new widget/layout/styling.
- Any time you need a new spacing value, radius, color, border width, or text style.

## Non-negotiable rules (repo-specific)

- No ad-hoc styling in feature code.
- No hardcoded colors (including `Colors.*` and `Color(0x...)`).
- No hardcoded `EdgeInsets` values.
- No hardcoded `BorderRadius.circular(...)`.
- No hardcoded `TextStyle(...)` in features.

## Approved sources

1. `lib/src/core/design_system.dart`
   - spacing constants (e.g. `kSpacingS`, `kSpacingM`)
   - radii constants (e.g. `kBorderRadiusSmall`)
   - border widths (e.g. `kBorderWidthThin`)
   - typography helpers (e.g. `bodyTextStyle(context)`, `helperTextStyle(context)`)

2. `lib/src/widgets/`
   - reusable patterns: cards, rows, scaffolds, form layout helpers.

## Procedure for adding a missing style

1. Add the constant/helper centrally
   - If it’s spacing/radius/border width/color/text style: add to `design_system.dart`.
   - If it’s a reusable pattern (layout chunk): add a widget/helper to `lib/src/widgets/`.

2. Use it everywhere
   - Replace any local/inlined equivalents with the central constant/helper.

## Sanity checks

- Colors come from `Theme.of(context).colorScheme.*` (or a design-system helper).
- Typography uses helpers from `design_system.dart`.
- Spacing is exclusively from the spacing scale.

## Good examples (patterns)

- `padding: const EdgeInsets.all(kSpacingM)`
- `borderRadius: BorderRadius.circular(kBorderRadiusSmall)`
- `style: bodyTextStyle(context)`
