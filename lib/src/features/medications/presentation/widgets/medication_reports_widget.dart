// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/notifications/low_stock_notifier.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_calculation_service.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_status_change_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';
import 'package:dosifi_v5/src/widgets/glass_card_surface.dart';
import 'package:dosifi_v5/src/widgets/next_dose_date_badge.dart';

class _HistoryItem {
  const _HistoryItem._({
    required this.time,
    this.doseLog,
    this.inventoryLog,
    this.statusChange,
    this.missedDose,
  });

  factory _HistoryItem.dose(DoseLog log) =>
      _HistoryItem._(time: log.actionTime, doseLog: log);

  factory _HistoryItem.inventory(InventoryLog log) =>
      _HistoryItem._(time: log.timestamp, inventoryLog: log);

  factory _HistoryItem.statusChange(DoseStatusChangeLog log) =>
      _HistoryItem._(time: log.changeTime, statusChange: log);

  factory _HistoryItem.missed(CalculatedDose dose) =>
      _HistoryItem._(time: dose.scheduledTime, missedDose: dose);

  final DateTime time;
  final DoseLog? doseLog;
  final InventoryLog? inventoryLog;
  final DoseStatusChangeLog? statusChange;
  final CalculatedDose? missedDose;
}

/// Comprehensive reports widget with tabs for History, Adherence, and future analytics
/// Replaces DoseHistoryWidget with expanded functionality
class MedicationReportsWidget extends StatefulWidget {
  const MedicationReportsWidget({
    required this.medication,
    this.isExpanded = true,
    this.onExpandedChanged,
    this.embedInParentCard = false,
    super.key,
  });

  final Medication medication;
  final bool isExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final bool embedInParentCard;

  @override
  State<MedicationReportsWidget> createState() =>
      _MedicationReportsWidgetState();
}

