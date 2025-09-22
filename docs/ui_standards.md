# UI Standards for Medication Editors

This document defines the shared visual rules for form controls used across all medication editors (Tablet Hybrid, Capsule, Injection, etc.).

- Field height: 36 px for all single-line TextFields and DropdownButtonFormField controls
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
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  constraints: const BoxConstraints(minHeight: kFieldHeight), // kFieldHeight = 36
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

---

General section (compact variant)

- Labels-left, fields-right layout
- Label column width: responsive 110–120 px depending on width (<400: 110, otherwise 120)
- Label cell height: 40px; vertically centered to align with fields
- Card padding: horizontal 8, vertical 6
- Page body padding (SingleChildScrollView): 10, 8, 10, 12
- InputDecoration padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10) to keep 40 px total height
- Hint text: left-aligned, 12 pt (compact variant)
- Border radius: 12 px; outlineVariant on enabled; 2 px primary on focus
- Floating labels disabled (labels are rendered in a separate left column)
- Rows with +/- controls: inset sibling rows by 36 px to align field edges (30 btn + 6 gap)
- Save bar: 48px container, Save button 40px tall, pre-save confirmation dialog shows summary of fields
- Storage: include Batch No., Location (text), Store below (°C) numeric (centered), Cold storage (toggle), Light sensitive (toggle), Storage instructions (text)

Hybrid Tablet Specifics

- Strength
  - Amount field centered; +/- buttons step by 1 (whole numbers)
  - Keyboard allows up to 2 decimals; deletion to empty allowed
  - mcg/mg/g units; ensure dropdown text is not cropped
- Inventory
  - Stock input centered, 2 decimals; +/- step by 0.25
  - Live validation for quarter steps (.00, .25, .50, .75); show inline error
  - Unit locked to "tablets" (disabled dropdown)
  - Optional low-stock alert with threshold field
- Expiry
  - 40px OutlinedButton with calendar icon; shows chosen date
- Save & Confirmation
  - Save button 40px tall, centered
  - Pre-save confirmation dialog with styled summary and detailed rows
- Routing
  - Add → Tablet and Edit Tablet both open the same single hybrid page (no menus/toggles). A dedicated hybrid route may exist only for testing.
