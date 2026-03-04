// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/utils/datetime_formatter.dart';
import 'package:skedux/src/features/schedules/domain/calculated_entry.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/widgets/entry_status_ui.dart';
import 'package:skedux/src/widgets/schedule_status_badge.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EntrySummaryRow extends StatelessWidget {
  const EntrySummaryRow({
    required this.entry,
    required this.onTap,
    this.showMedicationName = false,
    super.key,
  });

  final CalculatedEntry entry;
  final VoidCallback onTap;
  final bool showMedicationName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final schedule = Hive.box<Schedule>('schedules').get(entry.scheduleId);
    final disabled = schedule != null && !schedule.isActive;

    final visual = entryStatusVisual(context, entry.status, disabled: disabled);
    final statusColor = visual.color;
    final statusIcon = visual.icon;

    final timeStr = DateTimeFormatter.formatTime(context, entry.scheduledTime);

    final statusText = disabled
        ? 'Disabled'
        : switch (entry.status) {
            EntryStatus.logged => () {
                final actionTime = entry.existingLog?.actionTime;
                return actionTime != null
                    ? 'Taken at ${DateTimeFormatter.formatTime(context, actionTime)}'
                    : 'Logged';
              }(),
            EntryStatus.skipped => 'Skipped',
            EntryStatus.snoozed => 'Snoozed',
            EntryStatus.due => 'Overdue at $timeStr',
            EntryStatus.overdue => 'Missed at $timeStr',
            EntryStatus.pending => 'Take at $timeStr',
          };

    final entryInfo = '${_formatNumber(entry.entryValue)} ${entry.entryUnit}';
    final localTime = entry.scheduledTime.toLocal();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final weekday = DateFormat.E(localeTag).format(localTime);
    final shortDate = MaterialLocalizations.of(context).formatCompactDate(
      localTime,
    );
    final dateStr = '$weekday $shortDate';

    final line2 = showMedicationName
        ? '${entry.medicationName} | $entryInfo'
        : entryInfo;

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingM,
            vertical: kSpacingS,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: kOpacityMinimal),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  size: kIconSizeMedium,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: kSpacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.scheduleName,
                            style: bodyTextStyle(context)?.copyWith(
                              fontWeight: kFontWeightSemiBold,
                              color: cs.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (schedule != null && !schedule.isActive) ...[
                          const SizedBox(width: kSpacingXS),
                          ScheduleStatusBadge(schedule: schedule, dense: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: kSpacingXXS),
                    Text(
                      line2,
                      style: bodyTextStyle(context)?.copyWith(color: cs.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          '$dateStr | ',
                          style: helperTextStyle(
                            context,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            statusText,
                            style: helperTextStyle(
                              context,
                              color: statusColor,
                            )?.copyWith(fontWeight: kFontWeightMedium),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    var str = value.toStringAsFixed(3);
    str = str.replaceAll(RegExp(r'0+$'), '');
    str = str.replaceAll(RegExp(r'\.$'), '');
    return str;
  }
}
