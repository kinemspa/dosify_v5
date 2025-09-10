import 'package:hive_flutter/hive_flutter.dart';

part 'stock_movement.g.dart';

@HiveType(typeId: 51)
class StockMovement {
  StockMovement({
    required this.id,
    required this.supplyId,
    required this.delta,
    required this.reason,
    this.note,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  @HiveField(0)
  final String id; // uuid
  @HiveField(1)
  final String supplyId;
  @HiveField(2)
  final double delta; // positive for purchase/add, negative for usage
  @HiveField(3)
  final MovementReason reason;
  @HiveField(4)
  final String? note;
  @HiveField(5)
  final DateTime at;
}

@HiveType(typeId: 54)
enum MovementReason {
  @HiveField(0)
  purchase,
  @HiveField(1)
  used,
  @HiveField(2)
  correction,
  @HiveField(3)
  other,
}

