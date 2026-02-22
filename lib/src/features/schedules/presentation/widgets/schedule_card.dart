import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log_ids.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/widgets/glass_card_surface.dart';
import 'package:dosifi_v5/src/widgets/schedule_status_badge.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/widgets/next_dose_row.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.s,
    required this.dense,
    this.useGradient = false,
  });
  final Schedule s;
  final bool dense;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final next = _nextOccurrence(s);
    final last = _lastOccurrence(s);

    if (dense) {
      // Compact Card (Concept 9)
      final firstMinutes = ScheduleOccurrenceService.normalizedTimesOfDay(
        s,
      ).first;
      final timeLabel = DateTimeFormatter.formatTime(
        context,
        DateTime(0, 1, 1, firstMinutes ~/ 60, firstMinutes % 60),
      );

      return GlassCardSurface(
        onTap: () =>
            context.pushNamed('scheduleDetail', pathParameters: {'id': s.id}),
        useGradient: useGradient,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Time Column
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kSpacingM),
              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.medicationName,
                      style: cardTitleStyle(
                        context,
                      )?.copyWith(color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.doseValue} ${s.doseUnit}',
                      style: helperTextStyle(context),
                    ),
                  ],
                ),
              ),
              // Actions: Take + menu (Snooze / Skip)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.check, size: 20),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () async {
                      final ok = await confirmTake(context, s);
                      if (!ok) return;

                      // 1. Create Dose Log
                      await _markAsTaken(context, s);

                      // 2. Decrement Stock
                      final success = await applyStockDecrement(context, s);

                      if (success && context.mounted) {
                        showAppSnackBar(context, 'Marked as taken: ${s.name}');
                      }
                    },
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) async {
                      switch (value) {
                        case 'snooze':
                          await _snoozeSchedule(context, s);
                          break;
                        case 'skip':
                          await _skipSchedule(context, s);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'snooze',
                        child: Text('Snooze'),
                      ),
                      const PopupMenuItem(value: 'skip', child: Text('Skip')),
                    ],
                    icon: const Icon(Icons.more_vert, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Large Card (Existing Logic with Glass Surface)
    return GlassCardSurface(
      onTap: () =>
          context.pushNamed('scheduleDetail', pathParameters: {'id': s.id}),
      useGradient: useGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.medicationName,
            style: helperTextStyle(context)?.copyWith(letterSpacing: 1.1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.name,
                  style: sectionTitleStyle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!s.isActive) ...[
                const SizedBox(width: kSpacingS),
                ScheduleStatusBadge(schedule: s, dense: true),
              ],
            ],
          ),
          const SizedBox(height: kFieldSpacing),
          Text(
            '${_doseLine(s)} × ${_timesLine(context, s)}',
            style: helperTextStyle(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: kFieldSpacing),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NextDoseRow(schedule: s, nextDose: next, dense: true),
                    if (!dense && last != null)
                      Text(
                        'Last Dose: ${_fmtWhen(context, last)}',
                        style: helperTextStyle(
                          context,
                          color: cs.onSurfaceVariant.withValues(
                            alpha: kOpacityMediumHigh,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: kFieldSpacing),
              if (!dense)
                FilledButton.tonal(
                  onPressed: () async {
                    final ok = await confirmTake(context, s);
                    if (!ok) return;

                    await _markAsTaken(context, s);

                    final success = await applyStockDecrement(context, s);
                    if (success && context.mounted) {
                      showAppSnackBar(context, 'Marked as taken: ${s.name}');
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Take'),
                )
              else
                FilledButton.tonal(
                  onPressed: () => context.pushNamed(
                    'scheduleDetail',
                    pathParameters: {'id': s.id},
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _doseLine(Schedule s) {
    final v = s.doseValue;
    final vf = (v == v.roundToDouble())
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(2);
    return '$vf ${s.doseUnit}';
  }

  String _timesLine(BuildContext context, Schedule s) {
    final ts = ScheduleOccurrenceService.normalizedTimesOfDay(s);
    final label = ts
        .map(
          (m) => DateTimeFormatter.formatTime(
            context,
            DateTime(0, 1, 1, m ~/ 60, m % 60),
          ),
        )
        .join(', ');
    if (s.hasCycle && s.cycleEveryNDays != null) {
      final n = s.cycleEveryNDays!;
      return 'Every $n day${n == 1 ? '' : 's'} at $label';
    }
    const dlabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final ds = s.daysOfWeek.toList()..sort();

    // Show "Every day" if all 7 days are selected
    if (ds.length == 7) {
      return 'Every day at $label';
    }

    final dtext = ds.map((i) => dlabels[i - 1]).join(', ');
    return '$dtext at $label';
  }

  String _fmtWhen(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final time = DateTimeFormatter.formatTime(context, dt);
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) return 'Today $time';
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow =
        dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;
    if (isTomorrow) return 'Tomorrow $time';
    return '${dt.day}/${dt.month} $time';
  }

  DateTime? _nextOccurrence(Schedule s) {
    return ScheduleOccurrenceService.nextOccurrence(s);
  }

  /// Returns the next occurrence and its scheduler occurrence index.
  /// For cyclic schedules, occurrence is (date - anchor).inDays ~/ n.
  /// For weekly schedules, occurrence is the day offset from today (0..).
  _OccurrenceResult? _nextOccurrenceAndIndex(Schedule s) {
    final now = DateTime.now();
    final times = ScheduleOccurrenceService.normalizedTimesOfDay(s);
    // Weekly schedule: compute day offset as occurrence index
    final start = DateTime(now.year, now.month, now.day);

    if (s.hasCycle && s.cycleEveryNDays != null && s.cycleEveryNDays! > 0) {
      final n = s.cycleEveryNDays!.clamp(1, 365);
      final anchor = s.cycleAnchorDate ?? now;
      var day = DateTime(anchor.year, anchor.month, anchor.day);
      // Advance to today or the next cycle day
      while (day.isBefore(start)) day = day.add(Duration(days: n));
      // Search the upcoming cycle occurrences for the next scheduled time
      for (var i = 0; i < 365; i += n) {
        for (final minutes in times) {
          final dt = DateTime(
            day.year,
            day.month,
            day.day,
            minutes ~/ 60,
            minutes % 60,
          );
          if (dt.isAfter(now)) {
            final daysSinceAnchor = DateTime(day.year, day.month, day.day)
                .difference(DateTime(anchor.year, anchor.month, anchor.day))
                .inDays
                .clamp(0, 1 << 30);
            final occurrence = (daysSinceAnchor / n).floor();
            return _OccurrenceResult(dt, occurrence);
          }
        }
        day = day.add(Duration(days: n));
      }
      return null;
    }

    // Weekly pattern - count day offset from today's start as occurrence
    for (var d = 0; d < 60; d++) {
      final date = start.add(Duration(days: d));
      final onDay = s.daysOfWeek.contains(date.weekday);
      if (onDay) {
        for (final minutes in times) {
          final dt = DateTime(
            date.year,
            date.month,
            date.day,
            minutes ~/ 60,
            minutes % 60,
          );
          if (dt.isAfter(now)) return _OccurrenceResult(dt, d);
        }
      }
    }
    return null;
  }

  DateTime? _lastOccurrence(Schedule s) {
    final now = DateTime.now();
    final times = ScheduleOccurrenceService.normalizedTimesOfDay(s);
    for (var d = 0; d < 60; d++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: d));
      final onDay =
          s.hasCycle && s.cycleEveryNDays != null && s.cycleEveryNDays! > 0
          ? (() {
              final anchor = s.cycleAnchorDate ?? now;
              final a = DateTime(anchor.year, anchor.month, anchor.day);
              final d0 = DateTime(date.year, date.month, date.day);
              final diff = d0.difference(a).inDays;
              return diff >= 0 && diff % s.cycleEveryNDays! == 0;
            })()
          : s.daysOfWeek.contains(date.weekday);
      if (onDay) {
        for (final minutes in times) {
          final dt = DateTime(
            date.year,
            date.month,
            date.day,
            minutes ~/ 60,
            minutes % 60,
          );
          if (dt.isBefore(now)) return dt;
        }
      }
    }
    return null;
  }

  /// Helper: mark current schedule's next occurrence as taken by creating a DoseLog
  Future<void> _markAsTaken(BuildContext context, Schedule s) async {
    final occ = _nextOccurrenceAndIndex(s);
    final next = occ?.dt;
    if (next == null) return;

    final logId = DoseLogIds.occurrenceId(
      scheduleId: s.id,
      scheduledTime: next,
    );
    final log = DoseLog(
      id: logId,
      scheduleId: s.id,
      scheduleName: s.name,
      medicationId: s.medicationId ?? 'unknown',
      medicationName: s.medicationName,
      scheduledTime: next,
      doseValue: s.doseValue,
      doseUnit: s.doseUnit,
      action: DoseAction.taken,
      actionTime: DateTime.now(),
    );

    try {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsertOccurrence(log);

      // Cancel notification for this slot
      try {
        await NotificationService.cancel(
          ScheduleScheduler.doseNotificationIdFor(s.id, next),
        );
        for (final overdueId in ScheduleScheduler.overdueNotificationIdsFor(
          s.id,
          next,
        )) {
          await NotificationService.cancel(overdueId);
        }

        // Best-effort cleanup for legacy slot-based IDs.
        final minutes = next.hour * 60 + next.minute;
        final occurrence = occ?.occurrence ?? 0;
        final legacyId = ScheduleScheduler.slotIdFor(
          s.id,
          weekday: next.weekday,
          minutes: minutes,
          occurrence: occurrence,
        );
        await NotificationService.cancel(legacyId);
      } catch (_) {}
    } catch (e) {
      debugPrint('Error logging dose: $e');
    }
  }

  /// Helper: snooze current schedule's next occurrence by creating a DoseLog entry
  Future<void> _snoozeSchedule(BuildContext context, Schedule s) async {
    final occ = _nextOccurrenceAndIndex(s);
    final next = occ?.dt;
    if (next == null) {
      if (context.mounted) {
        showAppSnackBar(context, 'No upcoming dose to snooze');
      }
      return;
    }

    final snoozeUntil = next.add(const Duration(minutes: 15));

    final logId = DoseLogIds.occurrenceId(
      scheduleId: s.id,
      scheduledTime: next,
    );
    final log = DoseLog(
      id: logId,
      scheduleId: s.id,
      scheduleName: s.name,
      medicationId: s.medicationId ?? 'unknown',
      medicationName: s.medicationName,
      scheduledTime: next,
      actionTime: snoozeUntil,
      doseValue: s.doseValue,
      doseUnit: s.doseUnit,
      action: DoseAction.snoozed,
    );

    try {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsertOccurrence(log);

      // Cancel any existing reminder for this occurrence (best-effort).
      try {
        await NotificationService.cancel(
          ScheduleScheduler.doseNotificationIdFor(s.id, next),
        );
        for (final overdueId in ScheduleScheduler.overdueNotificationIdsFor(
          s.id,
          next,
        )) {
          await NotificationService.cancel(overdueId);
        }

        final minutes = next.hour * 60 + next.minute;
        final occurrence = occ?.occurrence ?? 0;
        final legacyId = ScheduleScheduler.slotIdFor(
          s.id,
          weekday: next.weekday,
          minutes: minutes,
          occurrence: occurrence,
        );
        await NotificationService.cancel(legacyId);
      } catch (_) {}

      // Reschedule notification for 15 minutes later as a one-off snooze alarm.
      try {
        await NotificationService.scheduleAtAlarmClock(
          ScheduleScheduler.doseNotificationIdFor(s.id, next),
          snoozeUntil,
          title: s.medicationName,
          body: '${s.name} • Snoozed',
          payload: 'dose:${s.id}:${next.millisecondsSinceEpoch}',
          actions: NotificationService.upcomingDoseActions,
          expandedLines: <String>[s.name, 'Snoozed'],
        );
      } catch (e) {
        // ignore scheduling failure - best effort
      }
      if (context.mounted) {
        final now = DateTime.now();
        final sameDay =
            snoozeUntil.year == now.year &&
            snoozeUntil.month == now.month &&
            snoozeUntil.day == now.day;
        final time = DateTimeFormatter.formatTime(context, snoozeUntil);
        final label = sameDay
            ? 'Dose snoozed until $time'
            : 'Dose snoozed until ${MaterialLocalizations.of(context).formatMediumDate(snoozeUntil)} • $time';
        showAppSnackBar(context, label);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Error snoozing: $e');
      }
    }
  }

  /// Helper: skip current schedule's next occurrence by creating a DoseLog and attempting to cancel notification
  Future<void> _skipSchedule(BuildContext context, Schedule s) async {
    final occ = _nextOccurrenceAndIndex(s);
    final next = occ?.dt;
    if (next == null) {
      if (context.mounted) {
        showAppSnackBar(context, 'No upcoming dose to skip');
      }
      return;
    }

    final logId = DoseLogIds.occurrenceId(
      scheduleId: s.id,
      scheduledTime: next,
    );
    final log = DoseLog(
      id: logId,
      scheduleId: s.id,
      scheduleName: s.name,
      medicationId: s.medicationId ?? 'unknown',
      medicationName: s.medicationName,
      scheduledTime: next,
      doseValue: s.doseValue,
      doseUnit: s.doseUnit,
      action: DoseAction.skipped,
    );

    try {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsertOccurrence(log);

      // Attempt to cancel scheduled notification for the day (best-effort)
      try {
        await NotificationService.cancel(
          ScheduleScheduler.doseNotificationIdFor(s.id, next),
        );
        for (final overdueId in ScheduleScheduler.overdueNotificationIdsFor(
          s.id,
          next,
        )) {
          await NotificationService.cancel(overdueId);
        }

        // Best-effort cleanup for legacy slot-based IDs.
        final minutes = next.hour * 60 + next.minute;
        final occurrence = occ?.occurrence ?? 0;
        final legacyId = ScheduleScheduler.slotIdFor(
          s.id,
          weekday: next.weekday,
          minutes: minutes,
          occurrence: occurrence,
        );
        await NotificationService.cancel(legacyId);
      } catch (_) {
        // ignore - best effort cancel
      }

      if (context.mounted) {
        showAppSnackBar(context, 'Dose skipped');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Error skipping dose: $e');
      }
    }
  }
}

/// Small result type to return both a DateTime and scheduler occurrence index
class _OccurrenceResult {
  final DateTime dt;
  final int occurrence;
  const _OccurrenceResult(this.dt, this.occurrence);
}

Future<bool> confirmTake(BuildContext context, Schedule s) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark dose as taken?'),
          content: Text('${s.medicationName} • ${s.doseValue} ${s.doseUnit}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Mark taken'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<bool> applyStockDecrement(BuildContext context, Schedule s) async {
  if (s.medicationId == null) {
    showAppSnackBar(
      context,
      'This schedule is not linked to a saved medication. Edit it to link a medication first.',
    );
    return false;
  }
  final medsBox = Hive.box<Medication>('medications');
  final med = medsBox.get(s.medicationId);
  if (med == null) {
    showAppSnackBar(
      context,
      'Linked medication not found. It may have been deleted.',
    );
    return false;
  }

  // Defer to centralized helper for stock decrement logic

  // Use centralized helper
  final updated = applyDoseTakenUpdate(med, s);
  if (updated == null) {
    showAppSnackBar(
      context,
      'Could not compute stock decrement for this dose. Check medication strength/units.',
    );
    return false;
  }
  final prevStock = med.stockValue;
  await medsBox.put(updated.id, updated);
  // If MDV and we consumed a backup vial (stock decreased) to open new active vial, inform user
  if (med.form == MedicationForm.multiDoseVial &&
      updated.stockValue < prevStock) {
    if (context.mounted) {
      showAppSnackBar(context, 'Active vial depleted. Opened new vial.');
    }
  }
  return true;
}
