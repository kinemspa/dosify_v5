// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/glass_card_surface.dart';

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
            _SchedFilter.activeOnly => items.where((s) => s.active).toList(),
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
            return Column(
              children: [
                _buildToolbar(context),
                const Expanded(
                  child: Center(child: Text('No schedules match your query')),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/schedules/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          if (_searchExpanded)
            Expanded(
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search schedules',
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
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
              icon: Icon(Icons.search, color: Colors.grey.shade400),
              onPressed: () => setState(() => _searchExpanded = true),
              tooltip: 'Search schedules',
            ),
          if (_searchExpanded) const SizedBox(width: 8),
          if (_searchExpanded)
            IconButton(
              icon: Icon(_viewIcon(_view), color: Colors.grey.shade400),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),
          if (!_searchExpanded) const Spacer(),
          if (!_searchExpanded)
            IconButton(
              icon: Icon(_viewIcon(_view), color: Colors.grey.shade400),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),
          if (!_searchExpanded) const SizedBox(width: 8),
          if (!_searchExpanded)
            PopupMenuButton<_SchedFilter>(
              icon: Icon(
                Icons.filter_list,
                color: _filter != _SchedFilter.all
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade400,
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
              icon: Icon(Icons.sort, color: Colors.grey.shade400),
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
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) => _ScheduleTile(s: items[i]),
        );
      case _SchedView.compact:
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _ScheduleCard(s: items[i], dense: true),
        );
      case _SchedView.large:
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _ScheduleCard(s: items[i], dense: false),
        );
    }
  }

  DateTime? _nextOccurrence(Schedule s) {
    final now = DateTime.now();
    final times = s.timesOfDay ?? [s.minutesOfDay];
    for (var d = 0; d < 60; d++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: d));
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
          if (dt.isAfter(now)) return dt;
        }
      }
    }
    return null;
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.s});
  final Schedule s;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = _nextOccurrence(s);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/schedules/detail/${s.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.secondaryContainer,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.medicationName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.medication,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${s.doseValue} ${s.doseUnit}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            next == null
                                ? '—'
                                : 'Next: ${TimeOfDay.fromDateTime(next).format(context)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await _confirmDelete(context, s);
                  if (!ok) return;
                  await ScheduleScheduler.cancelFor(s.id);
                  await Hive.box<Schedule>('schedules').delete(s.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted "${s.name}"')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _nextOccurrence(Schedule s) {
    final now = DateTime.now();
    final times = s.timesOfDay ?? [s.minutesOfDay];
    for (var d = 0; d < 60; d++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: d));
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
          if (dt.isAfter(now)) return dt;
        }
      }
    }
    return null;
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.s, required this.dense});
  final Schedule s;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final next = _nextOccurrence(s);
    final last = _lastOccurrence(s);

    if (dense) {
      // Compact Card (Concept 9)
      final timeLabel = s.timesOfDay != null && s.timesOfDay!.isNotEmpty
          ? TimeOfDay(
              hour: s.timesOfDay!.first ~/ 60,
              minute: s.timesOfDay!.first % 60,
            ).format(context)
          : TimeOfDay(
              hour: s.minutesOfDay ~/ 60,
              minute: s.minutesOfDay % 60,
            ).format(context);

      return GlassCardSurface(
        onTap: () => context.push('/schedules/detail/${s.id}'),
        useGradient: false,
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
                  color: cs.primaryContainer.withOpacity(0.4),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.doseValue} ${s.doseUnit}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Action
              Center(
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.check, size: 20),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () async {
                    final ok = await _confirmTake(context, s);
                    if (!ok) return;
                    final success = await _applyStockDecrement(context, s);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marked as taken: ${s.name}')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Large Card (Existing Logic with Glass Surface)
    return GlassCardSurface(
      onTap: () => context.push('/schedules/detail/${s.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.medicationName,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            s.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: kFieldSpacing),
          Text(
            '${_doseLine(s)} · ${_timesLine(context, s)}',
            style: theme.textTheme.bodySmall,
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
                    Text(
                      next == null
                          ? 'No upcoming dose'
                          : 'Next: ${_fmtWhen(context, next)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!dense && last != null)
                      Text(
                        'Last: ${_fmtWhen(context, last)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 11,
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
                    final ok = await _confirmTake(context, s);
                    if (!ok) return;
                    final success = await _applyStockDecrement(context, s);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marked as taken: ${s.name}')),
                      );
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
                  onPressed: () => context.push('/schedules/detail/${s.id}'),
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
    final ts = s.timesOfDay ?? [s.minutesOfDay];
    final label = ts
        .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context))
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
    final time = TimeOfDay.fromDateTime(dt).format(context);
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
    final now = DateTime.now();
    final times = s.timesOfDay ?? [s.minutesOfDay];
    for (var d = 0; d < 60; d++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: d));
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
          if (dt.isAfter(now)) return dt;
        }
      }
    }
    return null;
  }

  DateTime? _lastOccurrence(Schedule s) {
    final now = DateTime.now();
    final times = s.timesOfDay ?? [s.minutesOfDay];
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
}

