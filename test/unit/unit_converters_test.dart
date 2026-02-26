import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/unit_converters.dart';

void main() {
  group('convertMassUnit', () {
    // ── mg ↔ mcg ──────────────────────────────────────────────────────────
    test('mg → mcg: 2.0 mg == 2000.0 mcg', () {
      expect(convertMassUnit(Unit.mg, Unit.mcg, 2.0), 2000.0);
    });

    test('mcg → mg: 500.0 mcg == 0.5 mg', () {
      expect(convertMassUnit(Unit.mcg, Unit.mg, 500.0), 0.5);
    });

    // ── g ↔ mg ────────────────────────────────────────────────────────────
    test('g → mg: 1.0 g == 1000.0 mg', () {
      expect(convertMassUnit(Unit.g, Unit.mg, 1.0), 1000.0);
    });

    test('mg → g: 1000.0 mg == 1.0 g', () {
      expect(convertMassUnit(Unit.mg, Unit.g, 1000.0), 1.0);
    });

    // ── g ↔ mcg ───────────────────────────────────────────────────────────
    test('g → mcg: 1.0 g == 1_000_000.0 mcg', () {
      expect(convertMassUnit(Unit.g, Unit.mcg, 1.0), 1_000_000.0);
    });

    test('mcg → g: 1_000_000.0 mcg == 1.0 g', () {
      expect(convertMassUnit(Unit.mcg, Unit.g, 1_000_000.0), 1.0);
    });

    // ── per-mL variants behave identically to base units ──────────────────
    test('mgPerMl → mcgPerMl: 1.5 mg/mL == 1500.0 mcg/mL', () {
      expect(convertMassUnit(Unit.mgPerMl, Unit.mcgPerMl, 1.5), 1500.0);
    });

    test('mcgPerMl → mgPerMl: 250.0 mcg/mL == 0.25 mg/mL', () {
      expect(convertMassUnit(Unit.mcgPerMl, Unit.mgPerMl, 250.0), 0.25);
    });

    test('gPerMl → mgPerMl: 0.001 g/mL == 1.0 mg/mL', () {
      expect(convertMassUnit(Unit.gPerMl, Unit.mgPerMl, 0.001), 1.0);
    });

    // ── Identity (same unit) ──────────────────────────────────────────────
    test('identity — mg → mg returns value unchanged', () {
      expect(convertMassUnit(Unit.mg, Unit.mg, 42.0), 42.0);
    });

    test('identity — mcg → mcg returns value unchanged', () {
      expect(convertMassUnit(Unit.mcg, Unit.mcg, 100.0), 100.0);
    });

    // ── Incompatible units (Unit.units) ───────────────────────────────────
    test('incompatible — units → mg returns value unchanged', () {
      // Unit.units has no mass equivalent; value passthrough is the contract.
      expect(convertMassUnit(Unit.units, Unit.mg, 5.0), 5.0);
    });

    test('incompatible — mg → units returns value unchanged', () {
      expect(convertMassUnit(Unit.mg, Unit.units, 5.0), 5.0);
    });

    // ── Edge cases ────────────────────────────────────────────────────────
    test('zero value stays zero for any unit pair', () {
      expect(convertMassUnit(Unit.mg, Unit.mcg, 0.0), 0.0);
      expect(convertMassUnit(Unit.g, Unit.mg, 0.0), 0.0);
    });

    test('round-trip mg → mcg → mg is lossless', () {
      const original = 12.5;
      final inMcg = convertMassUnit(Unit.mg, Unit.mcg, original);
      final backToMg = convertMassUnit(Unit.mcg, Unit.mg, inMcg);
      expect(backToMg, closeTo(original, 1e-10));
    });

    test('round-trip g → mg → g is lossless', () {
      const original = 0.025;
      final inMg = convertMassUnit(Unit.g, Unit.mg, original);
      final backToG = convertMassUnit(Unit.mg, Unit.g, inMg);
      expect(backToG, closeTo(original, 1e-10));
    });

    test('fractional mcg value converts correctly', () {
      // 0.5 mg = 500 mcg
      expect(convertMassUnit(Unit.mg, Unit.mcg, 0.5), 500.0);
    });
  });
}
