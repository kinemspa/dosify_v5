import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/features/schedules/domain/entry_calculator.dart';

void main() {
  // Shared vial spec: 10000 mcg in 2000 µL → 5 mcg/µL concentration.
  const totalStrengthMcg = 10000.0;
  const totalVolumeMicroliter = 2000.0;
  const syringe1ml = SyringeType.ml_1_0; // 100 U/mL, max 100 U

  group('EntryCalculator.calculateFromStrengthMDV', () {
    test('half-vial entry: 5000 mcg → 1000 µL → 100 U', () {
      final result = EntryCalculator.calculateFromStrengthMDV(
        strengthMcg: 5000,
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: syringe1ml,
      );
      expect(result.success, isTrue);
      expect(result.entryMassMcg, 5000.0);
      expect(result.entryVolumeMicroliter, closeTo(1000.0, 0.001));
      expect(result.syringeUnits, closeTo(100.0, 0.001));
    });

    test('quarter-vial entry: 2500 mcg → 500 µL → 50 U', () {
      final result = EntryCalculator.calculateFromStrengthMDV(
        strengthMcg: 2500,
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: syringe1ml,
      );
      expect(result.success, isTrue);
      expect(result.entryMassMcg, 2500.0);
      expect(result.entryVolumeMicroliter, closeTo(500.0, 0.001));
      expect(result.syringeUnits, closeTo(50.0, 0.001));
    });

    test('entry > vial strength reports error', () {
      final result = EntryCalculator.calculateFromStrengthMDV(
        strengthMcg: 15000, // exceeds 10000 mcg
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: syringe1ml,
      );
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('>80% vial usage returns warning (not error)', () {
      // 9000 mcg → 1800 µL (90% of 2000 µL vial).
      // Use 3ml syringe (max 300 U) to avoid syringe-capacity error.
      final result = EntryCalculator.calculateFromStrengthMDV(
        strengthMcg: 9000,
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: SyringeType.ml_3_0,
      );
      expect(result.success, isTrue);
      expect(result.hasWarning, isTrue);
      expect(result.hasError, isFalse);
    });

    test('zero entry succeeds with zero output', () {
      final result = EntryCalculator.calculateFromStrengthMDV(
        strengthMcg: 0,
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: syringe1ml,
      );
      expect(result.success, isTrue);
      expect(result.entryMassMcg, 0.0);
      expect(result.entryVolumeMicroliter, 0.0);
      expect(result.syringeUnits, 0.0);
    });
  });

  group('EntryCalculator.calculateFromVolumeMDV', () {
    test('1000 µL → 5000 mcg → 100 U', () {
      final result = EntryCalculator.calculateFromVolumeMDV(
        volumeMicroliter: 1000,
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: syringe1ml,
      );
      expect(result.success, isTrue);
      expect(result.entryMassMcg, closeTo(5000.0, 0.001));
      expect(result.syringeUnits, closeTo(100.0, 0.001));
    });

    test('volume > vial capacity reports error', () {
      final result = EntryCalculator.calculateFromVolumeMDV(
        volumeMicroliter: 3000, // exceeds 2000 µL vial
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: syringe1ml,
      );
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });
  });

  group('EntryCalculator.calculateFromUnitsMDV', () {
    test('50 U → 500 µL → 2500 mcg', () {
      final result = EntryCalculator.calculateFromUnitsMDV(
        syringeUnits: 50,
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: syringe1ml,
      );
      expect(result.success, isTrue);
      expect(result.entryVolumeMicroliter, closeTo(500.0, 0.001));
      expect(result.entryMassMcg, closeTo(2500.0, 0.001));
    });

    test('units > syringe max reports error', () {
      final result = EntryCalculator.calculateFromUnitsMDV(
        syringeUnits: 200, // 1ml syringe max is 100 U
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: syringe1ml,
      );
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });
  });

  group('EntryCalculator — round-trip consistency', () {
    test('strength → volume → units all agree (500 µL round-trip)', () {
      const targetMcg = 2500.0;
      const expectedVolume = 500.0; // µL
      const expectedUnits = 50.0; // U

      final fromStrength = EntryCalculator.calculateFromStrengthMDV(
        strengthMcg: targetMcg,
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: syringe1ml,
      );
      final fromVolume = EntryCalculator.calculateFromVolumeMDV(
        volumeMicroliter: expectedVolume,
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: syringe1ml,
      );
      final fromUnits = EntryCalculator.calculateFromUnitsMDV(
        syringeUnits: expectedUnits,
        totalVialStrengthMcg: totalStrengthMcg,
        totalVialVolumeMicroliter: totalVolumeMicroliter,
        syringeType: syringe1ml,
      );

      for (final r in [fromStrength, fromVolume, fromUnits]) {
        expect(r.success, isTrue);
        expect(r.entryMassMcg, closeTo(targetMcg, 0.001));
        expect(r.entryVolumeMicroliter, closeTo(expectedVolume, 0.001));
        expect(r.syringeUnits, closeTo(expectedUnits, 0.001));
      }
    });
  });
}
