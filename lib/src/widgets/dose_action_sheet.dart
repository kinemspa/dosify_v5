import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';

/// Bottom sheet showing dose details and actions (Take, Snooze, Skip)
class DoseActionSheet extends StatefulWidget {
  final CalculatedDose dose;
  final void Function(String? notes) onMarkTaken;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final VoidCallback onDelete;

  const DoseActionSheet({
    super.key,
    required this.dose,
    required this.onMarkTaken,
    required this.onSnooze,
    required this.onSkip,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required CalculatedDose dose,
    required void Function(String? notes) onMarkTaken,
    required VoidCallback onSnooze,
    required VoidCallback onSkip,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DoseActionSheet(
        dose: dose,
        onMarkTaken: onMarkTaken,
        onSnooze: onSnooze,
        onSkip: onSkip,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<DoseActionSheet> createState() => _DoseActionSheetState();
}

class _DoseActionSheetState extends State<DoseActionSheet> {
  late final TextEditingController _notesController;
  late DoseStatus _selectedStatus;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.dose.existingLog?.notes ?? '',
    );
    _selectedStatus = widget.dose.status;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotesOnly() async {
    if (widget.dose.existingLog == null) return;

    try {
      // Update the existing log with new notes
      final updatedLog = DoseLog(
        id: widget.dose.existingLog!.id,
        scheduleId: widget.dose.existingLog!.scheduleId,
        scheduleName: widget.dose.existingLog!.scheduleName,
        medicationId: widget.dose.existingLog!.medicationId,
        medicationName: widget.dose.existingLog!.medicationName,
        scheduledTime: widget.dose.existingLog!.scheduledTime,
        doseValue: widget.dose.existingLog!.doseValue,
        doseUnit: widget.dose.existingLog!.doseUnit,
        action: widget.dose.existingLog!.action,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsert(updatedLog);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notes saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving notes: $e')));
      }
    }
  }

  Future<void> _saveChanges() async {
    // If status changed, call appropriate callback
    if (_selectedStatus != widget.dose.status) {
      final notes = _notesController.text.isEmpty ? null : _notesController.text;
      
      switch (_selectedStatus) {
        case DoseStatus.taken:
          widget.onMarkTaken(notes);
          break;
        case DoseStatus.skipped:
          widget.onSkip();
          break;
        case DoseStatus.snoozed:
          widget.onSnooze();
          break;
        case DoseStatus.pending:
        case DoseStatus.overdue:
          // Revert to original - delete existing log
          widget.onDelete();
          break;
      }
    } else if (widget.dose.existingLog != null) {
      // Status didn't change but might need to save notes
      await _saveNotesOnly();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(kBorderRadiusLarge),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.dose.scheduleName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.dose.doseDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoRow(
                      context,
                      'Time',
                      widget.dose.timeFormatted,
                      Icons.access_time,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Date',
                      MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(widget.dose.scheduledTime),
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 12),
                    // Compact status section
                    _buildStatusSection(context, widget.dose, colorScheme),
                    const SizedBox(height: 16),
                    // Action buttons - always visible with state-based styling
                    _buildActionButtons(context, widget.dose, colorScheme),
                    const SizedBox(height: 16),
                    // Notes field (always visible)
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add any notes about this dose...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.note_outlined),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    // Save & Close buttons
                    Row(
                      children: [
                        // Close without saving
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Save & Close
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () async {
                              await _saveChanges();
                              if (context.mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Save & Close'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    CalculatedDose dose,
    ColorScheme colorScheme,
  ) {
    // Use local state if changed, otherwise show original status
    final displayStatus = _selectedStatus;
    final statusColor = _getStatusColor(displayStatus, colorScheme);
    final statusIcon = _getStatusIcon(displayStatus);
    final statusText = _getStatusText(displayStatus);

    return Row(
      children: [
        Icon(statusIcon, size: 20, color: statusColor),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_hasChanged) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Changed',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    CalculatedDose dose,
    ColorScheme colorScheme,
  ) {
    // Use local state for selection
    final status = _selectedStatus;

    // Highlight based on current local status
    final takePrimary = status == DoseStatus.taken;
    final snoozePrimary = status == DoseStatus.snoozed;
    final skipPrimary = status == DoseStatus.skipped;

    return Row(
      children: [
        // Take button - toggles between taken and pending
        Expanded(
          child: takePrimary 
              ? FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = widget.dose.status == DoseStatus.taken 
                          ? DoseStatus.pending 
                          : widget.dose.status;
                      _hasChanged = true;
                    });
                  },
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Taken'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = DoseStatus.taken;
                      _hasChanged = true;
                    });
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Take'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        // Snooze button - toggles between snoozed and pending
        Expanded(
          child: snoozePrimary 
              ? FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = widget.dose.status == DoseStatus.snoozed 
                          ? DoseStatus.pending 
                          : widget.dose.status;
                      _hasChanged = true;
                    });
                  },
                  icon: const Icon(Icons.snooze, size: 18),
                  label: const Text('Snoozed'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = DoseStatus.snoozed;
                      _hasChanged = true;
                    });
                  },
                  icon: const Icon(Icons.snooze_outlined, size: 18),
                  label: const Text('Snooze'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        // Skip button - toggles between skipped and pending
        Expanded(
          child: skipPrimary 
              ? FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = widget.dose.status == DoseStatus.skipped 
                          ? DoseStatus.pending 
                          : widget.dose.status;
                      _hasChanged = true;
                    });
                  },
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Skipped'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = DoseStatus.skipped;
                      _hasChanged = true;
                    });
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Skip'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
        ),
      ],
    );
  }

  Color _getStatusColor(DoseStatus status, ColorScheme colorScheme) {
    switch (status) {
      case DoseStatus.taken:
        return colorScheme.primary; // Blue/Primary
      case DoseStatus.skipped:
        return Colors.grey; // Grey for canceled/skipped
      case DoseStatus.snoozed:
        return Colors.orange; // Orange for snoozed
      case DoseStatus.overdue:
        return colorScheme.error; // Red for missed/overdue
      case DoseStatus.pending:
        return colorScheme.onSurface.withValues(
          alpha: 0.6,
        ); // Muted for pending
    }
  }

  String _getStatusText(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return 'Taken';
      case DoseStatus.skipped:
        return 'Skipped';
      case DoseStatus.snoozed:
        return 'Snoozed';
      case DoseStatus.overdue:
        return 'Overdue';
      case DoseStatus.pending:
        return 'Pending';
    }
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return Icons.check_circle;
      case DoseStatus.skipped:
        return Icons.cancel;
      case DoseStatus.snoozed:
        return Icons.snooze;
      case DoseStatus.overdue:
        return Icons.warning;
      case DoseStatus.pending:
        return Icons.schedule;
    }
  }
}
