// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/utils/datetime_formatter.dart';
import 'package:skedux/src/core/notifications/low_stock_notifier.dart';
import 'package:skedux/src/features/medications/domain/inventory_log.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:skedux/src/features/reports/domain/report_time_range.dart';
import 'package:skedux/src/features/schedules/data/entry_log_repository.dart';
import 'package:skedux/src/features/schedules/domain/calculated_entry.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';
import 'package:skedux/src/widgets/entry_action_sheet.dart';
import 'package:skedux/src/widgets/unified_empty_state.dart';
import 'package:skedux/src/widgets/unified_status_badge.dart';

sealed class _CombinedHistoryItem {
  const _CombinedHistoryItem({
    required this.time,
    required this.medicationName,
  });

  final DateTime time;
  final String medicationName;

  Widget buildTitle(BuildContext context);

  ({IconData icon, Color color}) visualSpec(BuildContext context);
}

class _EntryHistoryItem extends _CombinedHistoryItem {
  _EntryHistoryItem({required this.log})
    : super(time: log.actionTime, medicationName: log.medicationName);

  final EntryLog log;

  @override
  ({IconData icon, Color color}) visualSpec(BuildContext context) {
    final spec = entryActionVisualSpec(context, log.action);
    return (icon: spec.icon, color: spec.color);
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  @override
  Widget buildTitle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayValue = log.actualEntryValue ?? log.entryValue;
    final displayUnit = log.actualEntryUnit ?? log.entryUnit;
    final spec = entryActionVisualSpec(context, log.action);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          medicationName,
          style: bodyTextStyle(
            context,
          )?.copyWith(fontWeight: kFontWeightSemiBold, color: cs.primary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: kSpacingXS / 2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: kSpacingXS,
          children: [
            Text(
              '${_formatAmount(displayValue)} $displayUnit',
              style: smallHelperTextStyle(
                context,
                color: spec.color.withValues(alpha: kOpacityMediumHigh),
              )?.copyWith(fontWeight: kFontWeightSemiBold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}

class _InventoryHistoryItem extends _CombinedHistoryItem {
  _InventoryHistoryItem({required this.log})
    : super(time: log.timestamp, medicationName: log.medicationName);

  final InventoryLog log;

  @override
  ({IconData icon, Color color}) visualSpec(BuildContext context) {
    final spec = inventoryChangeVisualSpec(context, log.changeType);
    return (icon: spec.icon, color: spec.color);
  }

  String _activityTypeLabel() {
    return switch (log.changeType) {
      InventoryChangeType.refillAdd ||
      InventoryChangeType.refillToMax => 'Refill',
      InventoryChangeType.vialRestocked => 'Restock',
      InventoryChangeType.vialOpened => 'Vial Opened',
      InventoryChangeType.manualAdjustment => 'Adjustment',
      InventoryChangeType.expired => 'Expired',
      InventoryChangeType.entryDeducted => 'Entry',
      InventoryChangeType.adHocEntry => 'Ad-hoc Entry',
    };
  }

  @override
  Widget buildTitle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = inventoryChangeVisualSpec(
      context,
      log.changeType,
    ).color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          medicationName,
          style: bodyTextStyle(
            context,
          )?.copyWith(fontWeight: kFontWeightSemiBold, color: cs.primary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: kSpacingXS / 2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: kSpacingXS,
          children: [
            Text(
              _activityTypeLabel(),
              style: smallHelperTextStyle(
                context,
                color: statusColor.withValues(alpha: kOpacityMediumHigh),
              )?.copyWith(fontWeight: kFontWeightSemiBold),
            ),
            Text(
              '—',
              style: smallHelperTextStyle(
                context,
                color: statusColor.withValues(alpha: kOpacityMedium),
              ),
            ),
            Text(
              log.description,
              style: smallHelperTextStyle(
                context,
                color: statusColor.withValues(alpha: kOpacityMediumHigh),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}

class CombinedReportsHistoryWidget extends StatefulWidget {
  const CombinedReportsHistoryWidget({
    required this.includedMedicationIds,
    this.includedScheduleIds,
    this.embedInParentCard = false,
    this.initialMaxItems = 25,
    this.rangePreset = ReportTimeRangePreset.allTime,
    super.key,
  });

  final Set<String> includedMedicationIds;
  final Set<String>? includedScheduleIds;
  final bool embedInParentCard;
  final int initialMaxItems;
  final ReportTimeRangePreset rangePreset;

  @override
  State<CombinedReportsHistoryWidget> createState() =>
      _CombinedReportsHistoryWidgetState();
}

class _CombinedReportsHistoryWidgetState
    extends State<CombinedReportsHistoryWidget> {
  static const int _pageSize = 10;

  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageIndex = 0;
  }

  @override
  void didUpdateWidget(covariant CombinedReportsHistoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.includedMedicationIds != widget.includedMedicationIds ||
        oldWidget.includedScheduleIds != widget.includedScheduleIds) {
      _pageIndex = 0;
    }
  }

  Future<void> _showEntryLogEditor(BuildContext context, EntryLog log) {
    final logBox = Hive.box<EntryLog>('entry_logs');
    final entryLogRepo = EntryLogRepository(logBox);

    final entry = CalculatedEntry(
      scheduleId: log.scheduleId,
      scheduleName: log.scheduleName,
      medicationName: log.medicationName,
      scheduledTime: log.scheduledTime,
      entryValue: log.entryValue,
      entryUnit: log.entryUnit,
      existingLog: log,
    );

    if (log.scheduleId == 'ad_hoc') {
      return EntryActionSheet.show(
        context,
        entry: entry,
        initialStatus: EntryStatus.logged,
        onMarkLogged: (_) async {
          // Ad-hoc persistence is handled inside EntryActionSheet.
        },
        onSnooze: (_) async {
          // Not applicable for ad-hoc entries.
        },
        onSkip: (_) async {
          // Not applicable for ad-hoc entries.
        },
        onDelete: (_) async {
          final latest = logBox.get(log.id);
          if (latest == null) return;

          if (latest.action == EntryAction.logged) {
            final medBox = Hive.box<Medication>('medications');
            final currentMed = medBox.get(latest.medicationId);
            if (currentMed != null) {
              final value = latest.actualEntryValue ?? latest.entryValue;
              final unit = latest.actualEntryUnit ?? latest.entryUnit;
              final delta = MedicationStockAdjustment.tryCalculateStockDelta(
                medication: currentMed,
                schedule: null,
                entryValue: value,
                entryUnit: unit,
                preferEntryValue: true,
              );
              if (delta != null && delta > 0) {
                final restored = MedicationStockAdjustment.restore(
                  medication: currentMed,
                  delta: delta,
                );
                await medBox.put(currentMed.id, restored);
                await LowStockNotifier.handleStockChange(
                  before: currentMed,
                  after: restored,
                );
              }
            }
          }

          await Hive.box<InventoryLog>('inventory_logs').delete(latest.id);
          await entryLogRepo.delete(latest.id);

          if (context.mounted) {
            showAppSnackBar(context, 'Entry log removed');
          }
        },
      );
    }

    return EntryActionSheet.show(
      context,
      entry: entry,
      onMarkLogged: (request) async {
        final trimmed = request.notes?.trim();
        final latest = logBox.get(log.id) ?? log;

        if (latest.action != EntryAction.logged) {
          final schedule = Hive.box<Schedule>('schedules').get(log.scheduleId);
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(log.medicationId);
          if (currentMed != null) {
            final effectiveEntryValue =
                request.actualEntryValue ??
                latest.actualEntryValue ??
                latest.entryValue;
            final effectiveEntryUnit =
                request.actualEntryUnit ??
                latest.actualEntryUnit ??
                latest.entryUnit;
            final delta = MedicationStockAdjustment.tryCalculateStockDelta(
              medication: currentMed,
              schedule: schedule,
              entryValue: effectiveEntryValue,
              entryUnit: effectiveEntryUnit,
              preferEntryValue:
                  request.actualEntryValue != null ||
                  latest.actualEntryValue != null,
            );
            if (delta != null) {
              final updatedMed = MedicationStockAdjustment.deduct(
                medication: currentMed,
                delta: delta,
              );
              await medBox.put(currentMed.id, updatedMed);
              await LowStockNotifier.handleStockChange(
                before: currentMed,
                after: updatedMed,
              );
            }
          }
        }

        final updated = EntryLog(
          id: log.id,
          scheduleId: log.scheduleId,
          scheduleName: log.scheduleName,
          medicationId: log.medicationId,
          medicationName: log.medicationName,
          scheduledTime: log.scheduledTime,
          actionTime: request.actionTime,
          entryValue: latest.entryValue,
          entryUnit: latest.entryUnit,
          action: EntryAction.logged,
          actualEntryValue: request.actualEntryValue ?? latest.actualEntryValue,
          actualEntryUnit: request.actualEntryUnit ?? latest.actualEntryUnit,
          notes: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        );

        await entryLogRepo.upsert(updated);

        if (context.mounted) {
          showAppSnackBar(context, 'Entry updated');
        }
      },
      onSnooze: (request) async {
        final trimmed = request.notes?.trim();
        final latest = logBox.get(log.id) ?? log;

        if (latest.action == EntryAction.logged) {
          final schedule = Hive.box<Schedule>('schedules').get(log.scheduleId);
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(log.medicationId);
          if (currentMed != null) {
            final oldEntryValue = latest.actualEntryValue ?? latest.entryValue;
            final oldEntryUnit = latest.actualEntryUnit ?? latest.entryUnit;
            final delta = MedicationStockAdjustment.tryCalculateStockDelta(
              medication: currentMed,
              schedule: schedule,
              entryValue: oldEntryValue,
              entryUnit: oldEntryUnit,
              preferEntryValue: latest.actualEntryValue != null,
            );
            if (delta != null) {
              final updatedMed = MedicationStockAdjustment.restore(
                medication: currentMed,
                delta: delta,
              );
              await medBox.put(currentMed.id, updatedMed);
              await LowStockNotifier.handleStockChange(
                before: currentMed,
                after: updatedMed,
              );
            }
          }
        }

        final updated = EntryLog(
          id: log.id,
          scheduleId: log.scheduleId,
          scheduleName: log.scheduleName,
          medicationId: log.medicationId,
          medicationName: log.medicationName,
          scheduledTime: log.scheduledTime,
          actionTime: request.actionTime,
          entryValue: latest.entryValue,
          entryUnit: latest.entryUnit,
          action: EntryAction.snoozed,
          actualEntryValue: request.actualEntryValue ?? latest.actualEntryValue,
          actualEntryUnit: request.actualEntryUnit ?? latest.actualEntryUnit,
          notes: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        );

        await entryLogRepo.upsert(updated);

        if (context.mounted) {
          showAppSnackBar(context, 'Entry updated');
        }
      },
      onSkip: (request) async {
        final trimmed = request.notes?.trim();
        final latest = logBox.get(log.id) ?? log;

        if (latest.action == EntryAction.logged) {
          final schedule = Hive.box<Schedule>('schedules').get(log.scheduleId);
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(log.medicationId);
          if (currentMed != null) {
            final oldEntryValue = latest.actualEntryValue ?? latest.entryValue;
            final oldEntryUnit = latest.actualEntryUnit ?? latest.entryUnit;
            final delta = MedicationStockAdjustment.tryCalculateStockDelta(
              medication: currentMed,
              schedule: schedule,
              entryValue: oldEntryValue,
              entryUnit: oldEntryUnit,
              preferEntryValue: latest.actualEntryValue != null,
            );
            if (delta != null) {
              await medBox.put(
                currentMed.id,
                MedicationStockAdjustment.restore(
                  medication: currentMed,
                  delta: delta,
                ),
              );
            }
          }
        }

        final updated = EntryLog(
          id: log.id,
          scheduleId: log.scheduleId,
          scheduleName: log.scheduleName,
          medicationId: log.medicationId,
          medicationName: log.medicationName,
          scheduledTime: log.scheduledTime,
          actionTime: request.actionTime,
          entryValue: latest.entryValue,
          entryUnit: latest.entryUnit,
          action: EntryAction.skipped,
          actualEntryValue: request.actualEntryValue ?? latest.actualEntryValue,
          actualEntryUnit: request.actualEntryUnit ?? latest.actualEntryUnit,
          notes: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        );

        await entryLogRepo.upsert(updated);

        if (context.mounted) {
          showAppSnackBar(context, 'Entry updated');
        }
      },
      onDelete: (_) async {
        final latest = logBox.get(log.id) ?? log;
        if (latest.action == EntryAction.logged) {
          final schedule = Hive.box<Schedule>('schedules').get(log.scheduleId);
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(log.medicationId);
          if (currentMed != null) {
            final oldEntryValue = latest.actualEntryValue ?? latest.entryValue;
            final oldEntryUnit = latest.actualEntryUnit ?? latest.entryUnit;
            final delta = MedicationStockAdjustment.tryCalculateStockDelta(
              medication: currentMed,
              schedule: schedule,
              entryValue: oldEntryValue,
              entryUnit: oldEntryUnit,
              preferEntryValue: latest.actualEntryValue != null,
            );
            if (delta != null) {
              await medBox.put(
                currentMed.id,
                MedicationStockAdjustment.restore(
                  medication: currentMed,
                  delta: delta,
                ),
              );
            }
          }
        }

        await entryLogRepo.delete(log.id);

        if (context.mounted) {
          showAppSnackBar(context, 'Entry log removed');
        }
      },
    );
  }

  void _showInventoryInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Inventory log', style: dialogTitleTextStyle(context)),
          content: Text(
            "Inventory items are system stock-change logs. Editing them isn't supported here yet.\n\nTo change stock, use the medication's stock actions (refill/restock/adjust).",
            style: dialogContentTextStyle(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final range = ReportTimeRange(widget.rangePreset).toUtcTimeRange();

    int dayKey(DateTime timeLocal) {
      return timeLocal.year * 10000 + timeLocal.month * 100 + timeLocal.day;
    }

    Widget buildDateHeader(DateTime localTime) {
      final localizations = MaterialLocalizations.of(context);
      final label =
          '${DateTimeFormatter.formatWeekdayAbbr(localTime)} | ${localizations.formatShortDate(localTime)}';
      return Padding(
        padding: const EdgeInsets.fromLTRB(kSpacingS, kSpacingXS, kSpacingS, 0),
        child: Text(
          label,
          style: helperTextStyle(context)?.copyWith(
            fontWeight: kFontWeightSemiBold,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Widget buildTimeLabel(DateTime localTime) {
      final text = DateTimeFormatter.formatTimeCompact(context, localTime);
      return SizedBox(
        width: kNextEntryDateCircleSizeLarge,
        child: Text(
          text,
          style: smallHelperTextStyle(
            context,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
          maxLines: 2,
          softWrap: true,
          textAlign: TextAlign.center,
        ),
      );
    }

    String entryActionBadgeLabel(EntryAction action) {
      return switch (action) {
        EntryAction.logged => 'LOGGED',
        EntryAction.skipped => 'SKIPPED',
        EntryAction.snoozed => 'SNOOZED',
      };
    }

    final entryLogBox = Hive.box<EntryLog>('entry_logs');
    final inventoryLogBox = Hive.box<InventoryLog>('inventory_logs');

    return ValueListenableBuilder(
      valueListenable: entryLogBox.listenable(),
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: inventoryLogBox.listenable(),
          builder: (context, ___, ____) {
            final included = widget.includedMedicationIds;
            final includedSchedules = widget.includedScheduleIds;
            final hasScheduleFilter =
              includedSchedules != null && includedSchedules.isNotEmpty;

            final entryLogs = entryLogBox.values
                .where((l) => included.contains(l.medicationId))
              .where(
                (l) =>
                  !hasScheduleFilter || includedSchedules.contains(l.scheduleId),
              )
                .where((l) => range == null || range.contains(l.actionTime))
                .toList(growable: false);

            final entryLogIds = entryLogs.map((l) => l.id).toSet();

            final inventoryLogs = inventoryLogBox.values
                .where((l) => included.contains(l.medicationId))
                .where((l) => range == null || range.contains(l.timestamp))
              .where((l) => !hasScheduleFilter || entryLogIds.contains(l.id))
                // Ad-hoc entries create both an InventoryLog and a EntryLog with the same id.
                // Prefer the EntryLog entry since it supports edits.
                .where(
                  (l) =>
                      !(l.changeType == InventoryChangeType.adHocEntry &&
                          entryLogIds.contains(l.id)),
                )
                .toList(growable: false);

            final items = <_CombinedHistoryItem>[
              for (final log in entryLogs) _EntryHistoryItem(log: log),
              for (final log in inventoryLogs) _InventoryHistoryItem(log: log),
            ]..sort((a, b) => b.time.compareTo(a.time));

            final pageCount = (items.length / _pageSize).ceil();
            if (pageCount == 0) {
              _pageIndex = 0;
            } else if (_pageIndex >= pageCount) {
              _pageIndex = pageCount - 1;
            }

            final start = _pageIndex * _pageSize;
            final end = (start + _pageSize).clamp(0, items.length);
            final displayItems = items
                .sublist(start, end)
                .toList(growable: false);

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (displayItems.isEmpty)
                  const UnifiedEmptyState(
                    title: 'No history yet',
                    icon: Icons.history_outlined,
                  )
                else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: kSpacingXS),
                    itemCount: displayItems.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(
                        alpha: kOpacityVeryLow,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      final spec = item.visualSpec(context);
                      final iconColor = spec.color;

                      final localTime = item.time.toLocal();
                      final currentDay = dayKey(localTime);
                      final previousDay = index == 0
                          ? null
                          : dayKey(displayItems[index - 1].time.toLocal());
                      final showDayLabel = previousDay != currentDay;

                      Future<void> onTap() {
                        if (item is _EntryHistoryItem) {
                          return _showEntryLogEditor(context, item.log);
                        }

                        _showInventoryInfo(context);
                        return Future.value();
                      }

                      return Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: onTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: kSpacingXXS,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDayLabel) buildDateHeader(localTime),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    kSpacingS,
                                    kSpacingXXS,
                                    kSpacingS,
                                    kSpacingXXS,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      buildTimeLabel(localTime),
                                      const SizedBox(width: kSpacingS),
                                      Expanded(child: item.buildTitle(context)),
                                      const SizedBox(width: kSpacingS),
                                      if (item is _EntryHistoryItem)
                                        UnifiedStatusBadge(
                                          label: entryActionBadgeLabel(
                                            item.log.action,
                                          ),
                                          icon: spec.icon,
                                          color: iconColor,
                                          dense: true,
                                        )
                                      else
                                        Container(
                                          width: kStepperButtonSize,
                                          height: kStepperButtonSize,
                                          decoration: BoxDecoration(
                                            color: iconColor.withValues(
                                              alpha: kOpacitySubtle,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            spec.icon,
                                            size: kIconSizeSmall,
                                            color: iconColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (pageCount > 1) ...[
                    const SizedBox(height: kSpacingXS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _pageIndex <= 0
                              ? null
                              : () => setState(() => _pageIndex -= 1),
                          constraints: kTightIconButtonConstraints,
                          padding: kNoPadding,
                          icon: Icon(
                            Icons.keyboard_arrow_left,
                            size: kIconSizeSmall,
                            color: cs.onSurfaceVariant.withValues(
                              alpha: kOpacityMediumHigh,
                            ),
                          ),
                        ),
                        const SizedBox(width: kSpacingXS),
                        Text(
                          '${_pageIndex + 1}/$pageCount',
                          style: microHelperTextStyle(context)?.copyWith(
                            color: cs.onSurfaceVariant.withValues(
                              alpha: kOpacityMediumHigh,
                            ),
                          ),
                        ),
                        const SizedBox(width: kSpacingXS),
                        IconButton(
                          onPressed: _pageIndex >= (pageCount - 1)
                              ? null
                              : () => setState(() => _pageIndex += 1),
                          constraints: kTightIconButtonConstraints,
                          padding: kNoPadding,
                          icon: Icon(
                            Icons.keyboard_arrow_right,
                            size: kIconSizeSmall,
                            color: cs.onSurfaceVariant.withValues(
                              alpha: kOpacityMediumHigh,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            );

            if (widget.embedInParentCard) return content;

            return Padding(
              padding: const EdgeInsets.all(kSpacingM),
              child: content,
            );
          },
        );
      },
    );
  }
}
