// Project imports:
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

class MedicationStockAdjustment {
  const MedicationStockAdjustment._();

  static double? tryCalculateStockDelta({
    required Medication medication,
    Schedule? schedule,
    double? doseValue,
    String? doseUnit,
  }) {
    final StockUnit stockUnit = medication.stockUnit;

    if (schedule != null) {
      final calculated = _tryCalculateFromSchedule(
        medication: medication,
        schedule: schedule,
      );
      if (calculated != null && calculated > 0) return calculated;

      // Fallback: if schedule is a simple numeric unit that matches stockUnit.
      final scheduleUnit = schedule.doseUnit.trim().toLowerCase();
      final scheduleValue = schedule.doseValue;
      if (scheduleValue > 0 &&
          _doseUnitMatchesStockUnit(scheduleUnit, stockUnit)) {
        return scheduleValue.toDouble();
      }
    }

    if (doseValue != null && doseValue > 0) {
      final unit = (doseUnit ?? '').trim().toLowerCase();

      if (stockUnit == StockUnit.multiDoseVials) {
        // For MDV, delta is mL consumed; only accept direct volume units.
        if (_looksLikeMl(unit)) return doseValue;
        return null;
      }

      if (unit.isEmpty || _doseUnitMatchesStockUnit(unit, stockUnit)) {
        return doseValue;
      }

      // Mass fallbacks: if doseUnit is a mass unit that matches stockUnit.
      final massDelta = _tryConvertMassToStockUnit(doseValue, unit, stockUnit);
      if (massDelta != null && massDelta > 0) return massDelta;
    }

    return null;
  }

  static Medication deduct({
    required Medication medication,
    required double delta,
  }) {
    if (delta <= 0) return medication;

    if (medication.stockUnit == StockUnit.multiDoseVials) {
      final max = medication.containerVolumeMl;
      final current = medication.activeVialVolume ?? 0.0;
      final next = (current - delta).clamp(0.0, max ?? double.infinity);
      return medication.copyWith(activeVialVolume: next);
    }

    final next = (medication.stockValue - delta).clamp(0.0, double.infinity);
    return medication.copyWith(stockValue: next);
  }

  static Medication restore({
    required Medication medication,
    required double delta,
  }) {
    if (delta <= 0) return medication;

    if (medication.stockUnit == StockUnit.multiDoseVials) {
      final max = medication.containerVolumeMl;
      final current = medication.activeVialVolume ?? 0.0;
      final next = (current + delta).clamp(0.0, max ?? double.infinity);
      return medication.copyWith(activeVialVolume: next);
    }

    return medication.copyWith(stockValue: medication.stockValue + delta);
  }

  static double? _tryCalculateFromSchedule({
    required Medication medication,
    required Schedule schedule,
  }) {
    switch (medication.stockUnit) {
      case StockUnit.tablets:
        if (schedule.doseTabletQuarters != null) {
          return schedule.doseTabletQuarters! / 4.0;
        }
        if (schedule.doseMassMcg != null) {
          final perTabMcg = _convertToMcg(
            medication.strengthValue,
            medication.strengthUnit,
          );
          if (perTabMcg <= 0) return null;
          return (schedule.doseMassMcg! / perTabMcg).clamp(
            0.0,
            double.infinity,
          );
        }
        return null;

      case StockUnit.capsules:
        if (schedule.doseCapsules != null) {
          return schedule.doseCapsules!.toDouble();
        }
        if (schedule.doseMassMcg != null) {
          final perCapMcg = _convertToMcg(
            medication.strengthValue,
            medication.strengthUnit,
          );
          if (perCapMcg <= 0) return null;
          return (schedule.doseMassMcg! / perCapMcg).clamp(
            0.0,
            double.infinity,
          );
        }
        return null;

      case StockUnit.preFilledSyringes:
        if (schedule.doseSyringes != null) {
          return schedule.doseSyringes!.toDouble();
        }
        return null;

      case StockUnit.singleDoseVials:
        if (schedule.doseVials != null) {
          return schedule.doseVials!.toDouble();
        }
        return null;

      case StockUnit.multiDoseVials:
        // Delta is mL consumed from the active vial.
        final usedMl = _tryCalculateMdvUsedMl(
          medication: medication,
          schedule: schedule,
        );
        if (usedMl != null && usedMl > 0) return usedMl;
        return null;

      case StockUnit.mcg:
        if (schedule.doseMassMcg != null) {
          return schedule.doseMassMcg!.toDouble();
        }
        return null;

      case StockUnit.mg:
        if (schedule.doseMassMcg != null) {
          return schedule.doseMassMcg! / 1000.0;
        }
        return null;

      case StockUnit.g:
        if (schedule.doseMassMcg != null) {
          return schedule.doseMassMcg! / 1e6;
        }
        return null;
    }
  }

