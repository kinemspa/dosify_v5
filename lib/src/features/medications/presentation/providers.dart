// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/data/medication_repository.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

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
