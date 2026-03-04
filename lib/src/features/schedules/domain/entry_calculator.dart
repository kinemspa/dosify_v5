import 'package:flutter/foundation.dart';

/// Entry calculation service for all medication forms.
/// Converts between entry formats (tablets ↔ strength, volume ↔ units)
/// and validates increments (1/4 for tablets, whole for capsules).
class EntryCalculator {
  // ==================== TABLETS ====================

  /// Calculates entry from tablet count.
  /// Validates that tablet count is a valid 1/4 increment.
  static EntryCalculationResult calculateFromTablets({
    required double tabletCount,
    required double strengthPerTabletMcg,
    required String strengthUnit,
  }) {
    // Validate tablet count is 1/4 increment
    final quarters = (tabletCount * 4).round();
    final validTabletCount = quarters / 4;

    if ((tabletCount * 4) % 1 != 0) {
final warnUnit = validTabletCount == 1.0 ? 'tablet' : 'tablets';
    final reqUnit = tabletCount == 1.0 ? 'tablet' : 'tablets';
    return EntryCalculationResult.warning(
      entryMassMcg: validTabletCount * strengthPerTabletMcg,
      entryTabletQuarters: quarters,
      displayText:
          '${_formatTabletCount(validTabletCount)} $warnUnit (${formatMass(validTabletCount * strengthPerTabletMcg)})',
      warning:
          '⚠️ Entry requires ${_formatTabletCount(tabletCount)} $reqUnit (rounded to ${_formatTabletCount(validTabletCount)})',
      );
    }

    final totalMcg = tabletCount * strengthPerTabletMcg;

    final tabletUnit = tabletCount == 1.0 ? 'tablet' : 'tablets';
    return EntryCalculationResult.success(
      entryMassMcg: totalMcg,
      entryTabletQuarters: quarters,
      displayText:
          '${_formatTabletCount(tabletCount)} $tabletUnit × ${formatMass(strengthPerTabletMcg)} = ${formatMass(totalMcg)} total',
    );
  }

  /// Calculates tablet count from desired strength.
  /// May round to nearest 1/4 increment if not exact.
  static EntryCalculationResult calculateFromStrength({
    required double strengthMcg,
    required double strengthPerTabletMcg,
  }) {
    final exactTabletCount = strengthMcg / strengthPerTabletMcg;
    final quarters = (exactTabletCount * 4).round();
    final validTabletCount = quarters / 4;

    // Check if rounding was needed
    if ((exactTabletCount - validTabletCount).abs() > 0.001) {
      return EntryCalculationResult.warning(
        entryMassMcg: validTabletCount * strengthPerTabletMcg,
        entryTabletQuarters: quarters,
        displayText:
            '${formatMass(validTabletCount * strengthPerTabletMcg)} (${_formatTabletCount(validTabletCount)} ${validTabletCount == 1.0 ? 'tablet' : 'tablets'})',
        warning:
            '⚠️ Entry requires ${_formatTabletCount(exactTabletCount)} ${exactTabletCount == 1.0 ? 'tablet' : 'tablets'} (rounded to ${_formatTabletCount(validTabletCount)})',
      );
    }

    return calculateFromTablets(
      tabletCount: validTabletCount,
      strengthPerTabletMcg: strengthPerTabletMcg,
      strengthUnit: 'mcg',
    );
  }

  // ==================== CAPSULES ====================

  /// Calculates entry from capsule count.
  /// Only accepts whole numbers.
  static EntryCalculationResult calculateFromCapsules({
    required int capsuleCount,
    required double strengthPerCapsuleMcg,
  }) {
    if (capsuleCount < 1) {
      return EntryCalculationResult.error('Capsule count must be at least 1');
    }

    final totalMcg = capsuleCount * strengthPerCapsuleMcg;

    return EntryCalculationResult.success(
      entryMassMcg: totalMcg,
      entryCapsules: capsuleCount,
      displayText:
          '$capsuleCount ${capsuleCount == 1 ? 'capsule' : 'capsules'} × ${formatMass(strengthPerCapsuleMcg)} = ${formatMass(totalMcg)} total',
    );
  }

