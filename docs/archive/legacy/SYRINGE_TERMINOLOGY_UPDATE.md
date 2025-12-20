# Insulin Syringe Terminology Update

## Date: 2025-01-24

## Summary

Updated all references to insulin syringe measurements from "IU" (International Units) to the proper terminology **"units" (U)** throughout the codebase.

## Why This Change?

The measurement markings on an insulin syringe are called **"units"** (abbreviated as **"U"**), not "IU". While "IU" stands for International Units and refers to medication potency, insulin syringes are marked in **units** that correspond to insulin concentrations like U-100 (100 units/mL).

## Changes Made

### Code Files Updated:
- `interactive_syringe_slider.dart` - Property names and UI text
- `white_syringe_gauge.dart` - All gauge references
- `reconstitution_calculator_widget.dart` - Calculator display text  
- `reconstitution_calculator_helpers.dart` - Helper text and conversions
- `reconstitution_calculator_formula.dart` - Formula documentation
- `reconstitution_calculator_dialog.dart` - Data model comments
- `unified_form.dart` - Legacy SyringeGauge widget
- `schedule.dart` - Field comments (field names kept for backward compatibility)

### Property Name Changes:
- `totalIU` → `totalUnits`
- `fillIU` → `fillUnits`
- `minIU` → `minUnits`
- `maxIU` → `maxUnits`

### UI Text Changes:
- Display changed from `"X IU"` to `"X U"`
- All user-facing text updated to use "units" terminology
- Comments clarified that units represent medication potency, not volume

### Backward Compatibility:
- Data model field names like `doseIU` kept unchanged to maintain database compatibility
- Only display text and variable names updated
- No breaking changes to persisted data

## Medical Accuracy

This change improves medical accuracy by:
1. Using correct terminology for insulin syringe markings
2. Clarifying that **units** represent medication potency (not syringe volume)
3. Following standard medical practice and pharmaceutical labeling

## Testing

All existing functionality remains the same - only terminology changed:
- Syringe widgets still display correctly
- Calculations remain accurate
- User interactions unchanged
- Data persistence unaffected

## Related Documentation

- See `RECONSTITUTION_CALCULATOR_FORMULA.md` for detailed formula documentation
- See `technical.md` for implementation details