class _MedicationReportsWidgetState extends State<MedicationReportsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpandedInternal = true; // Collapsible state (uncontrolled mode)

  static const int _historyPageStep = 25;
  int _historyMaxItems = _historyPageStep;

  static const int _inventoryEventsMaxItems = 10;
  static const int _historyMissedLookbackDays = 14;

  @override
  void initState() {
    super.initState();
    _isExpandedInternal = widget.isExpanded;
    final tabCount = 1 + _AdherenceReportSection.values.length;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isExpanded = widget.onExpandedChanged != null
        ? widget.isExpanded
        : _isExpandedInternal;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            if (widget.onExpandedChanged != null) {
              widget.onExpandedChanged?.call(!isExpanded);
              return;
            }

            setState(() => _isExpandedInternal = !_isExpandedInternal);
          },
          child: Padding(
            padding: const EdgeInsets.all(kSpacingM),
            child: Row(
              children: [
                if (!isExpanded)
                  const SizedBox(width: kDetailCardReorderHandleGutterWidth),
                Icon(
                  Icons.bar_chart_rounded,
                  size: kIconSizeMedium,
                  color: cs.primary,
                ),
                const SizedBox(width: kSpacingS),
                Text(
                  'Reports',
                  style: cardTitleStyle(
                    context,
                  )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: isExpanded ? 0 : -0.25,
                  duration: kAnimationNormal,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: kIconSizeLarge,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: kAnimationNormal,
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelPadding: const EdgeInsets.symmetric(horizontal: kSpacingM),
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicatorColor: cs.primary,
                dividerColor: cs.surface.withValues(alpha: kOpacityTransparent),
                labelStyle: smallHelperTextStyle(
                  context,
                )?.copyWith(fontWeight: kFontWeightSemiBold),
                tabs: [
                  const Tab(text: 'History'),
                  for (final section in _AdherenceReportSection.values)
                    Tab(text: section.label),
                ],
              ),
              SizedBox(
                height: kMedicationReportsTabHeight,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistoryTab(context),
                    for (final section in _AdherenceReportSection.values)
                      _buildReportTab(context, section),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedInParentCard) return content;

    return GlassCardSurface(
      useGradient: false,
      padding: EdgeInsets.zero,
      child: content,
    );
  }

  String _effectiveScheduleName({
    required String scheduleId,
    required String? scheduleName,
  }) {
    if (scheduleId == 'ad_hoc') return 'Unscheduled';

    final trimmed = scheduleName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;

    final schedule = Hive.box<Schedule>('schedules').get(scheduleId);
    final fallback = schedule?.name.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;

    return 'Scheduled dose';
  }

  Widget _buildEditIndicatorIcon(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Icon(
      Icons.edit,
      size: kIconSizeXXSmall,
      color: cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doseLogBox = Hive.box<DoseLog>('dose_logs');
    final inventoryLogBox = Hive.box<InventoryLog>('inventory_logs');
    final statusChangeBox = Hive.box<DoseStatusChangeLog>(
      'dose_status_change_logs',
    );

    final now = DateTime.now();
    final missedStart = now.subtract(
      const Duration(days: _historyMissedLookbackDays),
    );
    final missedFuture = DoseCalculationService.calculateDoses(
      startDate: missedStart,
      endDate: now,
      medicationId: widget.medication.id,
      includeInactive: true,
    );

    // Dose logs for this medication
    final doseLogs = doseLogBox.values
        .where((log) => log.medicationId == widget.medication.id)
        .toList(growable: false);

    final adHocDoseLogIds = doseLogs
        .where((log) => log.scheduleId == 'ad_hoc')
        .map((log) => log.id)
        .toSet();

    // Inventory events for this medication (refills, deductions, adjustments, etc)
    final inventoryLogs = inventoryLogBox.values
        .where((l) => l.medicationId == widget.medication.id)
        // Ad-hoc doses create both an InventoryLog and a DoseLog with the same id.
        // In History, show the editable DoseLog and suppress the duplicate inventory entry.
        .where(
          (l) =>
              !(l.changeType == InventoryChangeType.adHocDose &&
                  adHocDoseLogIds.contains(l.id)),
        )
        .toList(growable: false);

    // Status change events for this medication
    final statusChanges = statusChangeBox.values
        .where((l) => l.medicationId == widget.medication.id)
        .toList(growable: false);

    return FutureBuilder<List<CalculatedDose>>(
      future: missedFuture,
      builder: (context, snapshot) {
        final missedDoses = (snapshot.data ?? const <CalculatedDose>[])
            .where(
              (d) => d.status == DoseStatus.overdue && d.existingLog == null,
            )
            .toList(growable: false);

        final allItems = <_HistoryItem>[
          for (final log in doseLogs) _HistoryItem.dose(log),
          for (final log in inventoryLogs) _HistoryItem.inventory(log),
          for (final log in statusChanges) _HistoryItem.statusChange(log),
          for (final dose in missedDoses) _HistoryItem.missed(dose),
        ]..sort((a, b) => b.time.compareTo(a.time));

        final displayItems = allItems
            .take(_historyMaxItems)
            .toList(growable: false);
        final hasMore = displayItems.length < allItems.length;

        if (displayItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_outlined,
                  size: kEmptyStateIconSize,
                  color: cs.onSurfaceVariant.withValues(
                    alpha: kOpacityMediumLow,
                  ),
                ),
                const SizedBox(height: kSpacingM),
                Text('No history yet', style: helperTextStyle(context)),
                const SizedBox(height: kSpacingXS),
                Text(
                  'Recorded doses and inventory events will appear here',
                  style: smallHelperTextStyle(context),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  kSpacingS,
                  0,
                  kSpacingS,
                  kSpacingS,
                ),
                itemCount: displayItems.length + (hasMore ? 1 : 0),
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: kOpacityVeryLow),
                ),
                itemBuilder: (context, index) {
                  if (hasMore && index == displayItems.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: kSpacingS),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _historyMaxItems += _historyPageStep;
                            });
                          },
                          icon: const Icon(
                            Icons.expand_more,
                            size: kIconSizeSmall,
                          ),
                          label: Text(
                            'Load more',
                            style: helperTextStyle(
                              context,
                            )?.copyWith(fontWeight: kFontWeightSemiBold),
                          ),
                        ),
                      ),
                    );
                  }

                  final item = displayItems[index];
                  if (item.doseLog != null) {
                    return _buildDoseLogItem(context, item.doseLog!);
                  }
                  if (item.inventoryLog != null) {
                    return _buildInventoryEventRow(context, item.inventoryLog!);
                  }
                  if (item.statusChange != null) {
                    return _buildDoseStatusChangeRow(
                      context,
                      item.statusChange!,
                    );
                  }
                  return _buildMissedDoseRow(context, item.missedDose!);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDoseStatusChangeRow(
    BuildContext context,
    DoseStatusChangeLog log,
  ) {
    final cs = Theme.of(context).colorScheme;
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingXS / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NextDoseDateBadge(
            nextDose: log.changeTime,
            isActive: true,
            dense: true,
            showNextLabel: false,
          ),
          const SizedBox(width: kSpacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.fromStatus} → ${log.toStatus}',
                  style: helperTextStyle(
                    context,
                    color: cs.onSurfaceVariant,
                  )?.copyWith(fontWeight: kFontWeightSemiBold),
                ),
                const SizedBox(height: kSpacingXS / 2),
                Text(
                  timeFormat.format(log.changeTime),
                  style: smallHelperTextStyle(
                    context,
                    color: cs.onSurfaceVariant.withValues(
                      alpha: kOpacityMediumHigh,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: kSpacingS),
          Icon(
            Icons.swap_horiz,
            size: kIconSizeSmall,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedDoseRow(BuildContext context, CalculatedDose dose) {
    final cs = Theme.of(context).colorScheme;
    final timeFormat = DateFormat('h:mm a');

    final scheduleName = _effectiveScheduleName(
      scheduleId: dose.scheduleId,
      scheduleName: dose.scheduleName,
    );

    return InkWell(
      onTap: () => _showUniversalDoseActionSheetForMissedDose(context, dose),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kSpacingXS / 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NextDoseDateBadge(
              nextDose: dose.scheduledTime,
              isActive: true,
              dense: true,
              showNextLabel: false,
            ),
            const SizedBox(width: kSpacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$scheduleName • ${dose.doseValue} ${dose.doseUnit}',
                    style: helperTextStyle(
                      context,
                      color: cs.onSurfaceVariant.withValues(
                        alpha: kOpacityMediumHigh,
                      ),
                    ),
                  ),
                  const SizedBox(height: kSpacingXS / 2),
                  Text(
                    timeFormat.format(dose.scheduledTime),
                    style: smallHelperTextStyle(
                      context,
                      color: cs.onSurfaceVariant.withValues(
                        alpha: kOpacityMediumHigh,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpacingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingXS,
                vertical: kSpacingXS / 2,
              ),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: kOpacitySubtle),
                borderRadius: BorderRadius.circular(kBorderRadiusChip),
              ),
              child: Text(
                'Missed',
                style: hintLabelTextStyle(
                  context,
                  color: cs.error,
                )?.copyWith(fontWeight: kFontWeightBold),
              ),
            ),
            const SizedBox(width: kSpacingXS),
            _buildEditIndicatorIcon(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseLogItem(BuildContext context, DoseLog log) {
    final cs = Theme.of(context).colorScheme;
    final timeFormat = DateFormat('h:mm a');

    final displayValue = log.actualDoseValue ?? log.doseValue;
    final displayUnit = log.actualDoseUnit ?? log.doseUnit;
    final isAdHoc = log.scheduleId == 'ad_hoc';

    final Color iconColor;
    switch (log.action) {
      case DoseAction.taken:
        iconColor = cs.primary;
        break;
      case DoseAction.skipped:
        iconColor = cs.tertiary;
        break;
      case DoseAction.snoozed:
        iconColor = cs.secondary;
        break;
    }

    final title = _effectiveScheduleName(
      scheduleId: log.scheduleId,
      scheduleName: isAdHoc ? 'Unscheduled' : log.scheduleName,
    );

    return InkWell(
      onTap: () => _showUniversalDoseActionSheetForLog(context, log),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kSpacingXS / 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NextDoseDateBadge(
              nextDose: log.actionTime,
              isActive: true,
              dense: true,
              showNextLabel: false,
              showTodayIcon: isAdHoc,
            ),
            const SizedBox(width: kSpacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatAmount(displayValue),
                        style: bodyTextStyle(
                          context,
                        )?.copyWith(fontWeight: kFontWeightBold),
                      ),
                      const SizedBox(width: kSpacingXS),
                      Text(
                        displayUnit,
                        style: smallHelperTextStyle(
                          context,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: kSpacingS),
                      Text(
                        timeFormat.format(log.actionTime),
                        style: smallHelperTextStyle(
                          context,
                          color: cs.onSurfaceVariant.withValues(
                            alpha: kOpacityMediumHigh,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSpacingXS / 2),
                  Text(
                    title,
                    style: smallHelperTextStyle(
                      context,
                      color: cs.onSurfaceVariant.withValues(
                        alpha: kOpacityMediumHigh,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpacingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingXS,
                vertical: kSpacingXS / 2,
              ),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: kOpacitySubtle),
                borderRadius: BorderRadius.circular(kBorderRadiusChip),
              ),
              child: Text(
                log.action.name,
                style: hintLabelTextStyle(
                  context,
                  color: iconColor,
                )?.copyWith(fontWeight: kFontWeightBold),
              ),
            ),
            const SizedBox(width: kSpacingXS),
            GestureDetector(
              onTap: () => _showEditDoseLogTimeDialog(context, log),
              child: _buildEditIndicatorIcon(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDoseLogTimeDialog(
    BuildContext context,
    DoseLog log,
  ) async {
    final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
    final notesController = TextEditingController(text: log.notes ?? '');
    var selected = log.actionTime;

    final saved = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final dateFormat = DateFormat('EEE, MMM d, y');
        final timeFormat = DateFormat('h:mm a');

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: selected,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              setDialogState(() {
                selected = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  selected.hour,
                  selected.minute,
                );
              });
            }

            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: dialogContext,
                initialTime: TimeOfDay.fromDateTime(selected),
              );
              if (picked == null) return;
              setDialogState(() {
                selected = DateTime(
                  selected.year,
                  selected.month,
                  selected.day,
                  picked.hour,
                  picked.minute,
                );
              });
            }

            return AlertDialog(
              titleTextStyle: cardTitleStyle(
                dialogContext,
              )?.copyWith(color: cs.primary),
              contentTextStyle: bodyTextStyle(dialogContext),
              title: const Text('Edit Dose Time'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update the recorded date and time for this dose log.',
                    style: helperTextStyle(dialogContext),
                  ),
                  const SizedBox(height: kSpacingM),
                  SizedBox(
                    height: kStandardFieldHeight,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: pickDate,
                      icon: const Icon(
                        Icons.calendar_today,
                        size: kIconSizeSmall,
                      ),
                      label: Text(dateFormat.format(selected)),
                    ),
                  ),
                  const SizedBox(height: kSpacingS),
                  SizedBox(
                    height: kStandardFieldHeight,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: pickTime,
                      icon: const Icon(Icons.schedule, size: kIconSizeSmall),
                      label: Text(timeFormat.format(selected)),
                    ),
                  ),
                  const SizedBox(height: kSpacingM),
                  Text(
                    'Notes (optional):',
                    style: helperTextStyle(
                      dialogContext,
                    )?.copyWith(fontWeight: kFontWeightMedium),
                  ),
                  const SizedBox(height: kSpacingS),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    style: bodyTextStyle(dialogContext),
                    decoration: buildFieldDecoration(
                      dialogContext,
                      hint: 'e.g., Taken early',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final trimmedNotes = notesController.text.trim();
                    final updated = DoseLog(
                      id: log.id,
                      scheduleId: log.scheduleId,
                      scheduleName: log.scheduleName,
                      medicationId: log.medicationId,
                      medicationName: log.medicationName,
                      scheduledTime: log.scheduledTime,
                      actionTime: selected,
                      doseValue: log.doseValue,
                      doseUnit: log.doseUnit,
                      action: log.action,
                      actualDoseValue: log.actualDoseValue,
                      actualDoseUnit: log.actualDoseUnit,
                      notes: trimmedNotes.isEmpty ? null : trimmedNotes,
                    );
                    await repo.upsert(updated);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    notesController.dispose();

    if (!mounted) return;
    if (saved == true) {
      setState(() {});
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(const SnackBar(content: Text('Dose updated')));
    }
  }

  Future<void> _showUniversalDoseActionSheetForLog(
    BuildContext context,
    DoseLog log,
  ) {
    final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
    final logBox = Hive.box<DoseLog>('dose_logs');

    final dose = CalculatedDose(
      scheduleId: log.scheduleId,
      scheduleName: log.scheduleName,
      medicationName: log.medicationName,
      scheduledTime: log.scheduledTime,
      doseValue: log.doseValue,
      doseUnit: log.doseUnit,
      existingLog: log,
    );

    void showUpdatedSnackBar(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text(message)));
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

        await repo.upsert(updated);
        if (!mounted) return;
        setState(() {});
        showUpdatedSnackBar('Dose updated');
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

        await repo.upsert(updated);
        if (!mounted) return;
        setState(() {});
        showUpdatedSnackBar('Dose updated');
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

        await repo.upsert(updated);
        if (!mounted) return;
        setState(() {});
        showUpdatedSnackBar('Dose updated');
      },
      onDelete: (request) async {
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
        await repo.delete(log.id);
        if (!mounted) return;
        setState(() {});
        showUpdatedSnackBar('Dose log removed');
      },
    );
  }

  Future<void> _showUniversalDoseActionSheetForMissedDose(
    BuildContext context,
    CalculatedDose dose,
  ) {
    final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));

    void showUpdatedSnackBar(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    DoseLog buildLog(
      DoseAction action,
      String? notes, {
      required DateTime actionTime,
      double? actualDoseValue,
      String? actualDoseUnit,
    }) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final trimmed = notes?.trim();

      return DoseLog(
        id: id,
        scheduleId: dose.scheduleId,
        scheduleName: dose.scheduleName,
        medicationId: widget.medication.id,
        medicationName: widget.medication.name,
        scheduledTime: dose.scheduledTime,
        actionTime: actionTime,
        doseValue: dose.doseValue,
        doseUnit: dose.doseUnit,
        action: action,
        actualDoseValue: actualDoseValue,
        actualDoseUnit: actualDoseUnit,
        notes: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      );
    }

    return DoseActionSheet.show(
      context,
      dose: dose,
      onMarkTaken: (request) async {
        final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);
        final medBox = Hive.box<Medication>('medications');
        final currentMed = medBox.get(widget.medication.id);
        if (currentMed != null) {
          final effectiveDoseValue = request.actualDoseValue ?? dose.doseValue;
          final effectiveDoseUnit = request.actualDoseUnit ?? dose.doseUnit;
          final delta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: currentMed,
            schedule: schedule,
            doseValue: effectiveDoseValue,
            doseUnit: effectiveDoseUnit,
            preferDoseValue: request.actualDoseValue != null,
          );
          if (delta != null) {
            await medBox.put(
              currentMed.id,
              MedicationStockAdjustment.deduct(
                medication: currentMed,
                delta: delta,
              ),
            );
          }
        }

        await repo.upsert(
          buildLog(
            DoseAction.taken,
            request.notes,
            actionTime: request.actionTime,
            actualDoseValue: request.actualDoseValue,
            actualDoseUnit: request.actualDoseUnit,
          ),
        );
        if (!mounted) return;
        setState(() {});
        showUpdatedSnackBar('Dose logged');
      },
      onSnooze: (request) async {
        await repo.upsert(
          buildLog(
            DoseAction.snoozed,
            request.notes,
            actionTime: request.actionTime,
            actualDoseValue: request.actualDoseValue,
            actualDoseUnit: request.actualDoseUnit,
          ),
        );
        if (!mounted) return;
        setState(() {});
        showUpdatedSnackBar('Dose logged');
      },
      onSkip: (request) async {
        await repo.upsert(
          buildLog(
            DoseAction.skipped,
            request.notes,
            actionTime: request.actionTime,
            actualDoseValue: request.actualDoseValue,
            actualDoseUnit: request.actualDoseUnit,
          ),
        );
        if (!mounted) return;
        setState(() {});
        showUpdatedSnackBar('Dose logged');
      },
      onDelete: (request) async {
        // Missed doses have no existing log to delete.
      },
    );
  }

  Widget _buildReportTab(
    BuildContext context,
    _AdherenceReportSection section,
  ) {
    final cs = Theme.of(context).colorScheme;
    final adherenceData = _calculateAdherenceData();

    // No schedules = show message
    if (adherenceData.every((v) => v < 0)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: kEmptyStateIconSize,
              color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
            ),
            const SizedBox(height: kSpacingM),
            Text('No schedule data', style: helperTextStyle(context)),
            const SizedBox(height: kSpacingXS),
            Text(
              'Create a schedule to track adherence',
              style: smallHelperTextStyle(context),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(kSpacingM),
      children: [
        switch (section) {
          _AdherenceReportSection.adherence => _buildAdherenceLineSection(
            context,
            adherenceData,
          ),
          _AdherenceReportSection.takenMissed => _buildTakenMissedSection(
            context,
          ),
          _AdherenceReportSection.timeOfDay => _buildTimeOfDaySection(context),
          _AdherenceReportSection.summary => _buildSummarySection(
            context,
            adherenceData,
          ),
          _AdherenceReportSection.streaks => _buildStreaksSection(context),
          _AdherenceReportSection.actions => _buildActionsSection(context),
          _AdherenceReportSection.doseAmount => _buildDoseAmountSection(
            context,
          ),
          _AdherenceReportSection.doseStrength => _buildDoseStrengthSection(
            context,
          ),
          _AdherenceReportSection.inventoryEvents =>
            _buildInventoryEventsSection(context),
        },
      ],
    );
  }

  Widget _buildAdherenceLineSection(
    BuildContext context,
    List<double> adherenceData,
  ) {
    final cs = Theme.of(context).colorScheme;
    final avgPct = _getAveragePercentage(adherenceData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Last 7 Days', style: helperTextStyle(context)),
            const Spacer(),
            Text(
              '${avgPct}% avg',
              style: bodyTextStyle(context)?.copyWith(
                color: _getAdherenceColor(cs, avgPct),
                fontWeight: kFontWeightSemiBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: kSpacingM),
        SizedBox(
          height: kAdherenceChartHeight,
          child: CustomPaint(
            painter: _AdherenceLinePainter(
              data: adherenceData,
              color: cs.primary,
            ),
            child: Container(),
          ),
        ),
      ],
    );
  }

  Widget _buildTakenMissedSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final takenMissed = _calculateTakenMissedData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Taken vs missed',
          style: helperTextStyle(context)?.copyWith(
            fontWeight: kFontWeightSemiBold,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
        ),
        const SizedBox(height: kSpacingXS),
        SizedBox(
          height: kTakenMissedChartHeight,
          child: CustomPaint(
            painter: _TakenMissedStackedBarPainter(
              data: takenMissed,
              takenColor: cs.primary,
              missedColor: cs.error,
              emptyColor: cs.onSurfaceVariant.withValues(
                alpha: kOpacitySubtleLow,
              ),
            ),
            child: Container(),
          ),
        ),
        const SizedBox(height: kSpacingXS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = DateTime.now().subtract(Duration(days: 6 - i));
            final dayName = [
              'M',
              'T',
              'W',
              'T',
              'F',
              'S',
              'S',
            ][day.weekday - 1];
            return Text(
              dayName,
              style: hintLabelTextStyle(
                context,
                color: cs.onSurfaceVariant,
              )?.copyWith(fontWeight: kFontWeightMedium),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimeOfDaySection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeOfDayHistogram = _calculateTakenTimeOfDayHistogram();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time of day',
          style: helperTextStyle(context)?.copyWith(
            fontWeight: kFontWeightSemiBold,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
        ),
        const SizedBox(height: kSpacingXS),
        SizedBox(
          height: kTimeOfDayHistogramHeight,
          child: CustomPaint(
            painter: _TimeOfDayHistogramPainter(
              counts: timeOfDayHistogram,
              barColor: cs.secondary,
              emptyColor: cs.onSurfaceVariant.withValues(
                alpha: kOpacitySubtleLow,
              ),
            ),
            child: Container(),
          ),
        ),
        const SizedBox(height: kSpacingXS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '12a',
              style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
            ),
            Text(
              '6a',
              style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
            ),
            Text(
              '12p',
              style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
            ),
            Text(
              '6p',
              style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
            ),
            Text(
              '12a',
              style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    List<double> adherenceData,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: helperTextStyle(context)?.copyWith(
            fontWeight: kFontWeightSemiBold,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
        ),
        const SizedBox(height: kSpacingS),
        _buildSummaryStats(context, adherenceData),
      ],
    );
  }

  Widget _buildStreaksSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final consistencySparkline = _calculateConsistencySparklineData(days: 14);
    final streakStats = _calculateStreakStats(consistencySparkline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streaks',
          style: helperTextStyle(context)?.copyWith(
            fontWeight: kFontWeightSemiBold,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
        ),
        const SizedBox(height: kSpacingXS),
        SizedBox(
          height: kConsistencySparklineHeight,
          child: CustomPaint(
            painter: _ConsistencySparklinePainter(
              data: consistencySparkline,
              color: cs.primary,
            ),
            child: Container(),
          ),
        ),
        const SizedBox(height: kSpacingS),
        _buildStreakStats(context, streakStats),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final actionBreakdown = _calculateActionBreakdown(days: 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Actions',
              style: helperTextStyle(context)?.copyWith(
                fontWeight: kFontWeightSemiBold,
                color: cs.onSurfaceVariant.withValues(
                  alpha: kOpacityMediumHigh,
                ),
              ),
            ),
            const SizedBox(width: kSpacingS),
            Text(
              '30d',
              style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: kSpacingS),
        Row(
          children: [
            Expanded(
              child: _buildStatChip(
                context,
                label: 'Taken',
                value: '${actionBreakdown.taken}',
                color: cs.primary,
              ),
            ),
            const SizedBox(width: kSpacingS),
            Expanded(
              child: _buildStatChip(
                context,
                label: 'Skipped',
                value: '${actionBreakdown.skipped}',
                color: cs.tertiary,
              ),
            ),
            const SizedBox(width: kSpacingS),
            Expanded(
              child: _buildStatChip(
                context,
                label: 'Snoozed',
                value: '${actionBreakdown.snoozed}',
                color: cs.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoseAmountSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doseTrend = _calculateDoseTrendData(days: 30, maxPoints: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Dose amount',
              style: helperTextStyle(context)?.copyWith(
                fontWeight: kFontWeightSemiBold,
                color: cs.onSurfaceVariant.withValues(
                  alpha: kOpacityMediumHigh,
                ),
              ),
            ),
            const SizedBox(width: kSpacingS),
            Text(
              '30d',
              style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
            ),
            if (doseTrend.unit != null) ...[
              const SizedBox(width: kSpacingS),
              Text(
                doseTrend.unit!,
                style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
        const SizedBox(height: kSpacingS),
        if (doseTrend.values.isEmpty)
          Text('No taken dose data yet', style: helperTextStyle(context))
        else ...[
          SizedBox(
            height: kDoseTrendChartHeight,
            child: CustomPaint(
              painter: _DoseTrendPainter(
                values: doseTrend.values,
                color: cs.primary,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: kSpacingS),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  context,
                  label: 'Min',
                  value: doseTrend.unit == null
                      ? _formatAmount(doseTrend.min)
                      : '${_formatAmount(doseTrend.min)} ${doseTrend.unit}',
                  color: cs.tertiary,
                ),
              ),
              const SizedBox(width: kSpacingS),
              Expanded(
                child: _buildStatChip(
                  context,
                  label: 'Avg',
                  value: doseTrend.unit == null
                      ? _formatAmount(doseTrend.avg)
                      : '${_formatAmount(doseTrend.avg)} ${doseTrend.unit}',
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: kSpacingS),
              Expanded(
                child: _buildStatChip(
                  context,
                  label: 'Max',
                  value: doseTrend.unit == null
                      ? _formatAmount(doseTrend.max)
                      : '${_formatAmount(doseTrend.max)} ${doseTrend.unit}',
                  color: cs.secondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDoseStrengthSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doseStrengthHistory = _calculateDoseStrengthHistoryData(days: 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Dose strength',
              style: helperTextStyle(context)?.copyWith(
                fontWeight: kFontWeightSemiBold,
                color: cs.onSurfaceVariant.withValues(
                  alpha: kOpacityMediumHigh,
                ),
              ),
            ),
            const SizedBox(width: kSpacingS),
            Text(
              '30d',
              style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
            ),
            if (doseStrengthHistory.unit != null) ...[
              const SizedBox(width: kSpacingS),
              Text(
                doseStrengthHistory.unit!,
                style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
        const SizedBox(height: kSpacingS),
        if (!doseStrengthHistory.hasData)
          Text(
            'No taken dose strength data yet',
            style: helperTextStyle(context),
          )
        else
          SizedBox(
            height: kDoseStrengthChartHeight,
            child: CustomPaint(
              painter: _DoseStrengthBarChartPainter(
                values: doseStrengthHistory.values,
                barColor: cs.primary,
                emptyColor: cs.onSurfaceVariant.withValues(
                  alpha: kOpacitySubtleLow,
                ),
              ),
              child: Container(),
            ),
          ),
      ],
    );
  }

  Widget _buildInventoryEventsSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inventoryEvents = _calculateInventoryEvents(
      days: 30,
      maxItems: _inventoryEventsMaxItems,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Inventory events',
              style: helperTextStyle(context)?.copyWith(
                fontWeight: kFontWeightSemiBold,
                color: cs.onSurfaceVariant.withValues(
                  alpha: kOpacityMediumHigh,
                ),
              ),
            ),
            const SizedBox(width: kSpacingS),
            Text(
              '30d',
              style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: kSpacingS),
        if (inventoryEvents.isEmpty)
          Text('No inventory events yet', style: helperTextStyle(context))
        else
          Column(
            children: [
              for (int i = 0; i < inventoryEvents.length; i++) ...[
                _buildInventoryEventRow(context, inventoryEvents[i]),
                if (i != inventoryEvents.length - 1)
                  Divider(
                    height: kSpacingS,
                    color: cs.outlineVariant.withValues(alpha: kOpacityVeryLow),
                  ),
              ],
            ],
          ),
      ],
    );
  }

  List<InventoryLog> _calculateInventoryEvents({
    required int days,
    required int maxItems,
  }) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    final inventoryLogBox = Hive.box<InventoryLog>('inventory_logs');

    final logs =
        inventoryLogBox.values
            .where((l) => l.medicationId == widget.medication.id)
            .where((l) => l.timestamp.isAfter(cutoff))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (logs.length <= maxItems) return logs;
    return logs.take(maxItems).toList();
  }

  Widget _buildInventoryEventRow(BuildContext context, InventoryLog log) {
    final cs = Theme.of(context).colorScheme;
    final timeFormat = DateFormat('h:mm a');

    final canEditAdHoc = log.changeType == InventoryChangeType.adHocDose;
    final linkedAdHocDoseLog = canEditAdHoc
        ? Hive.box<DoseLog>('dose_logs').get(log.id)
        : null;

    final icon = _getInventoryEventIcon(log.changeType);
    final color = _getInventoryEventColor(cs, log.changeType);

    final isDoseDeduct =
        log.changeType == InventoryChangeType.doseDeducted ||
        log.changeType == InventoryChangeType.adHocDose;
    final isEmptyStockDose = isDoseDeduct && log.previousStock <= 0;
    final description = isEmptyStockDose
        ? '${log.description} • empty stock'
        : log.description;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingXS / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NextDoseDateBadge(
            nextDose: log.timestamp,
            isActive: true,
            dense: true,
            showNextLabel: false,
          ),
          const SizedBox(width: kSpacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: bodyTextStyle(
                    context,
                  )?.copyWith(fontWeight: kFontWeightSemiBold),
                ),
                const SizedBox(height: kSpacingXS / 2),
                Text(
                  timeFormat.format(log.timestamp),
                  style: smallHelperTextStyle(
                    context,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (log.notes != null && log.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: kSpacingXS / 2),
                  Text(
                    log.notes!.trim(),
                    style: smallHelperTextStyle(
                      context,
                      color: cs.onSurfaceVariant,
                    )?.copyWith(fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: kSpacingS),
          Container(
            width: kStepperButtonSize,
            height: kStepperButtonSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: kOpacitySubtle),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: kIconSizeSmall, color: color),
          ),
          if (linkedAdHocDoseLog != null) ...[
            const SizedBox(width: kSpacingXS),
            _buildEditIndicatorIcon(context),
          ],
        ],
      ),
    );

    if (linkedAdHocDoseLog == null) return row;
    return InkWell(
      onTap: () =>
          _showUniversalDoseActionSheetForLog(context, linkedAdHocDoseLog),
      child: row,
    );
  }

  IconData _getInventoryEventIcon(InventoryChangeType type) {
    switch (type) {
      case InventoryChangeType.refillAdd:
      case InventoryChangeType.refillToMax:
        return Icons.add_circle_outline;
      case InventoryChangeType.doseDeducted:
      case InventoryChangeType.adHocDose:
        return Icons.remove_circle_outline;
      case InventoryChangeType.manualAdjustment:
        return Icons.tune;
      case InventoryChangeType.vialOpened:
        return Icons.vaccines_outlined;
      case InventoryChangeType.vialRestocked:
        return Icons.inventory_2_outlined;
      case InventoryChangeType.expired:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getInventoryEventColor(ColorScheme cs, InventoryChangeType type) {
    switch (type) {
      case InventoryChangeType.refillAdd:
      case InventoryChangeType.refillToMax:
      case InventoryChangeType.vialRestocked:
        return cs.primary;
      case InventoryChangeType.doseDeducted:
      case InventoryChangeType.adHocDose:
      case InventoryChangeType.expired:
        return cs.error;
      case InventoryChangeType.vialOpened:
        return cs.secondary;
      case InventoryChangeType.manualAdjustment:
        return cs.tertiary;
    }
  }

  Widget _buildSummaryStats(BuildContext context, List<double> data) {
    final cs = Theme.of(context).colorScheme;

    final validDays = data.where((v) => v >= 0).toList();
    final average = validDays.isEmpty
        ? 0.0
        : validDays.reduce((a, b) => a + b) / validDays.length;
    final perfectDays = data.where((v) => v >= 1.0).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            context,
            label: 'Average',
            value: '${(average * 100).toInt()}%',
            color: _getAdherenceColor(cs, (average * 100).toInt()),
          ),
        ),
        const SizedBox(width: kSpacingS),
        Expanded(
          child: _buildStatChip(
            context,
            label: 'Perfect',
            value: '$perfectDays days',
            color: cs.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakStats(BuildContext context, _StreakStats stats) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            context,
            label: 'Current',
            value: '${stats.currentStreakDays} days',
            color: cs.primary,
          ),
        ),
        const SizedBox(width: kSpacingS),
        Expanded(
          child: _buildStatChip(
            context,
            label: 'Consistency',
            value: '${stats.consistencyPct}%',
            color: _getAdherenceColor(cs, stats.consistencyPct),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: kFieldContentPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: kOpacitySubtleLow),
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: helperTextStyle(context, color: color)),
          const SizedBox(width: kFieldSpacing),
          Text(
            value,
            style: bodyTextStyle(
              context,
            )?.copyWith(color: color, fontWeight: kFontWeightSemiBold),
          ),
        ],
      ),
    );
  }

  int _getAveragePercentage(List<double> data) {
    final validDays = data.where((v) => v >= 0).toList();
    if (validDays.isEmpty) return 0;
    return ((validDays.reduce((a, b) => a + b) / validDays.length) * 100)
        .toInt();
  }

  Color _getAdherenceColor(ColorScheme cs, int percentage) {
    if (percentage >= 80) return cs.primary;
    if (percentage >= 50) return cs.tertiary;
    return cs.error;
  }

  List<double> _calculateAdherenceData() {
    final now = DateTime.now();
    final doseLogBox = Hive.box<DoseLog>('dose_logs');
    final scheduleBox = Hive.box<Schedule>('schedules');

    final schedules = scheduleBox.values
        .where((s) => s.medicationId == widget.medication.id && s.active)
        .toList();

    if (schedules.isEmpty) return List.filled(7, -1.0);

    final adherenceData = <double>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));

      int expectedDoses = 0;
      int takenDoses = 0;

      for (final schedule in schedules) {
        if (!schedule.daysOfWeek.contains(day.weekday)) continue;
        final timesPerDay = schedule.timesOfDay?.length ?? 1;
        expectedDoses += timesPerDay;
      }

      final dayLogs = doseLogBox.values.where(
        (log) =>
            log.medicationId == widget.medication.id &&
            log.scheduledTime.isAfter(
              day.subtract(const Duration(seconds: 1)),
            ) &&
            log.scheduledTime.isBefore(dayEnd),
      );

      takenDoses = dayLogs
          .where((log) => log.action == DoseAction.taken)
          .length;

      if (expectedDoses == 0) {
        adherenceData.add(-1.0);
      } else {
        adherenceData.add((takenDoses / expectedDoses).clamp(0.0, 1.0));
      }
    }

    return adherenceData;
  }

  List<double> _calculateConsistencySparklineData({required int days}) {
    final now = DateTime.now();
    final doseLogBox = Hive.box<DoseLog>('dose_logs');
    final scheduleBox = Hive.box<Schedule>('schedules');

    final schedules = scheduleBox.values
        .where((s) => s.medicationId == widget.medication.id && s.active)
        .toList();

    if (schedules.isEmpty) return List.filled(days, -1.0);

    final data = <double>[];

    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));

      int expectedDoses = 0;
      for (final schedule in schedules) {
        if (!schedule.daysOfWeek.contains(day.weekday)) continue;
        final timesPerDay = schedule.timesOfDay?.length ?? 1;
        expectedDoses += timesPerDay;
      }

      final dayLogs = doseLogBox.values.where(
        (log) =>
            log.medicationId == widget.medication.id &&
            log.scheduledTime.isAfter(
              day.subtract(const Duration(seconds: 1)),
            ) &&
            log.scheduledTime.isBefore(dayEnd),
      );

      final taken = dayLogs.where((l) => l.action == DoseAction.taken).length;

      if (expectedDoses == 0) {
        data.add(-1.0);
      } else {
        data.add((taken / expectedDoses).clamp(0.0, 1.0));
      }
    }

    return data;
  }

  _StreakStats _calculateStreakStats(List<double> data) {
    final valid = data.where((v) => v >= 0).toList();
    final consistency = valid.isEmpty
        ? 0
        : ((valid.reduce((a, b) => a + b) / valid.length) * 100).toInt();

    int current = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      final v = data[i];
      if (v < 0) continue;
      if (v >= 0.999) {
        current++;
      } else {
        break;
      }
    }

    int best = 0;
    int run = 0;
    for (final v in data) {
      if (v < 0) continue;
      if (v >= 0.999) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }

    return _StreakStats(
      currentStreakDays: current,
      bestStreakDays: best,
      consistencyPct: consistency,
    );
  }

  List<_TakenMissedDay> _calculateTakenMissedData() {
    final now = DateTime.now();
    final doseLogBox = Hive.box<DoseLog>('dose_logs');
    final scheduleBox = Hive.box<Schedule>('schedules');

    final schedules = scheduleBox.values
        .where((s) => s.medicationId == widget.medication.id && s.active)
        .toList();

    if (schedules.isEmpty) {
      return List.generate(
        7,
        (_) => const _TakenMissedDay(expected: 0, taken: 0),
      );
    }

    final days = <_TakenMissedDay>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));

      int expectedDoses = 0;
      for (final schedule in schedules) {
        if (!schedule.daysOfWeek.contains(day.weekday)) continue;
        final timesPerDay = schedule.timesOfDay?.length ?? 1;
        expectedDoses += timesPerDay;
      }

      final dayLogs = doseLogBox.values.where(
        (log) =>
            log.medicationId == widget.medication.id &&
            log.scheduledTime.isAfter(
              day.subtract(const Duration(seconds: 1)),
            ) &&
            log.scheduledTime.isBefore(dayEnd),
      );

      final taken = dayLogs.where((l) => l.action == DoseAction.taken).length;
      days.add(
        _TakenMissedDay(
          expected: expectedDoses,
          taken: expectedDoses == 0 ? 0 : taken.clamp(0, expectedDoses),
        ),
      );
    }

    return days;
  }

  List<int> _calculateTakenTimeOfDayHistogram() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));
    final doseLogBox = Hive.box<DoseLog>('dose_logs');

    final counts = List<int>.filled(24, 0);

    final takenLogs = doseLogBox.values.where(
      (log) =>
          log.medicationId == widget.medication.id &&
          log.action == DoseAction.taken &&
          log.actionTime.isAfter(cutoff),
    );

    for (final log in takenLogs) {
      final hour = log.actionTime.hour;
      if (hour >= 0 && hour < 24) {
        counts[hour] = counts[hour] + 1;
      }
    }

    return counts;
  }

  _ActionBreakdown _calculateActionBreakdown({required int days}) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    final doseLogBox = Hive.box<DoseLog>('dose_logs');

    int taken = 0;
    int skipped = 0;
    int snoozed = 0;

    final logs = doseLogBox.values.where(
      (log) =>
          log.medicationId == widget.medication.id &&
          log.actionTime.isAfter(cutoff),
    );

    for (final log in logs) {
      switch (log.action) {
        case DoseAction.taken:
          taken++;
          break;
        case DoseAction.skipped:
          skipped++;
          break;
        case DoseAction.snoozed:
          snoozed++;
          break;
      }
    }

    return _ActionBreakdown(taken: taken, skipped: skipped, snoozed: snoozed);
  }

  _DoseTrendData _calculateDoseTrendData({
    required int days,
    required int maxPoints,
  }) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    final doseLogBox = Hive.box<DoseLog>('dose_logs');

    final takenLogs =
        doseLogBox.values
            .where(
              (log) =>
                  log.medicationId == widget.medication.id &&
                  log.action == DoseAction.taken &&
                  log.actionTime.isAfter(cutoff),
            )
            .toList()
          ..sort((a, b) => a.actionTime.compareTo(b.actionTime));

    if (takenLogs.isEmpty) return const _DoseTrendData.empty();

    final unitCounts = <String, int>{};
    for (final log in takenLogs) {
      final unit = (log.actualDoseUnit ?? log.doseUnit).trim();
      if (unit.isEmpty) continue;
      unitCounts[unit] = (unitCounts[unit] ?? 0) + 1;
    }

    String? modeUnit;
    int modeCount = 0;
    for (final entry in unitCounts.entries) {
      if (entry.value > modeCount) {
        modeUnit = entry.key;
        modeCount = entry.value;
      }
    }

    final filtered = modeUnit == null
        ? takenLogs
        : takenLogs
              .where((l) => (l.actualDoseUnit ?? l.doseUnit).trim() == modeUnit)
              .toList();

    if (filtered.isEmpty) return const _DoseTrendData.empty();

    final recent = filtered.length > maxPoints
        ? filtered.sublist(filtered.length - maxPoints)
        : filtered;

    final values = <double>[];
    for (final log in recent) {
      values.add(log.actualDoseValue ?? log.doseValue);
    }

    if (values.isEmpty) return const _DoseTrendData.empty();

    double min = values.first;
    double max = values.first;
    double sum = 0;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
      sum += v;
    }

    final avg = sum / values.length;

    return _DoseTrendData(
      values: values,
      unit: modeUnit,
      min: min,
      max: max,
      avg: avg,
    );
  }

  String _formatAmount(double value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  _DoseStrengthHistoryData _calculateDoseStrengthHistoryData({
    required int days,
  }) {
    final now = DateTime.now();
    final startDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    final doseLogBox = Hive.box<DoseLog>('dose_logs');
    final med = widget.medication;

    final isUnitsBased =
        med.strengthUnit == Unit.units || med.strengthUnit == Unit.unitsPerMl;

    final totalsByDay = <DateTime, double>{};
    final takenLogs = doseLogBox.values.where(
      (log) =>
          log.medicationId == med.id &&
          log.action == DoseAction.taken &&
          log.actionTime.isAfter(startDay),
    );

    for (final log in takenLogs) {
      final baseValue = _tryGetDoseStrengthBaseValue(
        log: log,
        unitsBased: isUnitsBased,
      );
      if (baseValue == null) continue;

      final dayKey = DateTime(
        log.actionTime.year,
        log.actionTime.month,
        log.actionTime.day,
      );
      totalsByDay[dayKey] = (totalsByDay[dayKey] ?? 0) + baseValue;
    }

    final baseSeries = <double>[];
    for (int i = 0; i < days; i++) {
      final day = startDay.add(Duration(days: i));
      baseSeries.add(totalsByDay[day] ?? 0);
    }

    double maxBase = 0;
    for (final v in baseSeries) {
      if (v > maxBase) maxBase = v;
    }

    String? unit;
    double scale = 1;
    if (isUnitsBased) {
      unit = 'units';
      scale = 1;
    } else {
      if (maxBase >= 1000000) {
        unit = 'g';
        scale = 1000000;
      } else if (maxBase >= 1000) {
        unit = 'mg';
        scale = 1000;
      } else {
        unit = 'mcg';
        scale = 1;
      }
    }

    final values = baseSeries.map((v) => v / scale).toList();
    final hasData = values.any((v) => v > 0);
    return _DoseStrengthHistoryData(
      values: values,
      unit: unit,
      hasData: hasData,
    );
  }

  double? _tryGetDoseStrengthBaseValue({
    required DoseLog log,
    required bool unitsBased,
  }) {
    final med = widget.medication;
    final value = log.actualDoseValue ?? log.doseValue;
    final unit = _normalizeUnit(log.actualDoseUnit ?? log.doseUnit);

    if (unitsBased) {
      if (unit == 'units' || unit == 'iu') {
        return value;
      }

      if (unit == 'ml') {
        final unitsPerMl = _getConcentrationUnitsPerMl(med);
        if (unitsPerMl == null) return null;
        return value * unitsPerMl;
      }

      if (unit == 'syringe' ||
          unit == 'syringes' ||
          unit == 'vial' ||
          unit == 'vials') {
        final unitsPerMl = _getConcentrationUnitsPerMl(med);
        final volumePerDose = med.volumePerDose;
        if (unitsPerMl == null || volumePerDose == null) return null;
        return value * volumePerDose * unitsPerMl;
      }

      return null;
    }

    if (unit == 'mcg') return value;
    if (unit == 'mg') return value * 1000;
    if (unit == 'g') return value * 1000000;

    if (unit == 'ml') {
      final mcgPerMl = _getConcentrationMcgPerMl(med);
      if (mcgPerMl == null) return null;
      return value * mcgPerMl;
    }

    if (unit == 'tablet' ||
        unit == 'tablets' ||
        unit == 'capsule' ||
        unit == 'capsules') {
      final mcgPerItem = _getPerItemStrengthMcg(med);
      if (mcgPerItem == null) return null;
      return value * mcgPerItem;
    }

    if (unit == 'syringe' ||
        unit == 'syringes' ||
        unit == 'vial' ||
        unit == 'vials') {
      final mcgPerMl = _getConcentrationMcgPerMl(med);
      final volumePerDose = med.volumePerDose;
      if (mcgPerMl == null || volumePerDose == null) return null;
      return value * volumePerDose * mcgPerMl;
    }

    return null;
  }

  String _normalizeUnit(String raw) {
    final u = raw.trim().toLowerCase();
    if (u == 'mL'.toLowerCase()) return 'ml';
    return u;
  }

  double? _getPerItemStrengthMcg(Medication med) {
    switch (med.strengthUnit) {
      case Unit.mcg:
        return med.strengthValue;
      case Unit.mg:
        return med.strengthValue * 1000;
      case Unit.g:
        return med.strengthValue * 1000000;
      case Unit.units:
      case Unit.mcgPerMl:
      case Unit.mgPerMl:
      case Unit.gPerMl:
      case Unit.unitsPerMl:
        return null;
    }
  }

  double? _getConcentrationMcgPerMl(Medication med) {
    switch (med.strengthUnit) {
      case Unit.mcgPerMl:
        return med.strengthValue;
      case Unit.mgPerMl:
        return med.strengthValue * 1000;
      case Unit.gPerMl:
        return med.strengthValue * 1000000;
      case Unit.unitsPerMl:
        return null;
      case Unit.mcg:
        return med.perMlValue;
      case Unit.mg:
        return med.perMlValue == null ? null : (med.perMlValue! * 1000);
      case Unit.g:
        return med.perMlValue == null ? null : (med.perMlValue! * 1000000);
      case Unit.units:
        return null;
    }
  }

  double? _getConcentrationUnitsPerMl(Medication med) {
    switch (med.strengthUnit) {
      case Unit.unitsPerMl:
        return med.strengthValue;
      case Unit.units:
        return med.perMlValue;
      case Unit.mcg:
      case Unit.mg:
      case Unit.g:
      case Unit.mcgPerMl:
      case Unit.mgPerMl:
      case Unit.gPerMl:
        return null;
    }
  }
}