  /// Calculates capsule count from desired strength.
  /// Rounds to nearest whole number.
  static EntryCalculationResult calculateFromStrengthCapsules({
    required double strengthMcg,
    required double strengthPerCapsuleMcg,
  }) {
    final exactCapsuleCount = strengthMcg / strengthPerCapsuleMcg;
    final roundedCount = exactCapsuleCount.round();

    if (roundedCount < 1) {
      return EntryCalculationResult.error(
        'Amount too small - requires less than 1 capsule',
      );
    }

    // Check if rounding was needed
    if ((exactCapsuleCount - roundedCount).abs() > 0.001) {
      return EntryCalculationResult.warning(
        entryMassMcg: roundedCount * strengthPerCapsuleMcg,
        entryCapsules: roundedCount,
        displayText:
            '${formatMass(roundedCount * strengthPerCapsuleMcg)} ($roundedCount ${roundedCount == 1 ? 'capsule' : 'capsules'})',
        warning:
            '⚠️ Amount requires ${exactCapsuleCount.toStringAsFixed(1)} capsules (rounded to $roundedCount)',
      );
    }

    return calculateFromCapsules(
      capsuleCount: roundedCount,
      strengthPerCapsuleMcg: strengthPerCapsuleMcg,
    );
  }

  // ==================== PRE-FILLED INJECTIONS ====================

  /// Calculates entry from number of pre-filled injections.
  static EntryCalculationResult calculateFromPrefilledInjections({
    required int injectionCount,
    required double strengthPerInjectionMcg,
    required double volumePerInjectionMicroliter,
  }) {
    if (injectionCount < 1) {
      return EntryCalculationResult.error('Injection count must be at least 1');
    }

    final totalMcg = injectionCount * strengthPerInjectionMcg;
    final totalVolume = injectionCount * volumePerInjectionMicroliter;

    return EntryCalculationResult.success(
      entryMassMcg: totalMcg,
      entryVolumeMicroliter: totalVolume,
      entrySyringes: injectionCount,
      displayText:
          '$injectionCount ${injectionCount == 1 ? 'injection' : 'injections'} (${formatMass(totalMcg)}, ${formatVolume(totalVolume)})',
    );
  }

  // ==================== SINGLE DOSE VIAL ====================

  /// Calculates entry from number of single-dose vials.
  static EntryCalculationResult calculateFromSingleDoseVials({
    required int vialCount,
    required double strengthPerVialMcg,
    required double volumePerVialMicroliter,
  }) {
    if (vialCount < 1) {
      return EntryCalculationResult.error('Vial count must be at least 1');
    }

    final totalMcg = vialCount * strengthPerVialMcg;
    final totalVolume = vialCount * volumePerVialMicroliter;

    return EntryCalculationResult.success(
      entryMassMcg: totalMcg,
      entryVolumeMicroliter: totalVolume,
      entryVials: vialCount,
      displayText:
          '$vialCount ${vialCount == 1 ? 'vial' : 'vials'} (${formatMass(totalMcg)}, ${formatVolume(totalVolume)} total)',
    );
  }

  // ==================== MULTI-DOSE VIAL (MDV) ====================

  /// Calculates MDV entry from desired strength.
  /// Returns strength, volume, and syringe units.
  static EntryCalculationResult calculateFromStrengthMDV({
    required double strengthMcg,
    required double totalVialStrengthMcg,
    required double totalVialVolumeMicroliter,
    required SyringeType syringeType,
  }) {
    // Validate doesn't exceed vial capacity
    if (strengthMcg > totalVialStrengthMcg) {
      return EntryCalculationResult.error(
        'Amount exceeds vial strength (${formatMass(totalVialStrengthMcg)} max)',
      );
    }

    // Calculate concentration (mcg per microliter)
    final concentration = totalVialStrengthMcg / totalVialVolumeMicroliter;

    // Calculate volume needed
    final volumeMicroliter = strengthMcg / concentration;

    // Validate doesn't exceed vial volume
    if (volumeMicroliter > totalVialVolumeMicroliter) {
      return EntryCalculationResult.error(
        'Amount exceeds vial capacity (${formatVolume(totalVialVolumeMicroliter)} max)',
      );
    }

    // Calculate syringe units
    final volumeMl = volumeMicroliter / 1000;
    final syringeUnits = volumeMl * syringeType.unitsPerMl;

    // Validate doesn't exceed syringe capacity
    if (syringeUnits > syringeType.maxUnits) {
      return EntryCalculationResult.error(
        'Amount exceeds syringe capacity (${syringeType.maxUnits}U max for ${syringeType.name} syringe)',
      );
    }

    // Warning for high entries (>80% of vial)
    if (volumeMicroliter > totalVialVolumeMicroliter * 0.8) {
      return EntryCalculationResult.warning(
        entryMassMcg: strengthMcg,
        entryVolumeMicroliter: volumeMicroliter,
        syringeUnits: syringeUnits,
        displayText:
          '${formatMass(strengthMcg)} (${formatVolume(volumeMicroliter)} / ${_trimFixed(syringeUnits.toStringAsFixed(1))}U)',
        warning: '⚠️ High entry - using >80% of vial. Verify calculation.',
      );
    }

    return EntryCalculationResult.success(
      entryMassMcg: strengthMcg,
      entryVolumeMicroliter: volumeMicroliter,
      syringeUnits: syringeUnits,
      displayText:
          '${formatMass(strengthMcg)} (${formatVolume(volumeMicroliter)} / ${_trimFixed(syringeUnits.toStringAsFixed(1))}U)',
    );
  }

