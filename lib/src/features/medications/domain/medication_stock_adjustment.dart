// Project imports:
import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';

class MedicationStockAdjustment {
  const MedicationStockAdjustment._();

  static double? tryCalculateStockDelta({
    required Medication medication,
    Schedule? schedule,
    double? entryValue,
    String? entryUnit,
    bool preferEntryValue = false,
  }) {
    final StockUnit stockUnit = medication.stockUnit;

    if (preferEntryValue && entryValue != null && entryValue > 0) {
      final delta = _tryCalculateFromEntryValue(
        medication: medication,
        entryValue: entryValue,
        entryUnit: entryUnit,
      );
      if (delta != null && delta > 0) return delta;
    }

    if (schedule != null) {
      final calculated = _tryCalculateFromSchedule(
        medication: medication,
        schedule: schedule,
      );
      if (calculated != null && calculated > 0) return calculated;

      // Fallback: if schedule is a simple numeric unit that matches stockUnit.
      final scheduleUnit = schedule.entryUnit.trim().toLowerCase();
      final scheduleValue = schedule.entryValue;
      if (scheduleValue > 0 &&
          _entryUnitMatchesStockUnit(scheduleUnit, stockUnit)) {
        return scheduleValue.toDouble();
      }
    }

    if (entryValue != null && entryValue > 0) {
      final unit = (entryUnit ?? '').trim().toLowerCase();

      if (stockUnit == StockUnit.multiDoseVials) {
        // For MDV, delta is mL consumed; only accept direct volume units.
        if (_looksLikeMl(unit)) return entryValue;
        return null;
      }

      if (unit.isEmpty || _entryUnitMatchesStockUnit(unit, stockUnit)) {
        return entryValue;
      }

      // Mass fallbacks: if entryUnit is a mass unit that matches stockUnit.
      final massDelta = _tryConvertMassToStockUnit(entryValue, unit, stockUnit);
      if (massDelta != null && massDelta > 0) return massDelta;
    }

    return null;
  }

  static double? _tryCalculateFromEntryValue({
    required Medication medication,
    required double entryValue,
    String? entryUnit,
  }) {
    final StockUnit stockUnit = medication.stockUnit;
    final unit = (entryUnit ?? '').trim().toLowerCase();

    if (stockUnit == StockUnit.multiDoseVials) {
      // For MDV, delta is mL consumed; only accept direct volume units.
      if (_looksLikeMl(unit)) return entryValue;
      return null;
    }

    if (unit.isEmpty || _entryUnitMatchesStockUnit(unit, stockUnit)) {
      return entryValue;
    }

    final massDelta = _tryConvertMassToStockUnit(entryValue, unit, stockUnit);
    if (massDelta != null && massDelta > 0) return massDelta;

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
        if (schedule.entryTabletQuarters != null) {
          return schedule.entryTabletQuarters! / 4.0;
        }
        if (schedule.entryMassMcg != null) {
          final perTabMcg = _convertToMcg(
            medication.strengthValue,
            medication.strengthUnit,
          );
          if (perTabMcg <= 0) return null;
          return (schedule.entryMassMcg! / perTabMcg).clamp(
            0.0,
            double.infinity,
          );
        }
        return null;

      case StockUnit.capsules:
        if (schedule.entryCapsules != null) {
          return schedule.entryCapsules!.toDouble();
        }
        if (schedule.entryMassMcg != null) {
          final perCapMcg = _convertToMcg(
            medication.strengthValue,
            medication.strengthUnit,
          );
          if (perCapMcg <= 0) return null;
          return (schedule.entryMassMcg! / perCapMcg).clamp(
            0.0,
            double.infinity,
          );
        }
        return null;

      case StockUnit.preFilledSyringes:
        if (schedule.entrySyringes != null) {
          return schedule.entrySyringes!.toDouble();
        }
        return null;

      case StockUnit.singleDoseVials:
        if (schedule.entryVials != null) {
          return schedule.entryVials!.toDouble();
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
        if (schedule.entryMassMcg != null) {
          return schedule.entryMassMcg!.toDouble();
        }
        return null;

      case StockUnit.mg:
        if (schedule.entryMassMcg != null) {
          return schedule.entryMassMcg! / 1000.0;
        }
        return null;

      case StockUnit.g:
        if (schedule.entryMassMcg != null) {
          return schedule.entryMassMcg! / 1e6;
        }
        return null;
    }
  }

  static double? _tryCalculateMdvUsedMl({
    required Medication medication,
    required Schedule schedule,
  }) {
    if (schedule.entryVolumeMicroliter != null) {
      return schedule.entryVolumeMicroliter! / 1000.0;
    }

    // Fallback: allow explicit mL entryValue in schedule.
    final scheduleUnit = schedule.entryUnit.trim().toLowerCase();
    if (_looksLikeMl(scheduleUnit) && schedule.entryValue > 0) {
      return schedule.entryValue.toDouble();
    }

    if (schedule.entryMassMcg != null) {
      final mgPerMl = _tryGetMgPerMl(medication);
      if (mgPerMl == null || mgPerMl <= 0) return null;
      final mg = schedule.entryMassMcg! / 1000.0;
      return mg / mgPerMl;
    }

    if (schedule.entryIU != null) {
      final iuPerMl = _tryGetUnitsPerMl(medication);
      if (iuPerMl == null || iuPerMl <= 0) return null;
      return schedule.entryIU! / iuPerMl;
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

  static bool _entryUnitMatchesStockUnit(String entryUnit, StockUnit stockUnit) {
    if (entryUnit.isEmpty) return false;

    switch (stockUnit) {
      case StockUnit.tablets:
        return entryUnit.contains('tablet');
      case StockUnit.capsules:
        return entryUnit.contains('capsule');
      case StockUnit.preFilledSyringes:
        return entryUnit.contains('syringe');
      case StockUnit.singleDoseVials:
        return entryUnit.contains('vial');
      case StockUnit.multiDoseVials:
        return _looksLikeMl(entryUnit);
      case StockUnit.mcg:
        return entryUnit == 'mcg' || entryUnit == 'μg' || entryUnit == 'ug';
      case StockUnit.mg:
        return entryUnit == 'mg';
      case StockUnit.g:
        return entryUnit == 'g';
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
