# Product Design Specification

This document captures the complete UI/UX and feature design for the Dosifi v5 Flutter mobile application.

Overview

- Flutter Mobile app
- Android only for now
- Modern award winning design
- Focus on UI and UX design (Material 3)
- Primary gradient: #09A8BD → #18537D
- Secondary colour: #EC873F

Home Page

- No back button on the home page
- Provide more summary cards

Medication List Screen

Init
- Helper Text: "Add a medication to begin tracking"
- Actions:
  - Button: "Add Medication" → Go to Select Medication screen

Normal (Controls and actions)
- Button: FAB → Select Medication Screen
- Button: Layout (top-right) → Toggle between layouts:
  - Large Cards
  - Compact Cards
  - List View
- Button: Search (magnifying glass) → Search filter
- Button: Sort → Sort current filtered results
- Button: Filter → Needs design (TBD)
- Button: Back (top-left app header) → Goes back to previous screen or Home

Select Medication Type Screen

- Back button (top-left) → Goes back to previous screen or Home
- Header: "Select a medication type to track."
- Options:
  - Tablet
    - Solid oral medication. Can be halved or quartered.
    - Navigate: Add Medication – Tablet
  - Capsule
    - Encapsulated oral medication.
  - Injection
    - Injection medication.

Select Injection Type Screen

- Back button (top-left) → Goes back to previous screen or Home
- Header: "Select an injection type to track."
- Options:
  - Pre-Filled Syringe
    - Ready to use single dose syringe
  - Single Dose Vial
    - One time use vial
  - Multi Dose Vial
    - Ready to use liquid vial for multiple doses
  - Lyophilized Vial
    - Reconstitute with sterile liquid before use

Add/Edit Medication Screens

Common Pattern
- Floating Summary Card: always visible at bottom, collapsible; dynamically updates from field inputs; includes Submit button.

Add/Edit Medication – Tablet

Floating Summary Card (dynamic examples):
- Tablets
- Panadol Tablets
- Panadol at 10mg per tablet
- Panadol at 10mg per tablet. 100 in stock.
- "Panamax - Keep refrigerated. Expires - 1/1/2027"
- "Take with food. Etc etc"

Navigation
- Back button (top-left) → previous screen or Home

General Card
- Field: Name (required) — text input
- Field: Manufacturer — text input
- Field: Description — text input
- Field: Notes — text input

Strength Card
- Field: Strength Value (required) — integer input
  - Increment/decrement buttons; whole numbers by default; manual edit supports 2 decimals
  - Same row as Strength Unit
- Field: Strength Unit (required) — dropdown: mcg, mg, g
  - UI may display mcg with helper text “mcg = Microgram”

Inventory Card
- Field: Stock Value (required) — integer input
  - Increment/decrement; allows quarter increments for Tablets
- Field: Stock Unit (required) — dropdown: tablets, mcg, mg, g
  - If tablets, summary shows strength × count
  - If mg, summary derives total tablets by converting via strength
- Toggle: Low Stock Alert — enables threshold fields
- Field: Low Stock (required if enabled) — integer input
  - Uses same unit as Stock Unit, or supports percentage rounded to whole unit
- Field: Expiry — No Expiry or Date Picker
- Field: Reserve Stock — N/A

Storage Information Card
- Field: Batch Number — text input
- Field: Storage / Lot Number — text input
- Field: Requires Refrigeration — toggle
- Field: Storage Instructions — text input

Submit
- Button: Submit → confirmation dialog summarizing all entered data with Confirm

Add/Edit Medication – Capsule

Floating Summary Card (dynamic examples):
- Capsules
- Panadol Capsules
- Panadol at 10mg per capsule
- Panadol at 10mg per capsule. 100 in stock.
- "Panamax - Keep refrigerated. Expires - 1/1/2027"
- "Take with food. Etc etc"

Navigation
- Back button (top-left) → previous screen or Home

General Card
- Name (required), Manufacturer, Description, Notes — text inputs

Strength Card
- Strength Value (required) — integer input (with 2-decimal manual edit)
- Strength Unit (required) — mcg, mg, g

Inventory Card
- Stock Value (required) — integer input; capsules are whole numbers only
- Stock Unit (required) — dropdown: capsules, mcg, mg, g
  - If capsules → show strength × capsules
  - If mg → convert based on strength → total capsules (whole numbers only)
- Low Stock Alert Toggle
- Low Stock Threshold (required if enabled)
- Expiry — No Expiry / Date Picker
- Reserve Stock — N/A

Storage Information Card
- Batch Number, Storage / Lot Number, Requires Refrigeration (toggle), Storage Instructions — text inputs

Submit
- Button: Submit → confirmation dialog

Add/Edit Medication – Injection — Pre-Filled Syringe

