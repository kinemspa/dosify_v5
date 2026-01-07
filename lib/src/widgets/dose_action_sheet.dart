import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_status_change_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/widgets/dose_dialog_dose_preview.dart';
import 'package:dosifi_v5/src/widgets/dose_summary_row.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

enum DoseActionSheetPresentation { bottomSheet, dialog }

/// Dose details and actions (Take, Snooze, Skip)
class DoseActionSheet extends StatefulWidget {
  final CalculatedDose dose;
  final Future<void> Function(String? notes, DateTime actionTime) onMarkTaken;
  final Future<void> Function(String? notes, DateTime actionTime) onSnooze;
  final Future<void> Function(String? notes, DateTime actionTime) onSkip;
  final Future<void> Function(String? notes) onDelete;
  final DoseActionSheetPresentation presentation;
  final DoseStatus? initialStatus;

  const DoseActionSheet({
    super.key,
    required this.dose,
    required this.onMarkTaken,
    required this.onSnooze,
    required this.onSkip,
    required this.onDelete,
    this.presentation = DoseActionSheetPresentation.dialog,
    this.initialStatus,
  });

  static Future<void> show(
    BuildContext context, {
    required CalculatedDose dose,
    required Future<void> Function(String? notes, DateTime actionTime)
    onMarkTaken,
    required Future<void> Function(String? notes, DateTime actionTime) onSnooze,
    required Future<void> Function(String? notes, DateTime actionTime) onSkip,
    required Future<void> Function(String? notes) onDelete,
    DoseStatus? initialStatus,
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
        initialStatus: initialStatus,
      ),
    );
  }

  @override
  State<DoseActionSheet> createState() => _DoseActionSheetState();
}

class _DoseActionSheetState extends State<DoseActionSheet> {
  late final TextEditingController _notesController;
  TextEditingController? _amountController;
  double? _originalAdHocAmount;
  double? _maxAdHocAmount;
  late DoseStatus _selectedStatus;
  late DateTime _selectedActionTime;
  DateTime? _selectedSnoozeUntil;
  bool _hasChanged = false;

