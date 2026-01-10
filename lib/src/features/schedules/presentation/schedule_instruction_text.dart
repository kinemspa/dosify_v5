import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

String scheduleTakeInstructionLabel(BuildContext context, Schedule schedule) {
  final dose = _doseLabel(schedule);
  final medName = schedule.medicationName.trim().isNotEmpty
      ? schedule.medicationName.trim()
      : schedule.name.trim();

  final type = _scheduleTypeLabel(schedule);
  final time = _timesLabel(context, schedule);

  return 'Take $dose of $medName on $type at $time';
}

String scheduleDoseSummaryLabel(Schedule schedule) {
  final dose = _doseLabel(schedule);
  final type = _scheduleTypeLabel(schedule);
  return '$dose · $type';
}

String _doseLabel(Schedule s) {
  final value = _formatNumber(s.doseValue);
  final unit = s.doseUnit.trim();

  if (unit.isEmpty) return value;

  final unitLabel = switch (unit) {
    'tablets' => s.doseValue == 1 ? 'tablet' : 'tablets',
    'capsules' => s.doseValue == 1 ? 'capsule' : 'capsules',
    'syringes' => s.doseValue == 1 ? 'syringe' : 'syringes',
    'vials' => s.doseValue == 1 ? 'vial' : 'vials',
    _ => unit,
  };

  return '$value $unitLabel';
}

String _scheduleTypeLabel(Schedule s) {
  if (s.hasCycle && s.cycleEveryNDays != null && s.cycleEveryNDays! > 0) {
    final n = s.cycleEveryNDays!;
    return 'Every $n day${n == 1 ? '' : 's'}';
  }

  if (s.hasDaysOfMonth) return 'Monthly';

  // Default (days-of-week).
  const dlabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final ds = s.daysOfWeek.toList()..sort();
  if (ds.length == 7) return 'Daily';
  return ds.map((i) => dlabels[i - 1]).join(', ');
}

String _timesLabel(BuildContext context, Schedule s) {
  final times = (s.timesOfDay ?? [s.minutesOfDay]).toList()..sort();
  if (times.isEmpty) return '—';

  final labels = times
      .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context))
      .toList();

  if (labels.length == 1) return labels.single;
  if (labels.length == 2) return '${labels[0]} and ${labels[1]}';

  return '${labels.sublist(0, labels.length - 1).join(', ')}, and ${labels.last}';
}

String _formatNumber(double v) {
  // Display like: 1, 1.5, 0.25 (trim trailing zeros).
  final fixed = v.toStringAsFixed(2);
  return fixed
      .replaceFirst(RegExp(r'\.0+$'), '')
      .replaceFirst(RegExp(r'(\.\d*[1-9])0+$'), r'$1');
}
