// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

part 'sealed_vial_batch.g.dart';

/// Represents a named batch of sealed MDV vials.
///
/// When users restock sealed vials with different batch names (e.g. "Red Cap"
/// vs "Blue Cap"), each batch is stored separately so they can be individually
/// tracked and selected during reconstitution.
@HiveType(typeId: 61)
class SealedVialBatch {
  const SealedVialBatch({required this.count, this.name});

  /// Batch name from the medication packaging (e.g. "Red Cap", "Lot 2025A").
  /// Null means unnamed/default batch.
  @HiveField(0)
  final String? name;

  /// Number of sealed vials remaining in this batch.
  @HiveField(1)
  final int count;

  SealedVialBatch copyWith({String? Function()? name, int? count}) {
    return SealedVialBatch(
      name: name != null ? name() : this.name,
      count: count ?? this.count,
    );
  }

  @override
  String toString() =>
      name != null ? '$count × $name' : '$count vial${count == 1 ? '' : 's'}';
}
