// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/providers.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/report_time_range_selector_row.dart';
import 'package:dosifi_v5/src/widgets/cards/activity_card.dart';
import 'package:dosifi_v5/src/widgets/cards/calendar_card.dart';
import 'package:dosifi_v5/src/widgets/cards/schedules_card.dart';
import 'package:dosifi_v5/src/widgets/cards/today_doses_card.dart';
import 'package:dosifi_v5/src/widgets/unified_empty_state.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();

}

class _HomePageState extends ConsumerState<HomePage> {
  static const _kCardToday = 'today';
  static const _kCardActivity = 'activity';
  static const _kCardSchedules = 'schedules';
  static const _kCardReports = 'reports';
  static const _kCardCalendar = 'calendar';

  late final List<String> _cardOrder;
  Set<String>? _reportIncludedMedicationIds;

  bool _isTodayExpanded = true;
  bool _isActivityExpanded = true;
  bool _isSchedulesExpanded = true;
  bool _isReportsExpanded = true;
  bool _isCalendarExpanded = true;

  ReportTimeRangePreset _reportsRangePreset = ReportTimeRangePreset.allTime;

  Future<void> _showIncludedMedsSelector(
    BuildContext context,
    List<Medication> meds,
  ) async {
    final selected = Set<String>.from(_reportIncludedMedicationIds ?? {});

    final updated = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: buildBottomSheetPagePadding(context),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Included meds', style: sectionTitleStyle(context)),
                    const SizedBox(height: kSpacingXS),
                    Text(
                      'Choose which medications appear in Reports.',
                      style: helperTextStyle(
                        context,
                        color: cs.onSurfaceVariant.withValues(
                          alpha: kOpacityMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: kSpacingM),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: meds.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: kSpacingXS),
                        itemBuilder: (context, i) {
                          final med = meds[i];
                          final isSelected = selected.contains(med.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (v) {
                              setModalState(() {
                                if (v ?? false) {
                                  selected.add(med.id);
                                } else {
                                  selected.remove(med.id);
                                }
                              });
                            },
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: kNoPadding,
                            title: Text(
                              med.name,
                              style: bodyTextStyle(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: kSpacingM),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: kSpacingS),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(context).pop(selected),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (updated == null) return;
    setState(() => _reportIncludedMedicationIds = updated);
  }

  @override
  void initState() {
    super.initState();
    _cardOrder = <String>[
      _kCardToday,
      _kCardActivity,
      _kCardSchedules,
      _kCardReports,
      _kCardCalendar,
    ];
    unawaited(_restoreCardOrder());
  }

  String _prefsKeyCardOrder() => 'home_card_order';

  List<String> _dedupeCardIdsPreserveOrder(Iterable<String> ids) {
    final seen = <String>{};
    final out = <String>[];
    for (final id in ids) {
      if (seen.add(id)) out.add(id);
    }
    return out;
  }

  Future<void> _restoreCardOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKeyCardOrder());
    if (stored == null || stored.isEmpty) return;

    final allowed = <String>{
      _kCardToday,
      _kCardActivity,
      _kCardSchedules,
      _kCardReports,
      _kCardCalendar,
    };
    final filtered = _dedupeCardIdsPreserveOrder(
      stored.where(allowed.contains),
    );
    for (final id in allowed) {
      if (!filtered.contains(id)) filtered.add(id);
    }

    if (!mounted) return;
    setState(() {
      _cardOrder
        ..clear()
        ..addAll(filtered);
    });
  }

  Future<void> _persistCardOrder(List<String> orderedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKeyCardOrder(),
      _dedupeCardIdsPreserveOrder(orderedIds),
    );
  }

