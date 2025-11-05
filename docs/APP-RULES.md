# App Rules

Status: Active

## CRITICAL: ALWAYS USE CENTRALIZED DESIGN SYSTEM

**NEVER hardcode colors, spacing, borders, or styling inline in feature files.**

Before implementing ANY UI element:
1. Check `lib/src/core/design_system.dart` for existing constants (spacing, radii, opacity, colors)
2. Check `lib/src/widgets/` for existing centralized widgets
3. If it doesn't exist, CREATE it in the appropriate centralized location FIRST
4. THEN use the centralized code in your implementation

**Violations:**
- Using `Colors.blue`, `Color(0xFF...)`, or Material 3 theme colors directly (use design_system.dart colors)
- Hardcoding padding values like `EdgeInsets.all(12)` (use kSpacingXS, kSpacingS, kSpacingM, etc.)
- Hardcoding border radius like `BorderRadius.circular(8)` (use kBorderRadiusS, kBorderRadiusM, etc.)
- Creating duplicate widgets across files (create ONE centralized version)
- Using inline `Container` decorations when a reusable card/button widget should exist

**This rule applies to EVERY change, EVERY feature, EVERY card, EVERY button.**

---

1) Deleting a medication must also delete any schedules linked to that medication.
- On medication delete, cancel notifications for linked schedules and remove those schedules from storage.
- This is a fundamental rule across the app to keep data consistent and avoid orphan schedules.

2) Add/Edit screens styling unification
- All Add/Edit medication screens should use the same sectioned card layout, fonts, paddings, and the centered Save FilledButton.
- Confirm dialogs should center actions.

Change History
- 2025-11-05: Added CRITICAL rule to ALWAYS use centralized design system - no inline styling, check design_system.dart and widgets/ first
- 2025-09-26: Added cascade delete rule for medications → schedules and UI unification rule for Add/Edit screens.
