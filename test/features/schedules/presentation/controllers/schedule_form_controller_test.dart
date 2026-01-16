import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/controllers/schedule_form_controller.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_mode.dart';

void main() {
  group('ScheduleFormController', () {
    test('initial state is correct for new schedule', () {
      final container = ProviderContainer();
      final state = container.read(scheduleFormProvider(null));
      
      expect(state.mode, ScheduleMode.everyDay);
      expect(state.times.length, 1);
      expect(state.times.first.hour, 9);
      expect(state.days.length, 7);
      expect(state.active, true);
    });

    test('setMode updates state correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(scheduleFormProvider(null).notifier);
      
      notifier.setMode(ScheduleMode.daysOfWeek);
      expect(container.read(scheduleFormProvider(null)).mode, ScheduleMode.daysOfWeek);
      expect(container.read(scheduleFormProvider(null)).useCycle, false);
      
      notifier.setMode(ScheduleMode.daysOnOff);
      expect(container.read(scheduleFormProvider(null)).mode, ScheduleMode.daysOnOff);
      expect(container.read(scheduleFormProvider(null)).useCycle, true);
    });

    test('addTime adds a time', () {
      final container = ProviderContainer();
      final notifier = container.read(scheduleFormProvider(null).notifier);
      
      notifier.addTime(const TimeOfDay(hour: 20, minute: 0));
      expect(container.read(scheduleFormProvider(null)).times.length, 2);
      expect(container.read(scheduleFormProvider(null)).times.last.hour, 20);
    });
  });
}
