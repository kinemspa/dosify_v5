// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

/// Dose history widget with tabs for viewing medication dose records
/// Used when medication doesn't have a schedule, or for viewing ad-hoc doses
class DoseHistoryWidget extends StatefulWidget {
  const DoseHistoryWidget({
    required this.medication,
    super.key,
  });

  final Medication medication;

  @override
  State<DoseHistoryWidget> createState() => _DoseHistoryWidgetState();
}

class _DoseHistoryWidgetState extends State<DoseHistoryWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Just History tab for now
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
          // Tab bar header
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(kBorderRadiusLarge),
                topRight: Radius.circular(kBorderRadiusLarge),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              indicatorColor: cs.primary,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'History', icon: Icon(Icons.history, size: 18)),
              ],
            ),
          ),
          // Tab content
          SizedBox(
            height: 250, // Fixed height for now
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryTab(context),
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
    final logs = doseLogBox.values
        .where((log) => log.medicationId == widget.medication.id)
        .toList()
      ..sort((a, b) => b.actionTime.compareTo(a.actionTime)); // Most recent first

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_outlined,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No dose history',
              style: helperTextStyle(context),
            ),
            const SizedBox(height: 4),
            Text(
              'Recorded doses will appear here',
              style: helperTextStyle(context)?.copyWith(
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: logs.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: cs.outlineVariant.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildDoseLogItem(context, log);
      },
    );
  }

  Widget _buildDoseLogItem(BuildContext context, DoseLog log) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Determine icon and color based on action
    final IconData icon;
    final Color iconColor;
    switch (log.action) {
      case DoseAction.taken:
        icon = Icons.check_circle_outline;
        iconColor = cs.primary;
        break;
      case DoseAction.skipped:
        icon = Icons.cancel_outlined;
        iconColor = Colors.orange;
        break;
      case DoseAction.snoozed:
        icon = Icons.snooze;
        iconColor = Colors.amber;
        break;
    }

    // Use actual dose if different from scheduled
    final displayValue = log.actualDoseValue ?? log.doseValue;
    final displayUnit = log.actualDoseUnit ?? log.doseUnit;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          // Dose info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatAmount(displayValue),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      displayUnit,
                      style: helperTextStyle(context),
                    ),
                    const Spacer(),
                    // Action badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.action.name,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dateFormat.format(log.actionTime),
                      style: helperTextStyle(context)?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeFormat.format(log.actionTime),
                      style: helperTextStyle(context)?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.notes!,
                    style: helperTextStyle(context)?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
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
    );
  }

  String _formatAmount(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

