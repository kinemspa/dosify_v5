# Changelog

All notable changes to this project will be documented in this file. Dates in UTC.

## Unreleased
- Tablet editor: General, Strength, Inventory, Storage sections implemented with hybrid layout (40px controls)
- UI polish: label vertical centering, fake vendor hints, dropdown styling, reduced save bar height
- Save flow: pre-save confirmation dialog and Hive persistence for Tablet via MedicationRepository
- Settings: Added theme mode switch (System/Light/Dark) with persistence. MaterialApp now respects the chosen ThemeMode.
- Medications: Medication Details sections styled with primary-accent headers, onSurfaceVariant labels, and outlined surface cards.
- Medications: New alternate Add/Edit Tablet pages:
  - Details-style: label left, value right; tap rows to edit via dialog/sheet. Routes: /medications/add/tablet/details, /medications/edit/tablet/details/:id.
  - Hybrid: looks like Details but with inline fields (no pop dialogs). Routes: /medications/add/tablet/hybrid, /medications/edit/tablet/hybrid/:id.
  - Both link from the standard editor via overflow menu.
- Schedules: Added typed dose UI to Add/Edit Schedule with live formula line per med type. On save, normalized typed fields are stored (micrograms, microliters, tablet quarters, whole counts, IU).
- Schedules: Schedules list now has a Take action that decrements medication stock according to normalized schedule and medication stock units (including MDV mL mapping).
- Scheduling: Added typed dose scaffolding (DoseUnit/DoseInputMode codes) and normalized fields (micrograms, microliters, tablet quarters, whole counts, IU). Backward compatible with existing fields.
- Medications: Large cards made significantly more compact (increased grid childAspectRatio, reduced paddings/avatar size, smaller secondary text). Removed stock/progress bar; retained typographic lines only. Injection type chips now show exact type label. Manufacturer shown next to name; strength line includes form (e.g., “10 mg Pre‑Filled Syringes”); expiry moved under status icons; stock text shows ratio and colors by percentage; compact grid is thinner; per-form icons added; PFS summary reworded with action buttons placeholder.
- Compact Cards: Restored style with form chip; layout is chip, then strength, then remaining stock; short expiry (“Exp dd/MM/yy”).
- List View: Typography now matches cards (bold name, primary strength, colored stock text), expiry shows “Expires: dd/MM/yy”.
- Large Cards: Action buttons positioned bottom-right; removed Take button (Refill only); space reserved to avoid overflow on small devices.
- Layout Toggle: Single toolbar button cycles Large → Compact → List and persists selection.
- Medication Details: Grouped sections (Identity, Strength & Composition, Inventory, Storage, Notes); “Form” renamed to “Medication Type”; expiry formatted dd/MM/yy.
- Housekeeping: Consolidated documentation into minimal set (README, docs/CHANGELOG.md, docs/product-design.md, docs/NOTIFICATIONS.md). Superseded docs now point here.

## [5.2.11] - 2025-09-12
- Dark mode: InputDecorationTheme.fillColor is now theme-aware (light: surfaceContainerLowest, dark: surfaceContainerHigh). Removed hard-coded whites from FormFieldStyler and section defaults.
- Deprecations: Replaced MaterialStatePropertyAll with WidgetStatePropertyAll where applicable; migrated many color.withOpacity(x) calls to color.withValues(alpha: x). Remaining occurrences mainly in settings preview pages.
- Pill Group rollout: Confirmed consistent use on Medications (all forms), Supplies (Add + Adjust), and Schedules dose inputs.

## [5.2.10] - 2025-09-11
- Schedules: Overhauled Add/Edit UX (full-screen med selector; auto name; per-form unit defaults; multiple times/day; day-of-week chips; Every N days; stable IDs).
- Supplies: Fixed undefined _qtyBtn in Stock Adjust by adding local helper matching unified control.
- Build: Verified debug build after changes.

## [5.2.9] - 2025-09-10
- UI standardization across Capsule, Pre-Filled Syringe, Single Dose Vial, and Multi Dose Vial Add/Edit pages (GradientAppBar; FAB Save/Update; compact summary; outlined+filled fields; Pill Group control; center-aligned dropdowns; consistent inventory/storage cards; dark mode alignment).
- Multi Dose Vial: Low stock options added (vial volume threshold and "Vials in Reserve"); removed legacy sticky summary bar; fixed trailing bracket/semicolon.
- Deprecation cleanup (WidgetStatePropertyAll, withValues) applied widely; remaining spots in settings preview.

## [5.2.8] - 2025-09-10
- Pill buttons: Clear primary-color ripple using Ink + InkWell (StrengthInput + Add Tablet).
- Removed outer outline from StrengthInput wrapper; now uses theme.primary ~1% tint.
- Global: Removed underline inputs (OutlineInputBorder via theme and FormFieldStyler).
- Add Tablet: Stabilized header height (removed AnimatedSize).

## [5.2.7] - 2025-09-10
- Strength Input – Pill group: Outlined boxes, compact paddings, themed focus border; centered dropdown menu; Expanded to avoid overflow.
- Runtime Pill group variant implemented in shared StrengthInput widget.
- Settings: Removed Strength Card Styles samples and route.

## [5.2.6] - 2025-09-10
- Sample style screens: Responsive and stable (ListView, adjusted aspect ratios for small devices).
- Medication list (large cards): Icon/avatar left; removed duplicate name/manufacturer; compact metrics row.

## [5.2.5] - 2025-09-10
- Settings: New Form Field Styles page with 10 input styles (excluding summary). Persisted to Add Tablet.
- Settings: Strength Input Styles updated to 10 chip-based variants; persisted via SharedPreferences.
- Add Tablet: Applies selected variants to sections.

## [5.2.4] - 2025-09-10
- Number formatting: fmt2 now removes only fractional trailing zeros; integers remain intact (10.00 → "10").
- Add Tablet: Save moved to bottom-centered FloatingActionButton.extended; confirmation dialog shows gradient summary + full details.
- Medication list: Large card visual updates (bold name, light grey brand, primary-colored strength and stock, gradient logo/avatar).

## [5.2.3] - 2025-09-10
- Add Tablet header: Dynamic height, reduced excess padding, fixed render overflow while editing strength.
- Large cards: Increased GridView cell height to prevent overflow.
- Settings: Strength Input Styles preview page added.

## [5.2.2] - 2025-09-09
- Fixed invalid spread-operator conditionals in medication_list_page to restore compilation.
- Corrected toolbar conditional rendering, dense vs large card display, and Column nesting.

## [5.2.1] - 2025-09-09
- Button styling: Save buttons changed from dark to lighter gray.
- Fixed RenderFlex overflow with refrigeration option.
- Preserved gradient backgrounds across medication forms.

## Technical notes (current)
- Tooling: Tested with Flutter 3.24.x, Dart 3.8.x (see pubspec.yaml for exact constraints).
- Android: minSdk 24, targetSdk 35; permissions include POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS.
- Notifications: Immediate notifications work. Scheduled notifications (exact/inexact/AlarmClock) currently not delivered in certain environments; feature de‑prioritized (see docs/NOTIFICATIONS.md).

## Known issues
- Lints: Style warnings (line length, remaining withOpacity uses in some preview pages, import organization); non-breaking.
- Automated tests: Unit/integration test coverage to be expanded.
