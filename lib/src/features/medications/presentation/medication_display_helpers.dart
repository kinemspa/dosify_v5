import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

/// Centralized helpers for displaying medication information.
class MedicationDisplayHelpers {
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
