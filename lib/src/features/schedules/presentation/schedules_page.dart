import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

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
            _SchedFilter.linkedOnly => items.where((s) => s.medicationId != null).toList(),
          };
          // Search
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            items = items.where((s) => s.name.toLowerCase().contains(q) || s.medicationName.toLowerCase().contains(q)).toList();
          }
          // Sort
          items.sort((a, b) {
            switch (_sort) {
              case _SchedSort.name:
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              case _SchedSort.med:
                return a.medicationName.toLowerCase().compareTo(b.medicationName.toLowerCase());
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
                const Expanded(child: Center(child: Text('No schedules match your query'))),
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
                color: _filter != _SchedFilter.all ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
              ),
              tooltip: 'Filter schedules',
              onSelected: (f) => setState(() => _filter = f),
              itemBuilder: (context) => const [
                PopupMenuItem(value: _SchedFilter.all, child: Text('All schedules')),
                PopupMenuItem(value: _SchedFilter.activeOnly, child: Text('Active only')),
                PopupMenuItem(value: _SchedFilter.linkedOnly, child: Text('Linked to medication')),
              ],
            ),
          if (!_searchExpanded)
            PopupMenuButton<_SchedSort>(
              icon: Icon(Icons.sort, color: Colors.grey.shade400),
              tooltip: 'Sort schedules',
              onSelected: (s) => setState(() => _sort = s),
              itemBuilder: (context) => const [
                PopupMenuItem(value: _SchedSort.next, child: Text('Sort by next time')),
                PopupMenuItem(value: _SchedSort.name, child: Text('Sort by name')),
                PopupMenuItem(value: _SchedSort.med, child: Text('Sort by medication')),
                PopupMenuItem(value: _SchedSort.created, child: Text('Sort by created')),
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
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
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
    for (int d = 0; d < 60; d++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: d));
      final onDay = s.hasCycle && s.cycleEveryNDays != null && s.cycleEveryNDays! > 0
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
          final dt = DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
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
    final subtitle = next == null
        ? '${s.medicationName} • ${s.doseValue} ${s.doseUnit}'
        : '${s.medicationName} • ${s.doseValue} ${s.doseUnit} • Next: ${TimeOfDay.fromDateTime(next).format(context)}';
    return ListTile(
      title: Text(s.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          final ok = await _confirmDelete(context, s);
          if (!ok) return;
          await ScheduleScheduler.cancelFor(s.id);
          await Hive.box<Schedule>('schedules').delete(s.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${s.name}"')));
          }
        },
      ),
      onTap: () => context.push('/schedules/edit/${s.id}'),
    );
  }

  DateTime? _nextOccurrence(Schedule s) {
    final now = DateTime.now();
    final times = s.timesOfDay ?? [s.minutesOfDay];
    for (int d = 0; d < 60; d++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: d));
      final onDay = s.hasCycle && s.cycleEveryNDays != null && s.cycleEveryNDays! > 0
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
          final dt = DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
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
    final next = _nextOccurrence(s);
    final last = _lastOccurrence(s);
    return Card(
      elevation: dense ? 1 : 2,
      child: InkWell(
        onTap: () => context.push('/schedules/edit/${s.id}'),
        child: Stack(
          children: [
            Padding(
              padding: dense ? const EdgeInsets.all(6) : const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: dense ? 24 : 36,
                    height: dense ? 24 : 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [theme.colorScheme.secondaryContainer, theme.colorScheme.secondary]),
                      borderRadius: BorderRadius.circular(dense ? 8 : 12),
                    ),
                    child: const Icon(Icons.alarm, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: dense ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600) : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${s.medicationName} • ${_doseLine(s)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await _confirmDelete(context, s);
                      if (!ok) return;
                      await ScheduleScheduler.cancelFor(s.id);
                      await Hive.box<Schedule>('schedules').delete(s.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${s.name}"')));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _timesLine(context, s),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Last: ${last == null ? '—' : _fmtWhen(context, last)}  •  Next: ${next == null ? '—' : _fmtWhen(context, next)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!dense) const SizedBox(height: 6),
              if (!dense)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final ok = await _confirmTake(context, s);
                      if (!ok) return;
                      final success = await _applyStockDecrement(context, s);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked as taken: ${s.name}')));
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Take'),
                  ),
                ),
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }

  String _doseLine(Schedule s) {
    final v = s.doseValue;
    final vf = (v == v.roundToDouble()) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return '$vf ${s.doseUnit}';
  }

  String _timesLine(BuildContext context, Schedule s) {
    final ts = s.timesOfDay ?? [s.minutesOfDay];
    final label = ts.map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context)).join(', ');
    if (s.hasCycle && s.cycleEveryNDays != null) {
      final n = s.cycleEveryNDays!;
      return 'Every $n day${n == 1 ? '' : 's'} at $label';
    }
    const dlabels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final ds = s.daysOfWeek.toList()..sort();
    final dtext = ds.map((i) => dlabels[i - 1]).join(', ');
    return '$dtext at $label';
  }

  String _fmtWhen(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final time = TimeOfDay.fromDateTime(dt).format(context);
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) return 'Today $time';
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;
    if (isTomorrow) return 'Tomorrow $time';
    return '${dt.day}/${dt.month} $time';
  }

  DateTime? _nextOccurrence(Schedule s) {
    final now = DateTime.now();
    final times = s.timesOfDay ?? [s.minutesOfDay];
    for (int d = 0; d < 60; d++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: d));
      final onDay = s.hasCycle && s.cycleEveryNDays != null && s.cycleEveryNDays! > 0
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
          final dt = DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
          if (dt.isAfter(now)) return dt;
        }
      }
    }
    return null;
  }

  DateTime? _lastOccurrence(Schedule s) {
    final now = DateTime.now();
    final times = s.timesOfDay ?? [s.minutesOfDay];
    for (int d = 0; d < 60; d++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: d));
      final onDay = s.hasCycle && s.cycleEveryNDays != null && s.cycleEveryNDays! > 0
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
          final dt = DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
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
          content: Text('Delete "${s.name}"? This will cancel its notifications.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
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
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Mark taken')),
          ],
        ),
      ) ??
      false;
}