  static double? _tryCalculateMdvUsedMl({
    required Medication medication,
    required Schedule schedule,
  }) {
    if (schedule.doseVolumeMicroliter != null) {
      return schedule.doseVolumeMicroliter! / 1000.0;
    }

    // Fallback: allow explicit mL doseValue in schedule.
    final scheduleUnit = schedule.doseUnit.trim().toLowerCase();
    if (_looksLikeMl(scheduleUnit) && schedule.doseValue > 0) {
      return schedule.doseValue.toDouble();
    }

    if (schedule.doseMassMcg != null) {
      final mgPerMl = _tryGetMgPerMl(medication);
      if (mgPerMl == null || mgPerMl <= 0) return null;
      final mg = schedule.doseMassMcg! / 1000.0;
      return mg / mgPerMl;
    }

    if (schedule.doseIU != null) {
      final iuPerMl = _tryGetUnitsPerMl(medication);
      if (iuPerMl == null || iuPerMl <= 0) return null;
      return schedule.doseIU! / iuPerMl;
    }

    return null;
  }

  static double? _tryGetMgPerMl(Medication medication) {
    switch (medication.strengthUnit) {
      case Unit.mgPerMl:
        return medication.perMlValue ?? medication.strengthValue;
      case Unit.mcgPerMl:
        return (medication.perMlValue ?? medication.strengthValue) / 1000.0;
      case Unit.gPerMl:
        return (medication.perMlValue ?? medication.strengthValue) * 1000.0;
      default:
        return null;
    }
  }

  static double? _tryGetUnitsPerMl(Medication medication) {
    if (medication.strengthUnit != Unit.unitsPerMl) return null;
    return medication.perMlValue ?? medication.strengthValue;
  }

  static double _convertToMcg(double value, Unit unit) {
    switch (unit) {
      case Unit.mcg:
        return value;
      case Unit.mg:
        return value * 1000.0;
      case Unit.g:
        return value * 1e6;
      default:
        return 0.0;
    }
  }

  static bool _doseUnitMatchesStockUnit(String doseUnit, StockUnit stockUnit) {
    if (doseUnit.isEmpty) return false;

    switch (stockUnit) {
      case StockUnit.tablets:
        return doseUnit.contains('tablet');
      case StockUnit.capsules:
        return doseUnit.contains('capsule');
      case StockUnit.preFilledSyringes:
        return doseUnit.contains('syringe');
      case StockUnit.singleDoseVials:
        return doseUnit.contains('vial');
      case StockUnit.multiDoseVials:
        return _looksLikeMl(doseUnit);
      case StockUnit.mcg:
        return doseUnit == 'mcg' || doseUnit == 'μg' || doseUnit == 'ug';
      case StockUnit.mg:
        return doseUnit == 'mg';
      case StockUnit.g:
        return doseUnit == 'g';
    }
  }

  static bool _looksLikeMl(String unit) {
    return unit == 'ml' || unit == 'mL'.toLowerCase() || unit.contains('ml');
  }

  static double? _tryConvertMassToStockUnit(
    double value,
    String unit,
    StockUnit stockUnit,
  ) {
    if (stockUnit != StockUnit.mcg &&
        stockUnit != StockUnit.mg &&
        stockUnit != StockUnit.g) {
      return null;
    }

    final mcg = switch (unit) {
      'mcg' => value,
      'μg' => value,
      'ug' => value,
      'mg' => value * 1000.0,
      'g' => value * 1e6,
      _ => null,
    };

    if (mcg == null) return null;

    return switch (stockUnit) {
      StockUnit.mcg => mcg,
      StockUnit.mg => mcg / 1000.0,
      StockUnit.g => mcg / 1e6,
      _ => null,
    };
  }
}
