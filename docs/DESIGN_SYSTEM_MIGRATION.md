# Design System Migration Guide

## Overview

This guide explains how to migrate existing pages to use the centralized design system defined in `lib/src/core/design_system.dart`.

## Problem Statement

Currently, many pages in the app have inconsistent styling:
- Custom `InputDecoration` created in each page
- Hardcoded padding and spacing values
- Inconsistent helper text positioning
- Different field heights and border styles
- Varying color opacity values

The **reference implementation** (`med_editor_template_demo_page.dart`) shows the correct styling, but other pages don't follow it.

## Solution

All styling is now centralized in `design_system.dart`. Every page **MUST** use the helpers and constants from this file.

---

## Quick Migration Checklist

When migrating a page, check off each item:

```dart
/// [ ] Import design_system.dart
/// [ ] Replace InputDecoration with buildFieldDecoration()
/// [ ] Wrap fields in Field36
/// [ ] Use LabelFieldRow for all label+field pairs  
/// [ ] Replace helper text with buildHelperText()
/// [ ] Use sectionSpacing between sections
/// [ ] Apply kPagePadding to ScrollView
/// [ ] Use StepperRow36 for numbers
/// [ ] Use SmallDropdown36 for dropdowns
/// [ ] Use DateButton36 for dates
/// [ ] Remove all custom styling constants
```

---

## Before & After Examples

### Example 1: Text Field

#### ❌ BEFORE (Inconsistent)
```dart
TextField(
  controller: _nameController,
  decoration: InputDecoration(
    hintText: 'Enter name',
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    contentPadding: EdgeInsets.all(12),
  ),
)
```

#### ✅ AFTER (Design System)
```dart
Field36(
  child: TextField(
    controller: _nameController,
    decoration: buildFieldDecoration(context, hint: 'Enter name'),
  ),
)
```

---

### Example 2: Helper Text

#### ❌ BEFORE (Inconsistent)
```dart
Padding(
  padding: const EdgeInsets.only(left: 120, top: 4, bottom: 8),
  child: Text(
    'Enter your medication name',
    style: TextStyle(
      fontSize: 12,
      color: Colors.grey[600],
    ),
  ),
)
```

#### ✅ AFTER (Design System)
```dart
buildHelperText(context, 'Enter your medication name')
```

---

### Example 3: Form Section

#### ❌ BEFORE (Inconsistent)
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey[300]!),
  ),
  child: Column(
    children: [
      Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('Name:'),
          ),
          Expanded(child: nameField),
        ],
      ),
      SizedBox(height: 4),
      Padding(
        padding: EdgeInsets.only(left: 100),
        child: Text('Help text', style: TextStyle(fontSize: 11)),
      ),
    ],
  ),
)
```

#### ✅ AFTER (Design System)
```dart
SectionFormCard(
  title: 'General',
  neutral: true,
  children: [
    LabelFieldRow(label: 'Name', field: nameField),
    buildHelperText(context, 'Enter medication name'),
  ],
)
```

---

### Example 4: Complete Page Structure

#### ❌ BEFORE (Inconsistent)
```dart
Scaffold(
  appBar: AppBar(title: Text('Add Schedule')),
  body: Padding(
    padding: EdgeInsets.all(20),
    child: Column(
      children: [
        // Custom layouts everywhere
        Container(...),
        SizedBox(height: 15),
        Container(...),
      ],
    ),
  ),
)
```

#### ✅ AFTER (Design System)
```dart
Scaffold(
  appBar: GradientAppBar(title: 'Add Schedule'),
  body: Stack(
    children: [
      SingleChildScrollView(
        padding: kPagePadding,
        child: Column(
          children: [
            SizedBox(height: _summaryHeight + 10),
            SectionFormCard(title: 'General', neutral: true, children: [...]),
            sectionSpacing,
            SectionFormCard(title: 'Schedule', neutral: true, children: [...]),
          ],
        ),
      ),
      Positioned(
        left: 16,
        right: 16,
        top: 8,
        child: summaryCard,
      ),
    ],
  ),
)
```

---

## Component Reference

### 1. Text Fields

```dart
// Standard text field
Field36(
  child: TextField(
    controller: controller,
    decoration: buildFieldDecoration(context, hint: 'hint text'),
  ),
)

// With validation
Field36(
  child: TextFormField(
    controller: controller,
    decoration: buildFieldDecoration(context, hint: 'hint'),
    validator: (v) => validateRequired(v, fieldName: 'Name'),
  ),
)
```

### 2. Numeric Fields

```dart
// Integer stepper
StepperRow36(
  controller: controller,
  onDec: () => /* decrement logic */,
  onInc: () => /* increment logic */,
  decoration: buildCompactFieldDecoration(hint: '0'),
)
```

### 3. Dropdowns

```dart
SmallDropdown36<MyType>(
  value: currentValue,
  width: kSmallControlWidth,
  items: [
    DropdownMenuItem(value: val1, child: Center(child: Text('Option 1'))),
    DropdownMenuItem(value: val2, child: Center(child: Text('Option 2'))),
  ],
  onChanged: (v) => setState(() => currentValue = v!),
)
```

### 4. Date Pickers

```dart
DateButton36(
  label: selectedDate == null 
    ? 'Select date'
    : MaterialLocalizations.of(context).formatCompactDate(selectedDate!),
  onPressed: () async {
    final picked = await showDatePicker(/* ... */);
    if (picked != null) setState(() => selectedDate = picked);
  },
  width: kSmallControlWidth,
  selected: selectedDate != null,
)
```

### 5. Checkboxes

```dart
Row(
  children: [
    Checkbox(
      value: checked,
      onChanged: (v) => setState(() => checked = v ?? false),
    ),
    Text('Label', style: checkboxLabelStyle(context)),
  ],
)
```

### 6. Helper Text

```dart
// Standard helper
buildHelperText(context, 'This is helper text')

