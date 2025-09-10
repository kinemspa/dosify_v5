import 'package:hive_flutter/hive_flutter.dart';

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

class StockMovementAdapter extends TypeAdapter<StockMovement> {
  @override
  final int typeId = 51;

  @override
  StockMovement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return StockMovement(
      id: fields[0] as String,
      supplyId: fields[1] as String,
      delta: fields[2] as double,
      reason: fields[3] as MovementReason,
      note: fields[4] as String?,
      at: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StockMovement obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.supplyId)
      ..writeByte(2)
      ..write(obj.delta)
      ..writeByte(3)
      ..write(obj.reason)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.at);
  }
}

class MovementReasonAdapter extends TypeAdapter<MovementReason> {
  @override
  final int typeId = 54;

  @override
  MovementReason read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MovementReason.purchase;
      case 1:
        return MovementReason.used;
      case 2:
        return MovementReason.correction;
      case 3:
        return MovementReason.other;
      default:
        return MovementReason.other;
    }
  }

  @override
  void write(BinaryWriter writer, MovementReason obj) {
    switch (obj) {
      case MovementReason.purchase:
        writer.writeByte(0);
        break;
      case MovementReason.used:
        writer.writeByte(1);
        break;
      case MovementReason.correction:
        writer.writeByte(2);
        break;
      case MovementReason.other:
        writer.writeByte(3);
        break;
    }
  }
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

