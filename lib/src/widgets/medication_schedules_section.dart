import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/presentation/widgets/next_entry_card.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/features/schedules/presentation/widgets/enhanced_schedule_card.dart';

class MedicationSchedulesSection extends StatelessWidget {
  const MedicationSchedulesSection({
    super.key,
    required this.medication,
    this.showNextEntryCard = true,
  });

  final Medication medication;
  final bool showNextEntryCard;

  @override
  Widget build(BuildContext context) {
    final scheduleBox = Hive.box<Schedule>('schedules');
    final schedules = scheduleBox.values
        .where((s) => s.medicationId == medication.id)
        .toList();

    if (schedules.isEmpty) {
      return Text('No schedules', style: mutedTextStyle(context));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showNextEntryCard) ...[
          NextEntryCard(medication: medication, schedules: schedules),
          const SizedBox(height: kSpacingM),
        ],
        ...schedules.map(
          (schedule) => EnhancedScheduleCard(
            schedule: schedule,
            medication: medication,
            showEntryCardWhenPossible: false,
          ),
        ),
      ],
    );
  }
}
