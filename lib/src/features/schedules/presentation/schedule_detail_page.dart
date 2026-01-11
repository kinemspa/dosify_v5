// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_status_ui.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/medication_schedules_section.dart';
import 'package:dosifi_v5/src/widgets/next_dose_date_badge.dart';
import 'package:dosifi_v5/src/widgets/schedule_status_chip.dart';
import 'package:dosifi_v5/src/widgets/schedule_pause_dialog.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class ScheduleDetailPage extends StatefulWidget {
  const ScheduleDetailPage({required this.scheduleId, super.key});
  final String scheduleId;

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late final DoseLogRepository _doseLogRepo;

  String _mergedTitle(Schedule s) {
    final med = s.medicationName.trim();
    final name = s.name.trim();

    if (med.isEmpty) return name;
    if (name.isEmpty) return med;

    final nameLower = name.toLowerCase();
    final medLower = med.toLowerCase();
    if (nameLower.startsWith(medLower)) return name;

    return '$med - $name';
  }

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
  Color _getActionColor(BuildContext context, DoseAction action) {
    final cs = Theme.of(context).colorScheme;
    return switch (action) {
      DoseAction.taken => cs.primary,
      DoseAction.snoozed => cs.tertiary,
      DoseAction.skipped => cs.error,
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
        try {
          final s = box.get(widget.scheduleId) ?? schedule;
          final nextDose = _nextOccurrence(s);
          final mergedTitle = _mergedTitle(s);

          return DetailPageScaffold(
            title: mergedTitle,
            onEdit: () => context.push('/schedules/edit/${widget.scheduleId}'),
            onDelete: () => _confirmDelete(context, s),
            statsBannerContent: _buildScheduleHeader(
              context,
              s,
              nextDose,
              title: mergedTitle,
            ),
            sections: _buildSections(context, s, nextDose),
          );
        } catch (e) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 56,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to open schedule details',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.pop(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildScheduleHeader(
    BuildContext context,
    Schedule s,
    DateTime? nextDose, {
    required String title,
  }) {
    final cs = Theme.of(context).colorScheme;
    final headerOnPrimary = cs.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Schedule Details',
                style: sectionTitleStyle(
                  context,
                )?.copyWith(color: headerOnPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: kSpacingS),
            _buildHeaderStatusBadge(context, s),
          ],
        ),
        const SizedBox(height: kSpacingM),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DetailStatItem(
                icon: Icons.medication_outlined,
                label: 'Dose',
                value: _getDoseDisplay(s),
              ),
            ),
            const SizedBox(width: kPageHorizontalPadding),
            Expanded(
              child: DetailStatItem(
                icon: scheduleStatusIcon(s),
                label: 'Status',
                value: scheduleStatusLabel(s),
              ),
            ),
          ],
        ),
        const SizedBox(height: kCardInnerSpacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DetailStatItem(
                icon: Icons.repeat,
                label: 'Type',
                value: _scheduleTypeText(s),
              ),
            ),
            const SizedBox(width: kPageHorizontalPadding),
            Expanded(
              child: DetailStatItem(
                icon: Icons.access_time,
                label: 'Times',
                value: _timesText(context, s),
              ),
            ),
          ],
        ),
        const SizedBox(height: kCardInnerSpacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NextDoseDateBadge(
                nextDose: nextDose,
                isActive: s.isActive,
                dense: true,
                showNextLabel: false,
              ),
            ),
            const SizedBox(width: kPageHorizontalPadding),
            Expanded(
              child: DetailStatItem(
                icon: Icons.timer_outlined,
                label: 'In',
                value: nextDose == null ? '—' : _getTimeUntil(nextDose),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderStatusBadge(BuildContext context, Schedule s) {
    final badge = ScheduleStatusChip(schedule: s, dense: true);
    if (s.isCompleted) return badge;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => _promptPauseFromHeader(context, s),
        borderRadius: BorderRadius.circular(kBorderRadiusChip),
        child: badge,
      ),
    );
  }

  Future<void> _promptPauseFromHeader(BuildContext context, Schedule s) async {
    final choice = await showSchedulePauseDialog(context, schedule: s);
    if (choice == null) return;

    switch (choice) {
      case SchedulePauseDialogChoice.resume:
        await _setScheduleStatus(context, s, active: true, pausedUntil: null);
        return;
      case SchedulePauseDialogChoice.pauseIndefinitely:
        await _setScheduleStatus(context, s, active: false, pausedUntil: null);
        return;
      case SchedulePauseDialogChoice.pauseUntilDate:
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        );
        if (picked == null) return;
        final endOfDay = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
        );
        await _setScheduleStatus(
          context,
          s,
          active: false,
          pausedUntil: endOfDay,
        );
        return;
    }
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

  String _formatDateTime(BuildContext context, DateTime dt) {
    return '${DateFormat('EEE, MMM d, y').format(dt)} • ${TimeOfDay.fromDateTime(dt).format(context)}';
  }

  List<Widget> _buildSections(
    BuildContext context,
    Schedule s,
    DateTime? nextDose,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: kSpacingS),
        child: SectionFormCard(
          neutral: true,
          title: 'Schedule Details',
          children: _buildScheduleDetailsCardChildren(context, s),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: kSpacingS),
        child: SectionFormCard(
          neutral: true,
          title: 'Schedules',
          children: [_buildMedicationSchedulesSection(context, s)],
        ),
      ),
    ];
  }

  List<Widget> _buildScheduleDetailsCardChildren(
    BuildContext context,
    Schedule s,
  ) {
    final startAtLabel = s.startAt == null
        ? 'Not set'
        : _formatDateTime(context, s.startAt!);
    final endAtLabel = s.endAt == null
        ? 'Not set'
        : _formatDateTime(context, s.endAt!);

    return [
      buildDetailInfoRow(
        context,
        label: 'Name',
        value: s.name.trim().isEmpty ? '—' : s.name,
        onTap: () => _promptEditName(context, s),
      ),
      buildDetailInfoRow(
        context,
        label: 'Dose',
        value: _getDoseDisplay(s),
        onTap: () => _promptEditDose(context, s),
      ),
      buildDetailInfoRow(
        context,
        label: 'Type',
        value: _scheduleTypeText(s),
        onTap: () => _promptEditScheduleType(context, s),
        maxLines: 2,
      ),
      buildDetailInfoRow(
        context,
        label: 'Times',
        value: _timesText(context, s),
        onTap: () => _promptEditTimes(context, s),
        maxLines: 2,
      ),
      buildDetailInfoRow(
        context,
        label: 'Start',
        value: startAtLabel,
        onTap: () => _promptEditStartAt(context, s),
        maxLines: 2,
      ),
      buildDetailInfoRow(
        context,
        label: 'End',
        value: endAtLabel,
        onTap: () => _promptEditEndAt(context, s),
        maxLines: 2,
      ),
    ];
  }

  Future<void> _updateSchedule(BuildContext context, Schedule updated) async {
    try {
      final scheduleBox = Hive.box<Schedule>('schedules');
      await ScheduleScheduler.cancelFor(updated.id);
      await scheduleBox.put(updated.id, updated);

      if (updated.isActive) {
        await ScheduleScheduler.scheduleFor(updated);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update schedule: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _promptEditName(BuildContext context, Schedule s) async {
    final controller = TextEditingController(text: s.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Schedule name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final value = newName?.trim();
    if (value == null || value.isEmpty || value == s.name) return;

    await _updateSchedule(context, s.copyWithDetails(name: value));
  }

  Future<void> _promptEditDose(BuildContext context, Schedule s) async {
    final valueController = TextEditingController(
      text: s.doseValue == s.doseValue.roundToDouble()
          ? s.doseValue.toStringAsFixed(0)
          : s.doseValue.toString(),
    );

    final unitOptions = <String>{
      s.doseUnit,
      'mcg',
      'mg',
      'g',
      'ml',
      'iu',
      'units',
      'tablets',
      'capsules',
      'syringes',
      'vials',
    }.toList()..sort();

    String selectedUnit = s.doseUnit;

    final result = await showDialog<(double, String)>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit dose'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: kSpacingM),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: [
                      for (final u in unitOptions)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() => selectedUnit = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(valueController.text.trim());
                    if (parsed == null) return;
                    Navigator.of(dialogContext).pop((parsed, selectedUnit));
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    final (newValue, newUnit) = result;
    if (newValue == s.doseValue && newUnit == s.doseUnit) return;

    await _updateSchedule(
      context,
      s.copyWithDetails(doseValue: newValue, doseUnit: newUnit),
    );
  }

  Future<void> _promptEditTimes(BuildContext context, Schedule s) async {
    final initialTimes = (s.timesOfDay == null || s.timesOfDay!.isEmpty)
        ? <int>[s.minutesOfDay]
        : List<int>.from(s.timesOfDay!);
    initialTimes.sort();

    final updated = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) {
        var times = List<int>.from(initialTimes);

        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            Future<void> pickAndSetTime(int index) async {
              final current = TimeOfDay(
                hour: times[index] ~/ 60,
                minute: times[index] % 60,
              );
              final picked = await showTimePicker(
                context: dialogContext,
                initialTime: current,
              );
              if (picked == null) return;
              final minutes = picked.hour * 60 + picked.minute;
              setStateDialog(() {
                times[index] = minutes;
                times.sort();
              });
            }

            Future<void> addTime() async {
              final picked = await showTimePicker(
                context: dialogContext,
                initialTime: TimeOfDay.now(),
              );
              if (picked == null) return;
              final minutes = picked.hour * 60 + picked.minute;
              setStateDialog(() {
                times.add(minutes);
                times.sort();
              });
            }

            return AlertDialog(
              title: const Text('Edit times'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < times.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: kSpacingS),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => pickAndSetTime(i),
                                child: Text(
                                  TimeOfDay(
                                    hour: times[i] ~/ 60,
                                    minute: times[i] % 60,
                                  ).format(dialogContext),
                                ),
                              ),
                            ),
                            if (times.length > 1) ...[
                              const SizedBox(width: kSpacingS),
                              IconButton(
                                onPressed: () {
                                  setStateDialog(() => times.removeAt(i));
                                },
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: addTime,
                        icon: const Icon(Icons.add),
                        label: const Text('Add time'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(times),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == null) return;
    if (updated.isEmpty) return;

    final times = List<int>.from(updated)..sort();
    final newMinutesOfDay = times.first;
    final newTimesOfDay = times.length > 1 ? times : null;

    final isSame =
        (s.minutesOfDay == newMinutesOfDay) &&
        ((s.timesOfDay == null && newTimesOfDay == null) ||
            (s.timesOfDay != null &&
                newTimesOfDay != null &&
                _listEqualsInt(s.timesOfDay!, newTimesOfDay)));

    if (isSame) return;

    await _updateSchedule(
      context,
      s.copyWithDetails(
        minutesOfDay: newMinutesOfDay,
        timesOfDay: newTimesOfDay,
      ),
    );
  }

  bool _listEqualsInt(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _promptEditScheduleType(BuildContext context, Schedule s) async {
    if (s.hasDaysOfMonth) {
      await _promptEditMonthlyType(context, s);
      return;
    }

    if (s.hasCycle) {
      await _promptEditCycleType(context, s);
      return;
    }

    final updatedDays = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) {
        var selected = Set<int>.from(s.daysOfWeek);
        const labels = <int, String>{
          1: 'Mon',
          2: 'Tue',
          3: 'Wed',
          4: 'Thu',
          5: 'Fri',
          6: 'Sat',
          7: 'Sun',
        };

        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit days'),
              content: Wrap(
                spacing: kSpacingXS,
                runSpacing: kSpacingXS,
                children: [
                  for (final day in labels.keys)
                    FilterChip(
                      label: Text(labels[day]!),
                      selected: selected.contains(day),
                      onSelected: (isSelected) {
                        setStateDialog(() {
                          if (isSelected) {
                            selected.add(day);
                          } else {
                            selected.remove(day);
                          }
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final days = selected.toList()..sort();
                    Navigator.of(dialogContext).pop(days);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updatedDays == null) return;
    if (updatedDays.isEmpty) return;
    if (_listEqualsInt(s.daysOfWeek, updatedDays)) return;

    await _updateSchedule(context, s.copyWithDetails(daysOfWeek: updatedDays));
  }

  Future<void> _promptEditCycleType(BuildContext context, Schedule s) async {
    final nController = TextEditingController(
      text: (s.cycleEveryNDays ?? 1).toString(),
    );
    DateTime? anchor = s.cycleAnchorDate;

    final result = await showDialog<(int, DateTime?)>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit cycle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Every N days',
                      hintText: '2',
                    ),
                  ),
                  const SizedBox(height: kSpacingM),
                  Text(
                    anchor == null
                        ? 'Anchor date: Not set'
                        : 'Anchor date: ${DateFormat('d MMM y').format(anchor!)}',
                    style: bodyTextStyle(dialogContext),
                  ),
                  const SizedBox(height: kSpacingS),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: anchor ?? now,
                            firstDate: DateTime(now.year - 10),
                            lastDate: DateTime(now.year + 20),
                          );
                          if (picked == null) return;
                          setStateDialog(() {
                            anchor = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                          });
                        },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(anchor == null ? 'Set' : 'Change'),
                      ),
                      const SizedBox(width: kSpacingS),
                      if (anchor != null)
                        TextButton(
                          onPressed: () => setStateDialog(() => anchor = null),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = int.tryParse(nController.text.trim());
                    if (parsed == null || parsed <= 0) return;
                    Navigator.of(dialogContext).pop((parsed, anchor));
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    final (n, newAnchor) = result;
    if (s.cycleEveryNDays == n && s.cycleAnchorDate == newAnchor) return;

    await _updateSchedule(
      context,
      s.copyWithDetails(cycleEveryNDays: n, cycleAnchorDate: newAnchor),
    );
  }

  Future<void> _promptEditMonthlyType(BuildContext context, Schedule s) async {
    final initialDays = (s.daysOfMonth ?? const <int>[]).toList()..sort();
    final daysController = TextEditingController(
      text: initialDays.isEmpty ? '' : initialDays.join(', '),
    );

    MonthlyMissingDayBehavior behavior = s.monthlyMissingDayBehavior;

    final result = await showDialog<(List<int>, MonthlyMissingDayBehavior)>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit monthly schedule'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Days of month (1–31)',
                      hintText: '1, 15, 31',
                    ),
                  ),
                  const SizedBox(height: kSpacingM),
                  DropdownButtonFormField<MonthlyMissingDayBehavior>(
                    value: behavior,
                    decoration: const InputDecoration(
                      labelText: 'If a day doesn’t exist',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: MonthlyMissingDayBehavior.skip,
                        child: Text('Skip that month'),
                      ),
                      DropdownMenuItem(
                        value: MonthlyMissingDayBehavior.lastDay,
                        child: Text('Use last day of month'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() => behavior = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final raw = daysController.text.trim();
                    final parts = raw.isEmpty
                        ? <String>[]
                        : raw.split(RegExp('[^0-9]+'));
                    final days = <int>{};
                    for (final part in parts) {
                      if (part.isEmpty) continue;
                      final value = int.tryParse(part);
                      if (value == null) return;
                      if (value < 1 || value > 31) return;
                      days.add(value);
                    }
                    final sorted = days.toList()..sort();
                    if (sorted.isEmpty) return;
                    Navigator.of(dialogContext).pop((sorted, behavior));
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    final (days, newBehavior) = result;

    final sameDays =
        (s.daysOfMonth ?? const <int>[]).length == days.length &&
        _listEqualsInt((s.daysOfMonth ?? const <int>[]).toList()..sort(), days);
    final sameBehavior = s.monthlyMissingDayBehavior == newBehavior;
    if (sameDays && sameBehavior) return;

    await _updateSchedule(
      context,
      s.copyWithDetails(
        daysOfMonth: days,
        monthlyMissingDayBehaviorCode: newBehavior.index,
      ),
    );
  }

  Future<void> _promptEditStartAt(BuildContext context, Schedule s) async {
    await _promptEditBoundaryDateTime(
      context,
      title: 'Edit start date',
      initial: s.startAt,
      onSave: (value) =>
          _updateSchedule(context, s.copyWithDetails(startAt: value)),
    );
  }

  Future<void> _promptEditEndAt(BuildContext context, Schedule s) async {
    await _promptEditBoundaryDateTime(
      context,
      title: 'Edit end date',
      initial: s.endAt,
      onSave: (value) =>
          _updateSchedule(context, s.copyWithDetails(endAt: value)),
    );
  }

  Future<void> _promptEditBoundaryDateTime(
    BuildContext context, {
    required String title,
    required DateTime? initial,
    required Future<void> Function(DateTime? value) onSave,
  }) async {
    final result = await showDialog<DateTime?>(
      context: context,
      builder: (dialogContext) {
        DateTime? selected = initial;

        Future<void> pick() async {
          final now = DateTime.now();
          final initialDate = selected ?? now;
          final pickedDate = await showDatePicker(
            context: dialogContext,
            initialDate: DateTime(
              initialDate.year,
              initialDate.month,
              initialDate.day,
            ),
            firstDate: DateTime(now.year - 10),
            lastDate: DateTime(now.year + 20),
          );
          if (pickedDate == null) return;
          final pickedTime = await showTimePicker(
            context: dialogContext,
            initialTime: TimeOfDay.fromDateTime(initialDate),
          );
          if (pickedTime == null) return;
          selected = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        }

        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected == null
                        ? 'Not set'
                        : _formatDateTime(dialogContext, selected!),
                    style: bodyTextStyle(dialogContext),
                  ),
                  const SizedBox(height: kSpacingM),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await pick();
                      setStateDialog(() {});
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(selected == null ? 'Set' : 'Change'),
                  ),
                ],
              ),
              actions: [
                if (selected != null)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    child: const Text('Clear'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(initial),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == initial) return;
    await onSave(result);
  }

  Widget _buildMedicationSchedulesSection(BuildContext context, Schedule s) {
    final medId = s.medicationId;
    if (medId == null) return const SizedBox.shrink();

    final medBox = Hive.box<Medication>('medications');
    final med = medBox.get(medId);
    if (med == null) return const SizedBox.shrink();

    return MedicationSchedulesSection(medication: med);
  }

  Future<void> _setScheduleStatus(
    BuildContext context,
    Schedule s, {
    required bool active,
    required DateTime? pausedUntil,
  }) async {
    if (s.active == active && s.pausedUntil == pausedUntil) return;

    try {
      final scheduleBox = Hive.box<Schedule>('schedules');
      final updated = s.copyWith(active: active, pausedUntil: pausedUntil);

      await ScheduleScheduler.cancelFor(s.id);
      await scheduleBox.put(s.id, updated);

      if (updated.isActive) {
        await ScheduleScheduler.scheduleFor(updated);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Schedule set to ${scheduleStatusLabel(updated)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update schedule status: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ignore: unused_element
  Widget _buildNextDoseSection(
    BuildContext context,
    Schedule s,
    DateTime nextDose,
  ) {
    final existingLog = _getExistingLog(nextDose);
    final isTaken = existingLog?.action == DoseAction.taken;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingS),
      child: SectionFormCard(
        neutral: true,
        title: 'Next Dose',
        children: [
          buildDetailInfoRow(
            context,
            label: 'When',
            value:
                '${DateFormat('EEE, MMM d').format(nextDose)} • ${TimeOfDay.fromDateTime(nextDose).format(context)}',
            maxLines: 2,
          ),
          buildDetailInfoRow(
            context,
            label: 'Time until',
            value: _getTimeUntil(nextDose),
          ),
          if (existingLog != null)
            buildDetailInfoRow(
              context,
              label: 'Recorded',
              value:
                  '${_getActionLabel(existingLog.action)} at ${TimeOfDay.fromDateTime(existingLog.actionTime).format(context)}',
              highlighted: true,
            ),
          const SizedBox(height: kSpacingS),
          Row(
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
                    size: kIconSizeSmall,
                  ),
                  label: Text(existingLog != null ? 'Edit' : 'Take'),
                ),
              ),
              if (!isTaken) ...[
                const SizedBox(width: kSpacingS),
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
                    icon: Icon(Icons.snooze, size: kIconSizeSmall),
                    label: const Text('Snooze'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface.withValues(
                        alpha: kOpacityMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: kSpacingS),
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
                    foregroundColor: cs.onSurface.withValues(
                      alpha: kOpacityMedium,
                    ),
                  ),
                  child: Icon(Icons.close, size: kIconSizeSmall),
                ),
              ],
            ],
          ),
          if (existingLog != null) ...[
            const SizedBox(height: kSpacingS),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getActionIcon(existingLog.action),
                  size: kIconSizeSmall,
                  color: _getActionColor(context, existingLog.action),
                ),
                const SizedBox(width: kSpacingXS),
                Text(
                  _getActionLabel(existingLog.action),
                  style: helperTextStyle(context)?.copyWith(
                    color: _getActionColor(context, existingLog.action),
                    fontWeight: kFontWeightSemiBold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Unified dose timeline showing past (with logs), today, and future doses
  // ignore: unused_element
  Widget _buildDoseTimeline(BuildContext context, Schedule s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get 7 days: 3 past + today + 3 future
    final days = List.generate(7, (i) => today.add(Duration(days: i - 3)));

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingS),
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
              ? _getActionColor(
                  context,
                  existingLog.action,
                ).withValues(alpha: 0.1)
              : (isToday
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08)
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
          border: hasLog
              ? Border.all(
                  color: _getActionColor(context, existingLog.action),
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
                      ? _getActionColor(context, existingLog.action)
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
                        _getDoseDisplay(s),
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
                      color: _getActionColor(context, existingLog.action),
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
    String trimZerosNumber(double value, {int decimals = 3}) {
      final fixed = value.toStringAsFixed(decimals);
      return fixed
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }

    String formatMass(int mcg) {
      if (mcg == 0) return '0 mcg';
      if (mcg.abs() >= 1000000) {
        final g = mcg / 1000000.0;
        return '${trimZerosNumber(g, decimals: 3)} g';
      }
      if (mcg.abs() >= 1000) {
        final mg = mcg / 1000.0;
        return '${trimZerosNumber(mg, decimals: 3)} mg';
      }
      return '$mcg mcg';
    }

    String formatVolume(int microliter) {
      final ml = microliter / 1000.0;
      return '${trimZerosNumber(ml, decimals: 3)} mL';
    }

    String formatCount(double count, String singular) {
      final label = (count == 1) ? singular : '${singular}s';
      return '${trimZerosNumber(count, decimals: 3)} $label';
    }

    String? countPart;
    if (s.doseTabletQuarters != null) {
      final q = s.doseTabletQuarters!;
      final count = q / 4.0;
      String amount;
      if (q == 1) {
        amount = '1/4';
      } else if (q == 2) {
        amount = '1/2';
      } else if (q == 3) {
        amount = '3/4';
      } else if (q % 4 == 0) {
        amount = (q ~/ 4).toString();
      } else {
        amount = trimZerosNumber(count, decimals: 3);
      }

      final label = (count == 1) ? 'tablet' : 'tablets';
      countPart = '$amount $label';
    } else if (s.doseCapsules != null) {
      final count = s.doseCapsules!.toDouble();
      countPart = formatCount(count, 'capsule');
    } else if (s.doseSyringes != null) {
      final count = s.doseSyringes!.toDouble();
      countPart = formatCount(count, 'syringe');
    } else if (s.doseVials != null) {
      final count = s.doseVials!.toDouble();
      countPart = formatCount(count, 'vial');
    }

    final parts = <String>[];
    if (countPart != null && countPart.isNotEmpty) {
      parts.add(countPart);
    }

    if (s.doseMassMcg != null) {
      parts.add(formatMass(s.doseMassMcg!));
    }

    if (s.doseVolumeMicroliter != null) {
      parts.add(formatVolume(s.doseVolumeMicroliter!));
    }

    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }

    // Fallback (legacy)
    return '${_formatNumber(s.doseValue)} ${s.doseUnit}'.trim();
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
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _scheduleTypeText(Schedule schedule) {
    if (schedule.daysOfMonth?.isNotEmpty == true) return 'Days of month';
    if (schedule.hasCycle && schedule.cycleEveryNDays != null) {
      final n = schedule.cycleEveryNDays!;
      return 'Every $n day${n == 1 ? '' : 's'}';
    }
    final ds = schedule.daysOfWeek.toList();
    if (ds.length == 7) return 'Daily';
    return 'Days of week';
  }

  String _timesText(BuildContext context, Schedule schedule) {
    final ts = schedule.timesOfDay ?? [schedule.minutesOfDay];
    return ts
        .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context))
        .join('\n');
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
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Deleted "${schedule.name}"')),
      );
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
