Recommendation Plan (for recommendation.md)

Scope & Goals

Improve correctness (UTC/time, notifications, logs), maintainability (clear data boundaries, consistent state), UI consistency (design system compliance), and backlog-deliverables (inventory/reports/take-dose/notifications) without introducing regressions.
Treat “UTC-first” and notification behavior as safety-critical (per docs). Prioritize tests/guardrails before refactors.
Guiding Rules (Definition of Done for any item)

flutter analyze passes with no new warnings.
No new forbidden UI literals in feature code (colors/edge insets/radii/text styles) unless introduced centrally first.
Any change touching time, notifications, schedule matching, or logging must include at least 1 focused unit test that would have failed before the change.
No change to domain rules: medication delete must cascade schedules + cancel notifications; dose logs preserved.
Phase 0 — Inventory of Work (1 short sprint)
Purpose: turn “big refactor” into trackable backlog tasks.

Backlog triage

Review unchecked items across backlog/*.md and tag each as: Correctness / UX / UI / Data / Tooling.
Ensure each new recommendation has:
Target owner (agent)
Target files
Acceptance criteria
Test expectations
Baseline “hotspot map” (for agents)

Routing: router.dart
App init + Hive + startup: main.dart
Notifications scheduler: lib/src/core/notifications/schedule_scheduler.dart
Schedule occurrence logic: schedule_occurrence_service.dart
Dose logs + repository: dose_log.dart, dose_log_repository.dart
Design system + shared widgets: design_system.dart, widgets
Reports/Analytics/Inventory: lib/src/features/reports/presentation/analytics_page.dart, lib/src/features/reports/presentation/medication_reports_widget.dart, inventory_page.dart
Deliverable: a “Recommendation Index” section in recommendation.md listing the tasks below with IDs.

Phase 1 — Correctness Guardrails (highest priority)
Purpose: eliminate hidden correctness bugs (UTC/DST/off-by-one, schedule matching parity) before UI/architecture changes.

UTC-on-write for persisted timestamps
Problem: some models declare UTC semantics but default to local times.
Targets:
dose_log.dart
Inventory log model file (where InventoryLog.timestamp is defined; agents should locate and reference it explicitly)
Acceptance criteria:
All persisted timestamps that are defined as UTC are written as UTC.
No analytics/report screens interpret local timestamps as UTC (or vice versa).
Tests:
Add unit tests ensuring action/scheduled timestamps are stored UTC and remain consistent across serialize/deserialize.
Date-range queries correctness (DST/boundaries)
Problem: range filters risk excluding boundary events and mixing local vs UTC boundaries.
Target:
dose_log_repository.dart
Acceptance criteria:
Range queries include events exactly at start/end boundaries as intended (document inclusive/exclusive rule).
No off-by-one-day around midnight or DST transitions.
Tests:
At least one test for “day boundary” and one for DST-like shift behavior (simulate by using UTC conversions and known offsets).
Notification scheduling parity with supported schedule types
Problem: schedule occurrence logic supports more modes than notification scheduler (notably monthly).
Targets:
schedule_occurrence_service.dart
lib/src/core/notifications/schedule_scheduler.dart
Acceptance criteria:
Every schedule type supported by occurrence logic is schedulable (or explicitly disabled with UI messaging).
Monthly behavior (missing-day behavior, last-day) is consistent between UI and notifications.
Tests:
Unit tests for monthly occurrences and scheduling decisions.
Deterministic “existing log” lookup across notification + in-app flows
Problem: different ID strategies and matching rules can cause duplicates or missed detections.
Targets:
Notification deep-link handler file (agent to locate and cite; referenced earlier as handling _findExistingLog)
Schedule detail “take dose” flow file (agent to locate and cite; referenced earlier as generating IDs)
Acceptance criteria:
For a given schedule occurrence, the app can reliably find the existing dose log regardless of entry point.
Duplicates prevented when tapping notification action repeatedly.
Tests:
A unit test that simulates the same occurrence being logged via two paths and verifies dedupe.
Phase 2 — Data Boundaries & Reactivity (maintainability)
Purpose: make UI updates reliable and reduce “Hive in widgets everywhere”.

Standardize “Hive → Riverpod” reactivity pattern
Problem: some providers are explicitly non-reactive; other screens use ad-hoc ValueListenableBuilder stacks.
Targets:
lib/src/features/medications/presentation/medications_list_provider.dart
Analytics/Inventory pages reading boxes directly: lib/src/features/reports/presentation/analytics_page.dart, inventory_page.dart
Acceptance criteria:
Lists update when underlying Hive boxes change, without manual refresh.
A consistent pattern exists (documented) for “box listenable → provider state”.
Tests:
Provider tests (or unit tests around a wrapper) verifying updates on box changes (mock or in-memory approach as used elsewhere in repo).
Remove Hive reads from route builders
Problem: routing currently resolves models inside route builders; makes deep links and rebuilds fragile.
Target:
router.dart
Acceptance criteria:
Routes pass IDs/params; pages resolve via repository/provider and show a “not found” UI when missing.
No direct Hive .get() calls inside route builder closures.
Tests:
Widget tests for navigation to a missing ID showing “not found” rather than crashing.
Extract heavy analytics computations out of widgets
Problem: large widgets mix UI + complex computations; hard to test and maintain.
Targets:
lib/src/features/reports/presentation/medication_reports_widget.dart
lib/src/features/reports/widgets/combined_reports_history_widget.dart
Acceptance criteria:
Computations moved into pure services/functions in domain layer with unit tests.
Widgets become “render-only” given computed view models.
Tests:
Unit tests covering histogram bucketing, streak logic, trend sampling, and history merge/dedupe behavior.
Phase 3 — Design System Compliance & UI Consistency
Purpose: ensure consistent look/feel and prevent regressions from ad-hoc UI code.

Compliance sweep: eliminate forbidden literals in feature UI
Targets (known examples from earlier scan):
supplies_page.dart
Any other feature screens flagged by grep for Colors. / raw EdgeInsets / BorderRadius.circular (agent should create a short list in recommendation.md)
Acceptance criteria:
Feature UI no longer uses forbidden literals; tokens/widgets are used from design system.
Any new needed token is added centrally (not local ad-hoc).
Tests/verification:
Run existing “no literal font size” tooling if used in repo; add similar check for colors/padding if desired by team.
Centralize repeated UI patterns into shared widgets
Candidates:
“Export CSV section” currently embedded in lib/src/features/reports/presentation/analytics_page.dart
Inventory row patterns currently embedded in inventory_page.dart
Acceptance criteria:
One shared widget per pattern in widgets (or feature-shared widgets folder if that’s the convention), consumed consistently.
Phase 4 — UX Backlog Closure (deliver user-visible wins)
Purpose: close the most valuable user-facing gaps once correctness + architecture are safer.

Meds-only “full inventory table”
Backlog anchor:
12_reports_analytics_inventory.md
Targets:
inventory_page.dart
Stock service already exists: lib/src/features/medications/domain/medication_stock_service.dart
Requirements (proposed):
Table/list shows: Medication name, current stock, days remaining, status (OK/Low/Out).
Sort default: Out → Low → OK; optional search/filter chips.
Supplies section hidden unless supplies exist (since you’re not using supplies yet).
Acceptance criteria:
Satisfies “full inventory table” checkbox.
Works with 0 meds (empty state).
Tests:
Widget test for ordering and empty state.
Analytics export maturation (keep CSV v1, but make it robust)
Targets:
lib/src/features/reports/presentation/analytics_page.dart
Requirements:
Extract export logic into a reusable exporter service.
Decide timestamp inclusion: scheduled vs action vs both (document in export headers).
Add date-range selection control shared across report cards (if backlog desires).
Acceptance criteria:
Export output is stable and tested (escaping, headers, ordering).
Tests:
Unit test for CSV escaping and deterministic ordering.
Take Dose + Notification action UX polish
Backlog anchors:
10.2_widget_takedose.md
11_notifications.md
Targets:
Take dose widget file (agent to locate and cite)
Notification action handling files (agent to locate and cite)
Acceptance criteria:
Implements backlog “presets/precision/scrolling” and “advanced take/snooze/skip layout + more details” items as written.
No regressions in time windows or logged timestamps.
Tests:
Widget tests for take-dose dialog behavior; unit tests for notification action → log creation.
“Most Dangerous Hotspots” (treat as high-risk changes)
UTC vs local timestamp storage/reads (dose logs, inventory logs).
Schedule occurrence logic vs notification scheduler parity.
Deep-link “existing log” matching / dedupe.
Hive bootstrap/migration/recovery behavior in main.dart (and Hive bootstrap file(s) it calls).
Any change that affects medication deletion cascade rules.
Recommendation Item Template (copy/paste for backlog)
Title: <Area>: <Short outcome>
Problem:
Proposed change:
Target files:
Acceptance criteria:
Tests required:
Risk level (Low/Med/High):
Notes / dependencies: