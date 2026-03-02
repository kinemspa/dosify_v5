import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dosifi_v5/src/core/clock.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_providers.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log_ids.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_providers.dart';
import 'package:dosifi_v5/src/widgets/dose_card.dart';
import 'package:dosifi_v5/src/widgets/dose_card_meta_lines.dart';
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
    this.title = 'Today',
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
  bool _internalExpanded = true;
  bool _showAll = false;

  Widget _buildStatCell(
    BuildContext context, {
    required String label,
    required int count,
  }) {
    final cs = Theme.of(context).colorScheme;
    final base = helperTextStyle(context) ?? const TextStyle();
    final countStyle = base.copyWith(
      fontSize: kFontSizeMedium,
      fontWeight: kFontWeightBold,
      color: cs.primary,
      height: 1.0,
    );
    final labelStyle = base.copyWith(
      fontSize: kFontSizeCaption,
      color: cs.onSurfaceVariant,
      height: 1.0,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$count', style: countStyle),
        const SizedBox(height: 1),
        Text(label, style: labelStyle),
      ],
    );
  }

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

  List<
    ({
      CalculatedDose dose,
      Schedule schedule,
      Medication medication,
      String strengthLabel,
      String metrics,
    })
  >
  _resolveTodayDoses(
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
      final metrics = schedule.displayMetrics(med);

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
          (s) =>
              s.medicationId != null &&
              s.medicationId == widget.scope.medicationId,
        );
      case TodayDosesScopeType.schedule:
        schedules = schedules.where((s) => s.id == widget.scope.scheduleId);
    }

    final medsById = <String, Medication>{
      for (final m in medBox.values) m.id: m,
    };

    final logsById = <String, DoseLog>{for (final l in logBox.values) l.id: l};

    final items = _resolveTodayDoses(schedules, medsById, logsById);

    final hasMoreThanPreview = items.length > kHomeTodayMaxPreviewItems;
    final previewItems = _showAll
        ? items
        : items.take(kHomeTodayMaxPreviewItems).toList(growable: false);

    final scheduledCount = items.length;
    final upcomingCount = items
        .where(
          (i) =>
              i.dose.status == DoseStatus.pending ||
              i.dose.status == DoseStatus.due,
        )
        .length;
    final missedCount = items
        .where((i) => i.dose.status == DoseStatus.overdue)
        .length;
    final snoozedCount = items
        .where((i) => i.dose.status == DoseStatus.snoozed)
        .length;
    final takenCount = items
        .where((i) => i.dose.status == DoseStatus.logged)
        .length;
    final skippedCount = items
        .where((i) => i.dose.status == DoseStatus.skipped)
        .length;

    Widget buildDoseRow(
      BuildContext context,
      ({
        CalculatedDose dose,
        Schedule schedule,
        Medication medication,
        String strengthLabel,
        String metrics,
      })
      item,
    ) {
      return DoseCard(
        dose: item.dose,
        medicationName: item.medication.name,
        strengthOrConcentrationLabel: item.strengthLabel,
        doseMetrics: item.metrics,
        isActive: item.schedule.isActive,
        medicationFormIcon: MedicationDisplayHelpers.medicationFormIcon(
          item.medication.form,
        ),
        detailLines: buildDoseCardInventoryMetaLines(
          context,
          medication: item.medication,
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
      );
    }

    return CollapsibleSectionFormCard(
      neutral: widget.neutral,
      frameless: widget.frameless,
      title: widget.title,
      isExpanded: _expanded,
      reserveReorderHandleGutterWhenCollapsed:
          widget.reserveReorderHandleGutterWhenCollapsed,
      onExpandedChanged: _setExpanded,
      // No horizontal inset — dose cards fill the full card width, matching
      // the calendar stage layout. Stat row + button add their own padding.
      contentPadding: const EdgeInsets.only(bottom: kSpacingM),
      children: [
        if (items.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: kSpacingS,
                runSpacing: kSpacingXS,
                children: [
                  _buildStatCell(context, label: 'Scheduled', count: scheduledCount),
                  _buildStatCell(context, label: 'Upcoming',  count: upcomingCount),
                  _buildStatCell(context, label: 'Logged',    count: takenCount),
                  if (missedCount > 0)
                    _buildStatCell(context, label: 'Missed',  count: missedCount),
                  if (snoozedCount > 0)
                    _buildStatCell(context, label: 'Snoozed', count: snoozedCount),
                  if (skippedCount > 0)
                    _buildStatCell(context, label: 'Skipped', count: skippedCount),
                ],
              ),
            ),
          ),
          const SizedBox(height: kSpacingXS),
        ],
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: kSpacingM),
            child: UnifiedEmptyState(title: 'No upcoming doses'),
          )
        else ...[
          for (final item in previewItems) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
              child: buildDoseRow(context, item),
            ),
            const SizedBox(height: kSpacingS),
          ],
          if (hasMoreThanPreview)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: kTightTextButtonPadding,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    setState(() => _showAll = !_showAll);
                  },
                  icon: Icon(
                    _showAll
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: kIconSizeLarge,
                  ),
                  label: Text(_showAll ? 'Show less' : 'Show all'),
                ),
              ),
            ),
        ],
      ],
    );
  }
}