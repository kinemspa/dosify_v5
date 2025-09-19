# UI Standards for Medication Editors

This document defines the shared visual rules for form controls used across all medication editors (Tablet Hybrid, Capsule, Injection, etc.).

- Field height: 40 px for all single-line TextFields and DropdownButtonFormField controls
- Increment button size: 30 px square
- Input font sizes:
  - Text input: 14
  - Dropdown selected/menu items: 14
  - Help/hint text: 11
- Decoration: Filled surface, 12 px radius, outline on enabled, 2 px primary on focus
- Text scale: Clamp to 1.0 on editor pages to avoid OS scaling affecting control sizes
- Strength row alignment: nudge right by max(20px, kStrengthNudgeFrac * available width)

InputDecoration (shared)

```dart path=null start=null
// Enforces a full 40 px internal height and consistent padding
InputDecoration _dec({String? hint}) => InputDecoration(
  hintText: hint,
  isDense: false,
  isCollapsed: false,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  constraints: const BoxConstraints(minHeight: kFieldHeight), // kFieldHeight = 40
  floatingLabelBehavior: FloatingLabelBehavior.never,
  filled: true,
  // fillColor, borders, and hintStyle follow theme
);
```

Constants

```dart path=null start=null
const double kFieldHeight = 40.0;
const double kBtnSize = 30.0;
const double kInputFontSize = 14.0;
const double kDropdownFontSize = 14.0;
const double kHintFontSize = 11.0;
const double kStrengthNudgeMinPx = 20.0;
const double kStrengthNudgeFrac = 0.03; // 3% of available width
```

Usage guidance

- Always wrap single-line text inputs with SizedBox(height: kFieldHeight) except multi-line fields (e.g., Notes) which auto-expand with maxLines: null
- Apply _dec() for both TextFormField and DropdownButtonFormField
- Center-justify numeric fields and align +/- buttons using the shared sizes; Strength +/- step by 1, Stock +/- step by 0.25 and is locked to tablets
- Keep help text at 11 pt below controls; avoid mixing summaries into help

Propagation

- Apply these standards to Capsule and Injection editors and any new editors.