Future<bool> _confirmDelete(BuildContext context, Schedule s) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete schedule?'),
          content: Text(
            'Delete "${s.name}"? This will cancel its notifications.',
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
}

Future<bool> _confirmTake(BuildContext context, Schedule s) async {
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

Future<bool> _applyStockDecrement(BuildContext context, Schedule s) async {
  if (s.medicationId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This schedule is not linked to a saved medication. Edit it to link a medication first.',
        ),
      ),
    );
    return false;
  }
  final medsBox = Hive.box<Medication>('medications');
  final med = medsBox.get(s.medicationId);
  if (med == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Linked medication not found. It may have been deleted.'),
      ),
    );
    return false;
  }

  var delta = 0.0; // amount to subtract from stockValue

  switch (med.stockUnit) {
    case StockUnit.tablets:
      if (s.doseTabletQuarters != null) {
        delta = s.doseTabletQuarters! / 4.0;
      } else if (s.doseMassMcg != null) {
        // Convert mass to tablets using strength
        final perTabMcg = switch (med.strengthUnit) {
          Unit.mcg => med.strengthValue,
          Unit.mg => med.strengthValue * 1000,
          Unit.g => med.strengthValue * 1e6,
          Unit.units => med.strengthValue,
          Unit.mcgPerMl => med.strengthValue,
          Unit.mgPerMl => med.strengthValue * 1000,
          Unit.gPerMl => med.strengthValue * 1e6,
          Unit.unitsPerMl => med.strengthValue,
        };
        delta = (s.doseMassMcg! / perTabMcg).clamp(0, double.infinity);
      }
    case StockUnit.capsules:
      if (s.doseCapsules != null) {
        delta = s.doseCapsules!.toDouble();
      } else if (s.doseMassMcg != null) {
        final perCapMcg = switch (med.strengthUnit) {
          Unit.mcg => med.strengthValue,
          Unit.mg => med.strengthValue * 1000,
          Unit.g => med.strengthValue * 1e6,
          Unit.units => med.strengthValue,
          _ => med.strengthValue,
        };
        delta = (s.doseMassMcg! / perCapMcg).clamp(0, double.infinity);
      }
    case StockUnit.preFilledSyringes:
      if (s.doseSyringes != null) delta = s.doseSyringes!.toDouble();
    case StockUnit.singleDoseVials:
      if (s.doseVials != null) delta = s.doseVials!.toDouble();
    case StockUnit.multiDoseVials:
      // For MDV: activeVialVolume = active vial mL remaining
      // Deduct the raw mL volume used from active vial
      var usedMl = 0.0;
      if (s.doseVolumeMicroliter != null) {
        usedMl = s.doseVolumeMicroliter! / 1000.0;
      } else if (s.doseMassMcg != null) {
        double? mgPerMl;
        switch (med.strengthUnit) {
          case Unit.mgPerMl:
            mgPerMl = med.perMlValue ?? med.strengthValue;
          case Unit.mcgPerMl:
            mgPerMl = (med.perMlValue ?? med.strengthValue) / 1000.0;
          case Unit.gPerMl:
            mgPerMl = (med.perMlValue ?? med.strengthValue) * 1000.0;
          default:
            mgPerMl = null;
        }
        if (mgPerMl != null) usedMl = (s.doseMassMcg! / 1000.0) / mgPerMl;
      } else if (s.doseIU != null) {
        double? iuPerMl;
        if (med.strengthUnit == Unit.unitsPerMl) {
          iuPerMl = med.perMlValue ?? med.strengthValue;
        }
        if (iuPerMl != null) usedMl = s.doseIU! / iuPerMl;
      }

      if (usedMl > 0) {
        // MDV Logic: Decrement active vial first
        // Fallback to stockValue if activeVialVolume is null (legacy data)

        // CRITICAL FIX: If stockValue is larger than containerVolumeMl, it's likely a count (legacy data).
        // In that case, assume activeVialVolume is full (containerVolumeMl) and stockValue is the backup count.
        final isLegacyCount =
            med.activeVialVolume == null &&
            med.stockValue > (med.containerVolumeMl ?? 0);

        final currentActive = isLegacyCount
            ? (med.containerVolumeMl ?? 0.0)
            : (med.activeVialVolume ?? med.stockValue);

        var newActive = currentActive - usedMl;
        var newBackup = med.stockValue;

        // If we are in legacy mode (activeVialVolume was null), we need to initialize backup count.
        if (med.activeVialVolume == null) {
          if (isLegacyCount) {
            // stockValue was count, so keep it as backup count (minus 0 because we are using the "open" vial which we just assumed was full)
            // Wait, if we assume we just opened a vial from the stock, we should decrement stockValue?
            // No, if we assume the "active" vial was already open but untracked, we don't decrement backup.
            // BUT, if stockValue was 9, does that mean 9 sealed + 1 open? Or 9 total?
            // Usually stockValue is "total inventory". So if we have 9 total, and we say 1 is open, then backup is 8.
            newBackup = (med.stockValue - 1).clamp(0.0, double.infinity);
          } else {
            // stockValue was volume, so backup is 0
            newBackup = 0;
          }
        }

        if (newActive <= 0) {
          // Vial depleted, open new one if available
          if (newBackup > 0) {
            newBackup = newBackup - 1;
            // Carry over any excess usage to the new vial?
            // For now, just reset to full minus excess usage
            final capacity = med.containerVolumeMl ?? 0.0;
            newActive = capacity + newActive; // newActive is negative here

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Active vial depleted. Opened new vial.'),
                ),
              );
            }
          } else {
            newActive = 0;
          }
        }

        await medsBox.put(
          med.id,
          med.copyWith(
            activeVialVolume: newActive.clamp(0.0, double.infinity),
            stockValue: newBackup.clamp(0.0, double.infinity),
          ),
        );
        return true;
      }
      break; // Exit switch, don't use default delta logic

    case StockUnit.mcg:
      if (s.doseMassMcg != null) delta = s.doseMassMcg!.toDouble();
    case StockUnit.mg:
      if (s.doseMassMcg != null) delta = s.doseMassMcg! / 1000.0;
    case StockUnit.g:
      if (s.doseMassMcg != null) delta = s.doseMassMcg! / 1e6;
  }

  if (delta <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not compute stock decrement for this dose. Check medication strength/units.',
        ),
      ),
    );
    return false;
  }

  final newStock = (med.stockValue - delta).clamp(0.0, double.infinity);
  await medsBox.put(med.id, med.copyWith(stockValue: newStock));
  return true;
}
