# Medications Feature Specification (Final)

This document defines final behavior and constraints for all medication forms.

Global
- Material 3, bottom navigation with persistent tabs: Home, Medications, Schedules, Settings
- Back button on all non-home pages
- Number formatting: use fmt2(value) – up to 2 decimals, no trailing zeros
- Long helper text is rendered below field rows (not inside TextField helper) to avoid truncation

Med types
1) Tablet
- Strength: mcg/mg/g per tablet (decimal allowed)
- Stock: supports quarters (0.25 increments). No stepper shown for tablets.
- Low Stock: single threshold in selected unit
- Storage label: "Lot / Storage Location"

2) Capsule
- Strength: mcg/mg/g per capsule (decimal allowed)
- Stock: whole numbers only; stepper provided
- Low Stock: single threshold
- Storage label: "Lot / Storage Location"

3) Injection – Pre-Filled Syringe
- Strength units: mcg/mL, mg/mL, g/mL, units/mL (also mass-only units allowed)
- Per mL field appears when /mL chosen
- Stock: number of syringes (whole numbers; stepper)
- Low Stock: single threshold
- Storage label: "Lot / Storage Location"

4) Injection – Single Dose Vial
- Strength units: mcg/mL, mg/mL, g/mL, units/mL (also mass-only units allowed)
- Per mL field appears when /mL chosen
- Stock: number of vials (whole numbers; stepper)
- Low Stock: single threshold
- Storage label: "Lot / Storage Location"

5) Injection – Multi Dose Vial
- Strength units: mcg/mL, mg/mL, g/mL, units/mL (also mass-only units allowed)
- Per mL field appears when /mL chosen
- Vial Volume (mL): required. Represents the total liquid volume in the vial after reconstitution
- Vials in stock: whole numbers; stepper below Vial Volume
- Low Stock: dual thresholds when enabled
  - Vial Volume (mL) threshold – warns on current vial volume
  - Vials in Reserve threshold – warns on reserve vial count
- Storage label: "Lot / Storage Location"

Reconstitution Calculator (Dialog)
- Inputs
  - Vial Quantity (Strength in vial, same unit dimension as dose)
  - Desired Dose + Dose Unit (mcg/mg/g/units); mass units are auto-converted for computation
  - Syringe Size: 0.3/0.5/1/3/5 mL (shows IU in label, assuming 100 IU/mL)
  - Vial Size (mL): optional upper bound on resulting volume
- Assumptions
  - IU mapping: 100 IU == 1 mL; IU fill F implies dose volume F/100 mL
- Math
  - Concentration C (per mL) = 100 × Dose / IU
  - Solvent Volume V (mL to add) = Strength_in_vial / C
  - Constraint: V ≤ Vial Size (if provided)
- Options (Presets)
  - Compute allowed IU range [minIU, maxIU] where maxIU = min(syringe_IU, 100 × Dose × VialSize / Strength)
  - Provide three presets evenly spaced within this range: Concentrated (min), Standard (mid), Diluted (max)
  - Chip subtitles show: C (unit/mL) • V (mL) • IU, plus short hint per option
  - Show "No valid options" when constraints eliminate the range
- Slider
  - Range: [minIU, maxIU]; labels show IU and syringe capacity
- Summary (always visible within dialog)
  - Syringe label and IU, concentration per mL, vial volume (and limit if provided)
- Submit
  - Auto-populates on Multi Dose Vial screen: Per mL concentration and Vial Volume
  - Remembers last-used Dose, Unit, Syringe, and Vial Size for subsequent openings

Save behavior
- On Submit in any Add/Edit medication screen, show confirmation dialog with Cancel/Confirm.
- On Confirm, persist to Hive and navigate to Medications list.

Data model (Hive)
- Adapters: Unit(1), StockUnit(2), MedicationForm(3), Medication(10)
- Medication fields (subset):
  - containerVolumeMl (20) – multi-dose vial volume after reconstitution
  - lowStockVialVolumeThresholdMl (21)
  - lowStockVialsThresholdCount (22)

Formatting and validation rules
- All numeric outputs use fmt2 (no trailing zeros)
- Integer fields use steppers (capsules, syringes, single/multi vials, low stock count for vials). Tablet stock uses quarters and remains a numeric input without stepper.
- Helper text placed below field rows for readability.