// Colored helper (e.g., error)
buildHelperText(
  context,
  'Warning message',
  color: Theme.of(context).colorScheme.error,
)
```

---

## Constants Reference

### Spacing
```dart
kPagePadding              // EdgeInsets.fromLTRB(16, 16, 16, 100)
kSectionSpacing           // 12.0
kHelperTextLeftPadding    // kLabelColWidth + 8
kHelperTextTopPadding     // 2.0
kHelperTextBottomPadding  // 6.0
```

### Opacity
```dart
kHelperTextOpacity        // 0.75
kDisabledOpacity          // 0.5
kCardBorderOpacity        // 0.5
```

### Widget Helpers
```dart
sectionSpacing            // SizedBox(height: kSectionSpacing)
```

---

## Migration Steps (Detailed)

### Step 1: Add Import

```dart
import 'package:dosifi_v5/src/core/design_system.dart';
```

### Step 2: Update Page Structure

Replace custom padding with standard structure:

```dart
SingleChildScrollView(
  padding: kPagePadding,  // ← Use this
  child: Column(/* ... */),
)
```

### Step 3: Convert Sections

Replace custom containers with:

```dart
SectionFormCard(
  title: 'Section Title',
  neutral: true,
  children: [
    // fields here
  ],
)
```

### Step 4: Convert Fields

For each field:
1. Wrap in `Field36` (if text field)
2. Use `buildFieldDecoration()` for decoration
3. Use `LabelFieldRow` for label+field layout
4. Add `buildHelperText()` after the field

### Step 5: Add Spacing

Between sections:
```dart
sectionSpacing  // or const SizedBox(height: kSectionSpacing)
```

### Step 6: Clean Up

Remove:
- Custom `InputDecoration` functions
- Hardcoded padding constants
- Custom helper text widgets
- Custom spacing values

---

## Common Patterns

### Pattern: Required Field with Helper

```dart
LabelFieldRow(
  label: 'Name *',
  field: Field36(
    child: TextFormField(
      controller: _nameController,
      decoration: buildFieldDecoration(context, hint: 'Enter name'),
      validator: (v) => validateRequired(v, fieldName: 'Name'),
    ),
  ),
),
buildHelperText(context, 'Enter the medication name'),
```

### Pattern: Numeric Field with Range

```dart
LabelFieldRow(
  label: 'Dose *',
  field: StepperRow36(
    controller: _doseController,
    onDec: () {
      final v = int.tryParse(_doseController.text) ?? 0;
      setState(() => _doseController.text = (v - 1).clamp(1, 999).toString());
    },
    onInc: () {
      final v = int.tryParse(_doseController.text) ?? 0;
      setState(() => _doseController.text = (v + 1).clamp(1, 999).toString());
    },
    decoration: buildCompactFieldDecoration(hint: '0'),
  ),
),
buildHelperText(context, 'Enter dose amount (1-999)'),
```

### Pattern: Dropdown with Unit

```dart
LabelFieldRow(
  label: 'Unit *',
  field: SmallDropdown36<Unit>(
    value: _selectedUnit,
    width: kSmallControlWidth,
    items: [
      DropdownMenuItem(value: Unit.mg, child: Center(child: Text('mg'))),
      DropdownMenuItem(value: Unit.mcg, child: Center(child: Text('mcg'))),
    ],
    onChanged: (v) => setState(() => _selectedUnit = v!),
  ),
),
buildHelperText(context, 'Select the unit of measurement'),
```

---

## Testing Your Migration

After migrating a page, verify:

1. ✅ All fields have consistent height (kFieldHeight = 36)
2. ✅ All borders look the same (12px radius, correct opacity)
3. ✅ Helper text is consistently positioned
4. ✅ Section spacing is 12px
5. ✅ Colors match the theme (no hardcoded values)
6. ✅ Compact controls (dropdowns, date buttons) are kSmallControlWidth
7. ✅ Page padding is kPagePadding
8. ✅ No console warnings about inconsistent styling

---

## Priority Pages to Migrate

1. **High Priority:**
   - add_edit_schedule_page.dart
   - schedule_summary_card.dart
   - Any user-facing form pages

2. **Medium Priority:**
   - Settings pages
   - List pages with filters

3. **Low Priority:**
   - Debug pages
   - Internal tool pages

---

## Getting Help

If you're unsure about how to migrate a specific component:

1. Check `med_editor_template_demo_page.dart` for reference
2. Look for similar components in migrated pages
3. Review the constants and helpers in `design_system.dart`
4. Check this guide's examples

---

## Summary

**The Rule:** Never create custom styling in pages. Always use `design_system.dart`.

**The Goal:** Every page looks like it came from the same template - because it did!

**The Benefit:** Consistent, professional UI that's easy to maintain and update.
