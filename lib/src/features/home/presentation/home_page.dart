// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/widgets/ads/anchored_ad_banner.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/cards/activity_card.dart';
import 'package:dosifi_v5/src/widgets/cards/calendar_card.dart';
import 'package:dosifi_v5/src/widgets/cards/today_doses_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _kCardToday = 'today';
  static const _kCardActivity = 'activity';
  static const _kCardCalendar = 'calendar';

  late final List<String> _cardOrder;
  Set<String>? _reportIncludedMedicationIds;

  bool _isTodayExpanded = true;
  bool _isActivityExpanded = true;
  bool _isCalendarExpanded = true;

  ReportTimeRangePreset _reportsRangePreset = ReportTimeRangePreset.allTime;

  @override
  void initState() {
    super.initState();
    _cardOrder = <String>[_kCardToday, _kCardActivity, _kCardCalendar];
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

    final allowed = <String>{_kCardToday, _kCardActivity, _kCardCalendar};
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

    // NOTE: Child cards (TodayDosesCard, CalendarCard, ActivityCard) each
    // watch their own Hive box-change providers independently.  Watching
    // them *again* here caused a cascading rebuild storm (6-10× per Hive
    // write) that overwhelmed the emulator.  Removed to prevent that.

    final allCardsCollapsed =
        !_isTodayExpanded && !_isActivityExpanded && !_isCalendarExpanded;

    void showCollapseAllInstruction() {
      showAppSnackBar(
        context,
        'Collapse all cards first to rearrange them.',
        duration: kAppSnackBarDurationShort,
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

    final calendarCard = CalendarCard(
      scope: const CalendarCardScope.all(),
      isExpanded: _isCalendarExpanded,
      showOpenCalendarAction: false,
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

    final cards = <String, Widget>{
      _kCardToday: todayCard,
      _kCardActivity: activityCard,
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
              Divider(
                height: kSpacingL,
                thickness: kBorderWidthThin,
                indent: kSpacingS,
                endIndent: kSpacingS,
                color: cs.outlineVariant.withValues(alpha: kOpacityMinimal),
              ),
          ],
        ),
    ];

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
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
          clipBehavior: Clip.none,
          children: [
            Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: homeHeroTitleStyle(context),
            ),
            const SizedBox(height: kSpacingXS),
            Text(
              'Today is ${DateTimeFormatter.formatWeekdayName(DateTime.now())}, ${DateTimeFormatter.formatDateLong(DateTime.now())}',
              textAlign: TextAlign.center,
              style: helperTextStyle(context),
            ),
            const SizedBox(height: kSpacingL),
            _buildHomeCards(context),
            const SizedBox(height: kSpacingXL),
          ],
        ),
      ),
      bottomNavigationBar: const AnchoredAdBanner(),
    );
  }
}
