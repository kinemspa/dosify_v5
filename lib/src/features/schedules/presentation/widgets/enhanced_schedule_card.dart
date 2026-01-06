// ignore_for_file: unused_element

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/widgets/confirm_schedule_edit_dialog.dart';
import 'package:dosifi_v5/src/widgets/schedule_pause_dialog.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_status_ui.dart';

/// Enhanced expandable schedule card for medication detail page
/// Shows schedule summary by default, expands to show full details
class EnhancedScheduleCard extends StatefulWidget {
  const EnhancedScheduleCard({
    super.key,
    required this.schedule,
    required this.medication,
  });

  final Schedule schedule;
  final Medication medication;

  @override
  State<EnhancedScheduleCard> createState() => _EnhancedScheduleCardState();
}

class _EnhancedScheduleCardState extends State<EnhancedScheduleCard> {
  bool _isExpanded = false;

  Future<void> _promptEditSchedule() async {
    final confirmed = await showConfirmEditScheduleDialog(context);
    if (!confirmed || !mounted) return;
    context.push('/schedules/edit/${widget.schedule.id}');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final nextDose = _getNextDose();
    final adherenceData = _getAdherenceData();
    final adherenceRate = (adherenceData['total'] as int) > 0
        ? adherenceData['rate'] as double
        : 100.0;

    return AnimatedContainer(
      duration: kAnimationNormal,
      curve: kCurveEmphasized,
      margin: const EdgeInsets.only(bottom: kSpacingS),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: kAnimationNormal,
          curve: kCurveEmphasized,
          padding: EdgeInsets.all(_isExpanded ? kCardPadding : kSpacingM),
          decoration: BoxDecoration(
            color: _isExpanded ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(kBorderRadiusMedium),
            border: _isExpanded
                ? Border.all(
                    color: colorScheme.outlineVariant.withValues(
                      alpha: kCardBorderOpacity,
                    ),
                    width: kBorderWidthThin,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COLLAPSED STATE - Ultra Clean Single Row
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(kBorderRadiusMedium),
                child: Row(
                  children: [
                    // Schedule name (primary info)
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.schedule.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: kFontWeightMedium,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!widget.schedule.isActive) ...[
                            const SizedBox(width: kSpacingXS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: kSpacingXS,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(kSpacingXS),
                              ),
                              child: Text(
                                scheduleStatusLabel(widget.schedule),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Next dose time OR frequency (secondary info)
                    if (widget.schedule.isActive && nextDose != null)
                      Text(
                        _formatNextDoseShort(nextDose),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: kFontWeightMedium,
                        ),
                      )
                    else
                      Text(_getFrequencyText(), style: mutedTextStyle(context)),
                    const SizedBox(width: kSpacingS),
                    // Expand/collapse control
                    Padding(
                      padding: const EdgeInsets.all(kSpacingXS),
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: kAnimationFast,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: kIconSizeMedium,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: kOpacityMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // EXPANDED STATE - Premium Details
              AnimatedCrossFade(
                duration: kAnimationNormal,
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: kSpacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dose & Frequency Row
                      Row(
                        children: [
                          _buildInfoChip(
                            context,
                            icon: Icons.medication_rounded,
                            label:
                                '${_formatNumber(widget.schedule.doseValue)} ${widget.schedule.doseUnit}',
                            isPrimary: true,
                          ),
                          const SizedBox(width: kSpacingS),
                          _buildInfoChip(
                            context,
                            icon: Icons.schedule_rounded,
                            label: _getTimesText(),
                          ),
                        ],
                      ),
                      const SizedBox(height: kSpacingM),

                      // Days Row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: kIconSizeSmall,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: kOpacityMedium,
                            ),
                          ),
                          const SizedBox(width: kSpacingS),
                          Expanded(
                            child: Text(
                              _getDaysText(),
                              style: mutedTextStyle(
                                context,
                              )?.copyWith(fontWeight: kFontWeightMedium),
                            ),
                          ),
                        ],
                      ),

                      // Adherence (if data exists)
                      if ((adherenceData['total'] as int) > 0) ...[
                        const SizedBox(height: kSpacingM),
                        Row(
                          children: [
                            // Progress bar
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(kSpacingXS),
                                child: LinearProgressIndicator(
                                  value: adherenceRate / 100,
                                  minHeight: kSpacingXS,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(
                                    _getAdherenceColor(adherenceRate),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: kSpacingM),
                            Text(
                              '${adherenceRate.toStringAsFixed(0)}%',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _getAdherenceColor(adherenceRate),
                                fontWeight: kFontWeightBold,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: kSpacingL),

                      // Schedule Details Section
                      _buildExpandedSection(
                        context,
                        title: 'Schedule Details',
                        children: [
                          _buildDetailRow(
                            context,
                            'Dose',
                            '${_formatNumber(widget.schedule.doseValue)} ${widget.schedule.doseUnit}',
                          ),
                          _buildDetailRow(context, 'Times', _getTimesText()),
                          _buildDetailRow(context, 'Days', _getDaysText()),
                          _buildDetailRow(
                            context,
                            'Started',
                            DateFormat(
                              'MMM d, yyyy',
                            ).format(widget.schedule.createdAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: kSpacingM),

                      // Recent Activity Section
                      _buildExpandedSection(
                        context,
                        title: 'Recent Activity',
                        children: [_buildRecentDoses()],
                      ),
                      const SizedBox(height: kSpacingL),

                      // Action Buttons Row (Schedule-level actions only)
                      Row(
                        children: [
                          _buildSecondaryAction(
                            context,
                            icon: widget.schedule.isActive
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            onTap: _showPauseOptions,
                          ),
                          const SizedBox(width: kSpacingS),
                          _buildSecondaryAction(
                            context,
                            icon: Icons.edit_rounded,
                            onTap: _promptEditSchedule,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Premium info chip
  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isPrimary = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingM,
        vertical: kSpacingS,
      ),
      decoration: BoxDecoration(
        color: isPrimary
            ? colorScheme.primaryContainer.withValues(alpha: kOpacityMediumLow)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: kIconSizeSmall,
            color: isPrimary
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: kSpacingXS),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: kFontWeightMedium,
              color: isPrimary
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Primary action button
  Widget _buildPrimaryAction(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: kSpacingM),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: kFontWeightSemiBold,
            ),
          ),
        ),
      ),
    );
  }

  // Secondary action button
  Widget _buildSecondaryAction(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        child: Container(
          padding: const EdgeInsets.all(kSpacingM),
          child: Icon(
            icon,
            size: kIconSizeMedium,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _formatNextDoseShort(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.isNegative) {
      return 'Overdue';
    } else if (diff.inMinutes < 60) {
      return 'in ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return DateFormat('h:mm a').format(dt);
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEE').format(dt);
    }
  }

  Widget _buildExpandedSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDoses() {
    final logs = _getRecentLogs();

    if (logs.isEmpty) {
      return Text(
        'No doses recorded yet',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: [
        ...logs
            .take(3)
            .map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      _getActionIcon(log.action),
                      size: 14,
                      color: _getActionColor(log.action),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatLastTaken(log.actionTime)} • ${_getActionLabel(log.action)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (log.notes != null && log.notes!.isNotEmpty)
                      Icon(
                        Icons.note_outlined,
                        size: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                  ],
                ),
              ),
            ),
        if (logs.length > 3)
          TextButton(
            onPressed: () =>
                context.push('/schedules/detail/${widget.schedule.id}'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'View all history →',
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // Helper methods
  DateTime? _getNextDose() {
    // TODO: Implement next dose calculation
    final now = DateTime.now();
    return now.add(const Duration(hours: 2, minutes: 15));
  }

  Map<String, dynamic> _getAdherenceData() {
    final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final logs = repo
        .getByDateRange(weekAgo, now)
        .where((log) => log.scheduleId == widget.schedule.id)
        .toList();

    final taken = logs.where((l) => l.action == DoseAction.taken).length;
    final total = logs.length;
    final rate = total > 0 ? (taken / total) * 100 : 0.0;

    return {'taken': taken, 'total': total, 'rate': rate};
  }

  List<DoseLog> _getRecentLogs() {
    final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
    final logs = repo.getByScheduleId(widget.schedule.id);
    logs.sort((a, b) => b.actionTime.compareTo(a.actionTime));
    return logs;
  }

  String _formatNextDose(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.inMinutes < 60) {
      return 'in ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return 'Today at ${DateFormat('h:mm a').format(dt)} (in ${hours}h ${minutes}m)';
    } else if (diff.inDays == 1) {
      return 'Tomorrow at ${DateFormat('h:mm a').format(dt)}';
    } else {
      return '${DateFormat('EEEE').format(dt)} at ${DateFormat('h:mm a').format(dt)}';
    }
  }

  String _formatLastTaken(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(dt)}';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _getFrequencyText() {
    if (widget.schedule.hasCycle) {
      return 'Every ${widget.schedule.cycleEveryNDays} days';
    } else if (widget.schedule.hasDaysOfMonth) {
      final days = widget.schedule.daysOfMonth!.join(', ');
      return 'Days $days of month';
    } else if (widget.schedule.daysOfWeek.length == 7) {
      return 'Every day';
    } else {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final days = widget.schedule.daysOfWeek
          .map((d) => dayNames[d - 1])
          .join(', ');
      return days;
    }
  }

  String _getTimesText() {
    if (widget.schedule.hasMultipleTimes) {
      final times = widget.schedule.timesOfDay!
          .map((m) {
            final hour = m ~/ 60;
            final minute = m % 60;
            final dt = DateTime(0, 0, 0, hour, minute);
            return DateFormat('h:mm a').format(dt);
          })
          .join(', ');
      return times;
    } else {
      final hour = widget.schedule.minutesOfDay ~/ 60;
      final minute = widget.schedule.minutesOfDay % 60;
      final dt = DateTime(0, 0, 0, hour, minute);
      return DateFormat('h:mm a').format(dt);
    }
  }

  String _getDaysText() {
    return _getFrequencyText();
  }

  Color _getAdherenceColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
  }

  IconData _getActionIcon(DoseAction action) {
    switch (action) {
      case DoseAction.taken:
        return Icons.check_circle;
      case DoseAction.skipped:
        return Icons.block;
      case DoseAction.snoozed:
        return Icons.snooze;
    }
  }

  Color _getActionColor(DoseAction action) {
    switch (action) {
      case DoseAction.taken:
        return Colors.green;
      case DoseAction.skipped:
        return Theme.of(context).colorScheme.primary;
      case DoseAction.snoozed:
        return Colors.orange;
    }
  }

  String _getActionLabel(DoseAction action) {
    switch (action) {
      case DoseAction.taken:
        return 'Taken';
      case DoseAction.skipped:
        return 'Skipped';
      case DoseAction.snoozed:
        return 'Snoozed';
    }
  }

  // Action handlers
  void _takeDoseNow() async {
    final now = DateTime.now();

    // Show quick confirmation dialog with notes option
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) {
        final notesController = TextEditingController();
        final siteController = TextEditingController();

        return AlertDialog(
          title: const Text('Record Dose'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recording ${_formatNumber(widget.schedule.doseValue)} ${widget.schedule.doseUnit}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: siteController,
                decoration: const InputDecoration(
                  labelText: 'Injection site (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'notes': notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  'site': siteController.text.isEmpty
                      ? null
                      : siteController.text,
                });
              },
              child: const Text('Record'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      // Create dose log
      final logId = '${widget.schedule.id}_${now.millisecondsSinceEpoch}';

      // Combine notes and injection site
      String? combinedNotes = result['notes'];
      if (result['site'] != null && result['site']!.isNotEmpty) {
        if (combinedNotes != null && combinedNotes.isNotEmpty) {
          combinedNotes = '$combinedNotes\nInjection site: ${result['site']}';
        } else {
          combinedNotes = 'Injection site: ${result['site']}';
        }
      }

      final log = DoseLog(
        id: logId,
        scheduleId: widget.schedule.id,
        scheduleName: widget.schedule.name,
        medicationId: widget.medication.id,
        medicationName: widget.medication.name,
        scheduledTime: now,
        doseValue: widget.schedule.doseValue,
        doseUnit: widget.schedule.doseUnit,
        action: DoseAction.taken,
        notes: combinedNotes,
      );

      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsert(log);

      // Update medication stock
      final medBox = Hive.box<Medication>('medications');
      final currentMed = medBox.get(widget.medication.id);
      if (currentMed != null) {
        final newStockValue =
            (currentMed.stockValue - widget.schedule.doseValue).clamp(
              0.0,
              double.infinity,
            );
        await medBox.put(
          currentMed.id,
          currentMed.copyWith(stockValue: newStockValue),
        );
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Dose recorded successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _skipDose() async {
    final now = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Dose'),
        content: Text(
          'Skip ${_formatNumber(widget.schedule.doseValue)} ${widget.schedule.doseUnit}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final logId = '${widget.schedule.id}_${now.millisecondsSinceEpoch}';
      final log = DoseLog(
        id: logId,
        scheduleId: widget.schedule.id,
        scheduleName: widget.schedule.name,
        medicationId: widget.medication.id,
        medicationName: widget.medication.name,
        scheduledTime: now,
        doseValue: widget.schedule.doseValue,
        doseUnit: widget.schedule.doseUnit,
        action: DoseAction.skipped,
      );

      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsert(log);

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dose skipped'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _snoozeDose() async {
    final now = DateTime.now();

    final snoozeDuration = await showDialog<Duration>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Dose'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Remind me in:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('15 minutes'),
              onTap: () => Navigator.pop(context, const Duration(minutes: 15)),
            ),
            ListTile(
              title: const Text('30 minutes'),
              onTap: () => Navigator.pop(context, const Duration(minutes: 30)),
            ),
            ListTile(
              title: const Text('1 hour'),
              onTap: () => Navigator.pop(context, const Duration(hours: 1)),
            ),
            ListTile(
              title: const Text('2 hours'),
              onTap: () => Navigator.pop(context, const Duration(hours: 2)),
            ),
          ],
        ),
      ),
    );

    if (snoozeDuration != null && mounted) {
      final logId = '${widget.schedule.id}_${now.millisecondsSinceEpoch}';
      final log = DoseLog(
        id: logId,
        scheduleId: widget.schedule.id,
        scheduleName: widget.schedule.name,
        medicationId: widget.medication.id,
        medicationName: widget.medication.name,
        scheduledTime: now,
        doseValue: widget.schedule.doseValue,
        doseUnit: widget.schedule.doseUnit,
        action: DoseAction.snoozed,
        notes: 'Snoozed for ${snoozeDuration.inMinutes} minutes',
      );

      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsert(log);

      // TODO: Schedule notification for snooze time

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dose snoozed for ${snoozeDuration.inMinutes} minutes',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showPauseOptions() async {
    final choice = await showSchedulePauseDialog(
      context,
      schedule: widget.schedule,
    );
    if (!mounted || choice == null) return;

    final scheduleBox = Hive.box<Schedule>('schedules');

    switch (choice) {
      case SchedulePauseDialogChoice.resume:
        scheduleBox.put(
          widget.schedule.id,
          widget.schedule.copyWith(active: true, pausedUntil: null),
        );
        break;

      case SchedulePauseDialogChoice.pauseIndefinitely:
        scheduleBox.put(
          widget.schedule.id,
          widget.schedule.copyWith(active: false, pausedUntil: null),
        );
        break;

      case SchedulePauseDialogChoice.pauseUntilDate:
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(now.year, now.month, now.day),
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 10),
        );
        if (!mounted || picked == null) return;

        final endOfDay = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
          999,
        );

        scheduleBox.put(
          widget.schedule.id,
          widget.schedule.copyWith(active: false, pausedUntil: endOfDay),
        );
        break;
    }

    if (mounted) {
      setState(() {});
      final refreshed = scheduleBox.get(widget.schedule.id) ?? widget.schedule;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Schedule set to ${scheduleStatusLabel(refreshed)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Quick edit methods
  void _quickEditDose() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: _formatNumber(widget.schedule.doseValue),
        );

        return AlertDialog(
          title: const Text('Edit Dose Amount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Dose Amount',
                  suffixText: widget.schedule.doseUnit,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      final current =
                          double.tryParse(controller.text) ??
                          widget.schedule.doseValue;
                      final newValue = (current - 0.5).clamp(0.1, 1000.0);
                      controller.text = _formatNumber(newValue);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    onPressed: () {
                      final current =
                          double.tryParse(controller.text) ??
                          widget.schedule.doseValue;
                      final newValue = (current + 0.5).clamp(0.1, 1000.0);
                      controller.text = _formatNumber(newValue);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value > 0) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result != widget.schedule.doseValue && mounted) {
      final scheduleBox = Hive.box<Schedule>('schedules');
      final updated = Schedule(
        id: widget.schedule.id,
        name: widget.schedule.name,
        medicationName: widget.schedule.medicationName,
        doseValue: result,
        doseUnit: widget.schedule.doseUnit,
        minutesOfDay: widget.schedule.minutesOfDay,
        daysOfWeek: widget.schedule.daysOfWeek,
        active: widget.schedule.active,
        medicationId: widget.schedule.medicationId,
        timesOfDay: widget.schedule.timesOfDay,
        cycleEveryNDays: widget.schedule.cycleEveryNDays,
        cycleAnchorDate: widget.schedule.cycleAnchorDate,
        daysOfMonth: widget.schedule.daysOfMonth,
        createdAt: widget.schedule.createdAt,
        minutesOfDayUtc: widget.schedule.minutesOfDayUtc,
        daysOfWeekUtc: widget.schedule.daysOfWeekUtc,
        timesOfDayUtc: widget.schedule.timesOfDayUtc,
      );
      scheduleBox.put(widget.schedule.id, updated);

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dose updated to ${_formatNumber(result)} ${widget.schedule.doseUnit}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _quickEditTimes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Time editing coming soon. Use the edit button to modify times.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