Floating Summary Card (dynamic examples):
- Pre Filled Syringe
- Dupixent Pre Filled Syringe
- Dupixent 150mg/mL Pre Filled Syringes
- Dupixent 150mg/mL Pre Filled Syringes. 100 in stock.
- "Sanofi Genzyme - Keep refrigerated. Expires - 1/1/2027"
- "Subcutaneous Injection, Etc etc"

Navigation
- Back button (top-left)

General Card
- Name (required), Manufacturer, Description, Notes — text inputs

Strength Card
- Strength Value (required) — integer input (2-decimal manual edit)
- Strength Unit (required) — mcg, mg, g, units, mcg/mL, mg/mL, g/mL, units/mL
  - If a per mL unit is selected, show:
- Field: Per mL Value — integer input

Inventory Card
- Stock Value (required) — integer input; whole syringes only
- Stock Unit (required) — pre filled syringes
- Low Stock Alert toggle
- Low Stock Threshold (required if enabled)
- Expiry — No Expiry / Date Picker
- Reserve Stock — N/A

Storage Information Card
- Batch Number, Storage / Lot Number, Requires Refrigeration (toggle), Storage Instructions — text inputs

Submit
- Button: Submit → confirmation dialog

Add/Edit Medication – Injection — Single Dose Vial

Floating Summary Card (dynamic examples)
- Single Dose Vial → Heparin examples as provided
- Manufacturer, refrigeration, expiry, administration notes

Navigation
- Back button (top-left)

General Card
- Name (required), Manufacturer, Description, Notes — text inputs

Strength Card
- Strength Value (required), Strength Unit (required: mcg, mg, g, units, mcg/mL, mg/mL, g/mL, units/mL), Per mL Value (if applicable)

Inventory Card
- Stock Value (required) — whole vials only
- Stock Unit (required) — single use vials
- Low Stock Alert toggle
- Low Stock Threshold (required if enabled)
- Expiry — No Expiry / Date Picker
- Reserve Stock — N/A

Storage Information Card
- Batch Number, Storage / Lot Number, Requires Refrigeration (toggle), Storage Instructions — text inputs

Submit
- Button: Submit → confirmation dialog

Add/Edit Medication – Injection — Multi Dose Vial

Floating Summary Card (dynamic examples)
- Multi Dose Vial variants (e.g., Genotropin), reconstituted summary, refrigeration, expiry, administration notes

Navigation
- Back button (top-left)

General Card
- Name (required), Manufacturer, Description, Notes — text inputs

Strength Card
- Strength Value (required), Strength Unit (required), Per mL Value (if applicable)

Inventory Card
- Button: Requires Reconstitution → opens Reconstitution Calculator dialog
  - If used, Stock Value and Stock Unit can be pre-populated from calculator results
- Stock Value (required) — integer input (2-decimal manual edit)
- Stock Unit (required)
- Low Stock Alert toggle
- Low Stock Threshold (required if enabled)
- Expiry — No Expiry / Date Picker
- Reserve Stock — N/A

Storage Information Card
- Batch Number, Storage / Lot Number, Requires Refrigeration (toggle), Storage Instructions — text inputs

Reconstitution Calculator (Dialog)

Fields
- Strength Value (required) — integer input (auto-populated from Add Medication Strength; edits sync back)
- Strength Unit (required) — mcg, mg, g, units, mcg/mL, mg/mL, g/mL, units/mL (auto-populated; edits sync back)
- Desired Dose (required) — integer input (2-decimal manual edit)
- Desired Dose Unit (required) — mcg, mg, g, units, mcg/mL, mg/mL, g/mL, units/mL
- Syringe Size (required) — 0.3mL, 0.5mL, 1mL, 3mL, 5mL (drives constraints)
- Vial Size (optional) — No constraint, 1mL, 2mL, 3mL, 5mL, 7mL, 8mL, 10mL, 20mL, 30mL (drives constraints)
- Reconstitution Diluent — Dropdown: Don’t track, <Select available supply fluid>, Create New Supply
  - If “Don’t track”, a free-text “Reconstitution Diluent Name” appears
- Calculator Diagram — Three selectable options: Concentrated, Standard, Diluted
  - The calculator chooses values as far apart as possible while satisfying:
    - 5%–100% of the syringe capacity
    - Solvent (mL) ≤ Target Vial Size (if provided)
  - Visual guidance: syringe graphic showing fill amount; display formula
  - Display formula (example):
    - Units = (Desired Dose (mg) ÷ (Peptide (mg) ÷ Solvent (mL))) × (Syringe Units ÷ Syringe Capacity (mL))
  - Display instruction text:
    - "Reconstitute <MEDNAME> with <RECONFLUIDNAME> with <X> mL for a target dose of <DOSE> to administer on a <SyringeSize> using <X> IU."
