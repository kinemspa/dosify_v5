import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';

void main() {
  test('SyringeTypeLookup.commonPresets is stable and excludes 10ml', () {
    expect(
      SyringeTypeLookup.commonPresets,
      const [
        SyringeType.ml_0_3,
        SyringeType.ml_0_5,
        SyringeType.ml_1_0,
        SyringeType.ml_3_0,
        SyringeType.ml_5_0,
      ],
    );
    expect(
      SyringeTypeLookup.commonPresets.contains(SyringeType.ml_10_0),
      isFalse,
    );
  });
}
