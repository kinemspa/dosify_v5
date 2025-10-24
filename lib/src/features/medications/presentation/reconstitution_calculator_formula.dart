/// Reconstitution Calculator Formula - Version 2.0
///
/// ⚠️ CRITICAL MEDICAL CALCULATION
///
/// This file implements the medically accurate reconstitution formula for ALL
/// medication units (mg, mcg, g, units).
///
/// **See docs/RECONSTITUTION_CALCULATOR_FORMULA.md for full documentation**
///
/// DO NOT MODIFY WITHOUT:
/// 1. Reading the documentation
/// 2. Testing all 7 validated examples
/// 3. Medical review
///
/// Last Updated: 2025-01-10
/// Version: 2.0 (Proper Units Support)
library;

// Project imports:
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_helpers.dart';

/// Result of reconstitution calculation
class ReconstitutionCalculation {
  const ReconstitutionCalculation({
    required this.concentration,
    required this.volumePerDose,
    required this.syringeMarkings,
    required this.diluentVolume,
    required this.isValid,
    this.errorMessage,
  });

  /// Concentration after reconstitution (in same unit/mL as input)
  /// Examples: 10 units/mL, 2.5 mg/mL, 1000 mcg/mL
  final double concentration;

  /// Volume to draw per dose (mL)
  final double volumePerDose;

  /// Number of markings on standard 1mL syringe (100 markings per mL)
  final int syringeMarkings;

  /// Volume of diluent added to vial (mL)
  final double diluentVolume;

  /// Whether this calculation is valid
  final bool isValid;

  /// Error message if calculation is invalid
  final String? errorMessage;
}

/// Calculate reconstitution for a medication vial
///
/// **FORMULA (Universal for ALL units):**
/// ```
/// Concentration (C) = Total_Strength / Diluent_Volume
/// Volume_per_Dose (V) = Desired_Dose / Concentration
/// Syringe_Markings = Volume_per_Dose × 100
/// ```
///
/// **CRITICAL RULES:**
/// 1. Strength and Dose MUST be in the same unit
/// 2. Units are medication potency, NOT syringe markings
/// 3. Works for mg, mcg, g, and units identically
///
/// **Parameters:**
/// - [totalStrength]: Total amount in vial (e.g., 10 units, 5mg, 2000mcg)
/// - [desiredDose]: Amount per injection (e.g., 2 units, 0.25mg, 250mcg)
/// - [diluentVolume]: mL of water/diluent to add to vial
/// - [unitLabel]: Unit name for validation ('mg', 'mcg', 'g', 'units')
///
/// **Example 1: HGH**
/// ```dart
/// calculate(
///   totalStrength: 10,     // 10 units in vial
///   desiredDose: 2,        // 2 units per injection
///   diluentVolume: 1.0,    // Add 1mL water
///   unitLabel: 'units',
/// )
/// // Returns:
/// // - concentration: 10 units/mL
/// // - volumePerDose: 0.2 mL
/// // - syringeMarkings: 20 (on 1mL syringe)
/// ```
///
/// **Example 2: BPC-157**
/// ```dart
/// calculate(
///   totalStrength: 5000,   // 5000 mcg (5mg) in vial
///   desiredDose: 250,      // 250 mcg per injection
///   diluentVolume: 2.0,    // Add 2mL water
///   unitLabel: 'mcg',
/// )
/// // Returns:
/// // - concentration: 2500 mcg/mL
/// // - volumePerDose: 0.1 mL
/// // - syringeMarkings: 10 (on 1mL syringe)
/// ```
ReconstitutionCalculation calculateReconstitution({
  required double totalStrength,
  required double desiredDose,
  required double diluentVolume,
  required String unitLabel,
}) {
  // Validation
  if (!isValidValue(totalStrength)) {
    return const ReconstitutionCalculation(
      concentration: 0,
      volumePerDose: 0,
      syringeMarkings: 0,
      diluentVolume: 0,
      isValid: false,
      errorMessage: 'Invalid total strength value',
    );
  }

  if (!isValidValue(desiredDose)) {
    return const ReconstitutionCalculation(
      concentration: 0,
      volumePerDose: 0,
      syringeMarkings: 0,
      diluentVolume: 0,
      isValid: false,
      errorMessage: 'Invalid desired dose value',
    );
  }

  if (!isValidValue(diluentVolume)) {
    return const ReconstitutionCalculation(
      concentration: 0,
      volumePerDose: 0,
      syringeMarkings: 0,
      diluentVolume: 0,
      isValid: false,
      errorMessage: 'Invalid diluent volume',
    );
  }

  // CRITICAL FORMULA - See docs/RECONSTITUTION_CALCULATOR_FORMULA.md

  // Step 1: Calculate concentration after reconstitution
  // Concentration (C) = Total_Strength / Diluent_Volume
  final concentration = totalStrength / diluentVolume;

  // Step 2: Calculate volume to draw per dose
  // Volume_per_Dose (V) = Desired_Dose / Concentration
  final volumePerDose = desiredDose / concentration;

  // Step 3: Calculate syringe markings (100 markings per mL)
  // Syringe_Markings = Volume_per_Dose × 100
  final syringeMarkings = calculateSyringeMarkings(volumePerDose);

  return ReconstitutionCalculation(
    concentration: round2(concentration),
    volumePerDose: round2(volumePerDose),
    syringeMarkings: syringeMarkings,
    diluentVolume: diluentVolume,
    isValid: true,
  );
}

/// Calculate dose from volume (reverse calculation)
///
/// Used when user drags slider to see what dose they would get
///
/// **Formula:**
/// ```
/// Dose = Volume × Concentration
/// Concentration = Total_Strength / Diluent_Volume
/// ```
///
/// **Example:**
/// ```dart
/// calculateDoseFromVolume(
///   volumeMl: 0.2,         // User dragged slider to 0.2mL
///   totalStrength: 10,     // 10 units in vial
///   diluentVolume: 1.0,    // Added 1mL water
/// )
/// // Returns: 2.0 units
/// ```
double calculateDoseFromVolume({
  required double volumeMl,
  required double totalStrength,
  required double diluentVolume,
}) {
  if (!isValidValue(volumeMl)) return 0;
  if (!isValidValue(totalStrength)) return 0;
  if (!isValidValue(diluentVolume)) return 0;

  // Concentration = Total_Strength / Diluent_Volume
  final concentration = totalStrength / diluentVolume;

  // Dose = Volume × Concentration
  final dose = volumeMl * concentration;

  return round2(dose);
}

/// Calculate volume from dose (forward calculation)
///
/// Used when user types dose to see what volume to draw
///
/// **Formula:**
/// ```
/// Volume = Dose / Concentration
/// Concentration = Total_Strength / Diluent_Volume
/// ```
double calculateVolumeFromDose({
  required double dose,
  required double totalStrength,
  required double diluentVolume,
}) {
  if (!isValidValue(dose)) return 0;
  if (!isValidValue(totalStrength)) return 0;
  if (!isValidValue(diluentVolume)) return 0;

  // Concentration = Total_Strength / Diluent_Volume
  final concentration = totalStrength / diluentVolume;

  // Volume = Dose / Concentration
  final volume = dose / concentration;

  return round2(volume);
}
