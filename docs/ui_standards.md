# UI Standards

This project uses a centralized design system. UI should not define new ad-hoc styling in feature code or in “how-to” docs.

Authoritative sources:
- `lib/src/core/design_system.dart` (tokens + helper builders)
- `lib/src/widgets/` (reusable layout/widgets)
- `AGENTS.md` and `docs/APP-RULES.md` (enforcement rules)

Rules of thumb
- Reuse existing shared widgets and spacing/radius/text helpers.
- If a visual pattern is repeated, create it centrally first, then reuse it.
- Avoid documenting pixel-perfect constants here; keep values in `design_system.dart` so docs don’t drift.
- Avoid bottom-sheet popups for summaries/transient info; prefer inline summaries in the page layout.
- Prefer subtle domain differentiation (e.g., small avatar/icon tint) over heavy persistent accents that change card layout.
