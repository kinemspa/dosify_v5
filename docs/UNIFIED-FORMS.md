# Unified Add/Edit Form Templates

This document describes the shared UI building blocks and the unified Injection Add/Edit page used to guarantee visual parity with the Tablet/Capsule add screens.

Goals:
- Identical look and behavior across all add medication forms
- Left labels with onSurfaceVariant color and bold weight
- 36px-tall fields, unified borders/fill/padding
- Primary-colored section headings and consistent section card decoration
- No RenderFlex overflow on compact dropdowns/steppers

Components

1) SectionFormCard (lib/src/widgets/unified_form.dart)
- Section container with primary-tinted background, subtle border, and shadow
- Title uses colorScheme.primary and titleMedium, fontWeight.w700

2) LabelFieldRow
- Fixed 120px left label column
- Right side hosts Field36-wrapped inputs or compact controls

3) Field36 (existing)
- Wrapper for fixed-height inputs (36px) to ensure uniform vertical rhythm

4) StepperRow36
- [-] [ 120×36 Field36 TextFormField ] [+]
- Use for numeric fields (e.g., Strength, Stock)

5) SmallDropdown36
- 120×36 DropdownButtonFormField wrapper
- Always pass the unified InputDecoration for parity

6) DateButton36
- 120×36 Outlined date button with calendar icon

Decoration

All text inputs and dropdowns on unified screens should use the same InputDecoration as Tablet/Capsule screens. Example (simplified):

- contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)
- constraints: minHeight: 40
- floatingLabelBehavior: never
- hintStyle: bodySmall 11px, color onSurfaceVariant
- filled: true, fillColor: surfaceContainerLowest
- border: 12px radius
- enabledBorder: outlineVariant
- focusedBorder: primary, width 2

Usage: See AddEditInjectionUnifiedPage for canonical implementation.

Unified Injection Page

File: lib/src/features/medications/presentation/add_edit_injection_unified_page.dart

- Supports three kinds via enum InjectionKind { pfs, single, multi }
- Sections: General, Strength, Inventory (+ Expiry), Storage Information
- All rows use LabelFieldRow + Field36, StepperRow36, SmallDropdown36, DateButton36
- Support text lines match Tablet/Capsule styling (bodySmall, onSurfaceVariant)
- Quantity Unit defaults per kind: PFS → pre filled syringes; Single → single dose vials; Multi → multi dose vials

Routing

- /medications/add/injection/pfs → AddEditInjectionUnifiedPage(kind: pfs)
- /medications/add/injection/single → AddEditInjectionUnifiedPage(kind: single)
- /medications/add/injection/multi → AddEditInjectionUnifiedPage(kind: multi)

Migration Notes

- Legacy injection pages remain for edit routes temporarily. If desired, point edit routes to the unified page with the appropriate kind and initial: med.
- Prefer unified_form.dart components for any new forms.

Rules

- Always commit changes to local git
- Avoid bottom-sheet popups; prefer inline content or dialogs
- Keep docs updated when UI patterns change