  Widget _buildHomeCards(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Rebuild this section whenever any relevant Hive box changes.
    ref.watch(schedulesBoxChangesProvider);
    ref.watch(medicationsBoxChangesProvider);
    ref.watch(doseLogsBoxChangesProvider);

    final allCardsCollapsed =
        !_isTodayExpanded &&
      !_isActivityExpanded &&
        !_isSchedulesExpanded &&
        !_isReportsExpanded &&
        !_isCalendarExpanded;

    void showCollapseAllInstruction() {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Collapse all cards first to rearrange them.'),
            duration: Duration(seconds: 2),
          ),
        );
    }

    final todayCard = Builder(
      builder: (context) {
        return TodayDosesCard(
          scope: const TodayDosesScope.all(),
          isExpanded: _isTodayExpanded,
          onExpandedChanged: (expanded) {
            if (!mounted) return;
            setState(() => _isTodayExpanded = expanded);
          },
          reserveReorderHandleGutterWhenCollapsed: true,
        );
      },
    );

    final schedulesCard = SchedulesCard(
      scope: const SchedulesCardScope.all(),
      isExpanded: _isSchedulesExpanded,
      reserveReorderHandleGutterWhenCollapsed: true,
      onExpandedChanged: (expanded) {
        if (!mounted) return;
        setState(() => _isSchedulesExpanded = expanded);
      },
    );

    final calendarCard = CalendarCard(
      scope: const CalendarCardScope.all(),
      isExpanded: _isCalendarExpanded,
      reserveReorderHandleGutterWhenCollapsed: true,
      onExpandedChanged: (expanded) {
        if (!mounted) return;
        setState(() => _isCalendarExpanded = expanded);
      },
    );

    final activityCard = ValueListenableBuilder(
      valueListenable: Hive.box<Medication>('medications').listenable(),
      builder: (context, Box<Medication> medBox, _) {
        final meds = medBox.values.toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

        if (_reportIncludedMedicationIds == null) {
          _reportIncludedMedicationIds = meds.map((m) => m.id).toSet();
        } else {
          final currentIds = meds.map((m) => m.id).toSet();
          _reportIncludedMedicationIds = _reportIncludedMedicationIds!
              .intersection(currentIds);
          if (_reportIncludedMedicationIds!.isEmpty && currentIds.isNotEmpty) {
            _reportIncludedMedicationIds = currentIds;
          }
        }

        final included = _reportIncludedMedicationIds!;

        return ActivityCard(
          medications: meds,
          includedMedicationIds: included,
          onIncludedMedicationIdsChanged: (next) {
            if (!mounted) return;
            setState(() => _reportIncludedMedicationIds = next);
          },
          rangePreset: _reportsRangePreset,
          onRangePresetChanged: (next) {
            if (!mounted) return;
            setState(() => _reportsRangePreset = next);
          },
          isExpanded: _isActivityExpanded,
          reserveReorderHandleGutterWhenCollapsed: true,
          onExpandedChanged: (expanded) {
            if (!mounted) return;
            setState(() => _isActivityExpanded = expanded);
          },
        );
      },
    );

    final reportsCard = ValueListenableBuilder(
      valueListenable: Hive.box<Medication>('medications').listenable(),
      builder: (context, Box<Medication> medBox, _) {
        final meds = medBox.values.toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

        if (_reportIncludedMedicationIds == null) {
          _reportIncludedMedicationIds = meds.map((m) => m.id).toSet();
        } else {
          final currentIds = meds.map((m) => m.id).toSet();
          _reportIncludedMedicationIds = _reportIncludedMedicationIds!
              .intersection(currentIds);
          if (_reportIncludedMedicationIds!.isEmpty && currentIds.isNotEmpty) {
            _reportIncludedMedicationIds = currentIds;
          }
        }

        final included = _reportIncludedMedicationIds!;
        final range = ReportTimeRange(_reportsRangePreset).toUtcTimeRange();

        return ValueListenableBuilder(
          valueListenable: Hive.box<DoseLog>('dose_logs').listenable(),
          builder: (context, Box<DoseLog> logBox, _) {
            final logs = logBox.values
                .where((l) => included.contains(l.medicationId))
                .where((l) => range == null || range.contains(l.actionTime))
                .toList(growable: false);

            final taken = logs.where((l) => l.action == DoseAction.taken).length;
            final skipped =
                logs.where((l) => l.action == DoseAction.skipped).length;
            final snoozed =
                logs.where((l) => l.action == DoseAction.snoozed).length;

            return CollapsibleSectionFormCard(
              neutral: true,
              frameless: true,
              title: 'Reports',
              isExpanded: _isReportsExpanded,
              reserveReorderHandleGutterWhenCollapsed: true,
              onExpandedChanged: (expanded) {
                if (!mounted) return;
                setState(() => _isReportsExpanded = expanded);
              },
              children: [
                if (meds.isEmpty)
                  const UnifiedEmptyState(title: 'No medications')
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${included.length}/${meds.length} meds included',
                          style: helperTextStyle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: kSpacingS),
                      OutlinedButton.icon(
                        onPressed: () => _showIncludedMedsSelector(context, meds),
                        icon: const Icon(
                          Icons.tune_rounded,
                          size: kIconSizeSmall,
                        ),
                        label: const Text('Included meds'),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSpacingS),
                  ReportTimeRangeSelectorRow(
                    value: _reportsRangePreset,
                    onChanged: (next) {
                      if (!mounted) return;
                      setState(() => _reportsRangePreset = next);
                    },
                  ),
                  const SizedBox(height: kSpacingS),
                  buildDetailInfoRow(
                    context,
                    label: 'Dose logs',
                    value: logs.length.toString(),
                  ),
                  buildDetailInfoRow(
                    context,
                    label: 'Taken',
                    value: taken.toString(),
                  ),
                  buildDetailInfoRow(
                    context,
                    label: 'Skipped',
                    value: skipped.toString(),
                  ),
                  buildDetailInfoRow(
                    context,
                    label: 'Snoozed',
                    value: snoozed.toString(),
                  ),
                  const SizedBox(height: kSpacingS),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.push('/analytics'),
                      icon: const Icon(
                        Icons.bar_chart_rounded,
                        size: kIconSizeSmall,
                      ),
                      label: const Text('Open Analytics'),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );

    final cards = <String, Widget>{
      _kCardToday: todayCard,
      _kCardActivity: activityCard,
      _kCardSchedules: schedulesCard,
      _kCardReports: reportsCard,
      _kCardCalendar: calendarCard,
    };

    final orderedIds = _dedupeCardIdsPreserveOrder(
      _cardOrder.where(cards.containsKey),
    );
    for (final id in cards.keys) {
      if (!orderedIds.contains(id)) orderedIds.add(id);
    }

    final children = <Widget>[
      for (final entry in orderedIds.asMap().entries)
        Column(
          key: ValueKey<String>('home_card_${entry.value}'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                cards[entry.value]!,
                if (!(entry.value == _kCardToday && _isTodayExpanded) &&
                    !(entry.value == _kCardActivity && _isActivityExpanded) &&
                    !(entry.value == _kCardSchedules && _isSchedulesExpanded) &&
                    !(entry.value == _kCardReports && _isReportsExpanded) &&
                    !(entry.value == _kCardCalendar && _isCalendarExpanded))
                  Positioned(
                    left: kSpacingS,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: allCardsCollapsed
                          ? ReorderableDelayedDragStartListener(
                              index: entry.key,
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                size: kIconSizeMedium,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: kOpacityMedium,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onLongPress: showCollapseAllInstruction,
                              onTap: showCollapseAllInstruction,
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                size: kIconSizeMedium,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: kOpacityMedium,
                                ),
                              ),
                            ),
                    ),
                  ),
              ],
            ),
            if (entry.key != orderedIds.length - 1)
              const SizedBox(height: kSpacingL),
          ],
        ),
    ];

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final moved = orderedIds.removeAt(oldIndex);
          orderedIds.insert(newIndex, moved);
          _cardOrder
            ..clear()
            ..addAll(orderedIds);
        });
        unawaited(_persistCardOrder(orderedIds));
      },
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Home'),
      // Logo moved to body header to avoid duplicate appBar
      body: Padding(
        padding: kPagePaddingNoBottom,
        child: ListView(
          children: [
            Text(
              'Upcoming doses, schedules, and calendar',
              style: helperTextStyle(context),
            ),
            const SizedBox(height: kSpacingL),
            _buildHomeCards(context),
            const SizedBox(height: kSpacingXL),
          ],
        ),
      ),
    );
  }
}
