// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/widgets/next_dose_date_badge.dart';

sealed class _CombinedHistoryItem {
  const _CombinedHistoryItem({required this.time, required this.medicationName});

  final DateTime time;
  final String medicationName;

  Widget buildTitle(BuildContext context);

  IconData get icon;
  Color iconColor(ColorScheme cs);
}

class _DoseHistoryItem extends _CombinedHistoryItem {
  _DoseHistoryItem({required this.log})
      : super(time: log.actionTime, medicationName: log.medicationName);

  final DoseLog log;

  @override
  IconData get icon {
    switch (log.action) {
      case DoseAction.taken:
        return Icons.check_circle_rounded;
      case DoseAction.skipped:
        return Icons.cancel_rounded;
      case DoseAction.snoozed:
        return Icons.snooze_rounded;
    }
  }

  @override
  Color iconColor(ColorScheme cs) {
    switch (log.action) {
      case DoseAction.taken:
        return cs.primary;
      case DoseAction.skipped:
        return cs.tertiary;
      case DoseAction.snoozed:
        return cs.secondary;
    }
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
              style: bodyTextStyle(context)?.copyWith(
                fontWeight: kFontWeightSemiBold,
              ),
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
  IconData get icon => Icons.inventory_2_rounded;

  @override
  Color iconColor(ColorScheme cs) => cs.onSurfaceVariant;

  @override
  Widget buildTitle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          log.description,
          style: bodyTextStyle(context)?.copyWith(
            fontWeight: kFontWeightSemiBold,
          ),
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
    super.key,
  });

  final Set<String> includedMedicationIds;
  final bool embedInParentCard;
  final int initialMaxItems;

  @override
  State<CombinedReportsHistoryWidget> createState() =>
      _CombinedReportsHistoryWidgetState();
}

class _CombinedReportsHistoryWidgetState extends State<CombinedReportsHistoryWidget> {
  late int _maxItems;

  static const int _pageStep = 25;

  @override
  void initState() {
    super.initState();
    _maxItems = widget.initialMaxItems;
  }

  @override
  void didUpdateWidget(covariant CombinedReportsHistoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.includedMedicationIds != widget.includedMedicationIds) {
      _maxItems = widget.initialMaxItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                .toList(growable: false);

            final doseLogIds = doseLogs.map((l) => l.id).toSet();

            final inventoryLogs = inventoryLogBox.values
                .where((l) => included.contains(l.medicationId))
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

            final displayItems = items.take(_maxItems).toList(growable: false);
            final hasMore = displayItems.length < items.length;

            Widget buildEmpty() {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: kSpacingL),
                child: Center(
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
                    ],
                  ),
                ),
              );
            }

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (displayItems.isEmpty)
                  buildEmpty()
                else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      kSpacingS,
                      0,
                      kSpacingS,
                      0,
                    ),
                    itemCount: displayItems.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: kOpacityVeryLow),
                    ),
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      final iconColor = item.iconColor(cs);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: kSpacingXS / 2,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NextDoseDateBadge(
                              nextDose: item.time,
                              isActive: true,
                              dense: true,
                              showNextLabel: false,
                              showTodayIcon: true,
                            ),
                            const SizedBox(width: kSpacingS),
                            Expanded(child: item.buildTitle(context)),
                            const SizedBox(width: kSpacingS),
                            Container(
                              width: kStepperButtonSize,
                              height: kStepperButtonSize,
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: kOpacitySubtle),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.icon,
                                size: kIconSizeSmall,
                                color: iconColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (hasMore) ...[
                    const SizedBox(height: kSpacingS),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _maxItems += _pageStep;
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