class _DoseStrengthHistoryData {
  const _DoseStrengthHistoryData({
    required this.values,
    required this.unit,
    required this.hasData,
  });

  final List<double> values;
  final String? unit;
  final bool hasData;
}

enum _AdherenceReportSection {
  adherence,
  takenMissed,
  timeOfDay,
  summary,
  streaks,
  actions,
  doseAmount,
  doseStrength,
  inventoryEvents,
}

extension _AdherenceReportSectionX on _AdherenceReportSection {
  String get label {
    switch (this) {
      case _AdherenceReportSection.adherence:
        return 'Adherence';
      case _AdherenceReportSection.takenMissed:
        return 'Taken/Missed';
      case _AdherenceReportSection.timeOfDay:
        return 'Time of Day';
      case _AdherenceReportSection.summary:
        return 'Summary';
      case _AdherenceReportSection.streaks:
        return 'Streaks';
      case _AdherenceReportSection.actions:
        return 'Actions';
      case _AdherenceReportSection.doseAmount:
        return 'Dose Amount';
      case _AdherenceReportSection.doseStrength:
        return 'Dose Strength';
      case _AdherenceReportSection.inventoryEvents:
        return 'Inventory';
    }
  }
}

class _StreakStats {
  const _StreakStats({
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.consistencyPct,
  });

