
# UI Styling Unification

## Goal
- Eliminate design drift by enforcing the centralized design system across all UI.

## Definition of Done
- No new `Colors.*`, `Color(0x...)`, `EdgeInsets.*`, `BorderRadius.circular(...)`, or ad-hoc `TextStyle(...)` introduced in feature code.
- Repeated visual patterns (cards, chips/badges, empty states, section headers) are implemented once in `lib/src/core/design_system.dart` and/or `lib/src/widgets/`.
- High-risk screens have regression coverage (goldens or focused widget tests).

## Plan (phased)

### Phase 0 — Inventory & Prioritization
- [ ] Produce a “Top offenders” list from `lib/src/**` search results (colors/padding/radius/textstyle) and rank by: user-facing frequency + file size + number of literals.
- [ ] Create a short “migration map” (pattern → shared widget/token) so future work does not create parallel styles.

### Phase 1 — Fill Design-System Gaps (central-first)
- [ ] Add missing tokens/helpers to `lib/src/core/design_system.dart` for any recurring padding/radius/text sizes found during scan.
- [ ] Add/standardize shared UI building blocks in `lib/src/widgets/` (only when a pattern repeats):
	- [ ] Unified card surface(s) (standard + compact + outlined/flat variants).
	- [ ] Unified status chip/badge (Active/Paused/Taken/Skipped/etc) with one sizing model.
	- [ ] Unified empty state widget (icon + title + subtitle + CTA).
	- [ ] Unified “section header row” (title + trailing action).

### Phase 2 — Migrate Feature Screens (highest impact first)
- [ ] Migrate Supplies UI first (known-heavy literal usage) to use only design tokens and shared widgets.
- [ ] Migrate Medication Details UI hotspots (chips/toggles/inline editor sections) to remove remaining literals.
- [ ] Migrate Schedule Details UI to reuse shared header/card/chip patterns.
- [ ] Migrate Home UI sections to use the same card/section primitives as their source feature pages.

### Phase 3 — Enforce & Prevent Regression
- [ ] Add/extend a lint/check script that fails CI when forbidden literals appear in `lib/src/features/**`.
- [ ] Add 3–5 targeted golden tests for the most layout-sensitive cards (compact width + large text scale).
- [ ] Add a short contributor note in `docs/ui_standards.md` describing the enforcement rule and where to add new tokens/widgets.