  /// Calculates MDV entry from desired volume.
  /// Returns strength, volume, and syringe units.
  static EntryCalculationResult calculateFromVolumeMDV({
    required double volumeMicroliter,
    required double totalVialStrengthMcg,
    required double totalVialVolumeMicroliter,
    required SyringeType syringeType,
  }) {
    // Validate doesn't exceed vial volume
    if (volumeMicroliter > totalVialVolumeMicroliter) {
      return EntryCalculationResult.error(
        'Volume exceeds vial capacity (${formatVolume(totalVialVolumeMicroliter)} max)',
      );
    }

    // Calculate concentration and strength
    final concentration = totalVialStrengthMcg / totalVialVolumeMicroliter;
    final strengthMcg = volumeMicroliter * concentration;

    return calculateFromStrengthMDV(
      strengthMcg: strengthMcg,
      totalVialStrengthMcg: totalVialStrengthMcg,
      totalVialVolumeMicroliter: totalVialVolumeMicroliter,
      syringeType: syringeType,
    );
  }

  /// Calculates MDV entry from syringe units.
  /// Returns strength, volume, and syringe units.
  static EntryCalculationResult calculateFromUnitsMDV({
    required double syringeUnits,
    required double totalVialStrengthMcg,
    required double totalVialVolumeMicroliter,
    required SyringeType syringeType,
  }) {
    // Validate doesn't exceed syringe capacity
    if (syringeUnits > syringeType.maxUnits) {
      return EntryCalculationResult.error(
        'Units exceed syringe capacity (${syringeType.maxUnits}U max for ${syringeType.name} syringe)',
      );
    }

    // Calculate volume from units
    final volumeMl = syringeUnits / syringeType.unitsPerMl;
    final volumeMicroliter = volumeMl * 1000;

    return calculateFromVolumeMDV(
      volumeMicroliter: volumeMicroliter,
      totalVialStrengthMcg: totalVialStrengthMcg,
      totalVialVolumeMicroliter: totalVialVolumeMicroliter,
      syringeType: syringeType,
    );
  }

  // ==================== FORMATTING HELPERS ====================

  /// Formats mass (mcg/mg/g) with appropriate unit.
  static String formatMass(double mcg) {
    if (mcg >= 1000000) {
      return '${_trimFixed((mcg / 1000000).toStringAsFixed(1))}g';
    }
    if (mcg >= 1000) {
      return '${_trimFixed((mcg / 1000).toStringAsFixed(1))}mg';
    }
    return '${mcg.toStringAsFixed(0)}mcg';
  }

  /// Formats volume (ml) from microliters.
  static String formatVolume(double microliter) {
    return '${_trimFixed((microliter / 1000).toStringAsFixed(2))}ml';
  }

  static String _trimFixed(String value) {
    if (!value.contains('.')) return value;
    return value.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  /// Formats tablet count (shows fractions for < 1).
  static String _formatTabletCount(double count) {
    if (count < 1) {
      final quarters = (count * 4).round();
      if (quarters == 1) return '1/4';
      if (quarters == 2) return '1/2';
      if (quarters == 3) return '3/4';
    }

    // Check if whole number
    if (count % 1 == 0) {
      return count.toInt().toString();
    }

    return count.toStringAsFixed(2).replaceAll(RegExp(r'\.?0*$'), '');
  }
}

// ==================== SYRINGE TYPES ====================

/// Syringe types with unit scales.
enum SyringeType {
  ml_0_3(unitsPerMl: 100, maxUnits: 30, maxMl: 0.3, name: '0.3ml'),
  ml_0_5(unitsPerMl: 100, maxUnits: 50, maxMl: 0.5, name: '0.5ml'),
  ml_1_0(unitsPerMl: 100, maxUnits: 100, maxMl: 1.0, name: '1ml'),
  ml_3_0(unitsPerMl: 100, maxUnits: 300, maxMl: 3.0, name: '3ml'),
  ml_5_0(unitsPerMl: 100, maxUnits: 500, maxMl: 5.0, name: '5ml'),
  ml_10_0(unitsPerMl: 100, maxUnits: 1000, maxMl: 10.0, name: '10ml');

