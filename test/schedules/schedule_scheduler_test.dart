import 'package:flutter_test/flutter_test.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';

void main() {
  test('slotIdFor is deterministic and unique per occurrence', () {
    final id1 = ScheduleScheduler.slotIdFor(
      'schedule-1',
      weekday: 1,
      minutes: 480,
      occurrence: 0,
    );
    final id2 = ScheduleScheduler.slotIdFor(
      'schedule-1',
      weekday: 1,
      minutes: 480,
      occurrence: 1,
    );
    final id3 = ScheduleScheduler.slotIdFor(
      'schedule-2',
      weekday: 1,
      minutes: 480,
      occurrence: 0,
    );

    expect(id1, isNotNull);
    expect(id2, isNotNull);
    expect(id3, isNotNull);
    expect(id1, isNot(id2));
    expect(id1, isNot(id3));
    // Same inputs equal
    final id1b = ScheduleScheduler.slotIdFor(
      'schedule-1',
      weekday: 1,
      minutes: 480,
      occurrence: 0,
    );
    expect(id1, equals(id1b));
  });
}
