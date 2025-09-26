# App Rules

Status: Active

1) Deleting a medication must also delete any schedules linked to that medication.
- On medication delete, cancel notifications for linked schedules and remove those schedules from storage.
- This is a fundamental rule across the app to keep data consistent and avoid orphan schedules.

2) Add/Edit screens styling unification
- All Add/Edit medication screens should use the same sectioned card layout, fonts, paddings, and the centered Save FilledButton.
- Confirm dialogs should center actions.

Change History
- 2025-09-26: Added cascade delete rule for medications → schedules and UI unification rule for Add/Edit screens.