  final int currentStreakDays;
  final int bestStreakDays;
  final int consistencyPct;
}

class _ActionBreakdown {
  const _ActionBreakdown({
    required this.taken,
    required this.skipped,
    required this.snoozed,
  });

  final int taken;
  final int skipped;
  final int snoozed;
}

class _DoseTrendData {
  const _DoseTrendData({
    required this.values,
    required this.unit,
    required this.min,
    required this.max,
    required this.avg,
  });

  const _DoseTrendData.empty()
    : values = const [],
      unit = null,
      min = 0,
      max = 0,
      avg = 0;

  final List<double> values;
  final String? unit;
  final double min;
  final double max;
  final double avg;
}

class _AdherenceLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _AdherenceLinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kAdherenceChartLineStrokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final spacing = width / (data.length - 1);

    // Draw background grid
    final gridPaint = Paint()
      ..color = color.withValues(alpha: kOpacitySubtleLow)
      ..strokeWidth = kAdherenceChartGridStrokeWidth;

    for (int i = 0; i <= 4; i++) {
      final y = height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Build paths
    final linePath = Path();
    final areaPath = Path();
    bool hasStarted = false;

    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      if (value < 0) continue;

      final x = i * spacing;
      final y =
          height -
          (value * height * kAdherenceChartValueScale) -
          (height * kAdherenceChartVerticalPaddingFraction);

      if (!hasStarted) {
        linePath.moveTo(x, y);
        areaPath.moveTo(x, height);
        areaPath.lineTo(x, y);
        hasStarted = true;
      } else {
        linePath.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }

    if (hasStarted) {
      areaPath.lineTo((data.length - 1) * spacing, height);
      areaPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: kOpacityVeryLow),
          color.withValues(alpha: kOpacityFaint),
        ],
      );

      fillPaint.shader = gradient.createShader(
        Rect.fromLTWH(0, 0, width, height),
      );
      canvas.drawPath(areaPath, fillPaint);

      paint.color = color.withValues(alpha: kOpacityEmphasis);
      canvas.drawPath(linePath, paint);

      // Draw points
      for (int i = 0; i < data.length; i++) {
        final value = data[i];
        if (value < 0) continue;

        final x = i * spacing;
        final y =
            height -
            (value * height * kAdherenceChartValueScale) -
            (height * kAdherenceChartVerticalPaddingFraction);

        canvas.drawCircle(
          Offset(x, y),
          kAdherenceChartPointOuterRadius,
          Paint()
            ..color = color.withValues(alpha: kOpacityEmphasis)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          Offset(x, y),
          kAdherenceChartPointInnerRadius,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AdherenceLinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

class _TakenMissedDay {
  const _TakenMissedDay({required this.expected, required this.taken});

  final int expected;
  final int taken;

  int get missed => (expected - taken).clamp(0, expected);
}

class _TakenMissedStackedBarPainter extends CustomPainter {
  _TakenMissedStackedBarPainter({
    required this.data,
    required this.takenColor,
    required this.missedColor,
    required this.emptyColor,
  });

  final List<_TakenMissedDay> data;
  final Color takenColor;
  final Color missedColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final spacing = kTakenMissedChartBarSpacing;
    final totalBars = data.length;
    final barWidth =
        (size.width - (spacing * (totalBars - 1))) / totalBars.toDouble();
    final radius = Radius.circular(kTakenMissedChartBarRadius);

    final takenPaint = Paint()
      ..color = takenColor.withValues(alpha: kOpacityEmphasis);
    final missedPaint = Paint()
      ..color = missedColor.withValues(alpha: kOpacityMediumHigh);
    final emptyPaint = Paint()..color = emptyColor;

    for (int i = 0; i < totalBars; i++) {
      final d = data[i];
      final x = i * (barWidth + spacing);

      final rect = Rect.fromLTWH(x, 0, barWidth, size.height);
      final background = RRect.fromRectAndRadius(rect, radius);
      canvas.drawRRect(background, emptyPaint);

      if (d.expected <= 0) continue;

      final takenFrac = d.taken / d.expected;
      final missedFrac = d.missed / d.expected;

      final missedHeight = size.height * missedFrac;
      final takenHeight = size.height * takenFrac;

      // Missed segment (bottom)
      if (missedHeight > 0) {
        final missedRect = Rect.fromLTWH(
          x,
          size.height - missedHeight,
          barWidth,
          missedHeight,
        );
        final missedRRect = RRect.fromRectAndCorners(
          missedRect,
          bottomLeft: radius,
          bottomRight: radius,
          topLeft: Radius.zero,
          topRight: Radius.zero,
        );
        canvas.drawRRect(missedRRect, missedPaint);
      }

      // Taken segment (top)
      if (takenHeight > 0) {
        final takenRect = Rect.fromLTWH(
          x,
          size.height - missedHeight - takenHeight,
          barWidth,
          takenHeight,
        );
        final takenRRect = RRect.fromRectAndCorners(
          takenRect,
          topLeft: radius,
          topRight: radius,
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero,
        );
        canvas.drawRRect(takenRRect, takenPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TakenMissedStackedBarPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.takenColor != takenColor ||
        oldDelegate.missedColor != missedColor ||
        oldDelegate.emptyColor != emptyColor;
  }
}

class _TimeOfDayHistogramPainter extends CustomPainter {
  _TimeOfDayHistogramPainter({
    required this.counts,
    required this.barColor,
    required this.emptyColor,
  });

  final List<int> counts;
  final Color barColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty) return;
    final bars = counts.length;
    if (bars <= 1) return;

    final spacing = kTimeOfDayHistogramBarSpacing;
    final barWidth = (size.width - (spacing * (bars - 1))) / bars.toDouble();
    final radius = Radius.circular(kTimeOfDayHistogramBarRadius);

    final maxCount = counts.fold<int>(0, (m, v) => v > m ? v : m);

    final emptyPaint = Paint()..color = emptyColor;
    final barPaint = Paint()
      ..color = barColor.withValues(alpha: kOpacityEmphasis);

    for (int i = 0; i < bars; i++) {
      final x = i * (barWidth + spacing);
      final fullRect = Rect.fromLTWH(x, 0, barWidth, size.height);
      canvas.drawRRect(RRect.fromRectAndRadius(fullRect, radius), emptyPaint);

      final c = counts[i];
      if (c <= 0 || maxCount <= 0) continue;

      final frac = c / maxCount;
      final h = (size.height * frac).clamp(1.0, size.height);
      final barRect = Rect.fromLTWH(x, size.height - h, barWidth, h);
      canvas.drawRRect(RRect.fromRectAndRadius(barRect, radius), barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimeOfDayHistogramPainter oldDelegate) {
    return oldDelegate.counts != counts ||
        oldDelegate.barColor != barColor ||
        oldDelegate.emptyColor != emptyColor;
  }
}

class _ConsistencySparklinePainter extends CustomPainter {
  _ConsistencySparklinePainter({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kConsistencySparklineStrokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: kOpacityEmphasis);

    final width = size.width;
    final height = size.height;
    if (data.length == 1) return;

    final spacing = width / (data.length - 1);
    final path = Path();
    bool hasStarted = false;

    for (int i = 0; i < data.length; i++) {
      final v = data[i];
      if (v < 0) continue;

      final x = i * spacing;
      final y =
          height -
          (v *
              height *
              (1 - (2 * kConsistencySparklineVerticalPaddingFraction))) -
          (height * kConsistencySparklineVerticalPaddingFraction);

      if (!hasStarted) {
        path.moveTo(x, y);
        hasStarted = true;
      } else {
        path.lineTo(x, y);
      }
    }

    if (!hasStarted) return;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConsistencySparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

class _DoseTrendPainter extends CustomPainter {
  _DoseTrendPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    double min = values.first;
    double max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }

    final range = (max - min).abs();
    final safeRange = range < 0.000001 ? 1.0 : range;

    final width = size.width;
    final height = size.height;
    final spacing = width / (values.length - 1);
    final padFrac = kDoseTrendChartVerticalPaddingFraction;

    final gridPaint = Paint()
      ..color = color.withValues(alpha: kOpacitySubtleLow)
      ..strokeWidth = kAdherenceChartGridStrokeWidth;

    canvas.drawLine(
      Offset(0, height / 2),
      Offset(width, height / 2),
      gridPaint,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kDoseTrendChartStrokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: kOpacityEmphasis);

    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: kOpacityEmphasis);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * spacing;
      final frac = ((values[i] - min) / safeRange).clamp(0.0, 1.0);
      final usableHeight = height * (1 - (2 * padFrac));
      final y = height - (frac * usableHeight) - (height * padFrac);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    for (int i = 0; i < values.length; i++) {
      final x = i * spacing;
      final frac = ((values[i] - min) / safeRange).clamp(0.0, 1.0);
      final usableHeight = height * (1 - (2 * padFrac));
      final y = height - (frac * usableHeight) - (height * padFrac);
      canvas.drawCircle(Offset(x, y), kDoseTrendChartPointRadius, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DoseTrendPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _DoseStrengthBarChartPainter extends CustomPainter {
  _DoseStrengthBarChartPainter({
    required this.values,
    required this.barColor,
    required this.emptyColor,
  });

  final List<double> values;
  final Color barColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    double maxValue = 0;
    for (final v in values) {
      if (v > maxValue) maxValue = v;
    }

    final barCount = values.length;
    final spacing = kDoseStrengthChartBarSpacing;
    final totalSpacing = spacing * (barCount - 1);
    final barWidth = ((size.width - totalSpacing) / barCount).clamp(
      1.0,
      size.width,
    );
    final radius = Radius.circular(kDoseStrengthChartBarRadius);

    final fillPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final v = values[i];
      if (v <= 0 || maxValue <= 0) continue;

      final frac = (v / maxValue).clamp(0.0, 1.0);
      final h = (frac * size.height).clamp(1.0, size.height);
      final x = i * (barWidth + spacing);
      final rect = Rect.fromLTWH(x, size.height - h, barWidth, h);

      fillPaint.color = barColor.withValues(alpha: kOpacityEmphasis);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), fillPaint);
    }

    if (maxValue <= 0) {
      final baselinePaint = Paint()
        ..color = emptyColor
        ..strokeWidth = kAdherenceChartGridStrokeWidth;
      canvas.drawLine(
        Offset(0, size.height - 1),
        Offset(size.width, size.height - 1),
        baselinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DoseStrengthBarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.barColor != barColor ||
        oldDelegate.emptyColor != emptyColor;
  }
}
