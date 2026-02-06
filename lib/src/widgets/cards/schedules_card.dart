import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/providers.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/schedule_list_card.dart';
import 'package:dosifi_v5/src/widgets/unified_empty_state.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

enum SchedulesCardScopeType { all, medication, schedule }

class SchedulesCardScope {
  const SchedulesCardScope._(this.type, {this.medicationId, this.scheduleId});

  const SchedulesCardScope.all() : this._(SchedulesCardScopeType.all);

  const SchedulesCardScope.medication(String medicationId)
    : this._(SchedulesCardScopeType.medication, medicationId: medicationId);

  const SchedulesCardScope.schedule(String scheduleId)
    : this._(SchedulesCardScopeType.schedule, scheduleId: scheduleId);

  final SchedulesCardScopeType type;
  final String? medicationId;
  final String? scheduleId;
}

class SchedulesCard extends ConsumerStatefulWidget {
  const SchedulesCard({
    super.key,
    required this.scope,
    this.title = 'Schedules',
    this.isExpanded,
    this.onExpandedChanged,
    this.reserveReorderHandleGutterWhenCollapsed = false,
    this.neutral = true,
    this.frameless = true,
  });

  final SchedulesCardScope scope;
  final String title;

  /// If provided, expansion state is controlled by the parent.
  final bool? isExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  final bool reserveReorderHandleGutterWhenCollapsed;
  final bool neutral;
  final bool frameless;

  @override
  ConsumerState<SchedulesCard> createState() => _SchedulesCardState();
}

class _SchedulesCardState extends ConsumerState<SchedulesCard> {
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
    // Rebuild whenever schedules change.
    ref.watch(schedulesBoxChangesProvider);
    final scheduleBox = ref.watch(schedulesBoxProvider);

    final schedules = scheduleBox.values.where((s) {
      switch (widget.scope.type) {
        case SchedulesCardScopeType.all:
          return s.medicationId != null && (s.isActive || s.isPaused);
        case SchedulesCardScopeType.medication:
          return s.medicationId == widget.scope.medicationId &&
              (s.isActive || s.isPaused);
        case SchedulesCardScopeType.schedule:
          return s.id == widget.scope.scheduleId;
      }
    }).toList();

    schedules.sort((a, b) {
      final an = ScheduleOccurrenceService.nextOccurrence(a) ?? DateTime(9999);
      final bn = ScheduleOccurrenceService.nextOccurrence(b) ?? DateTime(9999);
      return an.compareTo(bn);
    });

    return CollapsibleSectionFormCard(
      neutral: widget.neutral,
      frameless: widget.frameless,
      title: widget.title,
      isExpanded: _expanded,
      reserveReorderHandleGutterWhenCollapsed:
          widget.reserveReorderHandleGutterWhenCollapsed,
      onExpandedChanged: _setExpanded,
      children: [
        if (schedules.isEmpty)
          const UnifiedEmptyState(title: 'No schedules')
        else
          for (final schedule in schedules) ...[
            ScheduleListCard(schedule: schedule, dense: true),
            const SizedBox(height: kSpacingS),
          ],
      ],
    );
  }
}
