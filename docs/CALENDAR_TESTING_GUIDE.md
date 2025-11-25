# Calendar Testing Playbook (Phase 8)

**Last updated**: November 14, 2025  
**Owners**: Scheduling Pod QA (contact #calendar-war-room in Slack)  
**Scope**: Manual + exploratory test coverage for the Calendar experience (Day/Week/Month views, detail embeddings, and dose interactions) before Phase 9 polish.

---

## 1. Why this playbook exists

The original "quick start" bullets left too much interpretation, which resulted in inconsistent validation. This playbook adds:

- A **repeatable environment recipe** (devices, configs, seed data)
- A **scenario matrix** that ties each test to risk, views touched, and exit criteria
- Explicit **pass/fail heuristics** and logging expectations
- A standard **reporting template** so Phase 8 bugs land in the right queues fast

Use it when smoke testing new calendar builds, validating bug fixes, or doing pre-release sign‑off.

---

## 2. Environment & data prerequisites

| Item | Requirement | Notes |
| --- | --- | --- |
| Flutter build | Release profile (`flutter run --release`) | Catch perf issues/regressions
| Devices | Pixel 7 (Android 14), Galaxy Tab S7 (Android 13), iPhone 15 Pro (iOS 18) | Cover phone + tablet + iOS layout quirks
| Feature flags | `calendar_phase8 = true`, `compact_calendar_v2 = true` | Toggle via `app_config.json`
| Test account | `qa.calendar.phase8@dosifi.dev` | Preloaded with medication catalog + settings
| Seed schedules | Import `test_data/calendar_phase8.json` | Contains daily / weekly / cycle templates
| Monitoring | Attach Flutter DevTools performance view | Watch for dropped frames & memory spikes
| Reference docs | `PHASE_8_TEST_SUITE.md`, `CALENDAR_UX_IMPROVEMENTS.md` | Keep open for acceptance criteria

> If you must recreate data manually, follow Appendix A at the end of this file to avoid mismatched anchor dates.

---

## 3. Scenario matrix (run order ≈ 45 minutes)

| ID | Area | Views touched | Risk | Time | Acceptance snapshot |
| --- | --- | --- | --- | --- | --- |
| S1 | Entry points & routing | Home, bottom nav, Med detail, Schedule detail | High | 5 min | All 4 entry points load Calendar without double pushes or stale state |
| S2 | View switching & layout | Day/Week/Month | High | 5 min | Toggle cycles through views, rulers/time indicators render, state persists |
| S3 | Date navigation | Day/Week/Month | High | 5 min | Arrows, swipes, and Today button remain in sync and respect locale start of week |
| S4 | Dose rendering logic | All views | High | 10 min | Daily/weekly/cycle schedules show correct recurrence math |
| S5 | Status coloring & actions | Day/Week | High | 5 min | Pending, Taken, Skipped, Snoozed, Overdue badges/colors match design tokens |
| S6 | Scoped filtering | Embedded calendars | Medium | 5 min | Medication & schedule detail calendars show only scoped doses |
| S7 | Edge + stress cases | Week/Month + data services | Medium | 10 min | Month boundary, midnight dose, stacked doses all behave + no crashes |
| S8 | Non-functional checkpoints | Day/Week, navigation | Medium | Optional 5 min | Perf <500 ms, memory <200 MB, no jank when 50+ events |

Check off each scenario. If any fails, log immediately (see §7) and skip remaining dependent tests until the fix lands.

---

## 4. Detailed procedures & pass criteria

### S1 — Entry points & routing
1. Launch the build cold. Land on Home.
2. Tap **Calendar CTA** (hero card). Expect: full calendar opens, previous route cleared.
3. Back to Home → tap bottom-nav **Calendar** icon. Expect: same screen, state preserved.
4. Open **Medications → select a med** with schedules → scroll to **Dose Calendar** embed. Expect: embed renders scoped view, tapping "See full calendar" deep-links.
5. Open **Schedules → select schedule** → scroll to embed. Expect: same behavior, but limit to the chosen schedule.

✅ Pass when all four entry points work without duplicate pushes, stale headers, or mismatched highlight states.

---

### S2 — View switching & layout
1. From main calendar, note default view (Week unless QA toggled previously).
2. Tap **View toggle** → cycle Day → Week → Month.
   - Day: vertical timeline 6 AM–11 PM, current time indicator (if today), stacked cards not overlapping.
   - Week: 7 columns Mon–Sun (or locale start), current day chip highlighted, grayscale for disabled dates.
   - Month: 6-row grid, out-of-month dates muted, dots/badges within cells.
3. Rotate device to landscape (tablet + phone). Ensure layouts adapt without clipping.

✅ Fail if toggle skips a view, loses scroll position, or reorders doses.

---

### S3 — Date navigation
For each view:
- Tap right/left chevrons → verify increments by day/week/month respectively.
- Swipe left/right (gesture) → same behavior as buttons.
- Tap **Today** → re-centers and scrolls the current item into view.
- Observe URL parameters (if running web build) to ensure they update.

Edge check: move across DST boundary (e.g., first Sunday in November). Confirm Day view stays on correct calendar date (no double 1 AM hour).

✅ Fail if Today misroutes, if gestures fight the page scroll, or if date label desynchronizes.

---

### S4 — Dose rendering logic
Seed schedules (or use appendix): Daily vitamin, Weekly M/W/F, 5-on-2-off cycle anchored last Monday.

1. **Day view (today):** Confirm each event sits in its time slot, uses correct icon, and tapping opens detail sheet with schedule metadata.
2. **Week view:** Validate recurrence distribution (daily = all columns, weekly = specified weekdays, cycle = 5 consecutive cells then 2 blanks).
3. **Month view:** Dot/badge count per cell matches number of doses; long-press reveals quick summary.
4. Jump forward/backward a month to ensure cycle math respects anchor date (no drifting).

Capture screenshots for each view; attach to Jira on failure.

---

### S5 — Status coloring & dose actions
Use an active schedule with manual logging enabled.

1. Locate a future dose → confirm pending color (neutral blue/gray) and hollow icon.
2. Open detail → tap **Mark as taken** → ensure card turns green, checkmark badge appears, aggregate counts update.
3. Duplicate dose → mark as **Skipped** (red) and **Snoozed** (amber) using action sheet.
4. Force an **Overdue** state by setting device clock +30 min or editing schedule time in the past. Expect red background + warning icon.
5. Refresh calendar (pull-to-refresh). Colors persist? Good.

✅ Fail if colors mismatch design tokens (see `CALENDAR_UX_IMPROVEMENTS.md`), statuses do not sync across views, or actions take >1 s to apply.

---

### S6 — Scoped filtering
Goal: ensure embedded calendars respect context.

1. Medication detail page → confirm only schedules for that medication appear. Add a second medication to ensure no bleed.
2. Schedule detail page → confirm only that schedule renders. Toggle status filters (if available).
3. Tap "See full calendar" CTA → ensure filter chips auto-apply matching scope.

✅ Fail if other meds/schedules leak, or the CTA loses context.

---

### S7 — Edge & stress cases

1. **Month boundary:** Navigate to week spanning two months; ensure Week view shows both months and month header updates correctly.
2. **Midnight dose:** Create schedule at 00:00. Day view intentionally hides (timeline 6 AM–11 PM) but Week/Month must still show dots/cards.
3. **Stacked doses:** Create 3 schedules with identical time. Day view should stack (z-order = alphabetical). Week view should show 3 distinct chips. Tap each to confirm hit targets.
4. **Bulk data:** Duplicate daily schedule until you have ~50 events in a week. Scroll Day view; monitor performance overlay for dropped frames (<5) and memory (<200 MB).

✅ Fail on crashes, overlapped cards, or perf metrics outside tolerance.

---

### S8 — Non-functional checklist (optional but recommended)
- Switch views rapidly 10 times → no flicker.
- Toggle dark mode → colors remain accessible (WCAG AA for text on cards).
- Turn off network mid-scroll → offline banner appears, cached data still renders.
- Re-enable network → data refreshes without duplicate toasts.

---

## 5. Critical bug taxonomy

Use these labels in Jira to speed triage:

- **CALC** – Recurrence math (cycle drift, wrong weekdays, missing month/year boundary doses)
- **LAYOUT** – Overlapping cards, wrong grid density, time indicator drift
- **NAV** – Broken Today button, gesture conflicts, date label mismatches
- **STATUS** – Wrong color/badge, action state not propagating, overdue detection
- **PERF** – Scroll jank (>16 ms frame), view toggle >500 ms, memory >200 MB
- **INTEGRATION** – Entry point mismatch, scoped embed leaking data, actions not updating store

When logging, include: build hash, device, scenario ID, reproduction steps, expected vs actual, and screenshots/video.

---

## 6. Reporting template

```
Scenario: [ID + name]
Device / OS / Build: [e.g., Pixel 7 / Android 14 / a1b2c3]
Status: ✅ PASS | ❌ FAIL | ⚠️ PARTIAL
Notes:
  - Observation 1
  - Observation 2
Bugs filed:
  - CALC-123 Broken cycle math when anchor in past
Artifacts: [links to screenshots, perf captures, logs]
```

For exploratory notes, drop them in `PHASE_8_TEST_SUITE.md` under the corresponding scenario so trends are visible.

---

## 7. Exit criteria before Phase 9 handoff

- [ ] All scenarios S1–S8 executed on at least two device classes (phone + tablet or phone + iOS)
- [ ] 0 open **Critical** or **High** bugs tied to CALC/LAYOUT/STATUS categories
- [ ] Performance budget met (Day scroll <16 ms avg frame, view toggle <500 ms)
- [ ] Accessibility spot-check completed (contrast, TalkBack/VoiceOver focus order)
- [ ] Regression sweep on previously closed Jira tickets (see `CALENDAR_UX_IMPROVEMENTS.md` appendix C)

Only after this checkbox set moves to complete should Phase 9 polish start.

---

## 8. Appendix A – Manual data recipe (backup)

Use only if seed JSON import fails. Create three schedules:

1. **Daily Vitamin**
   - Name: Vitamin D 5k
   - Form: Capsule
   - Dose: 1 capsule @ 09:00, every day, active.
2. **Weekly Recovery**
   - Name: Workout Supplement
   - Recurrence: Mon/Wed/Fri @ 18:00, active.
3. **5-on / 2-off Cycle**
   - Name: Peptide Cycle
   - Recurrence: custom cycle 5 days on, 2 off, anchor = most recent Monday, time 08:00.

Verify `Schedules > ... > Advanced` shows correct anchor timestamp before testing.

---

*Questions? Ping @dosifi-qa in Slack. Happy testing! 🧪*
