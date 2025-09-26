import 'package:hive_flutter/hive_flutter.dart';
import '../domain/medication.dart';

class MedicationRepository {
  MedicationRepository(this._box);

  final Box<Medication> _box;

  List<Medication> getAll() => _box.values.toList(growable: false);

  Future<void> upsert(Medication med) async {
    await _box.put(med.id, med);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
