// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/widgets/calendar/dose_calendar_widget.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_header.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class ScheduleDetailPage extends StatefulWidget {
  const ScheduleDetailPage({required this.scheduleId, super.key});
  final String scheduleId;

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late final DoseLogRepository _doseLogRepo;

  @override
  void initState() {
    super.initState();
    _doseLogRepo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
  }

  /// Generate unique ID using timestamp + random suffix
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'dose_$timestamp$random';
  }

  /// Check if there's already a log for this scheduled time
  DoseLog? _getExistingLog(DateTime scheduledTime) {
    final logs = _doseLogRepo.getByScheduleId(widget.scheduleId);
    final scheduledUtc = scheduledTime.toUtc();

    return logs.cast<DoseLog?>().firstWhere(
      (log) =>
          log!.scheduledTime.year == scheduledUtc.year &&
          log.scheduledTime.month == scheduledUtc.month &&
          log.scheduledTime.day == scheduledUtc.day &&
          log.scheduledTime.hour == scheduledUtc.hour &&
          log.scheduledTime.minute == scheduledUtc.minute,
      orElse: () => null,
    );
  }

  /// Show dialog to record dose with notes and injection site
  Future<void> _showRecordDoseDialog({
    required Schedule schedule,
    required DateTime scheduledTime,
    required DoseAction action,
    DoseLog? existingLog,
  }) async {
    final notesController = TextEditingController(text: existingLog?.notes);
    String? injectionSite = existingLog?.notes?.contains('Site:') == true
        ? existingLog!.notes!.split('Site:').last.trim()
        : null;

    final isInjection =
        schedule.medicationName.toLowerCase().contains('injection') ||
        schedule.doseUnit.toLowerCase().contains('syringe') ||
        schedule.doseUnit.toLowerCase().contains('vial');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DoseRecordDialog(
        action: action,
        existingLog: existingLog,
        isInjection: isInjection,
        notesController: notesController,
        initialInjectionSite: injectionSite,
      ),
    );

    if (result == null) return;

    if (result['delete'] == true && existingLog != null) {
      await _doseLogRepo.delete(existingLog.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dose log removed')));
      setState(() {});
      return;
    }

    final notes = result['notes'] as String?;
    final site = result['injectionSite'] as String?;
    final combinedNotes = [
      if (notes?.isNotEmpty == true) notes,
      if (site?.isNotEmpty == true) 'Site: $site',
    ].join('\n');

    final log = DoseLog(
      id: existingLog?.id ?? _generateId(),
      scheduleId: schedule.id,
      scheduleName: schedule.name,
      medicationId: schedule.medicationId ?? '',
      medicationName: schedule.medicationName,
      scheduledTime: scheduledTime.toUtc(),
      doseValue: schedule.doseValue,
      doseUnit: schedule.doseUnit,
      action: action,
      notes: combinedNotes.isEmpty ? null : combinedNotes,
    );

    await _doseLogRepo.upsert(log);

    if (!mounted) return;

    final actionText = action == DoseAction.taken
        ? 'taken'
        : action == DoseAction.skipped
        ? 'skipped'
        : 'snoozed for 15 minutes';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Dose $actionText')));

    setState(() {});
  }

  // Helper methods for dose action UI
  Color _getActionColor(DoseAction action) {
    return switch (action) {
      DoseAction.taken => Colors.green,
      DoseAction.snoozed => Colors.orange,
      DoseAction.skipped => Colors.red,
    };
  }

  IconData _getActionIcon(DoseAction action) {
    return switch (action) {
      DoseAction.taken => Icons.check_circle,
      DoseAction.snoozed => Icons.snooze,
      DoseAction.skipped => Icons.cancel,
    };
  }

  String _getActionLabel(DoseAction action) {
    return switch (action) {
      DoseAction.taken => 'Taken',
      DoseAction.snoozed => 'Snoozed',
      DoseAction.skipped => 'Skipped',
    };
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Schedule>('schedules');
    final schedule = box.get(widget.scheduleId);

    if (schedule == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Schedule not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Schedule> box, _) {
        final s = box.get(widget.scheduleId) ?? schedule;
        final nextDose = _nextOccurrence(s);

        return DetailPageScaffold(
          title: s.name,
          onEdit: () => context.push('/schedules/edit/${widget.scheduleId}'),
          onDelete: () => _confirmDelete(context, s),
          statsBannerContent: _buildScheduleHeader(context, s, nextDose),
          sections: _buildSections(context, s, nextDose),
        );
      },
    );
  }

  Widget _buildScheduleHeader(
    BuildContext context,
    Schedule s,
    DateTime? nextDose,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getHeaderDoseInfo(s),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: s.active
                      ? Colors.green.withValues(alpha: 0.25)
                      : Colors.grey.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: s.active ? Colors.greenAccent : Colors.white54,
                  ),
                ),
                child: Text(
                  s.active ? 'Active' : 'Paused',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Next dose with action buttons
          if (nextDose != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  // Status badge if dose is already recorded
                  () {
                    final existingLog = _getExistingLog(nextDose);
                    if (existingLog == null) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getActionColor(existingLog.action),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getActionIcon(existingLog.action),
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_getActionLabel(existingLog.action)} at ${TimeOfDay.fromDateTime(existingLog.actionTime).format(context)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }(),

                  Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            DateFormat('EEE').format(nextDose).toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            DateFormat('d').format(nextDose),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(nextDose).toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Show syringe icon for injections
                                () {
                                  if (s.medicationId != null) {
                                    try {
                                      final medicationBox = Hive.box<dynamic>(
                                        'medications',
                                      );
                                      final medication = medicationBox.get(
                                        s.medicationId,
                                      );
                                      if (medication != null) {
                                        final form =
                                            medication.form
                                                ?.toString()
                                                .split('.')
                                                .last ??
                                            '';
                                        final isInjection =
                                            form == 'injection' ||
                                            form == 'multiDoseVial' ||
                                            form == 'singleDoseVial';
                                        if (isInjection) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            child: Icon(
                                              Icons.medication,
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                              size: 12,
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      // Ignore
                                    }
                                  }
                                  return const SizedBox.shrink();
                                }(),
                                Text(
                                  'Next Dose',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              TimeOfDay.fromDateTime(nextDose).format(context),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Comprehensive dosing instructions
                          () {
                            if (s.medicationId != null) {
                              try {
                                final medicationBox = Hive.box<dynamic>(
                                  'medications',
                                );
                                final medication = medicationBox.get(
                                  s.medicationId,
                                );

                                if (medication != null) {
                                  final strengthValue =
                                      medication.strengthValue as double?;
                                  final strengthUnit =
                                      medication.strengthUnit
                                          ?.toString()
                                          .split('.')
                                          .last ??
                                      '';
                                  final form =
                                      medication.form
                                          ?.toString()
                                          .split('.')
                                          .last ??
                                      '';
                                  final volumePerDose =
                                      medication.volumePerDose as double?;
                                  final volumeUnit =
                                      medication.volumeUnit
                                          ?.toString()
                                          .split('.')
                                          .last ??
                                      'ml';
                                  final isInjection =
                                      form == 'injection' ||
                                      form == 'multiDoseVial' ||
                                      form == 'singleDoseVial';

                                  if (strengthValue != null &&
                                      strengthValue > 0) {
                                    final totalAmount =
                                        s.doseValue * strengthValue;

                                    // For injections: show ALL instructions
                                    if (isInjection && volumePerDose != null) {
                                      final syringeUnits = (volumePerDose * 100)
                                          .round();
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          // Dose count
                                          Text(
                                            '${_formatNumber(s.doseValue)} ${s.doseUnit}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          // Total medication amount
                                          Text(
                                            '${_formatNumber(totalAmount)} $strengthUnit',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          // Volume in mL
                                          Text(
                                            '${_formatNumber(volumePerDose)} $volumeUnit',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                              fontSize: 10,
                                            ),
                                          ),
                                          // Syringe units
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.medication,
                                                size: 10,
                                                color: Colors.greenAccent,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '$syringeUnits Units',
                                                style: TextStyle(
                                                  color: Colors.greenAccent,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }

                                    // For tablets/capsules: show total dose
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${_formatNumber(s.doseValue)} ${s.doseUnit}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_formatNumber(totalAmount)} $strengthUnit total',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                }
                              } catch (e) {
                                // Ignore errors
                              }
                            }

                            // Fallback: just dose count
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_formatNumber(s.doseValue)} ${s.doseUnit}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _getTimeUntil(nextDose),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            );
                          }(),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Action buttons
                  () {
                    final existingLog = _getExistingLog(nextDose);
                    final isTaken = existingLog?.action == DoseAction.taken;

                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showRecordDoseDialog(
                                schedule: s,
                                scheduledTime: nextDose,
                                action: DoseAction.taken,
                                existingLog: existingLog,
                              );
                            },
                            icon: Icon(
                              existingLog != null ? Icons.edit : Icons.check,
                              size: 14,
                            ),
                            label: Text(
                              existingLog != null ? 'Edit' : 'Take',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                        // Only show Snooze and Skip buttons if dose hasn't been taken
                        if (!isTaken) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showRecordDoseDialog(
                                  schedule: s,
                                  scheduledTime: nextDose,
                                  action: DoseAction.snoozed,
                                  existingLog: existingLog,
                                );
                              },
                              icon: const Icon(Icons.snooze, size: 14),
                              label: const Text(
                                'Snooze',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            onPressed: () {
                              _showRecordDoseDialog(
                                schedule: s,
                                scheduledTime: nextDose,
                                action: DoseAction.skipped,
                                existingLog: existingLog,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                            ),
                            child: const Icon(Icons.close, size: 14),
                          ),
                        ],
                      ],
                    );
                  }(),
                ],
              ),
            ),
          const SizedBox(height: 4),

          // Frequency pills
          Row(
            children: [
              _buildSmallChip(
                context,
                icon: Icons.repeat,
                label: _frequencyText(s),
              ),
              const SizedBox(width: 6),
              _buildSmallChip(
                context,
                icon: Icons.schedule,
                label: _timesText(context, s),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeUntil(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.inMinutes < 60) {
      return 'in ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'in ${diff.inHours}h';
    } else {
      return 'in ${diff.inDays}d';
    }
  }

  List<Widget> _buildSections(
    BuildContext context,
    Schedule s,
    DateTime? nextDose,
  ) {
    return [
      // Unified dose timeline (past, present, future)
      _buildDoseTimeline(context, s),

      // Schedule Details Card
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SectionFormCard(
          neutral: true,
          title: 'Schedule Details',
          children: [
            buildDetailInfoRow(
              context,
              label: 'Dose',
              value: _getDoseDisplay(s),
            ),
            // Week 5: Show reconstitution badge if applicable
            if (s.medicationId != null) _buildReconstitutionBadge(s),
            buildDetailInfoRow(
              context,
              label: 'Frequency',
              value: _frequencyText(s),
            ),
            buildDetailInfoRow(
              context,
              label: 'Times',
              value: _timesText(context, s),
            ),
            // Week 5: Add Recalculate button for MDV schedules with reconstitution
            if (s.medicationId != null) _buildRecalculateButton(s),
          ],
        ),
      ),

      // Dose Calendar Section
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SectionFormCard(
          neutral: true,
          title: 'Dose Calendar',
          children: [
            SizedBox(
              height: 400,
              child: DoseCalendarWidget(
                variant: CalendarVariant.compact,
                defaultView: CalendarView.week,
                scheduleId: s.id,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// Unified dose timeline showing past (with logs), today, and future doses
  Widget _buildDoseTimeline(BuildContext context, Schedule s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get 7 days: 3 past + today + 3 future
    final days = List.generate(7, (i) => today.add(Duration(days: i - 3)));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionFormCard(
        neutral: true,
        title: 'Dose Timeline',
        children: [
          // Scrollable timeline
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isPast = date.isBefore(today);
                final hasDoses = _hasDosesOnDate(date, s);

                return _buildTimelineDay(
                  context,
                  s,
                  date,
                  isToday: isToday,
                  isPast: isPast,
                  hasDoses: hasDoses,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDay(
    BuildContext context,
    Schedule s,
    DateTime date, {
    required bool isToday,
    required bool isPast,
    required bool hasDoses,
  }) {
    if (!hasDoses) {
      return const SizedBox.shrink();
    }

    final doses = _getDosesForDate(date, s);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            children: [
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isToday) const SizedBox(width: 8),
              Text(
                DateFormat('EEE, MMM d').format(date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Doses for this day
          ...doses.map((dt) {
            final existingLog = _getExistingLog(dt);
            return _buildTimelineDoseCard(
              context,
              s,
              dt,
              existingLog: existingLog,
              isPast: isPast,
              isToday: isToday,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineDoseCard(
    BuildContext context,
    Schedule s,
    DateTime dt, {
    DoseLog? existingLog,
    required bool isPast,
    required bool isToday,
  }) {
    final isTaken = existingLog?.action == DoseAction.taken;
    final hasLog = existingLog != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasLog
              ? _getActionColor(existingLog.action).withValues(alpha: 0.1)
              : (isToday
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08)
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
          border: hasLog
              ? Border.all(
                  color: _getActionColor(existingLog.action),
                  width: 1.5,
                )
              : (isToday
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      )
                    : Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      )),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasLog ? _getActionIcon(existingLog.action) : Icons.schedule,
                  size: 18,
                  color: hasLog
                      ? _getActionColor(existingLog.action)
                      : (isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TimeOfDay.fromDateTime(dt).format(context),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${_formatNumber(s.doseValue)} ${s.doseUnit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasLog)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getActionColor(existingLog.action),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getActionLabel(existingLog.action).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // Show notes and injection site if logged
            if (hasLog && existingLog.notes != null) ...[
              const SizedBox(height: 8),
              () {
                final notes = existingLog.notes!.trim();
                final hasInjectionSite = notes.contains('Site:');
                String displayNotes = notes;
                String? injectionSite;

                if (hasInjectionSite) {
                  final parts = notes.split('Site:');
                  displayNotes = parts[0].trim();
                  injectionSite = parts.length > 1 ? parts[1].trim() : null;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (displayNotes.isNotEmpty)
                      Text(
                        displayNotes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (injectionSite != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            injectionSite,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              }(),
            ],

            // Action buttons for future or today's doses
            if (!isPast || isToday) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (!isTaken) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.taken,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.check, size: 14),
                        label: Text(
                          existingLog != null ? 'Edit' : 'Take',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.snoozed,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.snooze, size: 14),
                        label: const Text(
                          'Snooze',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.skipped,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.close, size: 14),
                        label: const Text(
                          'Skip',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showRecordDoseDialog(
                            schedule: s,
                            scheduledTime: dt,
                            action: DoseAction.taken,
                            existingLog: existingLog,
                          );
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDoseDisplay(Schedule s) {
    // TODO: Get medication from database to show strength
    // For now just show the dose
    return '${_formatNumber(s.doseValue)} ${s.doseUnit}';
  }

  /// Week 5: Build reconstitution badge if medication has reconstitution data
  Widget _buildReconstitutionBadge(Schedule s) {
    try {
      final medicationBox = Hive.box<Medication>('medications');
      final medication = medicationBox.get(s.medicationId);

      if (medication == null || medication.reconstitutedAt == null) {
        return const SizedBox.shrink();
      }

      final recon = medication.reconstitutedAt!;
      final expiry = medication.reconstitutedVialExpiry;
      final reconDate = '${recon.month}/${recon.day}/${recon.year}';

      String badgeText;
      Color badgeColor;
      IconData badgeIcon;

      if (expiry != null) {
        final now = DateTime.now();
        final daysLeft = expiry.difference(now).inDays;

        if (daysLeft < 0) {
          badgeText = 'Vial expired ${-daysLeft} days ago';
          badgeColor = Theme.of(context).colorScheme.error;
          badgeIcon = Icons.warning;
        } else if (daysLeft == 0) {
          badgeText = 'Vial expires today';
          badgeColor = Theme.of(context).colorScheme.error;
          badgeIcon = Icons.warning;
        } else if (daysLeft == 1) {
          badgeText = 'Vial expires tomorrow';
          badgeColor = Colors.orange;
          badgeIcon = Icons.info_outline;
        } else if (daysLeft <= 3) {
          badgeText = 'Vial expires in $daysLeft days';
          badgeColor = Colors.orange;
          badgeIcon = Icons.info_outline;
        } else {
          badgeText = 'Reconstituted on $reconDate';
          badgeColor = Theme.of(context).colorScheme.primary;
          badgeIcon = Icons.check_circle_outline;
        }
      } else {
        badgeText = 'Reconstituted on $reconDate';
        badgeColor = Theme.of(context).colorScheme.primary;
        badgeIcon = Icons.check_circle_outline;
      }

      return Padding(
        padding: const EdgeInsets.only(left: 120, top: 4, bottom: 8),
        child: Row(
          children: [
            Icon(badgeIcon, size: 14, color: badgeColor),
            const SizedBox(width: 4),
            Text(
              badgeText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  /// Week 5: Build recalculate button for MDV schedules with reconstitution
  Widget _buildRecalculateButton(Schedule s) {
    try {
      final medicationBox = Hive.box<Medication>('medications');
      final medication = medicationBox.get(s.medicationId);

      if (medication == null ||
          medication.form != MedicationForm.multiDoseVial ||
          medication.reconstitutedAt == null) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: OutlinedButton.icon(
          onPressed: () {
            // Open medication detail page which has the reconstitution calculator
            context.push('/medications/detail/${medication.id}');
          },
          icon: const Icon(Icons.calculate, size: 18),
          label: const Text('Recalculate Reconstitution'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  bool _hasDosesOnDate(DateTime date, Schedule s) {
    final onDay = s.hasCycle && s.cycleEveryNDays != null
        ? (() {
            final anchor = s.cycleAnchorDate ?? DateTime.now();
            final a = DateTime(anchor.year, anchor.month, anchor.day);
            final d0 = DateTime(date.year, date.month, date.day);
            final diff = d0.difference(a).inDays;
            return diff >= 0 && diff % s.cycleEveryNDays! == 0;
          })()
        : s.daysOfWeek.contains(date.weekday);
    return onDay;
  }

  List<DateTime> _getDosesForDate(DateTime date, Schedule s) {
    final doses = <DateTime>[];
    final onDay = _hasDosesOnDate(date, s);

    if (onDay) {
      final times = s.timesOfDay ?? [s.minutesOfDay];
      for (final minutes in times) {
        final dt = DateTime(
          date.year,
          date.month,
          date.day,
          minutes ~/ 60,
          minutes % 60,
        );
        doses.add(dt);
      }
    }
    return doses;
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  /// Get header dose info: "100 mg of Panadol" or "2 tablets — 100 mg of Panadol"
  String _getHeaderDoseInfo(Schedule schedule) {
    if (schedule.medicationId != null) {
      try {
        final medicationBox = Hive.box<dynamic>('medications');
        final medication = medicationBox.get(schedule.medicationId);

        if (medication != null) {
          final strengthValue = medication.strengthValue as double?;
          final strengthUnit =
              medication.strengthUnit?.toString().split('.').last ?? '';
          final form = medication.form?.toString().split('.').last ?? '';
          final perMlValue = medication.perMlValue as double?;
          final volumePerDose = medication.volumePerDose as double?;
          final volumeUnit =
              medication.volumeUnit?.toString().split('.').last ?? 'ml';

          if (strengthValue != null && strengthValue > 0) {
            final totalAmount = schedule.doseValue * strengthValue;
            final isInjection =
                form == 'injection' ||
                form == 'multiDoseVial' ||
                form == 'singleDoseVial';

            // For injections, show mg/mcg + mL + syringe units
            if (isInjection && perMlValue != null && volumePerDose != null) {
              // Calculate syringe units (assuming 100 units = 1mL)
              final syringeUnits = (volumePerDose * 100).round();
              return '${_formatNumber(totalAmount)} $strengthUnit (${_formatNumber(volumePerDose)} $volumeUnit / $syringeUnits U) — ${schedule.medicationName}';
            }

            // For regular medications, show total dose
            return '${_formatNumber(totalAmount)} $strengthUnit of ${schedule.medicationName}';
          }
        }
      } catch (e) {
        // Box might not be open, just use fallback
      }
    }

    // Fallback: just show medication name
    return schedule.medicationName;
  }

  String _frequencyText(Schedule schedule) {
    if (schedule.hasCycle && schedule.cycleEveryNDays != null) {
      final n = schedule.cycleEveryNDays!;
      return 'Every $n day${n == 1 ? '' : 's'}';
    }
    final ds = schedule.daysOfWeek.toList()..sort();
    if (ds.length == 7) {
      return 'Every day';
    }
    const dlabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return ds.map((i) => dlabels[i - 1]).join(', ');
  }

  String _timesText(BuildContext context, Schedule schedule) {
    final ts = schedule.timesOfDay ?? [schedule.minutesOfDay];
    return ts
        .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context))
        .join(', ');
  }

  DateTime? _nextOccurrence(Schedule s) {
    return ScheduleOccurrenceService.nextOccurrence(s);
  }

  Future<void> _confirmDelete(BuildContext context, Schedule schedule) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete schedule?'),
            content: Text(
              'Delete "${schedule.name}"? This will cancel its notifications.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok || !context.mounted) return;

    await ScheduleScheduler.cancelFor(schedule.id);
    await Hive.box<Schedule>('schedules').delete(schedule.id);
    if (context.mounted) {
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted "${schedule.name}"')));
    }
  }
}

/// Dialog for recording a dose with notes and optional injection site
class _DoseRecordDialog extends StatefulWidget {
  final DoseAction action;
  final DoseLog? existingLog;
  final bool isInjection;
  final TextEditingController notesController;
  final String? initialInjectionSite;

  const _DoseRecordDialog({
    required this.action,
    required this.existingLog,
    required this.isInjection,
    required this.notesController,
    this.initialInjectionSite,
  });

  @override
  State<_DoseRecordDialog> createState() => _DoseRecordDialogState();
}

class _DoseRecordDialogState extends State<_DoseRecordDialog> {
  late final TextEditingController _injectionSiteController;

  @override
  void initState() {
    super.initState();
    _injectionSiteController = TextEditingController(
      text: widget.initialInjectionSite,
    );
  }

  @override
  void dispose() {
    _injectionSiteController.dispose();
    super.dispose();
  }

  String get _actionLabel {
    return switch (widget.action) {
      DoseAction.taken => 'Take Dose',
      DoseAction.snoozed => 'Snooze Dose',
      DoseAction.skipped => 'Skip Dose',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingLog != null ? 'Edit Dose' : _actionLabel),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notes field
            TextFormField(
              controller: widget.notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this dose...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            // Injection site field (only for injections)
            if (widget.isInjection) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _injectionSiteController,
                decoration: const InputDecoration(
                  labelText: 'Injection Site (optional)',
                  hintText: 'e.g., Left arm, Right thigh...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Delete button (if editing existing log)
        if (widget.existingLog != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop({'delete': true}),
            child: const Text('Delete'),
          ),

        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        // Save button
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            'notes': widget.notesController.text.trim(),
            'injectionSite': _injectionSiteController.text.trim(),
            'delete': false,
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
