import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/medication.dart';
import '../../medications/data/medication_repository.dart';

final medicationsBoxProvider = Provider<Box<Medication>>((ref) {
  final box = Hive.box<Medication>('medications');
  return box;
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final box = ref.watch(medicationsBoxProvider);
  return MedicationRepository(box);
});

final medicationsListProvider = Provider<List<Medication>>((ref) {
  final box = ref.watch(medicationsBoxProvider);
  // Note: Hive doesn't notify Riverpod; a proper solution would expose a
  // ValueListenable and watch it. For now, the list is fetched on build.
  return box.values.toList(growable: false);
});
