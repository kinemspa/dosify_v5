
# UI Styling Unification

## Goal
- Eliminate design drift by enforcing the centralized design system across all UI.

## Definition of Done
- No new `Colors.*`, `Color(0x...)`, `EdgeInsets.*`, `BorderRadius.circular(...)`, or ad-hoc `TextStyle(...)` introduced in feature code.
- Repeated visual patterns (cards, chips/badges, empty states, section headers) are implemented once in `lib/src/core/design_system.dart` and/or `lib/src/widgets/`.
- High-risk screens have regression coverage (goldens or focused widget tests).

## Plan (phased)

### Phase 0 — Inventory & Prioritization

### Phase 1 — Fill Design-System Gaps (central-first)

### Phase 2 — Migrate Feature Screens (highest impact first)
- [x] Migrate Supplies UI first (known-heavy literal usage) to use only design tokens and shared widgets.
- [ ] Migrate Medication Details UI hotspots (chips/toggles/inline editor sections) to remove remaining literals.
- [ ] Migrate Schedule Details UI to reuse shared header/card/chip patterns.
- [ ] Migrate Home UI sections to use the same card/section primitives as their source feature pages.

### Phase 3 — Enforce & Prevent Regression
- [x] Add/extend a lint/check script that fails CI when forbidden literals appear in `lib/src/features/**`.
- [ ] Add 3–5 targeted golden tests for the most layout-sensitive cards (compact width + large text scale).
- [x] Add a short contributor note in `docs/ui_standards.md` describing the enforcement rule and where to add new tokens/widgets.