  bool get _isAdHoc => widget.dose.existingLog?.scheduleId == 'ad_hoc';

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.dose.existingLog?.notes ?? '',
    );
    _selectedStatus = widget.initialStatus ?? widget.dose.status;

    final baseActionTime = widget.dose.existingLog?.actionTime ?? DateTime.now();
    _selectedActionTime = baseActionTime;
    if (widget.dose.existingLog == null && _selectedStatus == DoseStatus.snoozed) {
      final until = _defaultSnoozeUntil();
      final max = _maxSnoozeUntil();
      final clamped = max != null && until.isAfter(max) ? max : until;
      _selectedSnoozeUntil = clamped;
      _selectedActionTime = clamped;
    } else {
      _selectedSnoozeUntil = _selectedStatus == DoseStatus.snoozed
          ? _selectedActionTime
          : _defaultSnoozeUntil();
    }

    if (_isAdHoc && widget.dose.existingLog != null) {
      final log = widget.dose.existingLog!;
      _originalAdHocAmount = log.doseValue;
      _amountController = TextEditingController(
        text: _formatAmount(log.doseValue),
      );

      final medBox = Hive.box<Medication>('medications');
      final med = medBox.get(log.medicationId);
      if (med != null) {
        final isMdv = med.form == MedicationForm.multiDoseVial;
        final currentStock = isMdv
            ? (med.activeVialVolume ?? med.containerVolumeMl ?? 0)
            : med.stockValue;
        _maxAdHocAmount = (currentStock + log.doseValue).clamp(
          0.0,
          double.infinity,
        );
      } else {
        _maxAdHocAmount = double.infinity;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amountController?.dispose();
    super.dispose();
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  DateTime _defaultSnoozeUntil() {
    return DateTime.now().add(const Duration(minutes: 15));
  }

  DateTime? _maxSnoozeUntil() {
    final schedule = Hive.box<Schedule>(
      'schedules',
    ).get(widget.dose.scheduleId);
    if (schedule == null) return null;

    final now = DateTime.now();
    final fromForNext = widget.dose.scheduledTime.isAfter(now)
        ? widget.dose.scheduledTime.add(const Duration(minutes: 1))
        : now;

    final next = ScheduleOccurrenceService.nextOccurrence(
      schedule,
      from: fromForNext,
    );
    if (next == null) return null;

    final max = next.subtract(const Duration(minutes: 1));
    if (max.isBefore(now)) return now;
    return max;
  }

  double _adHocStepSize(String unit) {
    final normalized = unit.trim().toLowerCase();
    if (normalized == 'ml' || normalized.contains('ml')) return 0.1;
    return 1.0;
  }

  Future<void> _saveAdHocAmountAndNotesIfNeeded() async {
    if (!_isAdHoc) return;
    final existingLog = widget.dose.existingLog;
    if (existingLog == null) return;
    final controller = _amountController;
    if (controller == null) return;

    final parsedAmount = double.tryParse(controller.text) ?? 0;
    final maxAmount = _maxAdHocAmount ?? double.infinity;
    final newAmount = parsedAmount.clamp(0.0, maxAmount);
    final oldAmount = _originalAdHocAmount ?? existingLog.doseValue;
    final trimmedNotes = _notesController.text.trim();
    final newNotes = trimmedNotes.isEmpty ? null : trimmedNotes;

    final amountChanged = (newAmount - oldAmount).abs() > 0.000001;
    final notesChanged = (existingLog.notes ?? '') != (newNotes ?? '');
    if (!amountChanged && !notesChanged) return;

    final doseLogRepo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
    final inventoryBox = Hive.box<InventoryLog>('inventory_logs');
    final medBox = Hive.box<Medication>('medications');
    final med = medBox.get(existingLog.medicationId);

    if (amountChanged && med != null) {
      final isMdv = med.form == MedicationForm.multiDoseVial;
      final latestStock = isMdv
          ? (med.activeVialVolume ?? med.containerVolumeMl ?? 0)
          : med.stockValue;

      // We want net change to match "-newAmount" instead of "-oldAmount".
      // Delta to apply to current stock is: oldAmount - newAmount.
      final adjustment = oldAmount - newAmount;
      final updatedStock = (latestStock + adjustment).clamp(
        0.0,
        double.infinity,
      );

      if (isMdv) {
        final max =
            (med.containerVolumeMl != null && med.containerVolumeMl! > 0)
            ? med.containerVolumeMl!
            : double.infinity;
        await medBox.put(
          med.id,
          med.copyWith(activeVialVolume: updatedStock.clamp(0.0, max)),
        );
      } else {
        await medBox.put(med.id, med.copyWith(stockValue: updatedStock));
      }

      final inv = inventoryBox.get(existingLog.id);
      if (inv != null && inv.changeType == InventoryChangeType.adHocDose) {
        inventoryBox.put(
          inv.id,
          InventoryLog(
            id: inv.id,
            medicationId: inv.medicationId,
            medicationName: inv.medicationName,
            changeType: inv.changeType,
            previousStock: inv.previousStock,
            newStock: inv.previousStock - newAmount,
            changeAmount: -newAmount,
            notes: newNotes ?? inv.notes,
            timestamp: inv.timestamp,
          ),
        );
      }
    }

    final updatedLog = DoseLog(
      id: existingLog.id,
      scheduleId: existingLog.scheduleId,
      scheduleName: existingLog.scheduleName,
      medicationId: existingLog.medicationId,
      medicationName: existingLog.medicationName,
      scheduledTime: existingLog.scheduledTime,
      actionTime: _selectedActionTime,
      doseValue: amountChanged ? newAmount : existingLog.doseValue,
      doseUnit: existingLog.doseUnit,
      action: existingLog.action,
      actualDoseValue: existingLog.actualDoseValue,
      actualDoseUnit: existingLog.actualDoseUnit,
      notes: newNotes,
    );
    await doseLogRepo.upsert(updatedLog);

    _originalAdHocAmount = updatedLog.doseValue;
    controller.text = _formatAmount(updatedLog.doseValue);
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
        actionTime: _selectedActionTime,
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
    await _saveAdHocAmountAndNotesIfNeeded();

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
          await widget.onMarkTaken(notes, _selectedActionTime);
          break;
        case DoseStatus.skipped:
          await widget.onSkip(notes, _selectedActionTime);
          break;
        case DoseStatus.snoozed:
          await widget.onSnooze(
            notes,
            _selectedSnoozeUntil ?? _defaultSnoozeUntil(),
          );
          break;
        case DoseStatus.pending:
        case DoseStatus.overdue:
          // Revert to original - delete existing log
          await widget.onDelete(notes);
          break;
      }
    } else if (widget.dose.existingLog != null) {
      // Status didn't change but might need to save notes
      if (_isAdHoc) return;
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
          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: kBottomSheetContentPadding,
              children: [
                if (_isAdHoc && widget.dose.existingLog != null) ...[
                  SectionFormCard(
                    neutral: true,
                    title: 'Amount',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StepperRow36(
                              controller: _amountController!,
                              fixedFieldWidth: 120,
                              onDec: () {
                                final step = _adHocStepSize(
                                  widget.dose.existingLog!.doseUnit,
                                );
                                final max = _maxAdHocAmount ?? double.infinity;
                                final v =
                                    double.tryParse(_amountController!.text) ??
                                    0;
                                _amountController!.text = _formatAmount(
                                  (v - step).clamp(0.0, max),
                                );
                                setState(() => _hasChanged = true);
                              },
                              onInc: () {
                                final step = _adHocStepSize(
                                  widget.dose.existingLog!.doseUnit,
                                );
                                final max = _maxAdHocAmount ?? double.infinity;
                                final v =
                                    double.tryParse(_amountController!.text) ??
                                    0;
                                _amountController!.text = _formatAmount(
                                  (v + step).clamp(0.0, max),
                                );
                                setState(() => _hasChanged = true);
                              },
                              decoration: buildCompactFieldDecoration(
                                context: context,
                              ),
                            ),
                          ),
                          const SizedBox(width: kSpacingS),
                          Text(
                            widget.dose.existingLog!.doseUnit,
                            style: helperTextStyle(
                              context,
                            )?.copyWith(fontWeight: kFontWeightMedium),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: kSpacingM),
                ],
                SectionFormCard(
                  neutral: true,
                  title: 'Dose',
                  children: [
                    () {
                      final schedule = Hive.box<Schedule>(
                        'schedules',
                      ).get(widget.dose.scheduleId);

                      final med = (schedule?.medicationId != null)
                          ? Hive.box<Medication>(
                              'medications',
                            ).get(schedule!.medicationId)
                          : null;

                      if (schedule != null && med != null) {
                        return DoseDialogDosePreview(
                          med: med,
                          schedule: schedule,
                          status: _selectedStatus,
                        );
                      }

                      return DoseSummaryRow(
                        dose: widget.dose,
                        showMedicationName: true,
                        onTap: () {},
                      );
                    }(),
                  ],
                ),
                const SizedBox(height: kSpacingM),
                if (widget.dose.existingLog != null) ...[
                  SectionFormCard(
                    neutral: true,
                    title: 'Date & Time',
                    children: [
                      SizedBox(
                        height: kStandardFieldHeight,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedActionTime,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked == null) return;
                            setState(() {
                              _selectedActionTime = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                _selectedActionTime.hour,
                                _selectedActionTime.minute,
                              );
                              if (_selectedStatus == DoseStatus.snoozed) {
                                _selectedSnoozeUntil = _selectedActionTime;
                              }
                              _hasChanged = true;
                            });
                          },
                          icon: const Icon(
                            Icons.calendar_today,
                            size: kIconSizeSmall,
                          ),
                          label: Text(
                            MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(_selectedActionTime),
                          ),
                        ),
                      ),
                      const SizedBox(height: kSpacingS),
                      SizedBox(
                        height: kStandardFieldHeight,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                _selectedActionTime,
                              ),
                            );
                            if (picked == null) return;
                            setState(() {
                              _selectedActionTime = DateTime(
                                _selectedActionTime.year,
                                _selectedActionTime.month,
                                _selectedActionTime.day,
                                picked.hour,
                                picked.minute,
                              );
                              if (_selectedStatus == DoseStatus.snoozed) {
                                _selectedSnoozeUntil = _selectedActionTime;
                              }
                              _hasChanged = true;
                            });
                          },
                          icon: const Icon(
                            Icons.schedule,
                            size: kIconSizeSmall,
                          ),
                          label: Text(
                            TimeOfDay.fromDateTime(
                              _selectedActionTime,
                            ).format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSpacingM),
                ],
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
                if (_selectedStatus == DoseStatus.snoozed) ...[
                  SectionFormCard(
                    neutral: true,
                    title: 'Snooze Until',
                    children: [
                      SizedBox(
                        height: kStandardFieldHeight,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final max = _maxSnoozeUntil();
                            final firstDate = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            final lastDate = max != null
                                ? DateTime(max.year, max.month, max.day)
                                : now.add(const Duration(days: 60));

                            final initial =
                                _selectedSnoozeUntil ?? _defaultSnoozeUntil();
                            final clampedInitialDate = DateTime(
                              initial.year,
                              initial.month,
                              initial.day,
                            );
                            final safeInitialDate =
                                clampedInitialDate.isBefore(firstDate)
                                ? firstDate
                                : (clampedInitialDate.isAfter(lastDate)
                                      ? lastDate
                                      : clampedInitialDate);

                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: safeInitialDate,
                              firstDate: firstDate,
                              lastDate: lastDate.isBefore(firstDate)
                                  ? firstDate
                                  : lastDate,
                            );
                            if (pickedDate == null) return;

                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(initial),
                            );
                            if (pickedTime == null) return;

                            var dt = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );

                            if (dt.isBefore(now)) dt = now;
                            if (max != null && dt.isAfter(max)) dt = max;

                            setState(() {
                              _selectedSnoozeUntil = dt;
                              _selectedActionTime = dt;
                              _hasChanged = true;
                            });
                          },
                          icon: const Icon(
                            Icons.snooze_rounded,
                            size: kIconSizeSmall,
                          ),
                          label: Text(() {
                            final dt =
                                _selectedSnoozeUntil ?? _defaultSnoozeUntil();
                            final date = MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(dt);
                            final time = TimeOfDay.fromDateTime(
                              dt,
                            ).format(context);
                            return '$date • $time';
                          }()),
                        ),
                      ),
                      if (_maxSnoozeUntil() != null) ...[
                        const SizedBox(height: kSpacingS),
                        Text(() {
                          final max = _maxSnoozeUntil()!;
                          final date = MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(max);
                          final time = TimeOfDay.fromDateTime(
                            max,
                          ).format(context);
                          return 'Must be before the next scheduled dose ($date • $time).';
                        }(), style: helperTextStyle(context)),
                      ],
                    ],
                  ),
                  const SizedBox(height: kSpacingM),
                ],
                SectionFormCard(
                  neutral: true,
                  title: 'Notes',
                  children: [
                    TextField(
                      controller: _notesController,
                      onChanged: (_) => setState(() => _hasChanged = true),
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
                          icon: const Icon(Icons.save, size: kIconSizeSmall),
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
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: kSpacingS,
      runSpacing: kSpacingXS,
      alignment: WrapAlignment.center,
      children: [
        if (!_isAdHoc)
          PrimaryChoiceChip(
            label: const Text('Scheduled'),
            color: cs.primary,
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
          color: cs.primary,
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
          color: cs.secondary,
          selected: _selectedStatus == DoseStatus.snoozed,
          onSelected: (_) {
            setState(() {
              _selectedStatus = DoseStatus.snoozed;
              final until = _selectedSnoozeUntil ?? _defaultSnoozeUntil();
              final max = _maxSnoozeUntil();
              final clamped = max != null && until.isAfter(max) ? max : until;
              _selectedSnoozeUntil = clamped;
              _selectedActionTime = clamped;
              _hasChanged = true;
            });
          },
        ),
        PrimaryChoiceChip(
          label: const Text('Skipped'),
          color: cs.error,
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
                ? 'Press Save & Close to apply changes.'
                : 'Select a status, add notes, then press Save & Close.',
            style: helperTextStyle(context),
          ),
        ),
      ],
    );
  }
}
