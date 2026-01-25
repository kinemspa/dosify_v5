// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_instruction_text.dart';
import 'package:dosifi_v5/src/widgets/glass_card_surface.dart';
import 'package:dosifi_v5/src/widgets/large_card.dart';
import 'package:dosifi_v5/src/widgets/next_dose_date_badge.dart';
import 'package:dosifi_v5/src/widgets/schedule_status_chip.dart';

class ScheduleListCard extends StatelessWidget {
  const ScheduleListCard({
    super.key,
    required this.schedule,
    required this.dense,
  });

  final Schedule schedule;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final next = ScheduleOccurrenceService.nextOccurrence(schedule);
    final medTitle = _ScheduleCardText.medTitle(schedule);
    final scheduleSubtitle = _ScheduleCardText.scheduleSubtitle(schedule);
    final startedLabel = _ScheduleCardText.startedLabel(schedule);
    final endLabel = _ScheduleCardText.endLabel(schedule);

    if (dense) {
      final medName = schedule.medicationName.trim();
      final scheduleName = schedule.name.trim();
      final showScheduleName = medName.isNotEmpty && scheduleName.isNotEmpty;

      return GlassCardSurface(
        onTap: () => context.pushNamed(
          'scheduleDetail',
          pathParameters: {'id': schedule.id},
        ),
        useGradient: false,
        padding: kCompactCardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    medTitle,
                    style: cardTitleStyle(
                      context,
                    )?.copyWith(fontWeight: FontWeight.w800, color: cs.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showScheduleName) ...[
                    const SizedBox(height: kSpacingXXS),
                    Text(
                      scheduleName,
                      style: bodyTextStyle(
                        context,
                      )?.copyWith(fontWeight: kFontWeightSemiBold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: kSpacingXS),
                  Text(
                    scheduleDoseSummaryLabel(schedule),
                    style: microHelperTextStyle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpacingS),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                NextDoseDateBadge(
                  nextDose: next,
                  isActive: schedule.isActive,
                  dense: true,
                  showNextLabel: true,
                ),
                const SizedBox(height: kSpacingXS),
                SizedBox(
                  width: kNextDoseDateCircleSizeCompact,
                  child: Center(
                    child: ScheduleStatusChip(schedule: schedule, dense: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return LargeCard(
      onTap: () => context.pushNamed(
        'scheduleDetail',
        pathParameters: {'id': schedule.id},
      ),
      dense: true,
      leading: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            medTitle,
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: FontWeight.w800, color: cs.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (scheduleSubtitle != null) ...[
            const SizedBox(height: kSpacingXS),
            Text(
              scheduleSubtitle,
              style: bodyTextStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightSemiBold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: kSpacingXS),
          Text(
            scheduleTakeInstructionLabel(context, schedule),
            style: helperTextStyle(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: kSpacingXS),
          Row(
            children: [
              Expanded(
                child: Text(
                  startedLabel,
                  style: helperTextStyle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: kSpacingS),
              Expanded(
                child: Text(
                  endLabel,
                  style: helperTextStyle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: kSpacingXS),
            child: NextDoseDateBadge(
              nextDose: next,
              isActive: schedule.isActive,
              dense: false,
              showNextLabel: true,
              nextLabelStyle: NextDoseBadgeLabelStyle.tall,
            ),
          ),
          const SizedBox(height: kSpacingXS),
          ScheduleStatusChip(schedule: schedule, dense: true),
        ],
      ),
    );
  }
}

class _ScheduleCardText {
  static String medTitle(Schedule s) {
    final med = s.medicationName.trim();
    final name = s.name.trim();
    return med.isNotEmpty ? med : name;
  }

  static String startedLabel(Schedule s) {
    final start = s.startAt;
    if (start == null) return 'Start Date: —';
    return 'Start Date: ${DateFormat('d MMM').format(start)}';
  }

  static String endLabel(Schedule s) {
    final end = s.endAt;
    if (end == null) return 'End Date: No end';
    return 'End Date: ${DateFormat('d MMM').format(end)}';
  }

  static String? scheduleSubtitle(Schedule s) {
    final med = s.medicationName.trim();
    final name = s.name.trim();
    if (med.isEmpty) return null;
    if (name.isEmpty) return null;
    return name;
  }
}
