// Package imports:
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/hive/hive_box_safe_write.dart';
import 'package:dosifi_v5/src/features/medications/domain/saved_reconstitution_calculation.dart';

class SavedReconstitutionRepository {
  static const String boxName = 'saved_reconstitutions';

  static String ownedIdForMedication(String medicationId) => 'med:$medicationId';

  Box<SavedReconstitutionCalculation> get _box =>
      Hive.box<SavedReconstitutionCalculation>(boxName);

  SavedReconstitutionCalculation? get(String id) => _box.get(id);

  ValueListenable<Box<SavedReconstitutionCalculation>> listenable() =>
      _box.listenable();

  List<SavedReconstitutionCalculation> allSorted({bool includeOwned = true}) {
    final items = _box.values
        .where((item) => includeOwned || item.ownerMedicationId == null)
        .toList(growable: false);
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  SavedReconstitutionCalculation? ownedForMedication(String medicationId) {
    final direct = _box.get(ownedIdForMedication(medicationId));
    if (direct != null) return direct;

    // Backward/edge-case fallback: find any row explicitly marked as owned.
    try {
      return _box.values.firstWhere(
        (item) => item.ownerMedicationId == medicationId,
      );
    } catch (_) {
      return null;
    }
  }

  String buildOwnedDisplayName({
    required String medicationName,
    required double strengthValue,
    required String strengthUnit,
    required double solventVolumeMl,
    double? recommendedDose,
    String? doseUnit,
  }) {
    String fmtNoTrailing(double v) {
      if (v == v.roundToDouble()) return v.toInt().toString();
      return v.toStringAsFixed(2);
    }

    final parts = <String>[
      medicationName.trim().isNotEmpty ? medicationName.trim() : 'Medication',
      '${fmtNoTrailing(strengthValue)} $strengthUnit',
    ];

    if (recommendedDose != null &&
        recommendedDose > 0 &&
        doseUnit != null &&
        doseUnit.trim().isNotEmpty) {
      parts.add('${fmtNoTrailing(recommendedDose)} ${doseUnit.trim()}');
    }

    parts.add('${fmtNoTrailing(solventVolumeMl)} mL');
    return parts.join(' - ');
  }

  Future<void> upsert(SavedReconstitutionCalculation item) async {
    await _box.putSafe(item.id, item);
  }

  Future<void> delete(String id) async {
    await _box.deleteSafe(id);
  }

  Future<void> deleteForMedication(String medicationId) async {
    final ownedId = ownedIdForMedication(medicationId);
    await _box.deleteSafe(ownedId);

    // Backward/edge-case cleanup: delete any rows explicitly marked as owned.
    final ownedKeys = _box.keys.where((key) {
      final item = _box.get(key);
      return item?.ownerMedicationId == medicationId;
    }).toList(growable: false);

    for (final key in ownedKeys) {
      await _box.deleteSafe(key);
    }
  }
}
