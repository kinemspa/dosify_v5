/// Helper functions and utilities for reconstitution calculator
///
/// Extracted from reconstitution_calculator_widget.dart to reduce file size
/// and improve maintainability.
library;


/// Round value to 2 decimal places
double round2(double v) => (v * 100).round() / 100.0;

/// Round to nearest 0.5 mL (whole or half mL)
/// Used for vial volume rounding in reconstitution results
double roundToHalfMl(double v) {
  return (v * 2).round() / 2.0;
}

/// Format double for display
/// - Shows as integer if whole number
/// - Shows 1 decimal if ends in .X0
/// - Shows 2 decimals otherwise
String formatDouble(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  final s = v.toStringAsFixed(2);
  if (s.endsWith('0')) return v.toStringAsFixed(1);
  return s;
}

/// Convert mass units to base unit (mg)
///
/// Used for unit consistency in calculations when mixing mcg, mg, g
///
/// Examples:
/// - toBaseMass(5, 'g') = 5000 mg
/// - toBaseMass(250, 'mcg') = 0.25 mg
/// - toBaseMass(10, 'mg') = 10 mg
double toBaseMass(double value, String from) {
  if (from == 'g') return value * 1000.0;
  if (from == 'mg') return value;
  if (from == 'mcg') return value / 1000.0;
  return value;
}

/// Get context-aware helper text for strength input based on unit type
///
/// Provides guidance for different medication units:
/// - IU: Explains IU vs syringe markings, provides HGH conversion
/// - mg: Explains pre-filled vs powder vials
/// - mcg: Warns about unit confusion with mg
/// - g: Simple guidance for large-dose medications
String getStrengthHelperText(String unit) {
  switch (unit) {
    case 'units':
      return '''
Enter the total IU labeled on your vial (e.g., '10 IU' for HGH).

Can't find IU on vial?
• HGH: 1mg ≈ 3 IU (so 5mg ≈ 15 IU)
• Insulin: Usually labeled in IU (check for U-100, U-200, etc.)
• Other biologics: Check manufacturer documentation

⚠️ IU is medication potency, NOT syringe markings.
Never guess - incorrect dosing can be dangerous.''';

    case 'mg':
      return '''
Enter total mg in vial.

For pre-filled vials labeled as 'mg/mL':
Multiply concentration × volume (e.g., 200mg/mL × 10mL = 2000mg total)

For powder vials:
Enter amount shown on label (e.g., '5mg')''';

    case 'mcg':
      return '''
Enter total micrograms (mcg) in vial.

⚠️ Note: 1000mcg = 1mg
Check vial label carefully for unit.''';

    case 'g':
      return '''
Enter total grams in vial (typically antibiotics).

Note: 1g = 1000mg''';

    default:
      return 'Enter the total amount in your vial';
  }
}

/// HGH mg to IU conversion helper
///
/// Approximate conversion: 1mg HGH ≈ 3 IU
/// (varies by manufacturer: 2.6-3.3 IU per mg)
///
/// Returns approximate IU value
double convertHghMgToIU(double mg) {
  return mg * 3.0;
}

/// Get display label for syringe size in mL
String getSyringeLabel(double ml) {
  return '${ml.toStringAsFixed(1)} mL';
}

/// Calculate total markings on syringe
/// Standard syringes have 100 markings per mL
int calculateSyringeMarkings(double ml) {
  return (ml * 100).round();
}

/// Validate if a value is within acceptable range
bool isValidValue(double? value, {double min = 0, double? max}) {
  if (value == null || value.isNaN || value.isInfinite) return false;
  if (value <= min) return false;
  if (max != null && value > max) return false;
  return true;
}
