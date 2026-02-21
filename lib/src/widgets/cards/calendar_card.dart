import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_header.dart';
import 'package:dosifi_v5/src/widgets/calendar/dose_calendar_widget.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

enum CalendarCardScopeType { all, medication, schedule }

class CalendarCardScope {
  const CalendarCardScope._(this.type, {this.medicationId, this.scheduleId});

  const CalendarCardScope.all() : this._(CalendarCardScopeType.all);

  const CalendarCardScope.medication(String medicationId)
    : this._(CalendarCardScopeType.medication, medicationId: medicationId);

  const CalendarCardScope.schedule(String scheduleId)
    : this._(CalendarCardScopeType.schedule, scheduleId: scheduleId);

  final CalendarCardScopeType type;
  final String? medicationId;
  final String? scheduleId;
}

class CalendarCard extends ConsumerStatefulWidget {
  const CalendarCard({
    super.key,
    required this.scope,
    this.title = 'Calendar',
    this.showOpenCalendarAction = true,
    this.isExpanded,
    this.onExpandedChanged,
    this.reserveReorderHandleGutterWhenCollapsed = false,
    this.neutral = true,
    this.frameless = true,
    this.showSelectedDayPanel = true,
    this.height,
  });

  final CalendarCardScope scope;
  final String title;

  /// When false, hides the trailing "open full calendar" action.
  final bool showOpenCalendarAction;

  /// If provided, expansion state is controlled by the parent.
  final bool? isExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  final bool reserveReorderHandleGutterWhenCollapsed;
  final bool neutral;
  final bool frameless;

  /// When false, hides the selected day dose list panel below the calendar grid.
  final bool showSelectedDayPanel;

  /// Overrides the default mini calendar height.
  final double? height;

  @override
  ConsumerState<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends ConsumerState<CalendarCard> {
  bool _internalExpanded = true;

  bool get _expanded => widget.isExpanded ?? _internalExpanded;

  void _setExpanded(bool expanded) {
    widget.onExpandedChanged?.call(expanded);
    if (widget.isExpanded != null) return;
    if (!mounted) return;
    setState(() => _internalExpanded = expanded);
  }

  @override
  Widget build(BuildContext context) {
    final scheduleId =
        widget.scope.type == CalendarCardScopeType.schedule
            ? widget.scope.scheduleId
            : null;
    final medicationId =
        widget.scope.type == CalendarCardScopeType.medication
            ? widget.scope.medicationId
            : null;

    return CollapsibleSectionFormCard(
      neutral: widget.neutral,
      frameless: widget.frameless,
      title: widget.title,
      isExpanded: _expanded,
      trailing: widget.showOpenCalendarAction
          ? IconButton(
              onPressed: () => context.pushNamed(
                'calendar',
                extra: <String, dynamic>{
                  'scheduleId': scheduleId,
                  'medicationId': medicationId,
                },
              ),
              tooltip: 'Open full calendar',
              constraints: kTightIconButtonConstraints,
              padding: kNoPadding,
              icon: const Icon(Icons.open_in_new_rounded, size: kIconSizeMedium),
            )
          : null,
      reserveReorderHandleGutterWhenCollapsed:
          widget.reserveReorderHandleGutterWhenCollapsed,
      onExpandedChanged: _setExpanded,
      children: [
        SizedBox(
          height: widget.height ?? kHomeMiniCalendarHeight,
          child: DoseCalendarWidget(
            variant: CalendarVariant.mini,
            defaultView: CalendarView.month,
            scheduleId: scheduleId,
            medicationId: medicationId,
            showSelectedDayPanel: widget.showSelectedDayPanel,
            showHeaderOverride: true,
            showViewToggleOverride: true,
            embedInParentCard: true,
          ),
        ),
      ],
    );
  }
}
