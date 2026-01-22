// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_instruction_text.dart';
import 'package:dosifi_v5/src/widgets/next_dose_date_badge.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/glass_card_surface.dart';
import 'package:dosifi_v5/src/widgets/large_card.dart';
import 'package:dosifi_v5/src/widgets/schedule_status_chip.dart';

enum _SchedView { list, compact, large }

enum _SchedSort { next, name, med, created }

enum _SchedFilter { all, activeOnly, linkedOnly }

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});
  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  _SchedView _view = _SchedView.large;
  _SchedSort _sort = _SchedSort.next;
  _SchedFilter _filter = _SchedFilter.all;
  String _query = '';
  bool _searchExpanded = false;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Schedule>('schedules');
    return Scaffold(
      appBar: const GradientAppBar(title: 'Schedules', forceBackButton: true),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Schedule> b, _) {
          var items = b.values.toList(growable: false);
          // Filter
          items = switch (_filter) {
            _SchedFilter.all => items,
            _SchedFilter.activeOnly => items.where((s) => s.isActive).toList(),
            _SchedFilter.linkedOnly =>
              items.where((s) => s.medicationId != null).toList(),
          };
          // Search
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            items = items
                .where(
                  (s) =>
                      s.name.toLowerCase().contains(q) ||
                      s.medicationName.toLowerCase().contains(q),
                )
                .toList();
          }
          // Sort
          items.sort((a, b) {
            switch (_sort) {
              case _SchedSort.name:
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              case _SchedSort.med:
                return a.medicationName.toLowerCase().compareTo(
                  b.medicationName.toLowerCase(),
                );
              case _SchedSort.created:
                return a.createdAt.compareTo(b.createdAt);
              case _SchedSort.next:
                final an = _nextOccurrence(a) ?? DateTime(9999);
                final bn = _nextOccurrence(b) ?? DateTime(9999);
                return an.compareTo(bn);
            }
          });

          if (items.isEmpty) {
            if (_query.isEmpty && b.values.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: kEmptyStateIconSize,
                      color: Theme.of(context).colorScheme.onSurfaceVariant
                          .withValues(alpha: kOpacityMedium),
                    ),
                    const SizedBox(height: kSpacingM),
                    Text(
                      'Add a schedule to begin tracking',
                      style: mutedTextStyle(context),
                    ),
                    const SizedBox(height: kSpacingM),
                    FilledButton(
                      onPressed: () => context.push('/schedules/add'),
                      child: const Text('Add Schedule'),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                _buildToolbar(context),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: kEmptyStateIconSize,
                          color: Theme.of(context).colorScheme.onSurfaceVariant
                              .withValues(alpha: kOpacityMedium),
                        ),
                        const SizedBox(height: kSpacingM),
                        Text(
                          'No schedules found for "$_query"',
                          style: mutedTextStyle(context),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {
                            _query = '';
                            _searchExpanded = false;
                          }),
                          child: const Text('Clear search'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildToolbar(context),
              Expanded(child: _buildView(context, items)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/schedules/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Schedule'),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = cs.onSurfaceVariant.withValues(alpha: kOpacityMedium);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kPageHorizontalPadding,
        kSpacingXS,
        kSpacingXS,
        kSpacingXS,
      ),
      child: Row(
        children: [
          if (_searchExpanded)
            Expanded(
              child: TextField(
                autofocus: true,
                textCapitalization: kTextCapitalizationDefault,
                decoration: buildFieldDecoration(
                  context,
                  hint: 'Search schedules',
                  prefixIcon: Icon(
                    Icons.search,
                    size: kIconSizeMedium,
                    color: iconColor,
                  ),
                  suffixIcon: IconButton(
                    iconSize: kIconSizeMedium,
                    icon: Icon(Icons.close, color: iconColor),
                    onPressed: () => setState(() {
                      _searchExpanded = false;
                      _query = '';
                    }),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.search, color: iconColor),
              onPressed: () => setState(() => _searchExpanded = true),
              tooltip: 'Search schedules',
            ),
          if (_searchExpanded) const SizedBox(width: kSpacingS),
          if (_searchExpanded)
            IconButton(
              icon: Icon(_viewIcon(_view), color: iconColor),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),
          if (!_searchExpanded) const Spacer(),
          if (!_searchExpanded)
            IconButton(
              icon: Icon(_viewIcon(_view), color: iconColor),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),
          if (!_searchExpanded) const SizedBox(width: kSpacingS),
          if (!_searchExpanded)
            PopupMenuButton<_SchedFilter>(
              icon: Icon(
                Icons.filter_list,
                color: _filter != _SchedFilter.all ? cs.primary : iconColor,
              ),
              tooltip: 'Filter schedules',
              onSelected: (f) => setState(() => _filter = f),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _SchedFilter.all,
                  child: Text('All schedules'),
                ),
                PopupMenuItem(
                  value: _SchedFilter.activeOnly,
                  child: Text('Active only'),
                ),
                PopupMenuItem(
                  value: _SchedFilter.linkedOnly,
                  child: Text('Linked to medication'),
                ),
              ],
            ),
          if (!_searchExpanded)
            PopupMenuButton<_SchedSort>(
              icon: Icon(Icons.sort, color: iconColor),
              tooltip: 'Sort schedules',
              onSelected: (s) => setState(() => _sort = s),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _SchedSort.next,
                  child: Text('Sort by next time'),
                ),
                PopupMenuItem(
                  value: _SchedSort.name,
                  child: Text('Sort by name'),
                ),
                PopupMenuItem(
                  value: _SchedSort.med,
                  child: Text('Sort by medication'),
                ),
                PopupMenuItem(
                  value: _SchedSort.created,
                  child: Text('Sort by created'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _viewIcon(_SchedView v) => switch (v) {
    _SchedView.list => Icons.view_list,
    _SchedView.compact => Icons.view_comfy_alt,
    _SchedView.large => Icons.view_comfortable,
  };

  Future<void> _cycleView() async {
    final order = [_SchedView.large, _SchedView.compact, _SchedView.list];
    final idx = order.indexOf(_view);
    setState(() => _view = order[(idx + 1) % order.length]);
  }

  Widget _buildView(BuildContext context, List<Schedule> items) {
    switch (_view) {
      case _SchedView.list:
        return ListView.separated(
          padding: const EdgeInsets.all(kPageHorizontalPadding),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: kSpacingS),
          itemBuilder: (context, i) => _ScheduleListRow(s: items[i]),
        );
      case _SchedView.compact:
        return ListView.separated(
          padding: const EdgeInsets.all(kPageHorizontalPadding),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: kSpacingS),
          itemBuilder: (context, i) => _ScheduleCard(s: items[i], dense: true),
        );
      case _SchedView.large:
        return ListView.separated(
          padding: const EdgeInsets.all(kPageHorizontalPadding),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: kSpacingM),
          itemBuilder: (context, i) => _ScheduleCard(s: items[i], dense: false),
        );
    }
  }

  DateTime? _nextOccurrence(Schedule s) {
    return ScheduleOccurrenceService.nextOccurrence(s);
  }
}

class _ScheduleListRow extends StatelessWidget {
  const _ScheduleListRow({required this.s});

  final Schedule s;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final next = ScheduleOccurrenceService.nextOccurrence(s);

    final cadence = _ScheduleText.cadenceLabel(s);
    final timesPerDay = _ScheduleText.timesPerDayLabel(s);
    final detailLabel = '$cadence · $timesPerDay';
    final medTitle = _ScheduleText.medTitle(s);
    final scheduleSubtitle = _ScheduleText.scheduleSubtitle(s);

    return GlassCardSurface(
      onTap: () =>
          context.pushNamed('scheduleDetail', pathParameters: {'id': s.id}),
      useGradient: false,
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingS,
        vertical: kSpacingXS,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  medTitle,
                  style: cardTitleStyle(
                    context,
                  )?.copyWith(fontWeight: FontWeight.w800, color: cs.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: kSpacingXS),
                Text(
                  scheduleSubtitle ?? detailLabel,
                  style: helperTextStyle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: kSpacingS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _ScheduleText.nextDayLabel(context, next),
                style: helperTextStyle(
                  context,
                  color: s.isActive && next != null
                      ? cs.primary
                      : cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
                )?.copyWith(fontWeight: kFontWeightSemiBold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kSpacingXS),
              ScheduleStatusChip(schedule: s, dense: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.s, required this.dense});
  final Schedule s;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final next = ScheduleOccurrenceService.nextOccurrence(s);
    final medTitle = _ScheduleText.medTitle(s);
    final scheduleSubtitle = _ScheduleText.scheduleSubtitle(s);
    final startedLabel = _ScheduleText.startedLabel(s);
    final endLabel = _ScheduleText.endLabel(s);

    if (dense) {
      final medName = s.medicationName.trim();
      final scheduleName = s.name.trim();
      final showScheduleName = medName.isNotEmpty && scheduleName.isNotEmpty;

      return GlassCardSurface(
        onTap: () =>
            context.pushNamed('scheduleDetail', pathParameters: {'id': s.id}),
        useGradient: false,
        padding: kCompactCardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    medTitle,
                    style: cardTitleStyle(
                      context,
                    )?.copyWith(fontWeight: FontWeight.w800, color: cs.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showScheduleName) ...[
                    const SizedBox(height: kSpacingXXS),
                    Text(
                      scheduleName,
                      style: bodyTextStyle(
                        context,
                      )?.copyWith(fontWeight: kFontWeightSemiBold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: kSpacingXS),
                  Text(
                    scheduleDoseSummaryLabel(s),
                    style: helperTextStyle(
                      context,
                    )?.copyWith(fontSize: kFontSizeXSmall),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpacingS),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                NextDoseDateBadge(
                  nextDose: next,
                  isActive: s.isActive,
                  dense: true,
                  showNextLabel: true,
                ),
                const SizedBox(height: kSpacingXS),
                SizedBox(
                  width: kNextDoseDateCircleSizeCompact,
                  child: Center(
                    child: ScheduleStatusChip(schedule: s, dense: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return LargeCard(
      onTap: () =>
          context.pushNamed('scheduleDetail', pathParameters: {'id': s.id}),
      dense: true,
      leading: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            medTitle,
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: FontWeight.w800, color: cs.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (scheduleSubtitle != null) ...[
            const SizedBox(height: kSpacingXS),
            Text(
              scheduleSubtitle,
              style: bodyTextStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightSemiBold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: kSpacingXS),
          Text(
            scheduleTakeInstructionLabel(context, s),
            style: helperTextStyle(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: kSpacingXS),
          Row(
            children: [
              Expanded(
                child: Text(
                  startedLabel,
                  style: helperTextStyle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: kSpacingS),
              Expanded(
                child: Text(
                  endLabel,
                  style: helperTextStyle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: kSpacingXS),
            child: NextDoseDateBadge(
              nextDose: next,
              isActive: s.isActive,
              dense: false,
              showNextLabel: true,
              nextLabelStyle: NextDoseBadgeLabelStyle.tall,
            ),
          ),
          const SizedBox(height: kSpacingXS),
          Align(
            alignment: Alignment.center,
            child: ScheduleStatusChip(schedule: s, dense: true),
          ),
        ],
      ),
    );
  }
}

class _ScheduleText {
  static String medTitle(Schedule s) {
    final med = s.medicationName.trim();
    final name = s.name.trim();
    return med.isNotEmpty ? med : name;
  }

  static String startedLabel(Schedule s) {
    final start = s.startAt;
    if (start == null) return 'Start Date: —';
    return 'Start Date: ${DateFormat('d MMM').format(start)}';
  }

  static String endLabel(Schedule s) {
    final end = s.endAt;
    if (end == null) return 'End Date: No end';
    return 'End Date: ${DateFormat('d MMM').format(end)}';
  }

  static String? scheduleSubtitle(Schedule s) {
    final med = s.medicationName.trim();
    final name = s.name.trim();
    if (med.isEmpty) return null;
    if (name.isEmpty) return null;
    return name;
  }

  static String cadenceLabel(Schedule s) {
    if (s.hasCycle && s.cycleEveryNDays != null && s.cycleEveryNDays! > 0) {
      final n = s.cycleEveryNDays!;
      return 'Every $n day${n == 1 ? '' : 's'}';
    }

    const dlabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final ds = s.daysOfWeek.toList()..sort();
    if (ds.length == 7) return 'Daily';
    return ds.map((i) => dlabels[i - 1]).join(', ');
  }

  static String timesPerDayLabel(Schedule s) {
    final times = s.timesOfDay ?? [s.minutesOfDay];
    final count = times.isEmpty ? 1 : times.length;
    return '$count×/day';
  }

  static String nextDayLabel(BuildContext context, DateTime? dt) {
    if (dt == null) return 'No upcoming';
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) return 'Today';
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow =
        dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;
    if (isTomorrow) return 'Tomorrow';
    return '${dt.day}/${dt.month}';
  }
}
