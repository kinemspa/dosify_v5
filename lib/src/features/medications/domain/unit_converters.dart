// Project imports:
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

/// Converts [value] from [from] unit to [to] unit for mass-based units
/// (mcg / mg / g and their per-mL variants).
///
/// Returns [value] unchanged if one of the units is incompatible (e.g. [Unit.units]).
double convertMassUnit(Unit from, Unit to, double value) {
  double toMcg(Unit u) => switch (u) {
    Unit.mcg || Unit.mcgPerMl => 1.0,
    Unit.mg || Unit.mgPerMl => 1_000.0,
    Unit.g || Unit.gPerMl => 1_000_000.0,
    _ => 0.0, // units / unitsPerMl — incompatible
  };
  final f = toMcg(from);
  final t = toMcg(to);
  if (f == 0.0 || t == 0.0) return value;
  return value * f / t;
}
