import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dosifi_v5/src/core/clock.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log_ids.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/providers.dart';
import 'package:dosifi_v5/src/widgets/dose_card.dart';
import 'package:dosifi_v5/src/widgets/show_dose_action_sheet.dart';
import 'package:dosifi_v5/src/widgets/unified_empty_state.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

enum TodayDosesScopeType { all, medication, schedule }

class TodayDosesScope {
  const TodayDosesScope._(this.type, {this.medicationId, this.scheduleId});

  const TodayDosesScope.all() : this._(TodayDosesScopeType.all);

  const TodayDosesScope.medication(String medicationId)
    : this._(TodayDosesScopeType.medication, medicationId: medicationId);

  const TodayDosesScope.schedule(String scheduleId)
    : this._(TodayDosesScopeType.schedule, scheduleId: scheduleId);

  final TodayDosesScopeType type;
  final String? medicationId;
  final String? scheduleId;

  String get persistenceKey {
    switch (type) {
      case TodayDosesScopeType.all:
        return 'all';
      case TodayDosesScopeType.medication:
        return 'med_${medicationId ?? 'unknown'}';
      case TodayDosesScopeType.schedule:
        return 'sched_${scheduleId ?? 'unknown'}';
    }
  }
}

class TodayDosesCard extends ConsumerStatefulWidget {
  const TodayDosesCard({
    super.key,
    required this.scope,
    this.title = 'Up next',
    this.isExpanded,
    this.onExpandedChanged,
    this.reserveReorderHandleGutterWhenCollapsed = false,
    this.neutral = true,
    this.frameless = true,
  });

  final TodayDosesScope scope;
  final String title;

  /// If provided, expansion state is controlled by the parent.
  final bool? isExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  final bool reserveReorderHandleGutterWhenCollapsed;
  final bool neutral;
  final bool frameless;

  @override
  ConsumerState<TodayDosesCard> createState() => _TodayDosesCardState();
}

class _TodayDosesCardState extends ConsumerState<TodayDosesCard> {
  static const _prefsDismissedPrefix = 'today_card_dismissed:';

  bool _internalExpanded = true;
  bool _showAll = false;
  final Set<String> _dismissedOccurrenceIds = <String>{};

  bool get _expanded => widget.isExpanded ?? _internalExpanded;

  void _setExpanded(bool expanded) {
    widget.onExpandedChanged?.call(expanded);
    if (widget.isExpanded != null) return;
    if (!mounted) return;
    setState(() {
      _internalExpanded = expanded;
      if (!expanded) _showAll = false;
    });
  }

  String get _prefsKeyDismissed =>
      '$_prefsDismissedPrefix${widget.scope.persistenceKey}';

  @override
  void initState() {
    super.initState();
    unawaited(_restoreDismissed());
  }

