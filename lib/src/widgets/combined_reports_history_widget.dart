// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/core/notifications/low_stock_notifier.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';
import 'package:dosifi_v5/src/widgets/unified_empty_state.dart';
import 'package:dosifi_v5/src/widgets/unified_status_badge.dart';

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

class _DoseHistoryItem extends _CombinedHistoryItem {
  _DoseHistoryItem({required this.log})
    : super(time: log.actionTime, medicationName: log.medicationName);

  final DoseLog log;

  @override
  ({IconData icon, Color color}) visualSpec(BuildContext context) {
    final spec = doseActionVisualSpec(context, log.action);
    return (icon: spec.icon, color: spec.color);
  }

  String _effectiveScheduleName() {
    if (log.scheduleId == 'ad_hoc') return 'Unscheduled';
    final trimmed = log.scheduleName.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'Scheduled dose';
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  @override
  Widget buildTitle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = doseActionVisualSpec(context, log.action).color;

    final displayValue = log.actualDoseValue ?? log.doseValue;
    final displayUnit = log.actualDoseUnit ?? log.doseUnit;
    final scheduleName = _effectiveScheduleName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: kSpacingXS,
          children: [
            Text(
              '${_formatAmount(displayValue)} $displayUnit',
              style: bodyTextStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightSemiBold, color: statusColor),
            ),
            Text(
              '•',
              style: smallHelperTextStyle(
                context,
                color: cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
              ),
            ),
            Text(
              medicationName,
              style: smallHelperTextStyle(
                context,
                color: cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: kSpacingXS / 2),
        Text(
          scheduleName,
          style: smallHelperTextStyle(
            context,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          log.description,
          style: bodyTextStyle(
            context,
          )?.copyWith(fontWeight: kFontWeightSemiBold, color: statusColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: kSpacingXS / 2),
        Text(
          medicationName,
          style: smallHelperTextStyle(
            context,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class CombinedReportsHistoryWidget extends StatefulWidget {
  const CombinedReportsHistoryWidget({
    required this.includedMedicationIds,
    this.embedInParentCard = false,
    this.initialMaxItems = 25,
    this.rangePreset = ReportTimeRangePreset.allTime,
    super.key,
  });

  final Set<String> includedMedicationIds;
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
    if (oldWidget.includedMedicationIds != widget.includedMedicationIds) {
      _pageIndex = 0;
    }
  }

  Future<void> _showDoseLogEditor(BuildContext context, DoseLog log) {
    final logBox = Hive.box<DoseLog>('dose_logs');
    final doseLogRepo = DoseLogRepository(logBox);

    final dose = CalculatedDose(
      scheduleId: log.scheduleId,
      scheduleName: log.scheduleName,
      medicationName: log.medicationName,
      scheduledTime: log.scheduledTime,
      doseValue: log.doseValue,
      doseUnit: log.doseUnit,
      existingLog: log,
    );

    if (log.scheduleId == 'ad_hoc') {
      return DoseActionSheet.show(
        context,
        dose: dose,
        initialStatus: DoseStatus.taken,
        onMarkTaken: (_) async {
          // Ad-hoc persistence is handled inside DoseActionSheet.
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

          if (latest.action == DoseAction.taken) {
            final medBox = Hive.box<Medication>('medications');
            final currentMed = medBox.get(latest.medicationId);
            if (currentMed != null) {
              final value = latest.actualDoseValue ?? latest.doseValue;
              final unit = latest.actualDoseUnit ?? latest.doseUnit;
              final delta = MedicationStockAdjustment.tryCalculateStockDelta(
                medication: currentMed,
                schedule: null,
                doseValue: value,
                doseUnit: unit,
                preferDoseValue: true,
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
          await doseLogRepo.delete(latest.id);

          if (context.mounted) {
            showAppSnackBar(context, 'Dose log removed');
          }
        },
      );
    }

    return DoseActionSheet.show(
      context,
      dose: dose,
      onMarkTaken: (request) async {
        final trimmed = request.notes?.trim();
        final latest = logBox.get(log.id) ?? log;

        if (latest.action != DoseAction.taken) {
          final schedule = Hive.box<Schedule>('schedules').get(log.scheduleId);
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(log.medicationId);
          if (currentMed != null) {
            final effectiveDoseValue =
                request.actualDoseValue ??
                latest.actualDoseValue ??
                latest.doseValue;
            final effectiveDoseUnit =
                request.actualDoseUnit ??
                latest.actualDoseUnit ??
                latest.doseUnit;
            final delta = MedicationStockAdjustment.tryCalculateStockDelta(
              medication: currentMed,
              schedule: schedule,
              doseValue: effectiveDoseValue,
              doseUnit: effectiveDoseUnit,
              preferDoseValue:
                  request.actualDoseValue != null ||
                  latest.actualDoseValue != null,
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

        final updated = DoseLog(
          id: log.id,
          scheduleId: log.scheduleId,
          scheduleName: log.scheduleName,
          medicationId: log.medicationId,
          medicationName: log.medicationName,
          scheduledTime: log.scheduledTime,
          actionTime: request.actionTime,
          doseValue: latest.doseValue,
          doseUnit: latest.doseUnit,
          action: DoseAction.taken,
          actualDoseValue: request.actualDoseValue ?? latest.actualDoseValue,
          actualDoseUnit: request.actualDoseUnit ?? latest.actualDoseUnit,
          notes: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        );

        await doseLogRepo.upsert(updated);

        if (context.mounted) {
          showAppSnackBar(context, 'Dose updated');
        }
      },
      onSnooze: (request) async {
        final trimmed = request.notes?.trim();
        final latest = logBox.get(log.id) ?? log;

        if (latest.action == DoseAction.taken) {
          final schedule = Hive.box<Schedule>('schedules').get(log.scheduleId);
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(log.medicationId);
          if (currentMed != null) {
            final oldDoseValue = latest.actualDoseValue ?? latest.doseValue;
            final oldDoseUnit = latest.actualDoseUnit ?? latest.doseUnit;
            final delta = MedicationStockAdjustment.tryCalculateStockDelta(
              medication: currentMed,
              schedule: schedule,
              doseValue: oldDoseValue,
              doseUnit: oldDoseUnit,
              preferDoseValue: latest.actualDoseValue != null,
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

        final updated = DoseLog(
          id: log.id,
          scheduleId: log.scheduleId,
          scheduleName: log.scheduleName,
          medicationId: log.medicationId,
          medicationName: log.medicationName,
          scheduledTime: log.scheduledTime,
          actionTime: request.actionTime,
          doseValue: latest.doseValue,
          doseUnit: latest.doseUnit,
          action: DoseAction.snoozed,
          actualDoseValue: request.actualDoseValue ?? latest.actualDoseValue,
          actualDoseUnit: request.actualDoseUnit ?? latest.actualDoseUnit,
          notes: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        );

        await doseLogRepo.upsert(updated);

        if (context.mounted) {
          showAppSnackBar(context, 'Dose updated');
        }
      },
      onSkip: (request) async {
        final trimmed = request.notes?.trim();
        final latest = logBox.get(log.id) ?? log;

        if (latest.action == DoseAction.taken) {
          final schedule = Hive.box<Schedule>('schedules').get(log.scheduleId);
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(log.medicationId);
          if (currentMed != null) {
            final oldDoseValue = latest.actualDoseValue ?? latest.doseValue;
            final oldDoseUnit = latest.actualDoseUnit ?? latest.doseUnit;
            final delta = MedicationStockAdjustment.tryCalculateStockDelta(
              medication: currentMed,
              schedule: schedule,
              doseValue: oldDoseValue,
              doseUnit: oldDoseUnit,
              preferDoseValue: latest.actualDoseValue != null,
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

        final updated = DoseLog(
          id: log.id,
          scheduleId: log.scheduleId,
          scheduleName: log.scheduleName,
          medicationId: log.medicationId,
          medicationName: log.medicationName,
          scheduledTime: log.scheduledTime,
          actionTime: request.actionTime,
          doseValue: latest.doseValue,
          doseUnit: latest.doseUnit,
          action: DoseAction.skipped,
          actualDoseValue: request.actualDoseValue ?? latest.actualDoseValue,
          actualDoseUnit: request.actualDoseUnit ?? latest.actualDoseUnit,
          notes: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        );

        await doseLogRepo.upsert(updated);

        if (context.mounted) {
          showAppSnackBar(context, 'Dose updated');
        }
      },
      onDelete: (_) async {
        final latest = logBox.get(log.id) ?? log;
        if (latest.action == DoseAction.taken) {
          final schedule = Hive.box<Schedule>('schedules').get(log.scheduleId);
          final medBox = Hive.box<Medication>('medications');
          final currentMed = medBox.get(log.medicationId);
          if (currentMed != null) {
            final oldDoseValue = latest.actualDoseValue ?? latest.doseValue;
            final oldDoseUnit = latest.actualDoseUnit ?? latest.doseUnit;
            final delta = MedicationStockAdjustment.tryCalculateStockDelta(
              medication: currentMed,
              schedule: schedule,
              doseValue: oldDoseValue,
              doseUnit: oldDoseUnit,
              preferDoseValue: latest.actualDoseValue != null,
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

        await doseLogRepo.delete(log.id);

        if (context.mounted) {
          showAppSnackBar(context, 'Dose log removed');
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
          '${DateTimeFormatter.formatWeekdayAbbr(localTime)} · ${localizations.formatShortDate(localTime)}';
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
        width: kNextDoseDateCircleSizeLarge,
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

    String doseActionBadgeLabel(DoseAction action) {
      return switch (action) {
        DoseAction.taken => 'TAKEN',
        DoseAction.skipped => 'SKIPPED',
        DoseAction.snoozed => 'SNOOZED',
      };
    }

    final doseLogBox = Hive.box<DoseLog>('dose_logs');
    final inventoryLogBox = Hive.box<InventoryLog>('inventory_logs');

    return ValueListenableBuilder(
      valueListenable: doseLogBox.listenable(),
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: inventoryLogBox.listenable(),
          builder: (context, ___, ____) {
            final included = widget.includedMedicationIds;

            final doseLogs = doseLogBox.values
                .where((l) => included.contains(l.medicationId))
                .where((l) => range == null || range.contains(l.actionTime))
                .toList(growable: false);

            final doseLogIds = doseLogs.map((l) => l.id).toSet();

            final inventoryLogs = inventoryLogBox.values
                .where((l) => included.contains(l.medicationId))
                .where((l) => range == null || range.contains(l.timestamp))
                // Ad-hoc doses create both an InventoryLog and a DoseLog with the same id.
                // Prefer the DoseLog entry since it supports edits.
                .where(
                  (l) =>
                      !(l.changeType == InventoryChangeType.adHocDose &&
                          doseLogIds.contains(l.id)),
                )
                .toList(growable: false);

            final items = <_CombinedHistoryItem>[
              for (final log in doseLogs) _DoseHistoryItem(log: log),
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
                        if (item is _DoseHistoryItem) {
                          return _showDoseLogEditor(context, item.log);
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
                                      if (item is _DoseHistoryItem)
                                        UnifiedStatusBadge(
                                          label: doseActionBadgeLabel(
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
