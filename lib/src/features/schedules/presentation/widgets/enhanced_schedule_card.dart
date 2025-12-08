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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nextDose = _getNextDose();
    final adherenceData = _getAdherenceData();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Collapsed header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with expand/edit buttons
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.schedule.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      // Status badge
                      if (!widget.schedule.active)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PAUSED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => context.go('/schedules/\${widget.schedule.id}'),
                        tooltip: 'Edit Schedule',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Next dose info
                  if (nextDose != null && widget.schedule.active)
                    Row(
                      children: [
                        Icon(
                          Icons.alarm,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatNextDose(nextDose),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  
                  // Dose info and frequency
                  Row(
                    children: [
                      Icon(
                        Icons.medication,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatNumber(widget.schedule.doseValue)} ${widget.schedule.doseUnit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        ' • ${_getFrequencyText()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Adherence
                  if (adherenceData['total'] > 0)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: _getAdherenceColor(adherenceData['rate']),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${adherenceData['rate'].toStringAsFixed(0)}% adherence',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getAdherenceColor(adherenceData['rate']),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Text(
                          ' (${adherenceData['taken']}/${adherenceData['total']} this week)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          // Expanded content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Schedule details
                  _buildExpandedSection(
                    context,
                    title: 'Schedule',
                    children: [
                      _buildDetailRow(context, 'Times', _getTimesText()),
                      _buildDetailRow(context, 'Days', _getDaysText()),
                      _buildDetailRow(
                        context,
                        'Started',
                        DateFormat('MMM d, yyyy').format(widget.schedule.createdAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Recent activity
                  _buildExpandedSection(
                    context,
                    title: 'Recent Activity',
                    children: [
                      _buildRecentDoses(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Quick actions
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.schedule.active) ...[
                        _buildActionButton(
                          context,
                          label: 'Take Now',
                          icon: Icons.check_circle,
                          color: Colors.green,
                          onPressed: _takeDoseNow,
                        ),
                        _buildActionButton(
                          context,
                          label: 'Skip',
                          icon: Icons.block,
                          color: Colors.grey,
                          onPressed: _skipDose,
                        ),
                        _buildActionButton(
                          context,
                          label: 'Snooze',
                          icon: Icons.snooze,
                          color: Colors.orange,
                          onPressed: _snoozeDose,
                        ),
                        _buildActionButton(
                          context,
                          label: 'Pause',
                          icon: Icons.pause_circle,
                          color: Colors.blue,
                          onPressed: _togglePause,
                        ),
                      ] else
                        _buildActionButton(
                          context,
                          label: 'Resume',
                          icon: Icons.play_circle,
                          color: Colors.green,
                          onPressed: _togglePause,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
      );
    }
    
    return Column(
      children: [
        ...logs.take(3).map((log) => Padding(
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
        )),
        if (logs.length > 3)
          TextButton(
            onPressed: () => context.go('/schedules/${widget.schedule.id}'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('View all history →', style: TextStyle(fontSize: 12)),
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
    
    final logs = repo.getByDateRange(weekAgo, now)
        .where((log) => log.scheduleId == widget.schedule.id)
        .toList();
    
    final taken = logs.where((l) => l.action == DoseAction.taken).length;
    final total = logs.length;
    final rate = total > 0 ? (taken / total) * 100 : 0.0;
    
    return {
      'taken': taken,
      'total': total,
      'rate': rate,
    };
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
      final days = widget.schedule.daysOfWeek.map((d) => dayNames[d - 1]).join(', ');
      return days;
    }
  }

  String _getTimesText() {
    if (widget.schedule.hasMultipleTimes) {
      final times = widget.schedule.timesOfDay!.map((m) {
        final hour = m ~/ 60;
        final minute = m % 60;
        final dt = DateTime(0, 0, 0, hour, minute);
        return DateFormat('h:mm a').format(dt);
      }).join(', ');
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
        return Colors.grey;
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
                  'notes': notesController.text.isEmpty ? null : notesController.text,
                  'site': siteController.text.isEmpty ? null : siteController.text,
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
        final newStockValue = (currentMed.stockValue - widget.schedule.doseValue).clamp(0.0, double.infinity);
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
        content: Text('Skip ${_formatNumber(widget.schedule.doseValue)} ${widget.schedule.doseUnit}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
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
            content: Text('Dose snoozed for ${snoozeDuration.inMinutes} minutes'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _togglePause() {
    final scheduleBox = Hive.box<Schedule>('schedules');
    final updated = Schedule(
      id: widget.schedule.id,
      name: widget.schedule.name,
      medicationName: widget.schedule.medicationName,
      doseValue: widget.schedule.doseValue,
      doseUnit: widget.schedule.doseUnit,
      minutesOfDay: widget.schedule.minutesOfDay,
      daysOfWeek: widget.schedule.daysOfWeek,
      active: !widget.schedule.active,
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
    
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updated.active ? 'Schedule resumed' : 'Schedule paused'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
