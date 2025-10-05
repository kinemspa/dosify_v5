# Technical Overview — Dosifi v5

Architecture
- Flutter (Dart 3.x) mobile app, Android-first
- State management: Riverpod
- Navigation: go_router
- Local storage: Hive (adapters via build_runner)
- Notifications: flutter_local_notifications (+ timezone)
- Styling: Material 3, Google Fonts (primary gradient #09A8BD → #18537D)

Structure (selected)
- lib/src/app: app scaffold, router, theming
- lib/src/core: cross-cutting util (formatting, prefs, hive bootstrap, notifications)
- lib/src/features: feature-oriented modules (medications, schedules, calendar, etc.)

Medications module (in-progress)
- Tablet screens:
  - add_edit_tablet_page.dart (primary/hybrid WIP)
  - add_edit_tablet_hybrid_page.dart (hybrid detailed form)
  - add_edit_tablet_details_style_page.dart (details-style form)
- Shared components: FormFieldStyler, StrengthInput, AppHeader
- Design spec reference: docs/product-design.md (section: Add/Edit Medication – Tablet)

Conventions
- Use package: imports for files under lib/
- Keep sections ordered: General → Strength → Inventory → Storage
- Provide a live summary block that updates from form input
- Prefer unified input widgets for numeric steppers and dropdowns

Build & tooling
- flutter pub get
- Codegen: flutter packages pub run build_runner build --delete-conflicting-outputs
- Analyze: flutter analyze (very_good_analysis configured)
- Format: dart format .

Android specifics
- applicationId: com.dosifi.app
- namespace: com.dosifi.dosifi_v5
- compileSdk/targetSdk as in android/app/build.gradle.kts

Notifications (architecture and delivery)
- Library: flutter_local_notifications ^17.x with timezone support
- Storage model: we save schedule times as UTC minutes (and UTC weekdays) and convert to local tz when scheduling; this avoids DST and timezone drift.
- Scheduling strategy:
  - Cycle (every N days): schedule one-shot occurrences for the next ~30 cycle days (UTC-safe), AlarmClock mode for delivery.
  - Weekly: schedule one-shot occurrences for the next 60 days (UTC-safe), AlarmClock mode for delivery (preferred for OEM reliability).
  - Cancel logic removes those one-shot IDs for both cycle and weekly.
- AndroidManifest receivers (Android 12+/OEM reliability):
  - com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver (exported=true)
  - com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver (exported=true) with intent-filter for BOOT_COMPLETED and MY_PACKAGE_REPLACED
  - com.dexterous.flutterlocalnotifications.ScheduledNotificationTimeZoneChangeReceiver (exported=true) with TIME_CHANGED, TIME_SET, TIMEZONE_CHANGED
  - Permissions include POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
- In-app preflight checks at save time: ensure POST_NOTIFICATIONS granted; check areNotificationsEnabled and canScheduleExactAlarms; offer settings intents for remediation.
- Diagnostics (Settings > Diagnostics):
  - 5s ladder test (T+5 exact, T+6 AlarmClock, T+7 backup show) on high-importance test_alarm channel
  - Direct 5s (no scheduling) on test_alarm channel to validate UX/timing in foreground
  - 2-minute tests (AlarmClock and exact) on test_alarm channel
  - Debug dump prints tz.local, offsets, pendingNotificationRequests, areNotificationsEnabled, canScheduleExactAlarms
- Channels:
  - upcoming_dose (High) for production reminders
  - low_stock, expiry (Default)
  - test_alarm (Max) for diagnostics with short delays

Notes & next steps
- Many analyzer infos/warnings are style/order issues; plan a cleanup pass after UI layout is stabilized.
- Ensure every file ends with a newline (eol_at_end_of_file) and prefer package imports.

UI Blueprint Adoption
- Add Capsule screen now mirrors the Add Tablet blueprint:
  - 36px field height via Field36 and per-field InputDecoration constraints
  - Sections and rows: General → Strength → Inventory → Storage
  - Helper texts on their own rows (centered for dual-field rows, left for single-field)
  - Centered pill-style Save FAB
  - Storage toggles (Refrigerate/Freeze/Dark) with helpers
- Apply the same pattern for all medication forms going forward.

Dropdown alignment
- Unit and quantity dropdowns are centered within a 120px-wide box with a 36px control height, matching the integer fields. Do not use manual pixel padding for alignment; rely on center alignment inside the fixed-width box instead.

Surfaced validation in helper rows (with touched gating)
- Default InputDecoration error line is hidden to preserve the 36px control height.
- Validation messages are surfaced in the helper row beneath the field.
- Errors are only shown AFTER a field has been interacted with (touched) or after an attempted form submit. This prevents red "Required" messages on initial load.
- Implementation: per-field flags like _touchedName and a form-level _submitted gate the display of helper errors.

Checkbox tone and long-label behavior
- Checkbox labels use kCheckboxLabelStyle(context) (darker than support text but lighter than primary labels).
- When a checkbox is disabled by another control (e.g., Refrigerate disabled when Freeze is ON), render its label with kMutedLabelStyle(context) to visually indicate it isn't available.
- Long checkbox labels (e.g., "Enable alert when stock is low") must be wrapped with Expanded and allow softWrap to avoid overflow on small screens.

Theme-only fonts (no inline sizes)
- All text sizing is sourced from ThemeData and InputDecorationTheme; no inline copyWith(fontSize: …) on pages.
- Key sizes (subject to design updates):
  - textTheme.bodyMedium = 12sp (input text, dropdown text, regular labels)
  - textTheme.bodySmall = 11sp (helper texts, compact secondary text)
  - textTheme.titleSmall = 15sp (section titles)
  - textTheme.labelLarge = 12sp (button labels)
- Hint and helper colors derive from the theme:
  - hintStyle: from textTheme.bodyMedium with onSurfaceVariant tint
  - helperStyle: from textTheme.bodySmall with onSurfaceVariant tint
- Checkbox "muted" labels derive from textTheme.bodyMedium with onSurfaceVariant color via kMutedLabelStyle(context).
- If a visual adjustment is needed, update the shared theme in lib/src/app/app.dart rather than setting sizes locally.

Reconstitution Calculator Formula
- Implementation: ReconstitutionCalculatorWidget in lib/src/features/medications/presentation/
- Core calculation formula:
  - Vial Volume (V) = (S / D) × (U / 100)
  - Concentration (C) = D × (100 / U)
  - Where:
    - S = total strength in vial (mg, converted to base units)
    - D = desired dose per injection (mg, converted to base units)
    - U = IU units to draw from syringe (based on syringe capacity: 0.3mL=30IU, 0.5mL=50IU, 1mL=100IU, etc.)
    - V = vial volume in mL (solvent to add for reconstitution)
    - C = concentration per mL after reconstitution
- Unit conversion via _toBaseMass(): g→mg (*1000), mcg→mg (/1000), mg→mg (1:1)
- Option generation: calculator provides 3 reconstitution options (More concentrated/Balanced/More diluted) using min, mid, max IU ranges within slider bounds
- UI styling (standardized):
  - Layout rows use LabelFieldRow for consistent label column and spacing
  - Heading: "Reconstitution Calculator" in titleMedium, primary color, bold
  - Usage helper under title: "Enter dose and unit, choose syringe size, then pick an option or adjust the IU slider to see vial volume and concentration."
  - Diluent: Field36 text input for reconstitution fluid name (e.g., "Sterile Water")
  - Desired Dose + Dose Unit: Combined row with StepperRow36 (integer stepper) + SmallDropdown36; single helper beneath: "Enter the amount per dose and select its unit"
  - Syringe Size: SmallDropdown36 with kSmallControlWidth (120px), labels shortened to "0.3 mL", "0.5 mL", "1.0 mL", "3.0 mL", "5.0 mL" (no IU display in dropdown)
  - Vial Quantity (before dilution): StepperRow36 with integer-only input matching Desired Dose styling; helper: "Enter the total amount of drug in your vial (before dilution)"
  - Max Vial (mL): Integer-only StepperRow36 for maximum vial volume constraint
  - Reconstitution Options section: Vertical column of clickable rows (left side: title + subtitle + calc values, right side: Radio selector); no grey background on inactive options; border on selected
  - Options wording: "More concentrated" (lower volume, higher concentration), "Balanced" (midpoint), "More diluted" (higher volume, lower concentration)
  - Slider section: "Adjust IU draw" label with helper: "Adjust the IU draw for this syringe"
  - Inline syringe gauge removed from calculator UI
  - Action button text: "Save Reconstitution" (previously "Apply to vial" or "Submit")
  - Support text: kMutedLabelStyle(context)
  - Label styles: bodyMedium bold, 14sp, onSurfaceVariant at ~75% opacity
- ReconstitutionResult data model:
  - Extends to include optional diluentName field for tracking the reconstitution fluid name
  - Fields: perMlConcentration, solventVolumeMl, recommendedUnits, syringeSizeMl, diluentName (nullable String)
  - Passed from calculator widget/page/dialog to parent components for persistence and display
- WhiteSyringeGauge widget (lib/src/widgets/white_syringe_gauge.dart):
  - Reusable widget for visualizing reconstitution syringe fill in summary cards
  - PRIMARY COLOR styling: uses theme primary color for all elements (lines, ticks, fill, labels)
  - Thicker lines (2px baseline, 2px ticks, 8px fill with rounded caps)
  - IU markers shown on both major (50 IU) AND minor (10 IU) intervals
  - Numbers positioned BELOW horizontal baseline with proper padding (no overlap)
  - Ticks aligned to NOT protrude below baseline
  - Takes totalIU, fillIU, and optional color parameters
  - Canvas height: 44px (increased for label spacing)
  - Numbers displayed with padding to prevent collision
  - Integrated into CALCULATOR WIDGET for live preview (displays during calculation, before save)
  - Integrated into SummaryHeaderCard via optional reconTotalIU/reconFillIU parameters
  - Usage: Pass reconstitution IU data to display graphical syringe gauge with theme-aware colors
  - Support text below gauge uses RichText with bold primary-colored values (16px padding above text)

- Reconstitution Calculator Validation:
  - Calculator button is DISABLED until vial strength is entered
  - Helper text changes to error-styled message: "Please enter the vial strength above before using the reconstitution calculator."
  - Error text shown in error color with bold font weight
  - Normal helper text shown in muted color when strength is valid
  - Prevents user confusion by requiring prerequisite data entry

- Reconstitution Calculator UX Improvements:
  - Desired Dose stepper buttons now work correctly with double parsing (not just int)
  - Syringe gauge has 16px horizontal padding for better visual spacing from card edges
  - Increased vertical spacing between gauge and support text (24px, up from 16px)
  - Support text formatted with line breaks - each sentence on separate line for readability
  - Option explainer text moved inside option cards (not above them)
  - Each option card shows description: "Strong small dosage", "Approx 50% syringe size dosage", "Large doses"
  - All text styles use theme constants (theme.textTheme) for consistency
  - Warning text uses theme.textTheme.bodySmall with error color instead of raw TextStyle
  - Calculator remains visible after saving reconstitution (does not auto-hide)
  - Removed separate saved reconstitution display - user sees live calculator with dynamic updates
  - Live syringe gauge and support text always visible in calculator after save

- Multi-Dose Vial Summary Card Format:
  - Shows total dose and concentration: "XYmg in ZmL, ABmg/mL" format
  - Example: "10mg in 5mL, 500mcg/mL" or "1000mg in 10mL, 100mg/mL"
  - Calculates total dose from concentration × volume
  - Displayed in additionalInfo section of summary card
  - Only shows when both vial volume and concentration (perMl) are entered
  - Falls back to "Vial Volume: X mL" if only volume is entered

- Reconstitution Calculator Button States:
  - **Not showing**: OutlinedButton with primary color and calculate icon
  - **Showing**: FilledButton with close icon (primary fill makes it prominent)
  - Disabled state when no vial strength entered

- Reconstitution Calculator Layout Optimizations:
  - Reduced padding between sections (16px → 12px)
  - Compact option cards: 6px padding, 6px bottom margin, smaller text (11px for explainers)
  - Slider helper text moved above slider for better flow
  - Reduced spacing between Fine-tune heading and content
  - All sections designed to fit on screen with 3 options, slider, and syringe

- Prominent Reconstitution Instruction:
  - Large bold text: "Reconstitute with X mL [DiluentName]"
  - Positioned above syringe gauge
  - Primary color with underlined volume for emphasis
  - titleMedium font size for visibility
  - Updates dynamically with slider adjustments

- Desired Dose Field Improvements:
  - Removed upper limit clamping (was limiting to vial strength value)
  - Now allows entry of any value (user can enter 10000 mcg when vial is 10mg)
  - Validation happens in calculation logic, not in stepper buttons
  - Enables proper unit conversion scenarios (mcg/mg/g)

- Text Color Consistency:
  - Fine-tune heading explicitly uses theme.colorScheme.onSurface
  - Option card text uses theme.textTheme.bodySmall/bodyMedium
  - All helper text uses kMutedLabelStyle(context)
  - Explainer text in options uses onSurfaceVariant color

- Reconstitution Text Sizing and Spacing:
  - "Reconstitute with X mL" text uses titleSmall (not titleMedium)
  - Vertical padding: 4px (was 8px)
  - Spacing before text: 12px (was 16px)
  - Spacing between text and syringe: 8px (was not defined)
  - Spacing after syringe: 12px (was 16px)
  - Appropriately sized for context, not overwhelming

- Correct Medical Terminology:
  - Support text says "Draw X IU into syringe" (not "from syringe")
  - Medically accurate - you draw medication INTO the syringe from the vial
  - Applied to all instances of draw instruction text

- Diluent Name Display:
  - Option cards show actual diluent name when entered
  - Falls back to generic "Diluent" label if field empty
  - Dynamic text: `${diluentName.isNotEmpty ? diluentName : "Diluent"}`
  - More informative for user when reviewing options

- Saved Reconstitution Display:
  - Appears below calculator button when calculator closed after saving
  - Shows: Bold primary titleSmall text "Reconstitute with X mL [DiluentName]"
  - Includes syringe gauge visualization with saved IU values
  - Positioned with left padding alignment (kLabelColWidth + 8)
  - Only visible when: _reconResult != null && !_showCalculator
  - Provides persistent reference without keeping full calculator open
  - User can click "Edit Reconstitution" button to reopen calculator

- Calculator Minimize Behavior:
  - Calculator automatically hides after clicking "Save Reconstitution"
  - Button changes to "Edit Reconstitution" with outlined style
  - Saved recon display appears in place of calculator
  - Clean workflow: Calculate → Save → View Summary → Edit if needed

- Option Card Selection Logic:
  - Fixed Radio button selection to use unique values per option
  - Each option has unique value: 'concentrated', 'balanced', 'diluted'
  - Selected state determined by comparing _selectedUnits with option's u1/u2/u3 values
  - Prevents issue where all 3 options appear selected simultaneously
  - Invalid options (outside slider range) are greyed out (40% opacity) and not clickable
  - Radio buttons disabled for invalid options via onChanged: null

- Calculator Text Color Theme Compliance:
  - Calculator heading: bodyMedium, fontWeight w500, onSurfaceVariant with 0.8 opacity
  - Fine-tune heading: bodyLarge, fontWeight w600, onSurfaceVariant
  - Option card labels: bodyMedium with onSurfaceVariant (not onSurface)
  - Option card details: bodySmall with onSurfaceVariant
  - All helper text: kMutedLabelStyle(context)
  - Primary values highlighted with primary color
  - Ensures proper visual hierarchy - no text is "too dark"

- Calculator Visibility Logic:
  - Returns SizedBox.shrink() if initialStrengthValue <= 0
  - Only renders calculator content when strength is valid
  - No error text shown on main page when strength missing
  - Clean UX - calculator appears only when prerequisites met

- Validation examples (all verified):
  - Strength 5mg, Dose 250mcg, 5 IU → 1mL vial
  - Strength 5mg, Dose 250mcg, 15 IU → 3mL vial
  - Strength 5mg, Dose 250mcg, 25 IU → 5mL vial
  - Strength 5mg, Dose 500mcg, 20 IU → 2mL vial
  - Strength 5mg, Dose 500mcg, 90 IU → 9mL vial
