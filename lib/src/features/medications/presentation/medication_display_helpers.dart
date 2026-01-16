import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
// import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart'; // unused

/// Centralized helpers for displaying medication information.
class MedicationDisplayHelpers {
  static IconData medicationFormIcon(MedicationForm form) {
    // Keep icons consistent with the add-medication wizards.
    return switch (form) {
      MedicationForm.tablet => Icons.medication,
      MedicationForm.capsule => Icons.medication_liquid,
      MedicationForm.prefilledSyringe => Icons.vaccines,
      MedicationForm.singleDoseVial => Icons.science,
      MedicationForm.multiDoseVial => Icons.science,
    };
  }

  static String formatDoseMassFromMcg(Medication med, double mcg) {
    switch (med.strengthUnit) {
      case Unit.mcg:
      case Unit.mcgPerMl:
        return '${fmt2(mcg)} mcg';
      case Unit.mg:
      case Unit.mgPerMl:
        return '${fmt3(mcg / 1000)} mg';
      case Unit.g:
      case Unit.gPerMl:
        return '${fmt3(mcg / 1000000)} g';
      case Unit.units:
      case Unit.unitsPerMl:
        return '${fmt2(mcg)} units';
    }
  }

  static String formatDoseVolumeFromMicroliter(double microliter) {
    return '${fmt2(microliter / 1000)} mL';
  }

  static String formatSyringeUnits(double units, {bool longLabel = false}) {
    final value = units.ceil().toString();
    if (longLabel) return '$value units';
    return '$value U';
  }

  static String strengthOrConcentrationLabel(
    Medication med, {
    bool includePerUnit = true,
  }) {
    final unit = unitLabel(med.strengthUnit);

    final isPerMl = switch (med.strengthUnit) {
      Unit.mcgPerMl || Unit.mgPerMl || Unit.gPerMl || Unit.unitsPerMl => true,
      _ => false,
    };

    final term = isPerMl ? 'Concentration' : 'Strength';
    final value = fmt2(med.strengthValue);

    if (isPerMl) {
      return '$term: $value $unit';
    }

    if (!includePerUnit) {
      return '$term: $value $unit';
    }

    final perUnit = switch (med.form) {
      MedicationForm.tablet => 'tablet',
      MedicationForm.capsule => 'capsule',
      MedicationForm.prefilledSyringe => 'syringe',
      MedicationForm.singleDoseVial => 'vial',
      MedicationForm.multiDoseVial => null,
    };

    if (perUnit == null) return '$term: $value $unit';
    return '$term: $value $unit $perUnit';
  }

  static String unitLabel(Unit unit) {
    switch (unit) {
      case Unit.mcg:
        return 'mcg';
      case Unit.mg:
        return 'mg';
      case Unit.g:
        return 'g';
      case Unit.units:
        return 'units';
      case Unit.mcgPerMl:
        return 'mcg/mL';
      case Unit.mgPerMl:
        return 'mg/mL';
      case Unit.gPerMl:
        return 'g/mL';
      case Unit.unitsPerMl:
        return 'units/mL';
    }
  }

