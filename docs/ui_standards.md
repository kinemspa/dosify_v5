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

## Enforcement

Feature code under `lib/src/features/**` must not introduce new styling literals:
- `Colors.*` / `Color(0x...)`
- `EdgeInsets.*`
- `BorderRadius.*`
- `TextStyle(...)`

This is enforced by `tool/check_no_literal_styling.dart` and is run by:
- `pwsh ./tool/scripts/quality.ps1`

Baseline (temporary)
- Existing violations are tracked in `tool/analysis/literal_styling.baseline.txt`.
- If you refactor existing code and the checker flags “new” issues due to signature churn, regenerate the baseline:
	- `dart run tool/check_no_literal_styling.dart --write-baseline tool/analysis/literal_styling.baseline.txt`
