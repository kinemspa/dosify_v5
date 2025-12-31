// Package imports:
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/domain/saved_reconstitution_calculation.dart';

class SavedReconstitutionRepository {
  static const String boxName = 'saved_reconstitutions';

  Box<SavedReconstitutionCalculation> get _box =>
      Hive.box<SavedReconstitutionCalculation>(boxName);

  ValueListenable<Box<SavedReconstitutionCalculation>> listenable() =>
      _box.listenable();

  List<SavedReconstitutionCalculation> allSorted() {
    final items = _box.values.toList(growable: false);
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> upsert(SavedReconstitutionCalculation item) async {
    await _box.put(item.id, item);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
