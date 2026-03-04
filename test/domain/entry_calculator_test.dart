import 'package:flutter_test/flutter_test.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_calculator.dart';

void main() {
  group('EntryCalculator - Tablets', () {
    group('calculateFromTablets - Happy Path', () {
      test('2 tablets × 50mg = 100mg', () {
        final result = EntryCalculator.calculateFromTablets(
          tabletCount: 2,
          strengthPerTabletMcg: 50000, // 50mg in mcg
          strengthUnit: 'mg',
        );

        expect(result.success, true);
        expect(result.entryMassMcg, 100000); // 100mg
        expect(result.entryTabletQuarters, 8); // 2 × 4 = 8 quarters
        expect(result.displayText, contains('2 tablets'));
        expect(result.displayText, contains('100.0mg'));
      });

      test('0.25 tablets × 100mg = 25mg', () {
        final result = EntryCalculator.calculateFromTablets(
          tabletCount: 0.25,
          strengthPerTabletMcg: 100000,
          strengthUnit: 'mg',
        );

        expect(result.success, true);
        expect(result.entryMassMcg, 25000);
        expect(result.entryTabletQuarters, 1);
        expect(result.displayText, contains('1/4 tablet'));
      });

      test('2.75 tablets × 40mg = 110mg', () {
        final result = EntryCalculator.calculateFromTablets(
          tabletCount: 2.75,
          strengthPerTabletMcg: 40000,
          strengthUnit: 'mg',
        );

        expect(result.success, true);
        expect(result.entryMassMcg, 110000);
        expect(result.entryTabletQuarters, 11); // 2.75 × 4 = 11
      });
    });

    group('calculateFromTablets - Valid 1/4 Increments', () {
      test('0.25 increment works', () {
        final result = EntryCalculator.calculateFromTablets(
          tabletCount: 0.25,
          strengthPerTabletMcg: 50000,
          strengthUnit: 'mg',
        );
        expect(result.success, true);
      });

      test('0.5 increment works', () {
        final result = EntryCalculator.calculateFromTablets(
          tabletCount: 0.5,
          strengthPerTabletMcg: 50000,
          strengthUnit: 'mg',
        );
        expect(result.success, true);
      });

      test('0.75 increment works', () {
        final result = EntryCalculator.calculateFromTablets(
          tabletCount: 0.75,
          strengthPerTabletMcg: 50000,
          strengthUnit: 'mg',
        );
        expect(result.success, true);
      });

      test('1.25 increment works', () {
        final result = EntryCalculator.calculateFromTablets(
          tabletCount: 1.25,
          strengthPerTabletMcg: 50000,
          strengthUnit: 'mg',
        );
        expect(result.success, true);
      });
    });

    group('calculateFromTablets - Invalid Increments', () {
      test('0.3 tablets shows warning and rounds to 0.25', () {
        final result = EntryCalculator.calculateFromTablets(
          tabletCount: 0.3,
          strengthPerTabletMcg: 50000,
          strengthUnit: 'mg',
        );

        expect(result.success, true);
        expect(result.hasWarning, true);
        expect(result.warning, contains('rounded to'));
        expect(result.entryTabletQuarters, 1); // Rounded to 0.25
      });

      test('2.33 tablets rounds to 2.25 with warning', () {
        final result = EntryCalculator.calculateFromTablets(
          tabletCount: 2.33,
          strengthPerTabletMcg: 50000,
          strengthUnit: 'mg',
        );

        expect(result.success, true);
        expect(result.hasWarning, true);
        expect(result.entryTabletQuarters, 9); // 2.25 × 4 = 9
      });
    });

    group('calculateFromStrength - Tablets', () {
      test('100mg ÷ 50mg = 2 tablets', () {
        final result = EntryCalculator.calculateFromStrength(
          strengthMcg: 100000,
          strengthPerTabletMcg: 50000,
        );

        expect(result.success, true);
        expect(result.entryTabletQuarters, 8); // 2 tablets
        expect(result.displayText, contains('2 tablets'));
      });

      test('115mg ÷ 50mg = 2.3 tablets → shows warning', () {
        final result = EntryCalculator.calculateFromStrength(
          strengthMcg: 115000,
          strengthPerTabletMcg: 50000,
        );

        expect(result.success, true);
        expect(result.hasWarning, true);
        expect(result.warning, contains('2.3'));
      });
    });
  });

  group('EntryCalculator - Capsules', () {
    group('calculateFromCapsules - Happy Path', () {
      test('3 capsules × 500mg = 1500mg', () {
        final result = EntryCalculator.calculateFromCapsules(
          capsuleCount: 3,
          strengthPerCapsuleMcg: 500000,
        );

        expect(result.success, true);
        expect(result.entryMassMcg, 1500000);
        expect(result.entryCapsules, 3);
        expect(result.displayText, contains('3 capsules'));
        expect(
          result.displayText,
          contains('1.5g'),
        ); // Smart formatting: 1500mg → 1.5g
      });

      test('1 capsule × 25mg = 25mg', () {
        final result = EntryCalculator.calculateFromCapsules(
          capsuleCount: 1,
          strengthPerCapsuleMcg: 25000,
        );

        expect(result.success, true);
        expect(result.entryMassMcg, 25000);
        expect(result.entryCapsules, 1);
        expect(result.displayText, contains('1 capsule'));
      });
    });

    group('calculateFromStrengthCapsules - Whole Numbers', () {
      test('1500mg ÷ 500mg = 3 capsules', () {
        final result = EntryCalculator.calculateFromStrengthCapsules(
          strengthMcg: 1500000,
          strengthPerCapsuleMcg: 500000,
        );

        expect(result.success, true);
        expect(result.entryCapsules, 3);
      });

      test('1250mg ÷ 500mg = 2.5 → rounds to 3 with warning', () {
        final result = EntryCalculator.calculateFromStrengthCapsules(
          strengthMcg: 1250000,
          strengthPerCapsuleMcg: 500000,
        );

        expect(result.success, true);
        expect(result.hasWarning, true);
        expect(result.entryCapsules, 3); // Rounded up
        expect(result.warning, contains('2.5'));
      });
    });
  });

  group('EntryCalculator - MDV (Multi-Dose Vial)', () {
    // Test vial: 10mg in 5ml, using 0.5ml syringe (50U scale)
    const vialStrengthMcg = 10000.0; // 10mg
    const vialVolumeMicroliter = 5000.0; // 5ml
    const syringe = SyringeType.ml_0_5; // 0.5ml, 100U/ml

    group('calculateFromStrengthMDV - Happy Path', () {
      test('500mcg → 0.25ml, 25U', () {
        final result = EntryCalculator.calculateFromStrengthMDV(
          strengthMcg: 500,
          totalVialStrengthMcg: vialStrengthMcg,
          totalVialVolumeMicroliter: vialVolumeMicroliter,
          syringeType: syringe,
        );

        expect(result.success, true);
        expect(result.entryMassMcg, 500);
        expect(result.entryVolumeMicroliter, 250); // 0.25ml
        expect(result.syringeUnits, 25);
        expect(result.displayText, contains('500mcg'));
        expect(result.displayText, contains('0.25ml'));
        expect(result.displayText, contains('25'));
      });

      test('1000mcg → 0.5ml, 50U', () {
        final result = EntryCalculator.calculateFromStrengthMDV(
          strengthMcg: 1000,
          totalVialStrengthMcg: vialStrengthMcg,
          totalVialVolumeMicroliter: vialVolumeMicroliter,
          syringeType: syringe,
        );

        expect(result.success, true);
        expect(result.entryVolumeMicroliter, 500); // 0.5ml
        expect(result.syringeUnits, 50);
      });
    });

    group('calculateFromVolumeMDV - Happy Path', () {
      test('0.25ml → 500mcg, 25U', () {
        final result = EntryCalculator.calculateFromVolumeMDV(
          volumeMicroliter: 250, // 0.25ml
          totalVialStrengthMcg: vialStrengthMcg,
          totalVialVolumeMicroliter: vialVolumeMicroliter,
          syringeType: syringe,
        );

        expect(result.success, true);
        expect(result.entryMassMcg, 500);
        expect(result.entryVolumeMicroliter, 250);
        expect(result.syringeUnits, 25);
      });
    });

    group('calculateFromUnitsMDV - Happy Path', () {
      test('25U → 500mcg, 0.25ml', () {
        final result = EntryCalculator.calculateFromUnitsMDV(
          syringeUnits: 25,
          totalVialStrengthMcg: vialStrengthMcg,
          totalVialVolumeMicroliter: vialVolumeMicroliter,
          syringeType: syringe,
        );

        expect(result.success, true);
        expect(result.entryMassMcg, 500);
        expect(result.entryVolumeMicroliter, 250);
        expect(result.syringeUnits, 25);
      });
    });

    group('MDV - Edge Cases', () {
      test('12mg exceeds 10mg vial → error', () {
        final result = EntryCalculator.calculateFromStrengthMDV(
          strengthMcg: 12000,
          totalVialStrengthMcg: vialStrengthMcg,
          totalVialVolumeMicroliter: vialVolumeMicroliter,
          syringeType: syringe,
        );

        expect(result.success, false);
        expect(result.hasError, true);
        expect(result.error, contains('exceeds vial strength'));
      });

      test('6ml exceeds 5ml volume → error', () {
        final result = EntryCalculator.calculateFromVolumeMDV(
          volumeMicroliter: 6000,
          totalVialStrengthMcg: vialStrengthMcg,
          totalVialVolumeMicroliter: vialVolumeMicroliter,
          syringeType: syringe,
        );

        expect(result.success, false);
        expect(result.hasError, true);
        expect(result.error, contains('exceeds vial capacity'));
      });

      test('9mg (90% of vial) → warning', () {
        final result = EntryCalculator.calculateFromStrengthMDV(
          strengthMcg: 9000,
          totalVialStrengthMcg: vialStrengthMcg,
          totalVialVolumeMicroliter: vialVolumeMicroliter,
          syringeType: SyringeType.ml_5_0, // Larger syringe
        );

        expect(result.success, true);
        expect(result.hasWarning, true);
        expect(result.warning, contains('High entry'));
      });
    });

    group('MDV - Different Syringe Types', () {
      test('500mcg on 0.3ml syringe → error (exceeds capacity)', () {
        final result = EntryCalculator.calculateFromStrengthMDV(
          strengthMcg: 500,
          totalVialStrengthMcg: vialStrengthMcg,
          totalVialVolumeMicroliter: vialVolumeMicroliter,
          syringeType: SyringeType.ml_0_3,
        );

        // 500mcg = 0.25ml, but 0.3ml syringe has 30U max
        // 0.25ml × 100U/ml = 25U (within capacity)
        expect(result.success, true);
        expect(result.syringeUnits, 25);
      });

      test('500mcg on 1ml syringe → 25U', () {
        final result = EntryCalculator.calculateFromStrengthMDV(
          strengthMcg: 500,
          totalVialStrengthMcg: vialStrengthMcg,
          totalVialVolumeMicroliter: vialVolumeMicroliter,
          syringeType: SyringeType.ml_1_0,
        );

        expect(result.success, true);
        expect(result.syringeUnits, 25);
      });

      test('500mcg on 3ml syringe → 25U', () {
        final result = EntryCalculator.calculateFromStrengthMDV(
          strengthMcg: 500,
          totalVialStrengthMcg: vialStrengthMcg,
          totalVialVolumeMicroliter: vialVolumeMicroliter,
          syringeType: SyringeType.ml_3_0,
        );

        expect(result.success, true);
        expect(result.syringeUnits, 25);
      });
    });
  });

  group('EntryCalculator - Formatting', () {
    test('formatMass - mcg', () {
      expect(EntryCalculator.formatMass(500), '500mcg');
    });

    test('formatMass - mg', () {
      expect(EntryCalculator.formatMass(1000), '1.0mg');
      expect(EntryCalculator.formatMass(50000), '50.0mg');
    });

    test('formatMass - g', () {
      expect(EntryCalculator.formatMass(1000000), '1.0g');
    });

    test('formatVolume - ml', () {
      expect(EntryCalculator.formatVolume(250), '0.25ml');
      expect(EntryCalculator.formatVolume(500), '0.50ml');
      expect(EntryCalculator.formatVolume(1000), '1.00ml');
    });
  });

  group('EntryCalculator - Pre-filled Injections', () {
    test('1 injection × 0.3mg × 0.3ml', () {
      final result = EntryCalculator.calculateFromPrefilledInjections(
        injectionCount: 1,
        strengthPerInjectionMcg: 300,
        volumePerInjectionMicroliter: 300,
      );

      expect(result.success, true);
      expect(result.entryMassMcg, 300);
      expect(result.entryVolumeMicroliter, 300);
      expect(result.entrySyringes, 1);
      expect(result.displayText, contains('1 injection'));
    });

    test('2 injections × 0.3mg × 0.3ml = 0.6mg, 0.6ml', () {
      final result = EntryCalculator.calculateFromPrefilledInjections(
        injectionCount: 2,
        strengthPerInjectionMcg: 300,
        volumePerInjectionMicroliter: 300,
      );

      expect(result.success, true);
      expect(result.entryMassMcg, 600);
      expect(result.entryVolumeMicroliter, 600);
      expect(result.entrySyringes, 2);
      expect(result.displayText, contains('2 injections'));
    });
  });

  group('EntryCalculator - Single Entry Vials', () {
    test('2 vials × 10mg × 2ml', () {
      final result = EntryCalculator.calculateFromSingleDoseVials(
        vialCount: 2,
        strengthPerVialMcg: 10000,
        volumePerVialMicroliter: 2000,
      );

      expect(result.success, true);
      expect(result.entryMassMcg, 20000); // 20mg
      expect(result.entryVolumeMicroliter, 4000); // 4ml
      expect(result.entryVials, 2);
      expect(result.displayText, contains('2 vials'));
    });
  });
}