  /// Formats dose metrics consistently across screens.
  ///
  /// Inputs:
  /// - [med] provides the dosage form and preferred strength unit.
  /// - Dose inputs are expected to be in the same units used by schedules:
  ///   - [doseMassMcg] in micrograms
  ///   - [doseVolumeMicroliter] in microliters
  ///   - [syringeUnits] in device units (U)
  ///
  /// The returned string is intended for compact summaries (single line).
  static String doseMetricsSummary(
    Medication med, {
    int? doseTabletQuarters,
    int? doseCapsules,
    int? doseSyringes,
    int? doseVials,
    double? doseMassMcg,
    double? doseVolumeMicroliter,
    double? syringeUnits,
    String separator = ' • ',
  }) {
    String formatTabletCountFromQuarters(int quarters) {
      if (quarters == 1) return '1/4';
      if (quarters == 2) return '1/2';
      if (quarters == 3) return '3/4';
      final count = quarters / 4.0;
      if (count % 1 == 0) return count.toInt().toString();
      return fmt2(count);
    }

    String formatStrengthFromMcg(double mcg) {
      return formatDoseMassFromMcg(med, mcg);
    }

    final metrics = <String>[];

    switch (med.form) {
      case MedicationForm.tablet:
        if (doseTabletQuarters != null) {
          final quarters = doseTabletQuarters;
          final count = quarters / 4.0;
          final unit = (count - 1.0).abs() < 0.0001 || count < 1
              ? 'tablet'
              : 'tablets';
          metrics.add('${formatTabletCountFromQuarters(quarters)} $unit');
        }
      case MedicationForm.capsule:
        if (doseCapsules != null) {
          final n = doseCapsules;
          metrics.add('$n ${n == 1 ? 'capsule' : 'capsules'}');
        }
      case MedicationForm.prefilledSyringe:
        if (doseSyringes != null) {
          final n = doseSyringes;
          metrics.add('$n ${n == 1 ? 'syringe' : 'syringes'}');
        }
      case MedicationForm.singleDoseVial:
        if (doseVials != null) {
          final n = doseVials;
          metrics.add('$n ${n == 1 ? 'vial' : 'vials'}');
        }
      case MedicationForm.multiDoseVial:
        break;
    }

    if (doseMassMcg != null) {
      metrics.add(formatStrengthFromMcg(doseMassMcg));
    }

    if (doseVolumeMicroliter != null) {
      metrics.add(formatDoseVolumeFromMicroliter(doseVolumeMicroliter));
    }

    if (syringeUnits != null) {
      metrics.add(
        formatSyringeUnits(
          syringeUnits,
          longLabel: med.form == MedicationForm.multiDoseVial,
        ),
      );
    }

    if (metrics.isEmpty) return '';
    return metrics.join(separator);
  }

  static String formLabel(MedicationForm form, {bool plural = false}) {
    if (plural) {
      switch (form) {
        case MedicationForm.tablet:
          return 'Tablets';
        case MedicationForm.capsule:
          return 'Capsules';
        case MedicationForm.prefilledSyringe:
          return 'Pre-Filled Syringes';
        case MedicationForm.singleDoseVial:
          return 'Single Dose Vials';
        case MedicationForm.multiDoseVial:
          return 'Multi Dose Vial';
      }
    }
    // Singular
    switch (form) {
      case MedicationForm.tablet:
        return 'Tablet';
      case MedicationForm.capsule:
        return 'Capsule';
      case MedicationForm.prefilledSyringe:
        return 'Pre-Filled Syringe';
      case MedicationForm.singleDoseVial:
        return 'Single Dose Vial';
      case MedicationForm.multiDoseVial:
        return 'Multi Dose Vial';
    }
  }

  static String stockUnitLabel(StockUnit unit) {
    switch (unit) {
      case StockUnit.tablets:
        return 'tablets';
      case StockUnit.capsules:
        return 'capsules';
      case StockUnit.preFilledSyringes:
        return 'syringes';
      case StockUnit.singleDoseVials:
        return 'vials';
      case StockUnit.multiDoseVials:
        return 'vials';
      case StockUnit.mcg:
        return 'mcg';
      case StockUnit.mg:
        return 'mg';
      case StockUnit.g:
        return 'g';
    }
  }

  static StockDisplayInfo calculateStock(Medication m) {
    final isCountUnit =
        m.stockUnit == StockUnit.preFilledSyringes ||
        m.stockUnit == StockUnit.singleDoseVials ||
        m.stockUnit == StockUnit.multiDoseVials ||
        m.stockUnit == StockUnit.tablets ||
        m.stockUnit == StockUnit.capsules;
    final isMdv = m.form == MedicationForm.multiDoseVial;

    double current;
    double total;

    if (isMdv && m.containerVolumeMl != null && m.containerVolumeMl! > 0) {
      // MDV Logic
      total = m.containerVolumeMl!;
      if (m.activeVialVolume == null && m.stockValue > m.containerVolumeMl!) {
        // Legacy data fix
        current = m.containerVolumeMl!;
      } else {
        current = m.activeVialVolume ?? m.stockValue;
      }
      // Clamp
      current = current.clamp(0, total);
    } else if (isCountUnit) {
      current = m.stockValue.floorToDouble();
      total = (m.initialStockValue != null && m.initialStockValue! > 0)
          ? m.initialStockValue!.ceilToDouble()
          : current;
    } else {
      current = m.stockValue;
      total = m.initialStockValue ?? m.stockValue;
    }

    final pct = total > 0 ? (current / total) * 100.0 : 0.0;

    // Backup percentage for MDV
    double backupPct = 0;
    if (isMdv && m.stockUnit == StockUnit.multiDoseVials) {
      final backupCount = m.stockValue;
      final baseline =
          m.lowStockVialsThresholdCount != null &&
              m.lowStockVialsThresholdCount! > 0
          ? m.lowStockVialsThresholdCount!
          : backupCount;
      backupPct = baseline > 0 ? (backupCount / baseline) * 100.0 : 0.0;
    }

    // Label generation
    String label;
    if (isMdv) {
      label = '${fmt2(current)}/${fmt2(total)} mL';
    } else if (isCountUnit) {
      label =
          '${current.toStringAsFixed(0)}/${total.toStringAsFixed(0)} ${stockUnitLabel(m.stockUnit)}';
    } else {
      label = '${fmt2(current)}/${fmt2(total)} ${stockUnitLabel(m.stockUnit)}';
    }

    return StockDisplayInfo(
      current: current,
      total: total,
      percentage: pct,
      label: label,
      backupPercentage: backupPct,
      isMdv: isMdv,
      isCountUnit: isCountUnit,
    );
  }
}

