# RECONSTITUTION CALCULATOR FORMULA

## ⚠️ CRITICAL MEDICAL CALCULATION - DO NOT MODIFY WITHOUT REVIEW

This document defines the mathematical formula used in the medication reconstitution calculator.
**INCORRECT CALCULATIONS CAN RESULT IN DANGEROUS UNDER-DOSING OR OVER-DOSING.**

Last Updated: 2025-01-10
Version: 2.0 (IU Support Added)

---

## Formula Overview

The calculator determines:
1. How much diluent to add to a vial of powdered medication
2. What concentration results after reconstitution
3. How much volume to draw for each dose

---

## Universal Formula (ALL Medication Units)

```
INPUTS:
  S = Total strength in vial (in medication's unit: mg, mcg, g, or IU)
  V_add = Volume of diluent to add (mL)
  D = Desired dose per injection (in SAME unit as S)

CALCULATIONS:
  1. Concentration (C) = S / V_add
     Result in: mg/mL, mcg/mL, g/mL, or IU/mL

  2. Volume per dose (V_dose) = D / C
     Result in: mL

  3. Syringe markings = V_dose × 100
     (For 1mL syringe with 100 markings)
     
     For other syringe sizes:
     - 0.3mL syringe: V_dose × (100 / 0.3) = markings out of 30
     - 0.5mL syringe: V_dose × (100 / 0.5) = markings out of 50
     - 3mL syringe: V_dose × (100 / 3) = markings out of 300
```

---

## Critical Rules

### 1. **Unit Consistency**
- Strength and Dose MUST use the same unit
- If vial is "10 IU", dose must be in IU (not mg)
- If vial is "5mg", dose must be in mg (not mcg unless converted)

### 2. **IU ≠ Syringe Markings**
- IU (International Units) is medication potency
- Syringe markings are volume measurements (0.01mL each on 1mL syringe)
- They only match when concentration is exactly 100 units/mL (U-100 insulin)

### 3. **Pre-filled vs Powder**
- This calculator is for POWDER vials that need reconstitution
- Pre-filled vials already have concentration - skip calculator, just divide dose by concentration

---

## Validated Examples

### Example 1: HGH (Human Growth Hormone)
```
Vial: 10 IU (lyophilized powder)
Desired Dose: 2 IU per injection
User adds: 1mL bacteriostatic water

Calculation:
  C = 10 IU / 1mL = 10 IU/mL
  V_dose = 2 IU / 10 IU/mL = 0.2mL
  Syringe markings = 0.2 × 100 = 20 markings on 1mL syringe

✓ CORRECT: Draw 0.2mL (20 markings) for 2 IU dose
```

### Example 2: BPC-157 (Peptide)
```
Vial: 5mg (5000mcg) lyophilized powder
Desired Dose: 250mcg per injection
User adds: 2mL bacteriostatic water

Calculation:
  C = 5000mcg / 2mL = 2500mcg/mL
  V_dose = 250mcg / 2500mcg/mL = 0.1mL
  Syringe markings = 0.1 × 100 = 10 markings on 1mL syringe

✓ CORRECT: Draw 0.1mL (10 markings) for 250mcg dose
```

### Example 3: Semaglutide (Ozempic)
```
Vial: 2mg lyophilized powder
Desired Dose: 0.25mg per injection (starting dose)
User adds: 2mL bacteriostatic water

Calculation:
  C = 2mg / 2mL = 1mg/mL
  V_dose = 0.25mg / 1mg/mL = 0.25mL
  Syringe markings = 0.25 × 100 = 25 markings on 1mL syringe

✓ CORRECT: Draw 0.25mL (25 markings) for 0.25mg dose
```

### Example 4: Insulin (Reconstituted)
```
Vial: 100 IU lyophilized powder
Desired Dose: 10 IU per injection
User adds: 1mL diluent

Calculation:
  C = 100 IU / 1mL = 100 IU/mL (U-100 concentration)
  V_dose = 10 IU / 100 IU/mL = 0.1mL
  Syringe markings = 0.1 × 100 = 10 markings on insulin syringe

✓ CORRECT: Draw 0.1mL (10 markings) for 10 IU dose
✓ NOTE: At U-100, IU and syringe markings match (special case only!)
```