  const SyringeType({
    required this.unitsPerMl,
    required this.maxUnits,
    required this.maxMl,
    required this.name,
  });

  final double unitsPerMl;
  final double maxUnits;
  final double maxMl;
  final String name;
}

/// Centralized lookup helpers for syringe sizing.
class SyringeTypeLookup {
  /// Common syringe size presets intended for UI quick-pick controls.
  ///
  /// Excludes 10ml by default because it tends to be rare/noisy in everyday use.
  static const List<SyringeType> commonPresets = <SyringeType>[
    SyringeType.ml_0_3,
    SyringeType.ml_0_5,
    SyringeType.ml_1_0,
    SyringeType.ml_3_0,
    SyringeType.ml_5_0,
  ];

  static SyringeType forVolumeMl(double volumeMl) {
    if (volumeMl <= 0.3) return SyringeType.ml_0_3;
    if (volumeMl <= 0.5) return SyringeType.ml_0_5;
    if (volumeMl <= 1.0) return SyringeType.ml_1_0;
    if (volumeMl <= 3.0) return SyringeType.ml_3_0;
    if (volumeMl <= 5.0) return SyringeType.ml_5_0;
    return SyringeType.ml_10_0;
  }

  static SyringeType forUnits(double units) {
    final volumeMl = units / SyringeType.ml_1_0.unitsPerMl;
    return forVolumeMl(volumeMl);
  }
}

// ==================== RESULT CLASSES ====================

/// Result of a entry calculation.
@immutable
class EntryCalculationResult {
  const EntryCalculationResult({
    required this.success,
    required this.displayText,
    this.error,
    this.warning,
    this.entryMassMcg,
    this.entryVolumeMicroliter,
    this.entryTabletQuarters,
    this.entryCapsules,
    this.entrySyringes,
    this.entryVials,
    this.syringeUnits,
  });

  final bool success;
  final String displayText;
  final String? error;
  final String? warning;

  // Typed entry fields
  final double? entryMassMcg;
  final double? entryVolumeMicroliter;
  final int? entryTabletQuarters;
  final int? entryCapsules;
  final int? entrySyringes;
  final int? entryVials;
  final double? syringeUnits;

  bool get hasError => error != null;
  bool get hasWarning => warning != null;

  factory EntryCalculationResult.success({
    required String displayText,
    double? entryMassMcg,
    double? entryVolumeMicroliter,
    int? entryTabletQuarters,
    int? entryCapsules,
    int? entrySyringes,
    int? entryVials,
    double? syringeUnits,
  }) {
    return EntryCalculationResult(
      success: true,
      displayText: displayText,
      entryMassMcg: entryMassMcg,
      entryVolumeMicroliter: entryVolumeMicroliter,
      entryTabletQuarters: entryTabletQuarters,
      entryCapsules: entryCapsules,
      entrySyringes: entrySyringes,
      entryVials: entryVials,
      syringeUnits: syringeUnits,
    );
  }

  factory EntryCalculationResult.error(String message) {
    return EntryCalculationResult(
      success: false,
      displayText: '',
      error: message,
    );
  }

  factory EntryCalculationResult.warning({
    required String displayText,
    required String warning,
    double? entryMassMcg,
    double? entryVolumeMicroliter,
    int? entryTabletQuarters,
    int? entryCapsules,
    int? entrySyringes,
    int? entryVials,
    double? syringeUnits,
  }) {
    return EntryCalculationResult(
      success: true,
      displayText: displayText,
      warning: warning,
      entryMassMcg: entryMassMcg,
      entryVolumeMicroliter: entryVolumeMicroliter,
      entryTabletQuarters: entryTabletQuarters,
      entryCapsules: entryCapsules,
      entrySyringes: entrySyringes,
      entryVials: entryVials,
      syringeUnits: syringeUnits,
    );
  }

  @override
  String toString() => displayText;
}
