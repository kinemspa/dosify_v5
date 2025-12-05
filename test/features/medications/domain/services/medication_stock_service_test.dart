import 'package:flutter_test/flutter_test.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/medication_stock_service.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

void main() {
  group('MedicationStockService', () {
    group('calculateStockRatio', () {
      test('returns 0.0 when stock is empty', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 0,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        expect(MedicationStockService.calculateStockRatio(med), 0.0);
      });

      test('returns 1.0 when stock is full', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 100,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        expect(MedicationStockService.calculateStockRatio(med), 1.0);
      });

      test('returns 0.5 when stock is half full', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 50,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        expect(MedicationStockService.calculateStockRatio(med), 0.5);
      });

      test('clamps values above 1.0', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 150,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        expect(MedicationStockService.calculateStockRatio(med), 1.0);
      });
    });

    group('isLowStock', () {
      test('returns true when stock is below 25%', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 20,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        expect(MedicationStockService.isLowStock(med), true);
      });

      test('returns false when stock is above 25%', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 30,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        expect(MedicationStockService.isLowStock(med), false);
      });
    });

    group('calculateDaysRemaining', () {
      test('returns 0 when stock is empty', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 0,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        final schedule = Schedule(
          id: 's1',
          name: 'Daily',
          medicationName: 'Test',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 540,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        );

        expect(
          MedicationStockService.calculateDaysRemaining(med, [schedule]),
          0.0,
        );
      });

      test('calculates days remaining for daily schedule', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 30,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        final schedule = Schedule(
          id: 's1',
          name: 'Daily',
          medicationName: 'Test',
          medicationId: '1',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 540,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Every day
        );

        final days = MedicationStockService.calculateDaysRemaining(
          med,
          [schedule],
        );

        expect(days, 30.0); // 30 tablets / 1 per day = 30 days
      });

      test('calculates days remaining for twice daily schedule', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 30,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        final schedule = Schedule(
          id: 's1',
          name: 'Twice Daily',
          medicationName: 'Test',
          medicationId: '1',
          doseValue: 1,
          doseUnit: 'tablet',
          minutesOfDay: 540,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          timesOfDay: [540, 1080], // 9 AM and 6 PM
        );

        final days = MedicationStockService.calculateDaysRemaining(
          med,
          [schedule],
        );

        expect(days, 15.0); // 30 tablets / 2 per day = 15 days
      });

      test('returns null when no schedules', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 30,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        expect(MedicationStockService.calculateDaysRemaining(med, []), null);
      });
    });

    group('getStockStatus', () {
      test('returns "Out of stock" when empty', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 0,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        expect(MedicationStockService.getStockStatus(med), 'Out of stock');
      });

      test('returns "Critically low" when below 10%', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 5,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        expect(MedicationStockService.getStockStatus(med), 'Critically low');
      });

      test('returns "Good" when above 50%', () {
        final med = Medication(
          id: '1',
          name: 'Test',
          form: MedicationForm.tablet,
          strengthValue: 10,
          strengthUnit: Unit.mg,
          stockValue: 60,
          initialStockValue: 100,
          stockUnit: StockUnit.tablets,
        );

        expect(MedicationStockService.getStockStatus(med), 'Good');
      });
    });
  });
}
