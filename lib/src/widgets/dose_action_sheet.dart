import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/notifications/low_stock_notifier.dart';
import 'package:dosifi_v5/src/core/notifications/snooze_settings.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_status_change_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_value_formatter.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/widgets/dose_card.dart';
import 'package:dosifi_v5/src/widgets/dose_dialog_dose_preview.dart';
import 'package:dosifi_v5/src/widgets/dose_status_ui.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';

enum _MdvDoseChangeMode { strength, volume, units }

enum DoseActionSheetPresentation { bottomSheet, dialog }

class DoseActionSheetSaveRequest {
  const DoseActionSheetSaveRequest({
    required this.notes,
    required this.actionTime,
    this.actualDoseValue,
    this.actualDoseUnit,
  });

  final String? notes;
  final DateTime actionTime;
  final double? actualDoseValue;
  final String? actualDoseUnit;
}

/// Dose details and actions (Take, Snooze, Skip)
class DoseActionSheet extends StatefulWidget {
  final CalculatedDose dose;
  final Future<void> Function(DoseActionSheetSaveRequest request) onMarkTaken;
  final Future<void> Function(DoseActionSheetSaveRequest request) onSnooze;
  final Future<void> Function(DoseActionSheetSaveRequest request) onSkip;
  final Future<void> Function(DoseActionSheetSaveRequest request) onDelete;
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
    required Future<void> Function(DoseActionSheetSaveRequest request)
    onMarkTaken,
    required Future<void> Function(DoseActionSheetSaveRequest request) onSnooze,
    required Future<void> Function(DoseActionSheetSaveRequest request) onSkip,
    required Future<void> Function(DoseActionSheetSaveRequest request) onDelete,
    DoseStatus? initialStatus,
  }) {
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: cs.surface.withValues(alpha: kOpacityTransparent),
      builder: (context) => DoseActionSheet(
        dose: dose,
        onMarkTaken: onMarkTaken,
        onSnooze: onSnooze,
        onSkip: onSkip,
        onDelete: onDelete,
        presentation: DoseActionSheetPresentation.bottomSheet,
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
  TextEditingController? _doseOverrideController;
  double? _originalDoseOverrideValue;
  String? _doseOverrideUnit;
  _MdvDoseChangeMode? _mdvDoseChangeMode;
  SyringeType? _mdvSyringeType;
  String _mdvStrengthUnit = 'mg';
  late DoseStatus _selectedStatus;
  late DateTime _selectedActionTime;
  DateTime? _selectedSnoozeUntil;
  bool _hasChanged = false;

  bool get _isAdHoc => widget.dose.existingLog?.scheduleId == 'ad_hoc';

  Color _statusAccentColor(BuildContext context) {
    final schedule = Hive.box<Schedule>(
      'schedules',
    ).get(widget.dose.scheduleId);
    final disabled = schedule != null && !schedule.isActive;
    return doseStatusVisual(context, _selectedStatus, disabled: disabled).color;
  }

  Widget _buildDoseCardPreview(BuildContext context) {
    final schedule = Hive.box<Schedule>(
      'schedules',
    ).get(widget.dose.scheduleId);
    if (schedule == null) {
      return SizedBox(
        width: double.infinity,
        child: DoseDialogDoseFallbackSummary(dose: widget.dose),
      );
    }

    final med = Hive.box<Medication>('medications').get(schedule.medicationId);
    if (med == null) {
      return SizedBox(
        width: double.infinity,
        child: DoseDialogDoseFallbackSummary(dose: widget.dose),
      );
    }

    final strengthLabel = MedicationDisplayHelpers.strengthOrConcentrationLabel(
      med,
    );
    final metrics = MedicationDisplayHelpers.doseMetricsSummary(
      med,
      doseTabletQuarters: schedule.doseTabletQuarters,
      doseCapsules: schedule.doseCapsules,
      doseSyringes: schedule.doseSyringes,
      doseVials: schedule.doseVials,
      doseMassMcg: schedule.doseMassMcg?.toDouble(),
      doseVolumeMicroliter: schedule.doseVolumeMicroliter?.toDouble(),
      syringeUnits: schedule.doseIU?.toDouble(),
    );

    return SizedBox(
      width: double.infinity,
      child: DoseCard(
        dose: widget.dose,
        medicationName: med.name,
        strengthOrConcentrationLabel: strengthLabel,
        doseMetrics: metrics,
        isActive: schedule.isActive,
        medicationFormIcon: MedicationDisplayHelpers.medicationFormIcon(
          med.form,
        ),
        doseNumber: ScheduleOccurrenceService.occurrenceNumber(
          schedule,
          widget.dose.scheduledTime,
        ),
        statusOverride: _selectedStatus,
        showActions: false,
        onTap: () {},
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.dose.existingLog?.notes ?? '',
    );
    _selectedStatus = widget.initialStatus ?? widget.dose.status;

    final baseActionTime =
        widget.dose.existingLog?.actionTime ?? DateTime.now();
    _selectedActionTime = baseActionTime;
    if (widget.dose.existingLog == null &&
        _selectedStatus == DoseStatus.snoozed) {
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

    if (!_isAdHoc) {
      final existing = widget.dose.existingLog;
      _originalDoseOverrideValue =
          existing?.actualDoseValue ?? widget.dose.doseValue;
      _doseOverrideUnit = existing?.actualDoseUnit ?? widget.dose.doseUnit;
      _doseOverrideController = TextEditingController(
        text: _formatAmount(
          _originalDoseOverrideValue ?? widget.dose.doseValue,
        ),
      );

      final schedule = Hive.box<Schedule>(
        'schedules',
      ).get(widget.dose.scheduleId);
      final medId = schedule?.medicationId;
      final med = medId == null
          ? null
          : Hive.box<Medication>('medications').get(medId);
      if (med != null && med.form == MedicationForm.multiDoseVial) {
        _mdvStrengthUnit = _mdvStrengthUnitFor(med);
        _mdvDoseChangeMode = _inferMdvModeFromUnit(
          _doseOverrideUnit ?? widget.dose.doseUnit,
        );

        _mdvSyringeType = _defaultMdvSyringeType(
          med,
          overrideValue: _originalDoseOverrideValue,
          overrideUnit: _doseOverrideUnit ?? widget.dose.doseUnit,
        );

        _doseOverrideUnit = _mdvDoseChangeUnitLabel(
          _mdvDoseChangeMode!,
          _mdvStrengthUnit,
        );
      }
    }
  }

  String _mdvStrengthUnitFor(Medication med) {
    return switch (med.strengthUnit) {
      Unit.mcg || Unit.mcgPerMl => 'mcg',
      Unit.mg || Unit.mgPerMl => 'mg',
      Unit.g || Unit.gPerMl => 'g',
      Unit.units || Unit.unitsPerMl => 'units',
    };
  }

  _MdvDoseChangeMode _inferMdvModeFromUnit(String rawUnit) {
    final u = rawUnit.trim().toLowerCase();
    if (u == 'ml' || u.contains('ml')) return _MdvDoseChangeMode.volume;
    if (u == 'u' || u.contains('unit')) return _MdvDoseChangeMode.units;
    return _MdvDoseChangeMode.strength;
  }

  String _mdvDoseChangeUnitLabel(_MdvDoseChangeMode mode, String strengthUnit) {
    switch (mode) {
      case _MdvDoseChangeMode.units:
        return 'units';
      case _MdvDoseChangeMode.volume:
        return 'ml';
      case _MdvDoseChangeMode.strength:
        return strengthUnit;
    }
  }

  SyringeType _defaultMdvSyringeType(
    Medication med, {
    required double? overrideValue,
    required String overrideUnit,
  }) {
    final doseVolumeMl = med.volumePerDose;
    if (doseVolumeMl != null && doseVolumeMl > 0) {
      return SyringeTypeLookup.forVolumeMl(doseVolumeMl);
    }

    final unit = overrideUnit.trim().toLowerCase();
    final v = overrideValue;
    if (v != null && v > 0) {
      if (unit == 'ml' || unit.contains('ml')) {
        return SyringeTypeLookup.forVolumeMl(v);
      }
      if (unit == 'u' || unit.contains('unit')) {
        return SyringeTypeLookup.forUnits(v);
      }
    }

    return SyringeType.ml_1_0;
  }

  double _mdvStrengthToMcg(double value) {
    switch (_mdvStrengthUnit) {
      case 'mcg':
        return value;
      case 'mg':
        return value * 1000;
      case 'g':
        return value * 1000000;
      case 'units':
        return value;
      default:
        return value * 1000;
    }
  }

  DoseCalculationResult? _mdvDoseChangeResult({
    required Medication med,
    required String rawText,
  }) {
    final mode = _mdvDoseChangeMode;
    final syringe = _mdvSyringeType;
    final totalStrengthMcg = _mdvTotalVialStrengthMcg(med);
    final totalVolumeMicroliter = _mdvTotalVialVolumeMicroliter(med);
    if (mode == null || syringe == null) return null;
    if (totalStrengthMcg == null || totalVolumeMicroliter == null) return null;

    final value = double.tryParse(rawText.trim()) ?? 0;
    switch (mode) {
      case _MdvDoseChangeMode.strength:
        return DoseCalculator.calculateFromStrengthMDV(
          strengthMcg: _mdvStrengthToMcg(value),
          totalVialStrengthMcg: totalStrengthMcg,
          totalVialVolumeMicroliter: totalVolumeMicroliter,
          syringeType: syringe,
        );
      case _MdvDoseChangeMode.volume:
        return DoseCalculator.calculateFromVolumeMDV(
          volumeMicroliter: value * 1000,
          totalVialStrengthMcg: totalStrengthMcg,
          totalVialVolumeMicroliter: totalVolumeMicroliter,
          syringeType: syringe,
        );
      case _MdvDoseChangeMode.units:
        return DoseCalculator.calculateFromUnitsMDV(
          syringeUnits: value,
          totalVialStrengthMcg: totalStrengthMcg,
          totalVialVolumeMicroliter: totalVolumeMicroliter,
          syringeType: syringe,
        );
    }
  }

  double? _mdvTotalVialStrengthMcg(Medication med) {
    if (med.form != MedicationForm.multiDoseVial) return null;

    final volumeMl = med.containerVolumeMl ?? 1.0;
    final strength = med.strengthValue;

    return switch (med.strengthUnit) {
      Unit.mcg => strength,
      Unit.mg => strength * 1000,
      Unit.g => strength * 1000000,
      Unit.units => strength,
      Unit.mcgPerMl => strength * volumeMl,
      Unit.mgPerMl => (strength * 1000) * volumeMl,
      Unit.gPerMl => (strength * 1000000) * volumeMl,
      Unit.unitsPerMl => strength * volumeMl,
    };
  }

  double? _mdvTotalVialVolumeMicroliter(Medication med) {
    if (med.form != MedicationForm.multiDoseVial) return null;
    final volumeMl = med.containerVolumeMl ?? 1.0;
    return volumeMl * 1000;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amountController?.dispose();
    _doseOverrideController?.dispose();
    super.dispose();
  }

  String _formatAmount(double value) {
    final unit = _doseOverrideUnit ?? widget.dose.doseUnit;
    return DoseValueFormatter.format(value, unit);
  }

  DateTime _defaultSnoozeUntil() {
    final now = DateTime.now();
    final max = _maxSnoozeUntil();
    if (max == null || !max.isAfter(now)) {
      return now.add(const Duration(minutes: 15));
    }

    final pct = SnoozeSettings.value.value.defaultSnoozePercent;
    final window = max.difference(now);
    final seconds = (window.inSeconds * pct / 100).round();
    final target = now.add(Duration(seconds: seconds));
    return target.isAfter(max) ? max : target;
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

  Future<void> _showSnoozePastNextDoseAlert(DateTime max) {
    final date = MaterialLocalizations.of(context).formatMediumDate(max);
    final time = TimeOfDay.fromDateTime(max).format(context);
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Snooze limit'),
        content: Text(
          'Snooze time must be before the next scheduled dose. The latest allowed snooze is $date • $time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  double _adHocStepSize(String unit) {
    return DoseValueFormatter.stepSizeForUnit(unit);
  }

  double _doseOverrideStepSize(String unit) {
    return DoseValueFormatter.stepSizeForUnit(unit);
  }

  (double?, String?) _resolvedActualDoseOverride() {
    final controller = _doseOverrideController;
    if (controller == null) return (null, null);

    final unit = _doseOverrideUnit;
    final effectiveUnit = unit ?? widget.dose.doseUnit;
    final parsed = DoseValueFormatter.tryParseAndClamp(
      controller.text,
      effectiveUnit,
      min: 0.0,
      max: double.infinity,
    );
    if (parsed == null) return (null, unit);

    final baselineValue =
        widget.dose.existingLog?.doseValue ?? widget.dose.doseValue;
    final baselineUnit =
        widget.dose.existingLog?.doseUnit ?? widget.dose.doseUnit;

    final normalizedUnit = (unit ?? '').trim();
    if ((parsed - baselineValue).abs() <= 0.000001 &&
        normalizedUnit.toLowerCase() == baselineUnit.trim().toLowerCase()) {
      return (null, null);
    }

    return (parsed, unit);
  }

  Future<void> _saveAdHocAmountAndNotesIfNeeded() async {
    if (!_isAdHoc) return;
    final existingLog = widget.dose.existingLog;
    if (existingLog == null) return;
    final controller = _amountController;
    if (controller == null) return;

    final parsedAmount =
        DoseValueFormatter.tryParseAndClamp(
          controller.text,
          existingLog.doseUnit,
          min: 0.0,
          max: double.infinity,
        ) ??
        0;
    final maxAmount = _maxAdHocAmount ?? double.infinity;
    final newAmount = DoseValueFormatter.clampAndQuantize(
      parsedAmount,
      existingLog.doseUnit,
      min: 0.0,
      max: maxAmount,
    );
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

  Future<void> _saveExistingLogEdits() async {
    if (widget.dose.existingLog == null) return;

    try {
      final existing = widget.dose.existingLog!;
      final trimmedNotes = _notesController.text.trim();
      final newNotes = trimmedNotes.isEmpty ? null : trimmedNotes;

      final (newActualDoseValue, newActualDoseUnit) =
          _resolvedActualDoseOverride();

      final notesChanged = (existing.notes ?? '') != (newNotes ?? '');
      final actualValueChanged =
          (existing.actualDoseValue ?? 0) != (newActualDoseValue ?? 0) ||
          (existing.actualDoseValue == null) != (newActualDoseValue == null);
      final actualUnitChanged =
          (existing.actualDoseUnit ?? '') != (newActualDoseUnit ?? '') ||
          (existing.actualDoseUnit == null) != (newActualDoseUnit == null);

      if (!notesChanged && !actualValueChanged && !actualUnitChanged) return;

      if (existing.action == DoseAction.taken &&
          (actualValueChanged || actualUnitChanged)) {
        final schedule = Hive.box<Schedule>(
          'schedules',
        ).get(existing.scheduleId);
        final medBox = Hive.box<Medication>('medications');
        final med = medBox.get(existing.medicationId);

        if (med != null) {
          final oldValue = existing.actualDoseValue ?? existing.doseValue;
          final oldUnit = existing.actualDoseUnit ?? existing.doseUnit;
          final newValue = newActualDoseValue ?? existing.doseValue;
          final newUnit = newActualDoseUnit ?? existing.doseUnit;

          final oldDelta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: med,
            schedule: schedule,
            doseValue: oldValue,
            doseUnit: oldUnit,
            preferDoseValue: true,
          );
          final newDelta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: med,
            schedule: schedule,
            doseValue: newValue,
            doseUnit: newUnit,
            preferDoseValue: true,
          );

          if (oldDelta != null && newDelta != null) {
            final adjustment = oldDelta - newDelta;
            if (adjustment.abs() > 0.000001) {
              final updatedMed = adjustment > 0
                  ? MedicationStockAdjustment.restore(
                      medication: med,
                      delta: adjustment,
                    )
                  : MedicationStockAdjustment.deduct(
                      medication: med,
                      delta: -adjustment,
                    );
              await medBox.put(med.id, updatedMed);
              await LowStockNotifier.handleStockChange(
                before: med,
                after: updatedMed,
              );
            }
          }
        }
      }

      final updatedLog = DoseLog(
        id: existing.id,
        scheduleId: existing.scheduleId,
        scheduleName: existing.scheduleName,
        medicationId: existing.medicationId,
        medicationName: existing.medicationName,
        scheduledTime: existing.scheduledTime,
        actionTime: _selectedActionTime,
        doseValue: existing.doseValue,
        doseUnit: existing.doseUnit,
        action: existing.action,
        actualDoseValue: newActualDoseValue,
        actualDoseUnit: newActualDoseUnit,
        notes: newNotes,
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
    try {
      await _saveAdHocAmountAndNotesIfNeeded();

      final (actualDoseValue, actualDoseUnit) = _resolvedActualDoseOverride();

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
              notes: _notesController.text.isEmpty
                  ? null
                  : _notesController.text,
            ),
          );
        }

        final notes = _notesController.text.isEmpty
            ? null
            : _notesController.text;

        final request = DoseActionSheetSaveRequest(
          notes: notes,
          actionTime: _selectedStatus == DoseStatus.snoozed
              ? (_selectedSnoozeUntil ?? _defaultSnoozeUntil())
              : _selectedActionTime,
          actualDoseValue: actualDoseValue,
          actualDoseUnit: actualDoseUnit,
        );

        switch (_selectedStatus) {
          case DoseStatus.taken:
            await widget.onMarkTaken(request);
            break;
          case DoseStatus.skipped:
            await widget.onSkip(request);
            break;
          case DoseStatus.snoozed:
            await widget.onSnooze(request);
            break;
          case DoseStatus.pending:
          case DoseStatus.due:
          case DoseStatus.overdue:
            // Revert to original - delete existing log
            await widget.onDelete(request);
            break;
        }
      } else if (widget.dose.existingLog != null) {
        // Status didn't change but might need to save notes
        if (_isAdHoc) return;
        await _saveExistingLogEdits();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving dose changes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget formContent(
      BuildContext context,
      ScrollController scrollController,
    ) {
      return Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        thickness: kDoseActionSheetScrollbarThickness,
        radius: kDoseActionSheetScrollbarThumbRadius,
        child: ListView(
          controller: scrollController,
          padding: kDoseActionSheetContentPadding,
          children: [
            _buildDoseCardPreview(context),
            _buildMdvGaugePreviewIfNeeded(context),
            const SizedBox(height: kSpacingS),
            _buildStatusChips(),
            const SizedBox(height: kSpacingXS),
            _buildStatusHint(context),
            const SizedBox(height: kSpacingM),
            Text('Date & Time', style: sectionTitleStyle(context)),
            const SizedBox(height: kSpacingS),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: kStandardFieldHeight,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedActionTime,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        if (!context.mounted) return;
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
                      icon: Icon(
                        _selectedStatus == DoseStatus.taken
                            ? Icons.check_circle_rounded
                            : Icons.calendar_today,
                        size: kIconSizeSmall,
                        color: _statusAccentColor(context),
                      ),
                      label: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(_selectedActionTime),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: kSpacingS),
                Expanded(
                  child: SizedBox(
                    height: kStandardFieldHeight,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            _selectedActionTime,
                          ),
                        );
                        if (picked == null) return;
                        if (!context.mounted) return;
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
                      icon: Icon(
                        Icons.schedule,
                        size: kIconSizeSmall,
                        color: _statusAccentColor(context),
                      ),
                      label: Text(
                        TimeOfDay.fromDateTime(
                          _selectedActionTime,
                        ).format(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpacingM),
            if (_isAdHoc && widget.dose.existingLog != null) ...[
              Text('Amount', style: sectionTitleStyle(context)),
              const SizedBox(height: kSpacingS),
              Row(
                children: [
                  Expanded(
                    child: StepperRow36(
                      controller: _amountController!,
                      onDec: () {
                        final step = _adHocStepSize(
                          widget.dose.existingLog!.doseUnit,
                        );
                        final max = _maxAdHocAmount ?? double.infinity;
                        final v = double.tryParse(_amountController!.text) ?? 0;
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
                        final v = double.tryParse(_amountController!.text) ?? 0;
                        _amountController!.text = _formatAmount(
                          (v + step).clamp(0.0, max),
                        );
                        setState(() => _hasChanged = true);
                      },
                      decoration: buildCompactFieldDecoration(context: context),
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
              const SizedBox(height: kSpacingM),
            ],
            if (!_isAdHoc) ...[
              Text('Dose change', style: sectionTitleStyle(context)),
              const SizedBox(height: kSpacingS),
              Text(
                'Use this to record the actual dose taken, if different from the scheduled dose.',
                style: helperTextStyle(context),
              ),
              const SizedBox(height: kSpacingS),
              Builder(
                builder: (context) {
                  final schedule = Hive.box<Schedule>(
                    'schedules',
                  ).get(widget.dose.scheduleId);
                  final medId = schedule?.medicationId;
                  final med = medId == null
                      ? null
                      : Hive.box<Medication>('medications').get(medId);

                  final isMdv = med?.form == MedicationForm.multiDoseVial;

                  if (!isMdv || med == null) {
                    return Row(
                      children: [
                        Expanded(
                          child: StepperRow36(
                            controller: _doseOverrideController!,
                            onDec: () {
                              final unit = _doseOverrideUnit ?? '';
                              final step = _doseOverrideStepSize(unit);
                              final v =
                                  double.tryParse(
                                    _doseOverrideController!.text,
                                  ) ??
                                  0;
                              _doseOverrideController!.text = _formatAmount(
                                (v - step).clamp(0.0, double.infinity),
                              );
                              setState(() => _hasChanged = true);
                            },
                            onInc: () {
                              final unit = _doseOverrideUnit ?? '';
                              final step = _doseOverrideStepSize(unit);
                              final v =
                                  double.tryParse(
                                    _doseOverrideController!.text,
                                  ) ??
                                  0;
                              _doseOverrideController!.text = _formatAmount(
                                (v + step).clamp(0.0, double.infinity),
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
                          _doseOverrideUnit ?? widget.dose.doseUnit,
                          style: helperTextStyle(
                            context,
                          )?.copyWith(fontWeight: kFontWeightMedium),
                        ),
                      ],
                    );
                  }

                  final mode =
                      _mdvDoseChangeMode ?? _MdvDoseChangeMode.strength;
                  final syringe = _mdvSyringeType ?? SyringeType.ml_1_0;
                  final unitLabel = _mdvDoseChangeUnitLabel(
                    mode,
                    _mdvStrengthUnit,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabelFieldRow(
                        label: 'Mode',
                        field: SmallDropdown36<_MdvDoseChangeMode>(
                          value: mode,
                          items: const [
                            DropdownMenuItem(
                              value: _MdvDoseChangeMode.strength,
                              child: Text('Strength'),
                            ),
                            DropdownMenuItem(
                              value: _MdvDoseChangeMode.volume,
                              child: Text('Volume'),
                            ),
                            DropdownMenuItem(
                              value: _MdvDoseChangeMode.units,
                              child: Text('Units'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null || value == _mdvDoseChangeMode) {
                              return;
                            }
                            setState(() {
                              _mdvDoseChangeMode = value;
                              _doseOverrideUnit = _mdvDoseChangeUnitLabel(
                                value,
                                _mdvStrengthUnit,
                              );
                              _hasChanged = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: kSpacingS),
                      LabelFieldRow(
                        label: 'Syringe',
                        field: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: kSpacingS,
                              runSpacing: kSpacingXS,
                              children: SyringeTypeLookup.commonPresets
                                  .map(
                                    (t) => PrimaryChoiceChip(
                                      label: Text(t.name),
                                      selected: t == syringe,
                                      onSelected: (_) {
                                        if (t == _mdvSyringeType) return;
                                        setState(() {
                                          _mdvSyringeType = t;
                                          _hasChanged = true;
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: kSpacingS),
                            SmallDropdown36<SyringeType>(
                              value: syringe,
                              items: SyringeType.values
                                  .where((t) => t != SyringeType.ml_10_0)
                                  .map(
                                    (t) => DropdownMenuItem<SyringeType>(
                                      value: t,
                                      child: Text(t.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null || value == _mdvSyringeType) {
                                  return;
                                }
                                setState(() {
                                  _mdvSyringeType = value;
                                  _hasChanged = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: kSpacingS),
                      Row(
                        children: [
                          Expanded(
                            child: StepperRow36(
                              controller: _doseOverrideController!,
                              onDec: () {
                                final step = _doseOverrideStepSize(unitLabel);
                                final v =
                                    double.tryParse(
                                      _doseOverrideController!.text,
                                    ) ??
                                    0;
                                _doseOverrideController!.text = _formatAmount(
                                  (v - step).clamp(0.0, double.infinity),
                                );
                                setState(() => _hasChanged = true);
                              },
                              onInc: () {
                                final step = _doseOverrideStepSize(unitLabel);
                                final v =
                                    double.tryParse(
                                      _doseOverrideController!.text,
                                    ) ??
                                    0;
                                _doseOverrideController!.text = _formatAmount(
                                  (v + step).clamp(0.0, double.infinity),
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
                            unitLabel,
                            style: helperTextStyle(
                              context,
                            )?.copyWith(fontWeight: kFontWeightMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: kSpacingS),
                      // Gauge is rendered directly under the dose card preview.
                    ],
                  );
                },
              ),
              const SizedBox(height: kSpacingM),
            ],
            if (_selectedStatus == DoseStatus.snoozed) ...[
              Text('Snooze Until', style: sectionTitleStyle(context)),
              const SizedBox(height: kSpacingS),
              if (_maxSnoozeUntil() != null) ...[
                Text(() {
                  final max = _maxSnoozeUntil()!;
                  final date = MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(max);
                  final time = TimeOfDay.fromDateTime(max).format(context);
                  return 'Must be before the next scheduled dose ($date • $time).';
                }(), style: helperTextStyle(context)),
                const SizedBox(height: kSpacingS),
              ],
              SizedBox(
                height: kStandardFieldHeight,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final max = _maxSnoozeUntil();
                    final firstDate = DateTime(now.year, now.month, now.day);
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
                    if (!context.mounted) return;

                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(initial),
                    );
                    if (pickedTime == null) return;
                    if (!context.mounted) return;

                    var dt = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );

                    if (dt.isBefore(now)) dt = now;
                    if (max != null && dt.isAfter(max)) {
                      await _showSnoozePastNextDoseAlert(max);
                      if (!context.mounted) return;
                      dt = max;
                    }

                    setState(() {
                      _selectedSnoozeUntil = dt;
                      _selectedActionTime = dt;
                      _hasChanged = true;
                    });
                  },
                  icon: const Icon(Icons.snooze_rounded, size: kIconSizeSmall),
                  label: Text(() {
                    final dt = _selectedSnoozeUntil ?? _defaultSnoozeUntil();
                    final date = MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(dt);
                    final time = TimeOfDay.fromDateTime(dt).format(context);
                    return '$date • $time';
                  }()),
                ),
              ),
              const SizedBox(height: kSpacingM),
            ],
            Text('Notes', style: sectionTitleStyle(context)),
            const SizedBox(height: kSpacingS),
            TextField(
              controller: _notesController,
              onChanged: (_) => setState(() => _hasChanged = true),
              style: bodyTextStyle(context),
              decoration: buildFieldDecoration(
                context,
                hint: 'Add any notes about this dose…',
              ),
              maxLines: 3,
              textCapitalization: kTextCapitalizationDefault,
            ),
          ],
        ),
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
                Padding(
                  padding: kBottomSheetHeaderPadding.copyWith(
                    bottom: kSpacingM,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Take dose',
                              style: sectionTitleStyle(context),
                            ),
                            Text(
                              'Confirm status, adjust timing if needed, add notes, and save.',
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
                Expanded(child: formContent(context, scrollController)),
                Padding(
                  padding: kBottomSheetContentPadding,
                  child: Row(
                    children: [
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
                ),
              ],
            ),
          );
        },
      );
    }

    final dialogScrollController = ScrollController();
    final maxHeight = MediaQuery.of(context).size.height * 0.70;

    return AlertDialog(
      insetPadding: kDoseActionSheetDialogInsetPadding,
      titleTextStyle: cardTitleStyle(
        context,
      )?.copyWith(color: colorScheme.primary),
      contentTextStyle: bodyTextStyle(context),
      title: const Text('Take dose'),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm status, adjust timing if needed, add notes, and save.',
                style: helperTextStyle(context),
              ),
              const SizedBox(height: kSpacingS),
              Expanded(child: formContent(context, dialogScrollController)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await _saveChanges();
            if (context.mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.save, size: kIconSizeSmall),
          label: const Text('Save & Close'),
        ),
      ],
    );
  }

  Widget _buildMdvGaugePreviewIfNeeded(BuildContext context) {
    if (_isAdHoc) return const SizedBox.shrink();

    final schedule = Hive.box<Schedule>('schedules').get(widget.dose.scheduleId);
    final medId = schedule?.medicationId;
    final med = medId == null ? null : Hive.box<Medication>('medications').get(medId);
    if (med == null || med.form != MedicationForm.multiDoseVial) {
      return const SizedBox.shrink();
    }

    final syringe = _mdvSyringeType ?? SyringeType.ml_1_0;
    final result = _doseOverrideController == null
        ? null
        : _mdvDoseChangeResult(med: med, rawText: _doseOverrideController!.text);

    final fallbackVolumeMl = med.volumePerDose;
    final fallbackUnits = fallbackVolumeMl == null
        ? 0.0
        : (fallbackVolumeMl * SyringeType.ml_1_0.unitsPerMl);

    final fillUnits = (result?.syringeUnits ?? fallbackUnits).clamp(
      0.0,
      syringe.maxUnits.toDouble(),
    );

    return Column(
      children: [
        const SizedBox(height: kSpacingS),
        SizedBox(
          width: double.infinity,
          child: WhiteSyringeGauge(
            totalUnits: syringe.maxUnits.toDouble(),
            fillUnits: fillUnits,
            interactive: false,
            showValueLabel: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips() {
    final scheduledColor = doseStatusVisual(
      context,
      DoseStatus.pending,
      disabled: false,
    ).color;
    final skippedColor = doseStatusVisual(
      context,
      DoseStatus.skipped,
      disabled: false,
    ).color;
    final chips = <Widget>[];
    if (!_isAdHoc) {
      chips.add(
        PrimaryChoiceChip(
          label: const Text('Scheduled'),
          color: scheduledColor,
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
      );
    }

    chips.addAll([
      PrimaryChoiceChip(
        label: const Text('Taken'),
        color: kDoseStatusTakenGreen,
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
        color: kDoseStatusSnoozedOrange,
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
        color: skippedColor,
        selected: _selectedStatus == DoseStatus.skipped,
        onSelected: (_) {
          setState(() {
            _selectedStatus = DoseStatus.skipped;
            _hasChanged = true;
          });
        },
      ),
    ]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColWidth =
            (constraints.maxWidth - kSpacingS) / 2;
        final sized = <Widget>[];
        for (var i = 0; i < chips.length; i++) {
          final isLast = i == chips.length - 1;
          final width = chips.length == 3 && isLast
              ? constraints.maxWidth
              : twoColWidth;
          sized.add(SizedBox(width: width, child: chips[i]));
        }

        return Wrap(
          spacing: kSpacingS,
          runSpacing: kSpacingXS,
          alignment: WrapAlignment.center,
          children: sized,
        );
      },
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
                ? 'Tap Save & Close to apply changes.'
                : 'Select a status, add notes, then tap Save & Close.',
            style: helperTextStyle(context),
          ),
        ),
      ],
    );
  }
}