Future<bool> _applyStockDecrement(BuildContext context, Schedule s) async {
  if (s.medicationId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This schedule is not linked to a saved medication. Edit it to link a medication first.')),
    );
    return false;
  }
  final medsBox = Hive.box<Medication>('medications');
  final med = medsBox.get(s.medicationId!);
  if (med == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Linked medication not found. It may have been deleted.')),
    );
    return false;
  }

  double delta = 0.0; // amount to subtract from stockValue

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
      break;
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
      break;
    case StockUnit.preFilledSyringes:
      if (s.doseSyringes != null) delta = s.doseSyringes!.toDouble();
      break;
    case StockUnit.singleDoseVials:
      if (s.doseVials != null) delta = s.doseVials!.toDouble();
      break;
    case StockUnit.multiDoseVials:
      // Subtract as a fraction of a vial based on volume vs containerVolumeMl if we know volume
      final containerMl = med.containerVolumeMl ?? 0;
      double usedMl = 0.0;
      if (s.doseVolumeMicroliter != null) {
        usedMl = s.doseVolumeMicroliter! / 1000.0;
      } else if (s.doseMassMcg != null) {
        double? mgPerMl;
        switch (med.strengthUnit) {
          case Unit.mgPerMl:
            mgPerMl = med.perMlValue ?? med.strengthValue;
            break;
          case Unit.mcgPerMl:
            mgPerMl = (med.perMlValue ?? med.strengthValue) / 1000.0;
            break;
          case Unit.gPerMl:
            mgPerMl = (med.perMlValue ?? med.strengthValue) * 1000.0;
            break;
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
      if (containerMl > 0 && usedMl > 0) {
        delta = usedMl / containerMl; // subtract fractional vial
      }
      break;
    case StockUnit.mcg:
      if (s.doseMassMcg != null) delta = s.doseMassMcg!.toDouble();
      break;
    case StockUnit.mg:
      if (s.doseMassMcg != null) delta = s.doseMassMcg! / 1000.0;
      break;
    case StockUnit.g:
      if (s.doseMassMcg != null) delta = s.doseMassMcg! / 1e6;
      break;
  }

  if (delta <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not compute stock decrement for this dose. Check medication strength/units.')),
    );
    return false;
  }

  final newStock = (med.stockValue - delta).clamp(0.0, double.infinity) as double;
  await medsBox.put(med.id, med.copyWith(stockValue: newStock));
  return true;
}

