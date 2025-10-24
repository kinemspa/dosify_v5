# Styling Centralization Audit

**Date:** 2025-01-24  
**Issue:** Inline styling scattered across 25+ files instead of using centralized design system

## Critical Problem

The app has a design system (`lib/src/core/design_system.dart`) with centralized styling functions like:
- `buildFieldDecoration()` - Standard input decoration
- `buildCompactFieldDecoration()` - For steppers/dropdowns
- `buildHelperText()` - Helper text positioning
- Border constants (`kOutlineWidth`, `kFocusedOutlineWidth`)
- Spacing constants

**BUT** almost no files are using it. Instead, every file creates its own `InputDecoration` inline with different:
- Border widths (some 0.75px, some 1px, some use defaults)
- Border colors (inconsistent opacity values)
- Border radius (some 12px, some 8px, some 10px)
- Padding (various values)
- Fill colors (inconsistent)

## Impact

1. **Inconsistent UI** - Fields look different across the app
2. **Unmaintainable** - Changing border style requires editing 25+ files
3. **Error-prone** - Easy to miss files during updates
4. **Poor developer experience** - No single source of truth

## Files with Inline InputDecoration (25+ files)

### HIGH PRIORITY (User-facing forms)
1. ✅ `med_editor_template_demo_page.dart` - **REFERENCE IMPLEMENTATION** (MUST FIX FIRST)
2. ❌ `add_edit_tablet_general_page.dart` - Tablet form
3. ❌ `add_edit_capsule_page.dart` - Capsule form
4. ❌ `add_edit_injection_pfs_page.dart` - Pre-filled syringe form
5. ❌ `add_edit_injection_single_vial_page.dart` - Single dose vial form
6. ❌ `add_edit_injection_multi_vial_page.dart` - Multi dose vial form
7. ❌ `add_edit_injection_unified_page.dart` - Unified injection form
8. ⚠️ `add_edit_schedule_page.dart` - Schedule form (partially migrated)
9. ❌ `supplies_page.dart` - Supply management

### MEDIUM PRIORITY (Supporting pages)
10. ❌ `medication_list_page.dart` - Search field
11. ❌ `schedules_page.dart` - Search/filter
12. ❌ `unified_add_edit_medication_page.dart` - Unified form
13. ❌ `unified_add_edit_medication_page_template.dart` - Template
14. ❌ `add_edit_tablet_hybrid_page.dart` - Hybrid tablet form
15. ❌ `reconstitution_calculator_page.dart` - Calculator
16. ❌ `reconstitution_calculator_widget.dart` - Calculator widget
17. ❌ `mdv_volume_reconstitution_section.dart` - MDV section

### LOW PRIORITY (Debug/Settings/Widgets)
18. ❌ `add_tablet_debug_page.dart` - Debug page
19. ❌ `strength_input_styles_page.dart` - Settings
20. ❌ `strength_input.dart` - Widget
21. ❌ `stepper_field.dart` - Widget
22. ❌ `form_field_styler.dart` - Old styler (possibly obsolete?)
23. ❌ `app.dart` - Theme definition
24. ⚠️ `unified_form.dart` - Form widgets (uses some constants but not buildFieldDecoration)

## Specific Issues Found

### Example 1: Inconsistent Borders
**File:** `med_editor_template_demo_page.dart` (line 30-61)
```dart
// Custom _dec() method with:
enabledBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5), width: kOutlineWidth),
)
```

**File:** `add_edit_tablet_general_page.dart`
```dart
// Different custom method with different opacity
// Uses inline OutlineInputBorder with varying widths
```

**Design System:** `buildFieldDecoration()` exists but not used

### Example 2: Missing Borders
**File:** `med_editor_template_demo_page.dart` StepperRow36 (line 186-192)
```dart
decoration: const InputDecoration(
  hintText: '0',
  isDense: false,
  // NO BORDER STYLING AT ALL - uses Flutter defaults!
)
```

Should use `buildCompactFieldDecoration(hint: '0')`

### Example 3: Inline Padding
Multiple files have custom contentPadding values instead of using design system constant.

## Solution Plan

### Phase 1: Fix the Reference Implementation (CRITICAL)
✅ **File:** `med_editor_template_demo_page.dart`
- Replace `_dec()` method with `buildFieldDecoration()`
- Update all StepperRow36 to use `buildCompactFieldDecoration()`
- Ensure this is the SINGLE SOURCE OF TRUTH

### Phase 2: Migrate User-Facing Forms
Priority order:
1. Tablet forms
2. Capsule forms
3. Injection forms (all variants)
4. Schedule form (complete)
5. Supplies page

### Phase 3: Migrate Supporting Pages
1. List pages
2. Calculator pages
3. Template pages

### Phase 4: Migrate Widgets and Low Priority
1. Widget files
2. Debug pages
3. Settings pages

### Phase 5: Enforcement
1. Add lint rules to prevent new inline InputDecoration
2. Add build-time warnings
3. Update documentation
4. Code review checklist

## Design System Functions

### For Regular Text Fields
```dart
Field36(
  child: TextField(
    decoration: buildFieldDecoration(context, hint: 'Enter name'),
  ),
)
```

### For Steppers/Compact Controls
```dart
StepperRow36(
  controller: controller,
  onDec: () {},
  onInc: () {},
  decoration: buildCompactFieldDecoration(hint: '0'),
)
```

### For Dropdowns (within SmallDropdown36)
Already handled by `SmallDropdown36` widget - no decoration needed

## Migration Checklist (Per File)

- [ ] Import design_system.dart
- [ ] Find all `InputDecoration(` instances
- [ ] Replace with `buildFieldDecoration(context, hint: '...')` or `buildCompactFieldDecoration(hint: '...')`
- [ ] Remove any custom decoration builder methods (e.g., `_dec()`)
- [ ] Test that borders look identical to reference implementation
- [ ] Verify focus states work correctly
- [ ] Check error states display properly

## Expected Outcome

After migration:
1. **Single change point** - Update border width in design_system.dart, all 25+ files update automatically
2. **Consistent UI** - All fields have identical borders, padding, colors
3. **Maintainable** - Clear where styling is defined
4. **Documented** - Design system has examples and rules

## Timeline

- **Phase 1 (Reference):** 1 hour - FIX TODAY
- **Phase 2 (User forms):** 3-4 hours - High priority
- **Phase 3 (Supporting):** 2 hours - Medium priority
- **Phase 4 (Widgets/Low):** 2 hours - Low priority
- **Phase 5 (Enforcement):** 1 hour - Documentation and rules

**Total:** ~9 hours to completely centralize all styling

## Success Metrics

- [ ] Zero files with inline `InputDecoration(` outside of design_system.dart
- [ ] All fields visually identical across app
- [ ] Border width changeable in 1 place only
- [ ] No custom decoration builder methods in pages
- [ ] Lint rules prevent new inline decoration