- Precision: All results to 2 decimal places
- Drag control: Adjusts values and recalculates automatically
- Supplies Used — Dropdown: Don’t track, <Select available supply>, Create New Supply
- Buttons: Submit (confirm dialog), Cancel

Supply Add (Dialog)
- Supply Name (required) — text input
- Supply Type (required) — Dropdown: Item, Fluid (locked to Fluid when triggered from calculator)
- Volume Value (required) — integer input
- Volume Unit (required) — mL, L
- Expiry — No Expiry / Date Picker
- Low Stock Alert toggle
- Low Stock Threshold (required if enabled)
- Storage Information — text input

Schedules and Calendar

Calendar Screen

Month View
- Month grid (square day blocks)
- Weekday letters on columns
- Scheduled doses appear on days
- Status coloring:
  - Taken, Missed, Canceled (distinct colors)
- Day selection expands a collapsible panel below month grid showing that day’s dose cards; selecting again collapses
- Card density modes: Large, Compact, List
- Dose card actions: View details, Take, Snooze, Cancel; show stats (last dose taken, total taken, projected remaining, projected depletion)

Week View
- Columns: days of week
- Rows: hours of day
- Doses appear as mini cards; expandable similar to Month view

Day View
- All doses for the selected day as a list

Schedules View
- Shows all schedules
- Status filters: Active, Paused, Archived, Low stock

Add/Edit Schedules

Floating Summary Card
- Collapsible, always visible, dynamically updates

High-Level Fields (needs further design work)
- Schedule Name (e.g., "BPC 157 - 500mcg - 25IU")
- Medication Scheduled (select medication)
- Dose amount (e.g., 500mcg)
- Administration (e.g., Subcutaneous Injection via 1mL syringe)
- Administration Amount (e.g., 50IU / 0.5mL 500mcg)
- Schedule: e.g., Daily
- Time(s) of Day: e.g., 22:00
- Schedule Cycle: e.g., 4 weeks on, 2 weeks break
- Titration: None
- Maintenance: None
- Schedule End: No End
- Supplies used per dose (examples):
  - 1 × 1.0 mL Insulin Syringe
  - 1 × Alcohol Swab
  - 2 × Surgical Gloves

Navigation
- Back button (top-left)

Fields (detailed)
- General
  - Name (required) — text input; can auto-populate from medication and dose
  - Medication (required) — dropdown; shows available meds with remaining stock
  - Instructions / Notes — text input
- Dose
  - Dose Value (required) — integer input (2-decimal manual edit)
  - Dose Unit (required) — options based on medication type:
    - Tablet: Tablets, mcg, mg, g (min step: quarter tablets)
    - Capsule: Capsules, mcg, mg, g (min step: whole capsules)
    - Pre-Filled Syringe: Syringes or saved unit/sub-units (min step: whole syringe)
    - Single Dose Vial: Single use vial or saved unit/sub-units (min step: whole vial)
    - Multi Dose Vial: Saved unit/sub-units or syringe IU
  - Automatic calculations must be accurate and safe:
    - Example: 500mcg from a 1mg tablet → display 500mcg @ 0.5 tablets
    - Example: 750mcg from a reconstituted vial → display 750mcg @ 45 IU on 1mL syringe
- Administration
  - Administration Method — dropdown (defaults based on medication type)
- Schedule
  - Schedule Type — dropdown: Days per week (select days), Cycled Days (on/off)
  - Times — add one or more times per day (time picker)
  - Notification Setting — dropdown: Default / Select Saved Set / Add New Set (for future use)
  - Snooze Default Duration — default added time on Snooze (minutes/hours/days); auto-populates at ~33% between doses
  - Cyclic Regimen — define on/off cycles; must include at least one on and one off period; can repeat or chain multiple cycles
  - Titration — toggle; define increase/decrease amount and duration (doses/days/months/cycles)
- Supplies
  - Track Supplies — toggle
  - Supply 1–10 — dropdown: Select from saved supplies / Add New Supply
    - If Device: ask for device amount (units)
    - If Fluid: ask for volume amount used
  - On confirming a dose as taken, configured supplies are deducted automatically from stock

Notifications (types – for future integration)
- Upcoming Dose
- Scheduled Dose
- Reminder to take Dose
- Low Stock Alert
- Expiration
- Other (TBD)

Settings

General
- Medications
- Schedule
  - Start Day of Week — choose the first day shown in weekly views

Notifications
- Notification Sets
  - Default
    - Alert tone
    - Vibrate
    - Pre Alert Time
    - Dose Reminders — if no action taken, how long until reminder
    - Low Stock Alert Time — notify daily at set time until refilled
    - Expiration — lead time before expiration (days/hours)

Data
- Export Data
- Import Data

Diagnostics
- Seed Medication Data
- Seed Schedules
- Seed Supplies
- Confirm Data

