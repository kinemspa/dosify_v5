import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_status_change_log.dart';
import 'package:dosifi_v5/src/widgets/dose_summary_row.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

enum DoseActionSheetPresentation { bottomSheet, dialog }

/// Dose details and actions (Take, Snooze, Skip)
class DoseActionSheet extends StatefulWidget {
  final CalculatedDose dose;
  final void Function(String? notes) onMarkTaken;
  final void Function(String? notes) onSnooze;
  final void Function(String? notes) onSkip;
  final void Function(String? notes) onDelete;
  final DoseActionSheetPresentation presentation;

  const DoseActionSheet({
    super.key,
    required this.dose,
    required this.onMarkTaken,
    required this.onSnooze,
    required this.onSkip,
    required this.onDelete,
    this.presentation = DoseActionSheetPresentation.dialog,
  });

  static Future<void> show(
    BuildContext context, {
    required CalculatedDose dose,
    required void Function(String? notes) onMarkTaken,
    required void Function(String? notes) onSnooze,
    required void Function(String? notes) onSkip,
    required void Function(String? notes) onDelete,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => DoseActionSheet(
        dose: dose,
        onMarkTaken: onMarkTaken,
        onSnooze: onSnooze,
        onSkip: onSkip,
        onDelete: onDelete,
        presentation: DoseActionSheetPresentation.dialog,
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
        actionTime: widget.dose.existingLog!.actionTime,
        doseValue: widget.dose.existingLog!.doseValue,
        doseUnit: widget.dose.existingLog!.doseUnit,
        action: widget.dose.existingLog!.action,
        actualDoseValue: widget.dose.existingLog!.actualDoseValue,
        actualDoseUnit: widget.dose.existingLog!.actualDoseUnit,
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
      // Persist an audit event when editing an existing logged dose.
      // This keeps a record of "status changed" even if the change reverts
      // back to pending/overdue (which deletes the original log).
      if (widget.dose.existingLog != null) {
        final auditBox = Hive.box<DoseStatusChangeLog>(
          'dose_status_change_logs',
        );
        final now = DateTime.now();
        final id = now.microsecondsSinceEpoch.toString();
        auditBox.put(
          id,
          DoseStatusChangeLog(
            id: id,
            scheduleId: widget.dose.scheduleId,
            scheduleName: widget.dose.scheduleName,
            medicationId: widget.dose.existingLog!.medicationId,
            medicationName: widget.dose.existingLog!.medicationName,
            scheduledTime: widget.dose.scheduledTime,
            changeTime: now,
            fromStatus: widget.dose.status.name,
            toStatus: _selectedStatus.name,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          ),
        );
      }

      final notes = _notesController.text.isEmpty
          ? null
          : _notesController.text;

      switch (_selectedStatus) {
        case DoseStatus.taken:
          widget.onMarkTaken(notes);
          break;
        case DoseStatus.skipped:
          widget.onSkip(notes);
          break;
        case DoseStatus.snoozed:
          widget.onSnooze(notes);
          break;
        case DoseStatus.pending:
        case DoseStatus.overdue:
          // Revert to original - delete existing log
          widget.onDelete(notes);
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

    Widget content(BuildContext context, ScrollController scrollController) {
      return Column(
        children: [
          // Header
          Padding(
            padding: kBottomSheetHeaderPadding,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Take dose', style: sectionTitleStyle(context)),
                      Text(
                        'Confirm status, add notes, and save.',
                        style: helperTextStyle(context),
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
              padding: kBottomSheetContentPadding,
              children: [
                SectionFormCard(
                  neutral: true,
                  title: 'Dose',
                  children: [
                    DoseSummaryRow(
                      dose: widget.dose,
                      showMedicationName: true,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: kSpacingM),
                SectionFormCard(
                  neutral: true,
                  title: 'Status',
                  children: [
                    _buildStatusChips(),
                    const SizedBox(height: kSpacingXS),
                    _buildStatusHint(context),
                  ],
                ),
                const SizedBox(height: kSpacingM),
                SectionFormCard(
                  neutral: true,
                  title: 'Notes',
                  children: [
                    TextField(
                      controller: _notesController,
                      style: bodyTextStyle(context),
                      decoration: buildFieldDecoration(
                        context,
                        hint: 'Add any notes about this dose…',
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
                const SizedBox(height: kSpacingM),
                // Save & Close buttons
                Row(
                  children: [
                    // Close without saving
                    Expanded(
                      child: SizedBox(
                        height: kLargeButtonHeight,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ),
                    const SizedBox(width: kSpacingM),
                    // Save & Close
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: kLargeButtonHeight,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await _saveChanges();
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.save,
                            size: kIconSizeSmall,
                          ),
                          label: const Text('Save & Close'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (widget.presentation == DoseActionSheetPresentation.bottomSheet) {
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
                  width: kBottomSheetHandleWidth,
                  height: kBottomSheetHandleHeight,
                  margin: kBottomSheetHandleMargin,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: kOpacityLow,
                    ),
                    borderRadius: BorderRadius.circular(
                      kBottomSheetHandleRadius,
                    ),
                  ),
                ),
                Expanded(child: content(context, scrollController)),
              ],
            ),
          );
        },
      );
    }

    final dialogScrollController = ScrollController();
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return Dialog(
      insetPadding: const EdgeInsets.all(kSpacingL),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(kBorderRadiusLarge),
          ),
          child: content(context, dialogScrollController),
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: kSpacingS,
      runSpacing: kSpacingXS,
      children: [
        PrimaryChoiceChip(
          label: const Text('Scheduled'),
          selected:
              _selectedStatus == DoseStatus.pending ||
              _selectedStatus == DoseStatus.overdue,
          onSelected: (_) {
            setState(() {
              _selectedStatus = DoseStatus.pending;
              _hasChanged = true;
            });
          },
        ),
        PrimaryChoiceChip(
          label: const Text('Taken'),
          selected: _selectedStatus == DoseStatus.taken,
          onSelected: (_) {
            setState(() {
              _selectedStatus = DoseStatus.taken;
              _hasChanged = true;
            });
          },
        ),
        PrimaryChoiceChip(
          label: const Text('Snoozed'),
          selected: _selectedStatus == DoseStatus.snoozed,
          onSelected: (_) {
            setState(() {
              _selectedStatus = DoseStatus.snoozed;
              _hasChanged = true;
            });
          },
        ),
        PrimaryChoiceChip(
          label: const Text('Skipped'),
          selected: _selectedStatus == DoseStatus.skipped,
          onSelected: (_) {
            setState(() {
              _selectedStatus = DoseStatus.skipped;
              _hasChanged = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusHint(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          _hasChanged ? Icons.info_outline_rounded : Icons.schedule_rounded,
          size: kIconSizeSmall,
          color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
        ),
        const SizedBox(width: kSpacingS),
        Expanded(
          child: Text(
            _hasChanged
                ? 'Status changed — press Save & Close to apply.'
                : 'Change status if you need to correct this dose.',
            style: helperTextStyle(context),
          ),
        ),
      ],
    );
  }
}
