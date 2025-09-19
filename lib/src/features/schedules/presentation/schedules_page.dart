import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

class SchedulesPage extends StatelessWidget {
  const SchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Schedule>('schedules');
    return Scaffold(
      appBar: const GradientAppBar(title: 'Schedules', forceBackButton: true),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Schedule> b, _) {
          final items = b.values.where((s) => s.active).toList(growable: false);
          if (items.isEmpty) {
            return const Center(child: Text('No schedules yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = items[index];
              TimeOfDay time;
              if (s.minutesOfDayUtc != null) {
                final nowUtc = DateTime.now().toUtc();
                final h = s.minutesOfDayUtc! ~/ 60;
                final m = s.minutesOfDayUtc! % 60;
                final utcToday = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, h, m);
                final local = utcToday.toLocal();
                time = TimeOfDay(hour: local.hour, minute: local.minute);
              } else {
                time = TimeOfDay(hour: s.minutesOfDay ~/ 60, minute: s.minutesOfDay % 60);
              }
              return Dismissible(
                key: Key(s.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  color: Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
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
                },
                onDismissed: (_) async {
                  await ScheduleScheduler.cancelFor(s.id);
                  await box.delete(s.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted "${s.name}"')),
                    );
                  }
                },
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text('${s.medicationName} • ${s.doseValue} ${s.doseUnit} • ${time.format(context)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Take',
                        icon: const Icon(Icons.check_circle_outline),
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
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
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
                          if (confirm) {
                            await ScheduleScheduler.cancelFor(s.id);
                            await box.delete(s.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Deleted "${s.name}"')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () => context.push('/schedules/edit/${s.id}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/schedules/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
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

