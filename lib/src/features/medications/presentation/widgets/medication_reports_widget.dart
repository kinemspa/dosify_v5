// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';

/// Comprehensive reports widget with tabs for History, Adherence, and future analytics
/// Replaces DoseHistoryWidget with expanded functionality
class MedicationReportsWidget extends StatefulWidget {
  const MedicationReportsWidget({required this.medication, super.key});

  final Medication medication;

  @override
  State<MedicationReportsWidget> createState() =>
      _MedicationReportsWidgetState();
}

class _MedicationReportsWidgetState extends State<MedicationReportsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = true; // Collapsible state

  static const int _historyPageStep = 25;
  int _historyMaxItems = _historyPageStep;
  String? _expandedHistoryLogId;
  bool _historyHorizontalView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // History + Adherence
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: buildStandardCardDecoration(context: context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsible header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingL,
                vertical: kSpacingM,
              ),
              child: Row(
                children: [
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
                    turns: _isExpanded ? 0 : -0.25,
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
          // Collapsible content
          AnimatedCrossFade(
            duration: kAnimationNormal,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tab bar
                TabBar(
                  controller: _tabController,
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  indicatorColor: cs.primary,
                  dividerColor: cs.surface.withValues(
                    alpha: kOpacityTransparent,
                  ),
                  labelStyle: helperTextStyle(context)?.copyWith(
                    fontSize: kFontSizeMedium,
                    fontWeight: kFontWeightSemiBold,
                  ),
                  tabs: const [
                    Tab(
                      text: 'History',
                      icon: Icon(Icons.history, size: kIconSizeMedium),
                    ),
                    Tab(
                      text: 'Adherence',
                      icon: Icon(
                        Icons.analytics_outlined,
                        size: kIconSizeMedium,
                      ),
                    ),
                  ],
                ),
                // Tab content
                SizedBox(
                  height: kMedicationReportsTabHeight,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHistoryTab(context),
                      _buildAdherenceTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doseLogBox = Hive.box<DoseLog>('dose_logs');

    // Get dose logs for this medication
    final logs =
        doseLogBox.values
            .where((log) => log.medicationId == widget.medication.id)
            .toList()
          ..sort((a, b) => b.actionTime.compareTo(a.actionTime));

    final displayLogs = logs.take(_historyMaxItems).toList();
    final hasMore = displayLogs.length < logs.length;

    if (displayLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_outlined,
              size: kEmptyStateIconSize,
              color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
            ),
            const SizedBox(height: kSpacingM),
            Text('No dose history', style: helperTextStyle(context)),
            const SizedBox(height: kSpacingXS),
            Text(
              'Recorded doses will appear here',
              style: helperTextStyle(
                context,
              )?.copyWith(fontSize: kFontSizeSmall),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kSpacingS,
            kSpacingXS,
            kSpacingS,
            kSpacingXS,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Change view',
              onPressed: () {
                setState(() {
                  _historyHorizontalView = !_historyHorizontalView;
                });
              },
              icon: Icon(
                _historyHorizontalView
                    ? Icons.view_day_outlined
                    : Icons.view_agenda_outlined,
                size: kIconSizeMedium,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(kSpacingS),
            itemCount: displayLogs.length + (hasMore ? 1 : 0),
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: kOpacityVeryLow),
            ),
            itemBuilder: (context, index) {
              if (hasMore && index == displayLogs.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: kSpacingS),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _historyMaxItems += _historyPageStep;
                        });
                      },
                      icon: const Icon(Icons.expand_more, size: kIconSizeSmall),
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
              final log = displayLogs[index];
              return _buildDoseLogItem(context, log);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDoseLogItem(BuildContext context, DoseLog log) {
    if (_historyHorizontalView) {
      return _buildDoseLogItemHorizontal(context, log);
    }

    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final isExpanded = _expandedHistoryLogId == log.id;

    final IconData icon;
    final Color iconColor;
    switch (log.action) {
      case DoseAction.taken:
        icon = Icons.check_circle_outline;
        iconColor = cs.primary;
        break;
      case DoseAction.skipped:
        icon = Icons.cancel_outlined;
        iconColor = cs.tertiary;
        break;
      case DoseAction.snoozed:
        icon = Icons.snooze;
        iconColor = cs.secondary;
        break;
    }

    final displayValue = log.actualDoseValue ?? log.doseValue;
    final displayUnit = log.actualDoseUnit ?? log.doseUnit;

    return InkWell(
      onTap: () {
        setState(() {
          _expandedHistoryLogId = isExpanded ? null : log.id;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: kStepperButtonSize,
                  height: kStepperButtonSize,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: kOpacitySubtle),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: kIconSizeSmall, color: iconColor),
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
                          Text(displayUnit, style: helperTextStyle(context)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSpacingXS,
                              vertical: kSpacingXS / 2,
                            ),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(
                                alpha: kOpacitySubtle,
                              ),
                              borderRadius: BorderRadius.circular(
                                kBorderRadiusChip,
                              ),
                            ),
                            child: Text(
                              log.action.name,
                              style: helperTextStyle(context, color: iconColor)
                                  ?.copyWith(
                                    fontSize: kFontSizeHint,
                                    fontWeight: kFontWeightBold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: kSpacingXS),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: kIconSizeMedium,
                            color: cs.onSurfaceVariant.withValues(
                              alpha: kOpacityMediumLow,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: kSpacingXS),
                      Row(
                        children: [
                          Text(
                            dateFormat.format(log.actionTime),
                            style: helperTextStyle(
                              context,
                            )?.copyWith(fontSize: kFontSizeSmall),
                          ),
                          const SizedBox(width: kSpacingS),
                          Text(
                            timeFormat.format(log.actionTime),
                            style: helperTextStyle(
                              context,
                            )?.copyWith(fontSize: kFontSizeSmall),
                          ),
                        ],
                      ),
                      if (!isExpanded &&
                          log.notes != null &&
                          log.notes!.isNotEmpty) ...[
                        const SizedBox(height: kSpacingXS),
                        Text(
                          log.notes!,
                          style: helperTextStyle(context)?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: kFontSizeSmall,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: kAnimationFast,
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(
                  kStepperButtonSize + kSpacingS,
                  kSpacingS,
                  0,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.scheduleName,
                      style: bodyTextStyle(
                        context,
                      )?.copyWith(fontWeight: kFontWeightSemiBold),
                    ),
                    const SizedBox(height: kSpacingXS),
                    Text(
                      'Scheduled: ${dateFormat.format(log.scheduledTime)} • ${timeFormat.format(log.scheduledTime)}',
                      style: helperTextStyle(context),
                    ),
                    Text(
                      'Recorded: ${dateFormat.format(log.actionTime)} • ${timeFormat.format(log.actionTime)}',
                      style: helperTextStyle(context),
                    ),
                    const SizedBox(height: kSpacingXS),
                    Text(
                      log.action == DoseAction.taken
                          ? (log.wasOnTime
                                ? 'On time'
                                : 'Offset: ${log.minutesOffset} min')
                          : 'Action: ${log.action.name}',
                      style: helperTextStyle(
                        context,
                        color: cs.onSurfaceVariant.withValues(
                          alpha: kOpacityMediumHigh,
                        ),
                      ),
                    ),
                    if (log.notes != null && log.notes!.isNotEmpty) ...[
                      const SizedBox(height: kSpacingS),
                      Text(
                        log.notes!,
                        style: helperTextStyle(
                          context,
                        )?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: kSpacingS),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () =>
                            _showUniversalDoseActionSheetForLog(context, log),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: kIconSizeSmall,
                          color: cs.primary,
                        ),
                        label: Text(
                          'Edit',
                          style: helperTextStyle(
                            context,
                            color: cs.primary,
                          )?.copyWith(fontWeight: kFontWeightSemiBold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseLogItemHorizontal(BuildContext context, DoseLog log) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final isExpanded = _expandedHistoryLogId == log.id;

    final IconData icon;
    final Color iconColor;
    switch (log.action) {
      case DoseAction.taken:
        icon = Icons.check_circle_outline;
        iconColor = cs.primary;
        break;
      case DoseAction.skipped:
        icon = Icons.cancel_outlined;
        iconColor = cs.tertiary;
        break;
      case DoseAction.snoozed:
        icon = Icons.snooze;
        iconColor = cs.secondary;
        break;
    }

    final displayValue = log.actualDoseValue ?? log.doseValue;
    final displayUnit = log.actualDoseUnit ?? log.doseUnit;

    final dayNumber = DateFormat('d').format(log.actionTime);
    final monthName = DateFormat('MMM').format(log.actionTime);

    return InkWell(
      onTap: () {
        setState(() {
          _expandedHistoryLogId = isExpanded ? null : log.id;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: kNextDoseDateCircleSizeCompact,
                  child: Column(
                    children: [
                      Container(
                        width: kNextDoseDateCircleSizeCompact,
                        height: kNextDoseDateCircleSizeCompact,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: kOpacitySubtle),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          dayNumber,
                          style: cardTitleStyle(context)?.copyWith(
                            fontWeight: kFontWeightBold,
                            color: iconColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: kSpacingXS),
                      Text(
                        monthName,
                        style:
                            helperTextStyle(
                              context,
                              color: cs.onSurfaceVariant,
                            )?.copyWith(
                              fontSize: kFontSizeHint,
                              fontWeight: kFontWeightSemiBold,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: kSpacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: kIconSizeSmall, color: iconColor),
                          const SizedBox(width: kSpacingXS),
                          Text(
                            _formatAmount(displayValue),
                            style: bodyTextStyle(
                              context,
                            )?.copyWith(fontWeight: kFontWeightBold),
                          ),
                          const SizedBox(width: kSpacingXS),
                          Text(displayUnit, style: helperTextStyle(context)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSpacingXS,
                              vertical: kSpacingXS / 2,
                            ),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(
                                alpha: kOpacitySubtle,
                              ),
                              borderRadius: BorderRadius.circular(
                                kBorderRadiusChip,
                              ),
                            ),
                            child: Text(
                              log.action.name,
                              style: helperTextStyle(context, color: iconColor)
                                  ?.copyWith(
                                    fontSize: kFontSizeHint,
                                    fontWeight: kFontWeightBold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: kSpacingXS),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: kIconSizeMedium,
                            color: cs.onSurfaceVariant.withValues(
                              alpha: kOpacityMediumLow,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: kSpacingXS),
                      Row(
                        children: [
                          Text(
                            timeFormat.format(log.actionTime),
                            style: helperTextStyle(
                              context,
                            )?.copyWith(fontSize: kFontSizeSmall),
                          ),
                          const SizedBox(width: kSpacingS),
                          Text(
                            dateFormat.format(log.actionTime),
                            style: helperTextStyle(
                              context,
                            )?.copyWith(fontSize: kFontSizeSmall),
                          ),
                        ],
                      ),
                      if (!isExpanded &&
                          log.notes != null &&
                          log.notes!.isNotEmpty) ...[
                        const SizedBox(height: kSpacingXS),
                        Text(
                          log.notes!,
                          style: helperTextStyle(context)?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: kFontSizeSmall,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: kAnimationFast,
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(
                  kNextDoseDateCircleSizeCompact + kSpacingS,
                  kSpacingS,
                  0,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.scheduleName,
                      style: bodyTextStyle(
                        context,
                      )?.copyWith(fontWeight: kFontWeightSemiBold),
                    ),
                    const SizedBox(height: kSpacingXS),
                    Text(
                      'Scheduled: ${dateFormat.format(log.scheduledTime)} • ${timeFormat.format(log.scheduledTime)}',
                      style: helperTextStyle(context),
                    ),
                    Text(
                      'Recorded: ${dateFormat.format(log.actionTime)} • ${timeFormat.format(log.actionTime)}',
                      style: helperTextStyle(context),
                    ),
                    const SizedBox(height: kSpacingXS),
                    Text(
                      log.action == DoseAction.taken
                          ? (log.wasOnTime
                                ? 'On time'
                                : 'Offset: ${log.minutesOffset} min')
                          : 'Action: ${log.action.name}',
                      style: helperTextStyle(
                        context,
                        color: cs.onSurfaceVariant.withValues(
                          alpha: kOpacityMediumHigh,
                        ),
                      ),
                    ),
                    if (log.notes != null && log.notes!.isNotEmpty) ...[
                      const SizedBox(height: kSpacingS),
                      Text(
                        log.notes!,
                        style: helperTextStyle(
                          context,
                        )?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: kSpacingS),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () =>
                            _showUniversalDoseActionSheetForLog(context, log),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: kIconSizeSmall,
                          color: cs.primary,
                        ),
                        label: Text(
                          'Edit',
                          style: helperTextStyle(
                            context,
                            color: cs.primary,
                          )?.copyWith(fontWeight: kFontWeightSemiBold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUniversalDoseActionSheetForLog(
    BuildContext context,
    DoseLog log,
  ) {
    final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));

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
      onMarkTaken: (notes) {
        final trimmed = notes?.trim();
        final updated = DoseLog(
          id: log.id,
          scheduleId: log.scheduleId,
          scheduleName: log.scheduleName,
          medicationId: log.medicationId,
          medicationName: log.medicationName,
          scheduledTime: log.scheduledTime,
          actionTime: log.actionTime,
          doseValue: log.doseValue,
          doseUnit: log.doseUnit,
          action: DoseAction.taken,
          actualDoseValue: log.actualDoseValue,
          actualDoseUnit: log.actualDoseUnit,
          notes: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        );

        repo.upsert(updated).then((_) {
          if (!mounted) return;
          setState(() {});
          showUpdatedSnackBar('Dose updated');
        });
      },
      onSnooze: () {
        final updated = DoseLog(
          id: log.id,
          scheduleId: log.scheduleId,
          scheduleName: log.scheduleName,
          medicationId: log.medicationId,
          medicationName: log.medicationName,
          scheduledTime: log.scheduledTime,
          actionTime: log.actionTime,
          doseValue: log.doseValue,
          doseUnit: log.doseUnit,
          action: DoseAction.snoozed,
          notes: log.notes,
        );

        repo.upsert(updated).then((_) {
          if (!mounted) return;
          setState(() {});
          showUpdatedSnackBar('Dose updated');
        });
      },
      onSkip: () {
        final updated = DoseLog(
          id: log.id,
          scheduleId: log.scheduleId,
          scheduleName: log.scheduleName,
          medicationId: log.medicationId,
          medicationName: log.medicationName,
          scheduledTime: log.scheduledTime,
          actionTime: log.actionTime,
          doseValue: log.doseValue,
          doseUnit: log.doseUnit,
          action: DoseAction.skipped,
          notes: log.notes,
        );

        repo.upsert(updated).then((_) {
          if (!mounted) return;
          setState(() {});
          showUpdatedSnackBar('Dose updated');
        });
      },
      onDelete: () {
        repo.delete(log.id).then((_) {
          if (!mounted) return;
          setState(() {
            if (_expandedHistoryLogId == log.id) {
              _expandedHistoryLogId = null;
            }
          });
          showUpdatedSnackBar('Dose log removed');
        });
      },
    );
  }

  Widget _buildAdherenceTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final adherenceData = _calculateAdherenceData();
    final avgPct = _getAveragePercentage(adherenceData);
    final takenMissed = _calculateTakenMissedData();
    final timeOfDayHistogram = _calculateTakenTimeOfDayHistogram();
    final consistencySparkline = _calculateConsistencySparklineData(days: 14);
    final streakStats = _calculateStreakStats(consistencySparkline);
    final actionBreakdown = _calculateActionBreakdown(days: 30);
    final doseTrend = _calculateDoseTrendData(days: 30, maxPoints: 14);

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
              style: helperTextStyle(
                context,
              )?.copyWith(fontSize: kFontSizeSmall),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(kSpacingL),
      children: [
        // Period label
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
        const SizedBox(height: kSpacingXS),
        Text(
          'Scroll for more reports',
          style: helperTextStyle(
            context,
            color: cs.onSurfaceVariant,
          )?.copyWith(fontSize: kFontSizeHint),
        ),
        const SizedBox(height: kSpacingL),

        // Adherence graph
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
        const SizedBox(height: kSpacingS),

        Text(
          'Taken vs missed',
          style: helperTextStyle(context)?.copyWith(
            fontWeight: kFontWeightSemiBold,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
        ),
        const SizedBox(height: kSpacingS),

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

        // Day labels
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
              style: helperTextStyle(context, color: cs.onSurfaceVariant)
                  ?.copyWith(
                    fontSize: kFontSizeHint,
                    fontWeight: kFontWeightMedium,
                  ),
            );
          }),
        ),

        const SizedBox(height: kSpacingM),

        Text(
          'Time of day',
          style: helperTextStyle(context)?.copyWith(
            fontWeight: kFontWeightSemiBold,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
        ),
        const SizedBox(height: kSpacingS),

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
              style: helperTextStyle(
                context,
                color: cs.onSurfaceVariant,
              )?.copyWith(fontSize: kFontSizeHint),
            ),
            Text(
              '6a',
              style: helperTextStyle(
                context,
                color: cs.onSurfaceVariant,
              )?.copyWith(fontSize: kFontSizeHint),
            ),
            Text(
              '12p',
              style: helperTextStyle(
                context,
                color: cs.onSurfaceVariant,
              )?.copyWith(fontSize: kFontSizeHint),
            ),
            Text(
              '6p',
              style: helperTextStyle(
                context,
                color: cs.onSurfaceVariant,
              )?.copyWith(fontSize: kFontSizeHint),
            ),
            Text(
              '12a',
              style: helperTextStyle(
                context,
                color: cs.onSurfaceVariant,
              )?.copyWith(fontSize: kFontSizeHint),
            ),
          ],
        ),
        const SizedBox(height: kSpacingM),

        // Summary stats row
        _buildSummaryStats(context, adherenceData),
        const SizedBox(height: kSpacingM),

        Text(
          'Streaks',
          style: helperTextStyle(context)?.copyWith(
            fontWeight: kFontWeightSemiBold,
            color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
          ),
        ),
        const SizedBox(height: kSpacingS),

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
        const SizedBox(height: kSpacingM),

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
              style: helperTextStyle(
                context,
                color: cs.onSurfaceVariant,
              )?.copyWith(fontSize: kFontSizeHint),
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
        const SizedBox(height: kSpacingM),

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
              style: helperTextStyle(
                context,
                color: cs.onSurfaceVariant,
              )?.copyWith(fontSize: kFontSizeHint),
            ),
            if (doseTrend.unit != null) ...[
              const SizedBox(width: kSpacingS),
              Text(
                doseTrend.unit!,
                style: helperTextStyle(
                  context,
                  color: cs.onSurfaceVariant,
                )?.copyWith(fontSize: kFontSizeHint),
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