class StockDisplayInfo {
  final double current;
  final double total;
  final double percentage;
  final String label;
  final double backupPercentage;
  final bool isMdv;
  final bool isCountUnit;

  StockDisplayInfo({
    required this.current,
    required this.total,
    required this.percentage,
    required this.label,
    required this.backupPercentage,
    required this.isMdv,
    required this.isCountUnit,
  });

  String get fractionPart => label.split(' ').first;
  String get unitPart =>
      label.split(' ').length > 1 ? label.split(' ').sublist(1).join(' ') : '';
}

/// Apply a single scheduled dose decrement to a medication and return an updated
/// Medication object.
///
/// Behavior:
/// - For tablets/capsules/single dose vials/pre-filled syringes, this subtracts
///   the relevant quantity from `stockValue`.
/// - For multi-dose vials (MDV) it decrements `activeVialVolume` first and, if
///   the active vial is depleted, opens backup sealed vials (reducing `stockValue`)
///   as required to satisfy the dose. The helper will consume multiple backup
///   vials if necessary, and clamps values to non-negative ranges.
/// - Returns `null` if the decrement could not be computed (e.g., missing
///   strength, missing per-mL conversions required for MDV dosing).
Medication? applyDoseTakenUpdate(Medication med, Schedule s) {
  // Copy candidates
  var updated = med;

  switch (med.stockUnit) {
    case StockUnit.tablets:
      double delta = 0.0;
      if (s.doseTabletQuarters != null) {
        delta = s.doseTabletQuarters! / 4.0;
      } else if (s.doseMassMcg != null) {
        final perTabMcg = switch (med.strengthUnit) {
          Unit.mcg => med.strengthValue,
          Unit.mg => med.strengthValue * 1000,
          Unit.g => med.strengthValue * 1e6,
          Unit.units => med.strengthValue,
          Unit.mcgPerMl => med.strengthValue,
          Unit.mgPerMl => med.strengthValue * 1000,
          Unit.gPerMl => med.strengthValue * 1e6,
          Unit.unitsPerMl => med.strengthValue,
        };
        delta = (s.doseMassMcg! / perTabMcg).clamp(0, double.infinity);
      }
      if (delta <= 0) return null;
      updated = updated.copyWith(
        stockValue: (med.stockValue - delta).clamp(0.0, double.infinity),
      );
      return updated;

    case StockUnit.capsules:
      double delta = 0.0;
      if (s.doseCapsules != null) {
        delta = s.doseCapsules!.toDouble();
      } else if (s.doseMassMcg != null) {
        final perCapMcg = switch (med.strengthUnit) {
          Unit.mcg => med.strengthValue,
          Unit.mg => med.strengthValue * 1000,
          Unit.g => med.strengthValue * 1e6,
          Unit.units => med.strengthValue,
          _ => med.strengthValue,
        };
        delta = (s.doseMassMcg! / perCapMcg).clamp(0, double.infinity);
      }
      if (delta <= 0) return null;
      updated = updated.copyWith(
        stockValue: (med.stockValue - delta).clamp(0.0, double.infinity),
      );
      return updated;

    case StockUnit.preFilledSyringes:
      if (s.doseSyringes != null) {
        final delta = s.doseSyringes!.toDouble();
        updated = updated.copyWith(
          stockValue: (med.stockValue - delta).clamp(0.0, double.infinity),
        );
        return updated;
      }
      return null;

    case StockUnit.singleDoseVials:
      if (s.doseVials != null) {
        final delta = s.doseVials!.toDouble();
        updated = updated.copyWith(
          stockValue: (med.stockValue - delta).clamp(0.0, double.infinity),
        );
        return updated;
      }
      return null;

    case StockUnit.multiDoseVials:
      // For MDV: compute used milliliters and decrement active vial first
      var usedMl = 0.0;
      if (s.doseVolumeMicroliter != null) {
        usedMl = s.doseVolumeMicroliter! / 1000.0;
      } else if (s.doseMassMcg != null) {
        double? mgPerMl;
        switch (med.strengthUnit) {
          case Unit.mgPerMl:
            mgPerMl = med.perMlValue ?? med.strengthValue;
            break;
          case Unit.mcgPerMl:
            mgPerMl = (med.perMlValue ?? med.strengthValue) / 1000.0;
            break;
          case Unit.gPerMl:
            mgPerMl = (med.perMlValue ?? med.strengthValue) * 1000.0;
            break;
          default:
            mgPerMl = null;
        }
        if (mgPerMl != null) usedMl = (s.doseMassMcg! / 1000.0) / mgPerMl;
      } else if (s.doseIU != null) {
        double? iuPerMl;
        if (med.strengthUnit == Unit.unitsPerMl)
          iuPerMl = med.perMlValue ?? med.strengthValue;
        if (iuPerMl != null) usedMl = s.doseIU! / iuPerMl;
      }

      if (usedMl > 0) {
        final isLegacyCount =
            med.activeVialVolume == null &&
            med.stockValue > (med.containerVolumeMl ?? 0);
        final currentActive = isLegacyCount
            ? (med.containerVolumeMl ?? 0.0)
            : (med.activeVialVolume ?? med.stockValue);
        var newActive = currentActive - usedMl;
        var newBackup = med.stockValue;
        if (med.activeVialVolume == null) {
          if (isLegacyCount)
            newBackup = (med.stockValue - 1).clamp(0.0, double.infinity);
          else
            newBackup = 0;
        }
        if (newActive < 0) {
          final capacity = med.containerVolumeMl ?? 0.0;
          if (capacity > 0) {
            // Compute how many additional sealed vials are needed
            var deficit = -newActive;
            var extraVialsNeeded = (deficit / capacity).ceil();
            if (newBackup >= extraVialsNeeded) {
              newBackup = newBackup - extraVialsNeeded;
              newActive =
                  newActive +
                  extraVialsNeeded * capacity; // bring back to non-negative
            } else {
              // Use whatever backup vials are available; if insufficient, clamp remaining active to 0
              final usedVials = newBackup;
              newBackup = 0;
              newActive = newActive + usedVials * capacity;
              if (newActive < 0) newActive = 0;
            }
          } else {
            // No container capacity info; consume one backup if available as best-effort
            if (newBackup > 0) {
              newBackup = (newBackup - 1).clamp(0.0, double.infinity);
              newActive =
                  0; // best-effort: no remaining active volume unless otherwise tracked
            } else {
              newActive = 0;
            }
          }
        }
        updated = updated.copyWith(
          activeVialVolume: newActive.clamp(0.0, double.infinity),
          stockValue: newBackup.clamp(0.0, double.infinity),
        );
        return updated;
      }
      return null;

    case StockUnit.mcg:
      if (s.doseMassMcg != null) {
        final delta = s.doseMassMcg!.toDouble();
        updated = updated.copyWith(
          stockValue: (med.stockValue - delta).clamp(0.0, double.infinity),
        );
        return updated;
      }
      return null;
    case StockUnit.mg:
      if (s.doseMassMcg != null) {
        final delta = s.doseMassMcg! / 1000.0;
        updated = updated.copyWith(
          stockValue: (med.stockValue - delta).clamp(0.0, double.infinity),
        );
        return updated;
      }
      return null;
    case StockUnit.g:
      if (s.doseMassMcg != null) {
        final delta = s.doseMassMcg! / 1e6;
        updated = updated.copyWith(
          stockValue: (med.stockValue - delta).clamp(0.0, double.infinity),
        );
        return updated;
      }
      return null;
  }
}