  Future<void> _restoreDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKeyDismissed);
    if (stored == null || stored.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _dismissedOccurrenceIds
        ..clear()
        ..addAll(stored);
    });
  }

  Future<void> _persistDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKeyDismissed,
      _dismissedOccurrenceIds.toList(growable: false),
    );
  }

  void _restoreAllDismissed() {
    if (_dismissedOccurrenceIds.isEmpty) return;
    setState(_dismissedOccurrenceIds.clear);
    unawaited(_persistDismissed());
  }

  List<
    ({
      CalculatedDose dose,
      Schedule schedule,
      Medication medication,
      String strengthLabel,
      String metrics,
    })
  > _resolveTodayDoses(
    Iterable<Schedule> schedules,
    Map<String, Medication> medsById,
    Map<String, DoseLog> logsById,
  ) {
    final now = AppClock.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    final items =
        <
          ({
            CalculatedDose dose,
            Schedule schedule,
            Medication medication,
            String strengthLabel,
            String metrics,
          })
        >[];

    for (final schedule in schedules) {
      if (!schedule.isActive) continue;

      final medId = schedule.medicationId;
      if (medId == null) continue;

      final med = medsById[medId];
      if (med == null) continue;

      final times = ScheduleOccurrenceService.occurrencesInRange(
        schedule,
        start,
        end,
      );

      if (times.isEmpty) continue;

      final strengthLabel =
          MedicationDisplayHelpers.strengthOrConcentrationLabel(med);
      final metrics = MedicationDisplayHelpers.doseMetricsSummary(
        med,
        doseTabletQuarters: schedule.doseTabletQuarters,
        doseCapsules: schedule.doseCapsules,
        doseSyringes: schedule.doseSyringes,
        doseVials: schedule.doseVials,
        doseMassMcg: schedule.doseMassMcg?.toDouble(),
        doseVolumeMicroliter: schedule.doseVolumeMicroliter?.toDouble(),
        syringeUnits: schedule.doseIU?.toDouble(),
      );

      for (final dt in times) {
        final baseId = DoseLogIds.occurrenceId(
          scheduleId: schedule.id,
          scheduledTime: dt,
        );
        final existingLog =
            logsById[baseId] ??
            logsById[DoseLogIds.legacySnoozeIdFromBase(baseId)];

        final dose = CalculatedDose(
          scheduleId: schedule.id,
          scheduleName: schedule.name,
          medicationName: med.name,
          scheduledTime: dt,
          doseValue: schedule.doseValue,
          doseUnit: schedule.doseUnit,
          existingLog: existingLog,
        );

        items.add((
          dose: dose,
          schedule: schedule,
          medication: med,
          strengthLabel: strengthLabel,
          metrics: metrics,
        ));
      }
    }

    items.sort((a, b) => a.dose.scheduledTime.compareTo(b.dose.scheduledTime));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Rebuild whenever any relevant box changes.
    ref.watch(schedulesBoxChangesProvider);
    ref.watch(medicationsBoxChangesProvider);
    ref.watch(doseLogsBoxChangesProvider);

    final scheduleBox = ref.watch(schedulesBoxProvider);
    final medBox = ref.watch(medicationsBoxProvider);
    final logBox = ref.watch(doseLogsBoxProvider);

    Iterable<Schedule> schedules = scheduleBox.values;
    switch (widget.scope.type) {
      case TodayDosesScopeType.all:
        break;
      case TodayDosesScopeType.medication:
        schedules = schedules.where(
          (s) => s.medicationId != null && s.medicationId == widget.scope.medicationId,
        );
      case TodayDosesScopeType.schedule:
        schedules = schedules.where((s) => s.id == widget.scope.scheduleId);
    }

    final medsById = <String, Medication>{
      for (final m in medBox.values) m.id: m,
    };

    final logsById = <String, DoseLog>{
      for (final l in logBox.values) l.id: l,
    };

    final items = _resolveTodayDoses(schedules, medsById, logsById);

    final visibleItems =
        items.where((item) {
          final id = DoseLogIds.occurrenceId(
            scheduleId: item.dose.scheduleId,
            scheduledTime: item.dose.scheduledTime,
          );
          return !_dismissedOccurrenceIds.contains(id);
        }).toList(growable: false);

    final hiddenCount = items.length - visibleItems.length;
    final hasMoreThanPreview = visibleItems.length > kHomeTodayMaxPreviewItems;
    final showScrollablePreview = hasMoreThanPreview && !_showAll;

    Widget buildDoseRow(
      BuildContext context,
      ({
        CalculatedDose dose,
        Schedule schedule,
        Medication medication,
        String strengthLabel,
        String metrics,
      }) item,
    ) {
      final occurrenceId = DoseLogIds.occurrenceId(
        scheduleId: item.dose.scheduleId,
        scheduledTime: item.dose.scheduledTime,
      );

      return Dismissible(
        key: ValueKey<String>('today_dose_$occurrenceId'),
        direction: DismissDirection.endToStart,
        background: const SizedBox.shrink(),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: kStandardCardPadding,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: kStandardBorderRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_off_rounded,
                size: kIconSizeMedium,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: kSpacingS),
              Text('Hide', style: helperTextStyle(context)),
            ],
          ),
        ),
        onDismissed: (_) {
          setState(() => _dismissedOccurrenceIds.add(occurrenceId));
          unawaited(_persistDismissed());

          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: const Text('Dose hidden'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    if (!mounted) return;
                    setState(() => _dismissedOccurrenceIds.remove(occurrenceId));
                    unawaited(_persistDismissed());
                  },
                ),
              ),
            );
        },
        child: DoseCard(
          dose: item.dose,
          medicationName: item.medication.name,
          strengthOrConcentrationLabel: item.strengthLabel,
          doseMetrics: item.metrics,
          isActive: item.schedule.isActive,
          medicationFormIcon: MedicationDisplayHelpers.medicationFormIcon(
            item.medication.form,
          ),
          doseNumber: ScheduleOccurrenceService.occurrenceNumber(
            item.schedule,
            item.dose.scheduledTime,
          ),
          onTap: () => showDoseActionSheetFromModels(
            context,
            dose: item.dose,
            schedule: item.schedule,
            medication: item.medication,
          ),
          onQuickAction: (status) => showDoseActionSheetFromModels(
            context,
            dose: item.dose,
            schedule: item.schedule,
            medication: item.medication,
            initialStatus: status,
          ),
          onPrimaryAction: () => showDoseActionSheetFromModels(
            context,
            dose: item.dose,
            schedule: item.schedule,
            medication: item.medication,
          ),
        ),
      );
    }

    return CollapsibleSectionFormCard(
      neutral: widget.neutral,
      frameless: widget.frameless,
      title: widget.title,
      isExpanded: _expanded,
      trailing: hiddenCount <= 0
          ? null
          : IconButton(
              onPressed: _restoreAllDismissed,
              tooltip: 'Restore hidden doses',
              constraints: kTightIconButtonConstraints,
              padding: kNoPadding,
              icon: const Icon(Icons.restore_rounded, size: kIconSizeMedium),
            ),
      reserveReorderHandleGutterWhenCollapsed:
          widget.reserveReorderHandleGutterWhenCollapsed,
      onExpandedChanged: _setExpanded,
      children: [
        if (items.isEmpty)
          const UnifiedEmptyState(title: 'No upcoming doses')
        else if (visibleItems.isEmpty)
          const UnifiedEmptyState(title: 'All doses hidden')
        else if (!hasMoreThanPreview)
          for (final item in visibleItems) ...[
            buildDoseRow(context, item),
            const SizedBox(height: kSpacingS),
          ]
        else ...[
          buildHelperText(
            context,
            'Tip: swipe left on a dose to hide it.',
            fullWidth: true,
          ),
          const SizedBox(height: kSpacingS),
          if (showScrollablePreview)
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: kHomeTodayDosePreviewListMaxHeight,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  padding: kNoPadding,
                  itemCount: visibleItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: kSpacingS),
                  itemBuilder: (context, i) =>
                      buildDoseRow(context, visibleItems[i]),
                ),
              ),
            )
          else
            for (final item in visibleItems) ...[
              buildDoseRow(context, item),
              const SizedBox(height: kSpacingS),
            ],
          if (showScrollablePreview) const MoreContentIndicator(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() => _showAll = !_showAll);
              },
              child: Text(_showAll ? 'Show less' : 'Show all'),
            ),
          ),
        ],
      ],
    );
  }
}
