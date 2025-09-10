# Backlog

This backlog tracks work derived from docs/product-design.md and recent gap analysis. Update continuously.

Status conventions
- Now: Actively working next
- Next: Lined up after Now
- Later: Important but not blocking near-term work

Now
- Supplies core (Milestone A)
  - Data: Hive adapters for Supply and StockMovement
  - Repo: CRUD + stock compute, low-stock helpers
  - UI: /supplies list with low-stock badges, Add/Edit, quick adjust (+/−)
  - Docs: docs/supplies.md
- Calendar (Milestone B) – Agenda-first
  - Route /calendar (agenda for next 2 weeks)
  - Generate events from Schedules (UTC→local), no taken/skipped yet
  - Docs: docs/calendar.md
- Schedules polish (incremental)
  - Multiple times per day
  - Floating summary card on Add/Edit
- Medications list UX
  - Layout toggle (Large/Compact/List)
  - Basic search and sort

Next
- Lyophilized Vial option in Select Injection Type (+ route)
- Settings → Data: Export/Import JSON (local app docs dir)
- Diagnostics: Seed Medications/Schedules/Supplies buttons
- Calendar (Milestone C)
  - DoseLog model + repo
  - Mark taken/skipped; overlay on agenda
  - Optional: decrement Supplies on taken

Later
- Full Calendar Month/Week/Day views with density modes
- Notification Sets UI (tone/vibrate/pre-alert/reminders) – UI only while notifications are de-prioritized
- Visual polish: gradient (#09A8BD → #18537D) and secondary accents (#EC873F)
- CI: analyze/test/build; unit tests for adapters, repos, UTC helpers, calculator math

References
- Product design: docs/product-design.md
- Schedules spec: docs/schedules.md
- Notification investigation: docs/notification_scheduling_investigation.md

