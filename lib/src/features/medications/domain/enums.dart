// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

part 'enums.g.dart';

@HiveType(typeId: 1)
enum Unit {
  @HiveField(0)
  mcg,
  @HiveField(1)
  mg,
  @HiveField(2)
  g,
  @HiveField(3)
  units,
  @HiveField(4)
  mcgPerMl,
  @HiveField(5)
  mgPerMl,
  @HiveField(6)
  gPerMl,
  @HiveField(7)
  unitsPerMl,
}

@HiveType(typeId: 2)
enum StockUnit {
  @HiveField(0)
  tablets,
  @HiveField(1)
  capsules,
  @HiveField(2)
  preFilledSyringes,
  @HiveField(3)
  singleDoseVials,
  @HiveField(4)
  multiDoseVials,
  @HiveField(5)
  mcg,
  @HiveField(6)
  mg,
  @HiveField(7)
  g,
}

@HiveType(typeId: 3)
enum MedicationForm {
  @HiveField(0)
  tablet,
  @HiveField(1)
  capsule,
  @HiveField(2)
  injectionPreFilledSyringe,
  @HiveField(3)
  injectionSingleDoseVial,
  @HiveField(4)
  injectionMultiDoseVial,
}