### Example 5: Heparin
```
Vial: 5,000 IU lyophilized powder
Desired Dose: 500 IU per injection
User adds: 5mL sterile water

Calculation:
  C = 5000 IU / 5mL = 1000 IU/mL
  V_dose = 500 IU / 1000 IU/mL = 0.5mL
  Syringe markings = 0.5 × 100 = 50 markings on 1mL syringe

✓ CORRECT: Draw 0.5mL (50 markings) for 500 IU dose
```

### Example 6: Testosterone (Powder Form - Rare)
```
Vial: 1000mg lyophilized powder
Desired Dose: 100mg per injection
User adds: 5mL oil

Calculation:
  C = 1000mg / 5mL = 200mg/mL
  V_dose = 100mg / 200mg/mL = 0.5mL
  Syringe markings = 0.5 × 100 = 50 markings on 1mL syringe

✓ CORRECT: Draw 0.5mL (50 markings) for 100mg dose
```

### Example 7: EPO (Erythropoietin)
```
Vial: 4,000 IU lyophilized powder
Desired Dose: 1,000 IU per injection
User adds: 1mL sterile water

Calculation:
  C = 4000 IU / 1mL = 4000 IU/mL
  V_dose = 1000 IU / 4000 IU/mL = 0.25mL
  Syringe markings = 0.25 × 100 = 25 markings on 1mL syringe

✓ CORRECT: Draw 0.25mL (25 markings) for 1000 IU dose
```

---

## Unit Conversions (Reference Only)

### HGH (Somatropin)
- **1mg ≈ 3 IU** (varies by manufacturer: 2.6-3.3 IU)
- If vial shows "5mg", approximate IU = 5 × 3 = 15 IU
- **Always use the unit shown on the vial label when possible**

### Mass Conversions
- 1g = 1,000mg
- 1mg = 1,000mcg
- 1mcg = 0.001mg

### Insulin Concentrations
- U-100: 100 IU/mL (standard)
- U-200: 200 IU/mL
- U-500: 500 IU/mL

---

## Common Errors to Avoid

### ❌ ERROR 1: Confusing IU with syringe markings
```
Wrong: "10 IU vial + 1mL = draw 10 markings for 10 IU dose"
Right: "10 IU vial + 1mL = 10 IU/mL, need 1mL (100 markings) for 10 IU dose"
```

### ❌ ERROR 2: Mixing units
```
Wrong: Vial is "5mg", dose is "250mcg", calculate 250/5 = 50
Right: Convert first: 5mg = 5000mcg, then 250/5000 = 0.05
```

### ❌ ERROR 3: Using concentration for total strength
```
Wrong: Pre-filled vial "200mg/mL, 10mL" → strength = 200mg
Right: Total strength = 200mg/mL × 10mL = 2000mg
```

---

## Implementation Location

**File:** `lib/src/features/medications/presentation/reconstitution_calculator_widget.dart`

**Key Methods:**
- `_computeForDose()` - Main calculation method
- `_toBaseMass()` - Unit conversion helper
- `build()` - UI with dose input field

---

## Testing Requirements

All 7 examples above MUST pass validation before any changes are merged.

**Test Command:**
```dart
// Add unit tests for each example
test('HGH reconstitution calculation', () {
  final result = calculateReconstitution(
    totalStrength: 10,
    strengthUnit: Unit.units,
    desiredDose: 2,
    doseUnit: Unit.units,
    diluent Volume: 1.0,
  );
  
  expect(result.concentration, 10.0); // 10 IU/mL
  expect(result.volumePerDose, 0.2); // 0.2mL
  expect(result.syringeMarkings, 20); // 20 markings
});
```

---

## Change History

### Version 2.0 (2025-01-10)
- **BREAKING CHANGE:** Added proper IU (International Units) support
- Removed syringe marking slider (was incorrectly treating markings as medication units)
- Added dose input field in medication's actual unit
- Calculator now works with mg, mcg, g, and IU correctly
- Added 7 validated medication examples
- Previous system only worked correctly for U-100 insulin by coincidence

### Version 1.0 (Original)
- Basic reconstitution calculator
- Used syringe markings as proxy for medication units (incorrect for most medications)

---

## Medical Disclaimer

This calculator is a tool to assist with medication preparation calculations.
**Always verify calculations with a healthcare provider.**
**Follow your prescription and medication packaging instructions.**
**When in doubt, consult a pharmacist or physician.**

---

## Contact for Changes

Any modifications to this formula must be:
1. Medically reviewed
2. Tested against all 7 examples
3. Documented in this file
4. Approved by project maintainer

**DO NOT MODIFY WITHOUT FOLLOWING THIS PROCESS.**
