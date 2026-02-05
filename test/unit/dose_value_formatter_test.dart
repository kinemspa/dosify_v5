import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/features/schedules/domain/dose_value_formatter.dart';

void main() {
  group('DoseValueFormatter', () {
    test('formats integer-like units without decimals', () {
      expect(DoseValueFormatter.format(10.0, 'units'), '10');
      expect(DoseValueFormatter.format(10.4, 'units'), '10');
      expect(DoseValueFormatter.format(10.6, 'units'), '11');
    });

    test('formats ml with trimmed decimals', () {
      expect(DoseValueFormatter.format(0.5, 'ml'), '0.5');
      expect(DoseValueFormatter.format(1.0, 'ml'), '1');
      expect(DoseValueFormatter.format(1.25, 'ml'), '1.25');
    });

    test('clamps and quantizes to step', () {
      // Units -> step 1.
      expect(
        DoseValueFormatter.clampAndQuantize(10.2, 'units', min: 0, max: 999),
        10,
      );

      // ml -> step 0.01.
      expect(
        DoseValueFormatter.clampAndQuantize(0.234, 'ml', min: 0, max: 10),
        0.23,
      );

      // tablet-ish -> step 1.
      expect(
        DoseValueFormatter.clampAndQuantize(2.7, 'tablets', min: 0, max: 10),
        3,
      );
    });
  });
}
