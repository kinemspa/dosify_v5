import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/next_dose_card.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/enhanced_schedule_card.dart';

class MedicationSchedulesSection extends StatelessWidget {
  const MedicationSchedulesSection({
    super.key,
    required this.medication,
    this.showNextDoseCard = true,
  });

  final Medication medication;
  final bool showNextDoseCard;

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
        if (showNextDoseCard) ...[
          NextDoseCard(medication: medication, schedules: schedules),
          const SizedBox(height: kSpacingM),
        ],
        Text('Saved Schedules', style: sectionTitleStyle(context)),
        const SizedBox(height: kSpacingS),
        ...schedules.map(
          (schedule) => EnhancedScheduleCard(
            schedule: schedule,
            medication: medication,
            showDoseCardWhenPossible: false,
          ),
        ),
      ],
    );
  }
}
