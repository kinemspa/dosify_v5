import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';
import 'package:skedux/src/core/utils/datetime_formatter.dart';
import 'package:skedux/src/core/notifications/low_stock_notifier.dart';
import 'package:skedux/src/core/notifications/snooze_settings.dart';
import 'package:skedux/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/inventory_log.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:skedux/src/widgets/entry_action/entry_partial_entry_sheet.dart';
import 'package:skedux/src/widgets/entry_action/entry_syringe_picker_sheet.dart';
import 'package:skedux/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:skedux/src/features/schedules/data/entry_log_repository.dart';
import 'package:skedux/src/features/schedules/domain/calculated_entry.dart';

import 'package:skedux/src/features/schedules/domain/entry_calculator.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/features/schedules/domain/entry_status_change_log.dart';
import 'package:skedux/src/features/schedules/domain/entry_value_formatter.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:skedux/src/widgets/entry_card.dart';
import 'package:skedux/src/widgets/entry_card_meta_lines.dart';
import 'package:skedux/src/widgets/entry_dialog_entry_preview.dart';
import 'package:skedux/src/widgets/entry_status_ui.dart';
import 'package:skedux/src/widgets/unified_form.dart';
import 'package:skedux/src/widgets/entry_action/entry_syringe_gauge.dart';
import 'package:skedux/src/widgets/entry_action/entry_time_fields.dart';


enum _EntryStatusOption { scheduled, logged, snoozed, skipped, delete }

enum EntryActionSheetPresentation { bottomSheet, dialog }

class EntryActionSheetSaveRequest {
  const EntryActionSheetSaveRequest({
    required this.notes,
    required this.actionTime,
    this.actualEntryValue,
    this.actualEntryUnit,
  });

  final String? notes;
  final DateTime actionTime;
  final double? actualEntryValue;
  final String? actualEntryUnit;
}

/// Entry details and actions (Take, Snooze, Skip)
class EntryActionSheet extends StatefulWidget {
  final CalculatedEntry entry;
  final Future<void> Function(EntryActionSheetSaveRequest request) onMarkLogged;
  final Future<void> Function(EntryActionSheetSaveRequest request) onSnooze;
  final Future<void> Function(EntryActionSheetSaveRequest request) onSkip;
  final Future<void> Function(EntryActionSheetSaveRequest request) onDelete;
  final EntryActionSheetPresentation presentation;
  final EntryStatus? initialStatus;

  const EntryActionSheet({
    super.key,
    required this.entry,
    required this.onMarkLogged,
    required this.onSnooze,
    required this.onSkip,
    required this.onDelete,
    this.presentation = EntryActionSheetPresentation.dialog,
    this.initialStatus,
  });

  static Future<void> show(
    BuildContext context, {
    required CalculatedEntry entry,
    required Future<void> Function(EntryActionSheetSaveRequest request)
    onMarkLogged,
    required Future<void> Function(EntryActionSheetSaveRequest request) onSnooze,
    required Future<void> Function(EntryActionSheetSaveRequest request) onSkip,
    required Future<void> Function(EntryActionSheetSaveRequest request) onDelete,
    EntryStatus? initialStatus,
  }) {
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: cs.surface.withValues(alpha: kOpacityTransparent),
      builder: (context) => EntryActionSheet(
        entry: entry,
        onMarkLogged: onMarkLogged,
        onSnooze: onSnooze,
        onSkip: onSkip,
        onDelete: onDelete,
        presentation: EntryActionSheetPresentation.bottomSheet,
        initialStatus: initialStatus,
      ),
    );
  }

  @override
  State<EntryActionSheet> createState() => _EntryActionSheetState();
}

class _EntryActionSheetState extends State<EntryActionSheet> {
  late final TextEditingController _notesController;
  TextEditingController? _amountController;
  double? _originalAdHocAmount;
  double? _maxAdHocAmount;
  TextEditingController? _entryOverrideController;
  double? _originalEntryOverrideValue;
  String? _entryOverrideUnit;
  MdvEntryChangeMode? _mdvEntryChangeMode;
  SyringeType? _mdvSyringeType;
  String _mdvStrengthUnit = 'mg';
  late EntryStatus _selectedStatus;
  late DateTime _selectedActionTime;
  DateTime? _selectedSnoozeUntil;
  bool _hasChanged = false;
  bool _editExpanded = false;
  EntryLog? _lastLoggedLog;
  bool _showDownScrollHint = false;

  void _updateDownScrollHint(ScrollMetrics metrics) {
    final shouldShow = metrics.maxScrollExtent > (metrics.pixels + 0.5);
    if (_showDownScrollHint == shouldShow) return;
    if (!mounted) return;
    setState(() => _showDownScrollHint = shouldShow);
  }

  Widget _wrapWithDownScrollHint({
    required Widget child,
    required ScrollController controller,
  }) {
    final cs = Theme.of(context).colorScheme;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!controller.hasClients) return;
      _updateDownScrollHint(controller.position);
    });

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical) {
              _updateDownScrollHint(notification.metrics);
            }
            return false;
          },
          child: child,
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              opacity: _showDownScrollHint ? 1 : 0,
              duration: kAnimationFast,
              curve: kCurveSnappy,
              child: Padding(
                padding: kEntryActionSheetScrollHintPadding,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: kEntryActionSheetScrollHintIconSize,
                  color: cs.onSurfaceVariant.withValues(
                    alpha: kOpacityMediumHigh,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _isAdHoc => widget.entry.existingLog?.scheduleId == 'ad_hoc';

  Color _statusAccentColor(BuildContext context) {
    final schedule = Hive.box<Schedule>(
      'schedules',
    ).get(widget.entry.scheduleId);
    final disabled = schedule != null && !schedule.isActive;
    return entryStatusVisual(context, _selectedStatus, disabled: disabled).color;
  }

  _EntryStatusOption _currentStatusOption() {
    if (_isAdHoc) {
      return _selectedStatus == EntryStatus.logged
          ? _EntryStatusOption.logged
          : _EntryStatusOption.delete;
    }

    if (_selectedStatus == EntryStatus.logged) return _EntryStatusOption.logged;
    if (_selectedStatus == EntryStatus.snoozed) return _EntryStatusOption.snoozed;
    if (_selectedStatus == EntryStatus.skipped) return _EntryStatusOption.skipped;
    return _EntryStatusOption.scheduled;
  }

  void _applyStatusOption(_EntryStatusOption option) {
    setState(() {
      switch (option) {
        case _EntryStatusOption.scheduled:
          _selectedStatus = EntryStatus.pending;
          _hasChanged = true;
          break;
        case _EntryStatusOption.logged:
          _selectedStatus = EntryStatus.logged;
          _hasChanged = true;
          break;
        case _EntryStatusOption.snoozed:
          _selectedStatus = EntryStatus.snoozed;
          final until = _selectedSnoozeUntil ?? _defaultSnoozeUntil();
          final max = _maxSnoozeUntil();
          final clamped = max != null && until.isAfter(max) ? max : until;
          _selectedSnoozeUntil = clamped;
          _selectedActionTime = clamped;
          _hasChanged = true;
          break;
        case _EntryStatusOption.skipped:
          _selectedStatus = EntryStatus.skipped;
          _hasChanged = true;
          break;
        case _EntryStatusOption.delete:
          _selectedStatus = EntryStatus.pending;
          _hasChanged = true;
          break;
      }
    });
  }

  Widget _buildStatusToggle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final option = _currentStatusOption();

    String labelFor(_EntryStatusOption o) {
      return switch (o) {
        _EntryStatusOption.scheduled => 'Pending',
        _EntryStatusOption.logged => 'Logged',
        _EntryStatusOption.snoozed => 'Snoozed',
        _EntryStatusOption.skipped => 'Skipped',
        _EntryStatusOption.delete => 'Delete',
      };
    }

    IconData iconFor(_EntryStatusOption o) {
      return switch (o) {
        _EntryStatusOption.scheduled => Icons.event_available_rounded,
        _EntryStatusOption.logged => Icons.check_circle_rounded,
        _EntryStatusOption.snoozed => Icons.snooze_rounded,
        _EntryStatusOption.skipped => Icons.do_not_disturb_on_rounded,
        _EntryStatusOption.delete => Icons.delete_outline_rounded,
      };
    }

    _EntryStatusOption nextOption(_EntryStatusOption current) {
      if (_isAdHoc) {
        return current == _EntryStatusOption.logged
            ? _EntryStatusOption.delete
            : _EntryStatusOption.logged;
      }

      return switch (current) {
        _EntryStatusOption.scheduled => _EntryStatusOption.logged,
        _EntryStatusOption.logged => _EntryStatusOption.snoozed,
        _EntryStatusOption.snoozed => _EntryStatusOption.skipped,
        _EntryStatusOption.skipped => _EntryStatusOption.scheduled,
        _EntryStatusOption.delete => _EntryStatusOption.logged,
      };
    }

    final accent = _statusAccentColor(context);

    return Center(
      child: SizedBox(
        width: kEntryActionSheetStatusButtonWidth,
        height: kStandardFieldHeight,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: cs.onPrimary,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => _applyStatusOption(nextOption(option)),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconFor(option), size: kIconSizeSmall),
              const SizedBox(width: kSpacingS),
              Text(
                labelFor(option),
                style: bodyTextStyle(context)?.copyWith(color: cs.onPrimary),
              ),
              const SizedBox(width: kSpacingS),
              Opacity(
                opacity: 0.65,
                child: Icon(Icons.sync_alt_rounded, size: kIconSizeSmall),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedTimeField(BuildContext context) {
    return EntryLoggedTimeField(
      currentTime: _selectedActionTime,
      accentColor: _statusAccentColor(context),
      onTimeChanged: (dt) => setState(() {
        _selectedActionTime = dt;
        _hasChanged = true;
      }),
    );
  }

  Widget _buildSnoozeUntilField(BuildContext context) {
    return EntrySnoozeUntilField(
      selectedSnoozeUntil: _selectedSnoozeUntil,
      defaultSnoozeUntil: _defaultSnoozeUntil(),
      maxSnoozeUntil: _maxSnoozeUntil(),
      onSnoozeChanged: (dt) => setState(() {
        _selectedSnoozeUntil = dt;
        _selectedActionTime = dt;
        _hasChanged = true;
      }),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: sectionTitleStyle(context)),
        const SizedBox(height: kSpacingS),
        TextField(
          controller: _notesController,
          onChanged: (_) => setState(() => _hasChanged = true),
          style: bodyTextStyle(context),
          decoration: buildFieldDecoration(
            context,
            hint: 'Add any notes about this entry…',
          ),
          maxLines: 3,
          textCapitalization: kTextCapitalizationDefault,
        ),
      ],
    );
  }

  Widget _buildEntryCardPreview(BuildContext context) {
    final schedule = Hive.box<Schedule>(
      'schedules',
    ).get(widget.entry.scheduleId);
    final medId =
        schedule?.medicationId ?? widget.entry.existingLog?.medicationId;
    final med = medId == null
        ? null
        : Hive.box<Medication>('medications').get(medId);
    if (med == null) {
      return SizedBox(
        width: double.infinity,
        child: EntryDialogEntryFallbackSummary(entry: widget.entry),
      );
    }

    final strengthLabel = MedicationDisplayHelpers.strengthOrConcentrationLabel(
      med,
    );
    final metrics = schedule == null
        ? '${EntryValueFormatter.format(widget.entry.entryValue, widget.entry.entryUnit)} ${widget.entry.entryUnit}'
        : schedule.displayMetrics(med);

    String? lastEntryLine() {
      final log = _lastLoggedLog;
      final at = log?.actionTime;
      if (log == null || at == null) return null;

      final value = log.actualEntryValue ?? log.entryValue;
      final unit = log.actualEntryUnit ?? log.entryUnit;
      final amount = '${EntryValueFormatter.format(value, unit)} $unit';

      final now = DateTime.now();
      final sameDay =
          at.year == now.year && at.month == now.month && at.day == now.day;
      final time = DateTimeFormatter.formatTime(context, at);
      if (sameDay) return 'Last Entry: $amount | $time';

      final date = MaterialLocalizations.of(context).formatShortDate(at);
      return 'Last Entry: $amount | $date';
    }

    final metaLines = buildEntryCardInventoryMetaLines(
      context,
      medication: med,
      lastEntryLine: lastEntryLine(),
    );

    final mdvGaugeInCard = med.form == MedicationForm.multiDoseVial
        ? _buildMdvGaugeInCard(context, med: med)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EntryCard(
          entry: widget.entry,
          medicationName: med.name,
          strengthOrConcentrationLabel: strengthLabel,
          entryMetrics: metrics,
          isActive: schedule?.isActive ?? true,
          medicationFormIcon: MedicationDisplayHelpers.medicationFormIcon(
            med.form,
          ),
          entryNumber: schedule == null
              ? null
              : ScheduleOccurrenceService.occurrenceNumber(
                  schedule,
                  widget.entry.scheduledTime,
                ),
          statusOverride: _selectedStatus,
          detailLines: metaLines,
          onTap: () {},
        ),
        if (mdvGaugeInCard != null) ...[
          const SizedBox(height: kSpacingS),
          mdvGaugeInCard,
        ],
      ],
    );
  }

  Widget _buildMdvGaugeInCard(BuildContext context, {required Medication med}) {
    final syringe = _mdvSyringeType ?? SyringeType.ml_1_0;
    final result = _entryOverrideController == null
        ? null
        : mdvEntryChangeResult(
            med: med,
            rawText: _entryOverrideController!.text,
            mode: _mdvEntryChangeMode,
            syringe: _mdvSyringeType,
            strengthUnit: _mdvStrengthUnit,
          );

    final fallbackVolumeMl = med.volumePerEntry;
    final fallbackUnits = fallbackVolumeMl == null
        ? 0.0
        : (fallbackVolumeMl * SyringeType.ml_1_0.unitsPerMl);

    final fillUnits = (result?.syringeUnits ?? fallbackUnits).clamp(
      0.0,
      syringe.maxUnits.toDouble(),
    );

    return EntrySyringeGauge(syringeType: syringe, fillUnits: fillUnits);
  }

  /// Converts the current MDV entry value to the equivalent value in [newMode]
  /// so the user doesn't see a unit mismatch (e.g. "30 units → 30 mg").
  void _convertMdvEntryValueOnModeChange(MdvEntryChangeMode newMode) {
    final controller = _entryOverrideController;
    if (controller == null) return;

    // Resolve medication
    final schedule =
        Hive.box<Schedule>('schedules').get(widget.entry.scheduleId);
    final medId =
        schedule?.medicationId ?? widget.entry.existingLog?.medicationId;
    final med =
        medId == null ? null : Hive.box<Medication>('medications').get(medId);
    if (med == null) return;

    // Compute result for current mode + current text value
    final result = mdvEntryChangeResult(
      med: med,
      rawText: controller.text,
      mode: _mdvEntryChangeMode,
      syringe: _mdvSyringeType,
      strengthUnit: _mdvStrengthUnit,
    );
    if (result == null || !result.success || result.hasError) return;

    // Extract equivalent value in the new mode
    double? newValue;
    switch (newMode) {
      case MdvEntryChangeMode.strength:
        final mcg = result.entryMassMcg;
        if (mcg != null) {
          newValue = switch (_mdvStrengthUnit) {
            'mcg' => mcg,
            'mg' => mcg / 1000,
            'g' => mcg / 1000000,
            _ => mcg / 1000,
          };
        }
        break;
      case MdvEntryChangeMode.volume:
        final volUl = result.entryVolumeMicroliter;
        if (volUl != null) newValue = volUl / 1000;
        break;
      case MdvEntryChangeMode.units:
        newValue = result.syringeUnits;
        break;
    }

    if (newValue != null && newValue > 0) {
      controller.text = newValue % 1 == 0
          ? newValue.toInt().toString()
          : newValue.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '');
    }
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.entry.existingLog?.notes ?? '',
    );
    _selectedStatus = widget.initialStatus ?? widget.entry.status;

    final baseActionTime =
        widget.entry.existingLog?.actionTime ?? DateTime.now();
    _selectedActionTime = baseActionTime;
    if (widget.entry.existingLog == null &&
        _selectedStatus == EntryStatus.snoozed) {
      final until = _defaultSnoozeUntil();
      final max = _maxSnoozeUntil();
      final clamped = max != null && until.isAfter(max) ? max : until;
      _selectedSnoozeUntil = clamped;
      _selectedActionTime = clamped;
    } else {
      _selectedSnoozeUntil = _selectedStatus == EntryStatus.snoozed
          ? _selectedActionTime
          : _defaultSnoozeUntil();
    }

    if (_isAdHoc && widget.entry.existingLog != null) {
      final log = widget.entry.existingLog!;
      _originalAdHocAmount = log.entryValue;
      _amountController = TextEditingController(
        text: _formatAmount(log.entryValue),
      );

      final medBox = Hive.box<Medication>('medications');
      final med = medBox.get(log.medicationId);
      if (med != null) {
        final isMdv = med.form == MedicationForm.multiDoseVial;
        final currentStock = isMdv
            ? (med.activeVialVolume ?? med.containerVolumeMl ?? 0)
            : med.stockValue;

        // For existing ad-hoc logs, stock has already been deducted, so allow
        // increasing up to (currentStock + loggedAmount). For brand-new ad-hoc
        // entries (not yet persisted), cap at currentStock.
        final alreadyLogged = Hive.box<EntryLog>(
          'entry_logs',
        ).containsKey(log.id);
        final max = alreadyLogged
            ? (currentStock + log.entryValue)
            : currentStock;
        _maxAdHocAmount = max.clamp(0.0, double.infinity);

        final clampedInitial = log.entryValue.clamp(0.0, _maxAdHocAmount!);
        if ((clampedInitial - log.entryValue).abs() > 0.000001) {
          _amountController!.text = _formatAmount(clampedInitial);
        }
      } else {
        _maxAdHocAmount = double.infinity;
      }
    }

    if (!_isAdHoc) {
      final existing = widget.entry.existingLog;
      _originalEntryOverrideValue =
          existing?.actualEntryValue ?? widget.entry.entryValue;
      _entryOverrideUnit = existing?.actualEntryUnit ?? widget.entry.entryUnit;
      _entryOverrideController = TextEditingController(
        text: _formatAmount(
          _originalEntryOverrideValue ?? widget.entry.entryValue,
        ),
      );

      final schedule = Hive.box<Schedule>(
        'schedules',
      ).get(widget.entry.scheduleId);
      final medId = schedule?.medicationId;
      final med = medId == null
          ? null
          : Hive.box<Medication>('medications').get(medId);
      if (med != null && med.form == MedicationForm.multiDoseVial) {
        _mdvStrengthUnit = mdvStrengthUnitFor(med);
        _mdvEntryChangeMode = inferMdvModeFromUnit(
          _entryOverrideUnit ?? widget.entry.entryUnit,
        );

        final recon = SavedReconstitutionRepository().ownedForMedication(
          med.id,
        );
        final savedSyringeSizeMl = recon?.syringeSizeMl;

        _mdvSyringeType = savedSyringeSizeMl != null && savedSyringeSizeMl > 0
            ? SyringeTypeLookup.forVolumeMl(savedSyringeSizeMl)
            : defaultMdvSyringeType(
                med,
                overrideValue: _originalEntryOverrideValue,
                overrideUnit: _entryOverrideUnit ?? widget.entry.entryUnit,
              );

        _entryOverrideUnit = mdvEntryChangeUnitLabel(
          _mdvEntryChangeMode!,
          _mdvStrengthUnit,
        );
      }
    }

    // Cache most recent taken log for the medication (used for "Last entry").
    final schedule = Hive.box<Schedule>(
      'schedules',
    ).get(widget.entry.scheduleId);
    final medId =
        schedule?.medicationId ?? widget.entry.existingLog?.medicationId;
    if (medId != null) {
      final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
      final logs = repo.getByMedicationId(medId);
      final currentId = widget.entry.existingLog?.id;

      EntryLog? best;
      for (final l in logs) {
        if (l.action != EntryAction.logged) continue;
        final at = l.actionTime;
        if (currentId != null && l.id == currentId) continue;
        if (best == null || at.isAfter(best.actionTime)) {
          best = l;
        }
      }

      _lastLoggedLog = best;
    }

    // Always expand Advanced section so users can see it immediately
    _editExpanded = true;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amountController?.dispose();
    _entryOverrideController?.dispose();
    super.dispose();
  }

  String _formatAmount(double value) {
    final unit = _entryOverrideUnit ?? widget.entry.entryUnit;
    return EntryValueFormatter.format(value, unit);
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
    ).get(widget.entry.scheduleId);
    if (schedule == null) return null;

    final now = DateTime.now();
    final fromForNext = widget.entry.scheduledTime.isAfter(now)
        ? widget.entry.scheduledTime.add(const Duration(minutes: 1))
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

  (double?, String?) _resolvedActualEntryOverride() {
    final controller = _entryOverrideController;
    if (controller == null) return (null, null);

    final unit = _entryOverrideUnit;
    final effectiveUnit = unit ?? widget.entry.entryUnit;
    final parsed = EntryValueFormatter.tryParseAndClamp(
      controller.text,
      effectiveUnit,
      min: 0.0,
      max: double.infinity,
    );
    if (parsed == null) return (null, unit);

    final baselineValue =
        widget.entry.existingLog?.entryValue ?? widget.entry.entryValue;
    final baselineUnit =
        widget.entry.existingLog?.entryUnit ?? widget.entry.entryUnit;

    final normalizedUnit = (unit ?? '').trim();
    if ((parsed - baselineValue).abs() <= 0.000001 &&
        normalizedUnit.toLowerCase() == baselineUnit.trim().toLowerCase()) {
      return (null, null);
    }

    return (parsed, unit);
  }

  Future<void> _saveAdHocAmountAndNotesIfNeeded() async {
    if (!_isAdHoc) return;
    final existingLog = widget.entry.existingLog;
    if (existingLog == null) return;
    final controller = _amountController;
    if (controller == null) return;

    final parsedAmount =
        EntryValueFormatter.tryParseAndClamp(
          controller.text,
          existingLog.entryUnit,
          min: 0.0,
          max: double.infinity,
        ) ??
        0;
    final maxAmount = _maxAdHocAmount ?? double.infinity;
    final newAmount = EntryValueFormatter.clampAndQuantize(
      parsedAmount,
      existingLog.entryUnit,
      min: 0.0,
      max: maxAmount,
    );
    final oldAmount = _originalAdHocAmount ?? existingLog.entryValue;
    final trimmedNotes = _notesController.text.trim();
    final newNotes = trimmedNotes.isEmpty ? null : trimmedNotes;

    final amountChanged = (newAmount - oldAmount).abs() > 0.000001;
    final notesChanged = (existingLog.notes ?? '') != (newNotes ?? '');

    final entryLogBox = Hive.box<EntryLog>('entry_logs');
    final isNew = !entryLogBox.containsKey(existingLog.id);
    if (!isNew && !amountChanged && !notesChanged) return;

    final entryLogRepo = EntryLogRepository(entryLogBox);
    final inventoryBox = Hive.box<InventoryLog>('inventory_logs');
    final medBox = Hive.box<Medication>('medications');
    final med = medBox.get(existingLog.medicationId);

    if (med != null && (isNew || amountChanged)) {
      final isMdv = med.form == MedicationForm.multiDoseVial;
      final latestStock = isMdv
          ? (med.activeVialVolume ?? med.containerVolumeMl ?? 0)
          : med.stockValue;

      final double updatedStock;
      final double changeAmount;
      final double previousStock;
      if (isNew) {
        previousStock = latestStock;
        changeAmount = -newAmount;
        updatedStock = (latestStock - newAmount).clamp(0.0, double.infinity);
      } else {
        // We want net change to match "-newAmount" instead of "-oldAmount".
        // Delta to apply to current stock is: oldAmount - newAmount.
        final adjustment = oldAmount - newAmount;
        changeAmount = -newAmount;
        previousStock = latestStock + oldAmount;
        updatedStock = (latestStock + adjustment).clamp(0.0, double.infinity);
      }

      final Medication updatedMedication;
      if (isMdv) {
        final max =
            (med.containerVolumeMl != null && med.containerVolumeMl! > 0)
            ? med.containerVolumeMl!
            : double.infinity;
        updatedMedication = med.copyWith(
          activeVialVolume: updatedStock.clamp(0.0, max),
        );
      } else {
        updatedMedication = med.copyWith(stockValue: updatedStock);
      }

      await medBox.put(med.id, updatedMedication);
      await LowStockNotifier.handleStockChange(
        before: med,
        after: updatedMedication,
      );

      final inv = inventoryBox.get(existingLog.id);
      if (inv == null) {
        inventoryBox.put(
          existingLog.id,
          InventoryLog(
            id: existingLog.id,
            medicationId: existingLog.medicationId,
            medicationName: existingLog.medicationName,
            changeType: InventoryChangeType.adHocEntry,
            previousStock: previousStock,
            newStock: updatedStock,
            changeAmount: changeAmount,
            notes: newNotes ?? 'Ad-hoc entry',
            timestamp: _selectedActionTime,
          ),
        );
      } else if (inv.changeType == InventoryChangeType.adHocEntry) {
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

    final updatedLog = EntryLog(
      id: existingLog.id,
      scheduleId: existingLog.scheduleId,
      scheduleName: existingLog.scheduleName,
      medicationId: existingLog.medicationId,
      medicationName: existingLog.medicationName,
      scheduledTime: existingLog.scheduledTime,
      actionTime: _selectedActionTime,
      entryValue: (isNew || amountChanged) ? newAmount : existingLog.entryValue,
      entryUnit: existingLog.entryUnit,
      action: existingLog.action,
      actualEntryValue: existingLog.actualEntryValue,
      actualEntryUnit: existingLog.actualEntryUnit,
      notes: newNotes,
    );
    await entryLogRepo.upsert(updatedLog);

    _originalAdHocAmount = updatedLog.entryValue;
    controller.text = _formatAmount(updatedLog.entryValue);
  }

  Future<void> _saveExistingLogEdits() async {
    if (widget.entry.existingLog == null) return;

    try {
      final existing = widget.entry.existingLog!;
      final trimmedNotes = _notesController.text.trim();
      final newNotes = trimmedNotes.isEmpty ? null : trimmedNotes;

      final (newActualEntryValue, newActualEntryUnit) =
          _resolvedActualEntryOverride();

      final notesChanged = (existing.notes ?? '') != (newNotes ?? '');
      final actualValueChanged =
          (existing.actualEntryValue ?? 0) != (newActualEntryValue ?? 0) ||
          (existing.actualEntryValue == null) != (newActualEntryValue == null);
      final actualUnitChanged =
          (existing.actualEntryUnit ?? '') != (newActualEntryUnit ?? '') ||
          (existing.actualEntryUnit == null) != (newActualEntryUnit == null);

      if (!notesChanged && !actualValueChanged && !actualUnitChanged) return;

      if (existing.action == EntryAction.logged &&
          (actualValueChanged || actualUnitChanged)) {
        final schedule = Hive.box<Schedule>(
          'schedules',
        ).get(existing.scheduleId);
        final medBox = Hive.box<Medication>('medications');
        final med = medBox.get(existing.medicationId);

        if (med != null) {
          final oldValue = existing.actualEntryValue ?? existing.entryValue;
          final oldUnit = existing.actualEntryUnit ?? existing.entryUnit;
          final newValue = newActualEntryValue ?? existing.entryValue;
          final newUnit = newActualEntryUnit ?? existing.entryUnit;

          final oldDelta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: med,
            schedule: schedule,
            entryValue: oldValue,
            entryUnit: oldUnit,
            preferEntryValue: true,
          );
          final newDelta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: med,
            schedule: schedule,
            entryValue: newValue,
            entryUnit: newUnit,
            preferEntryValue: true,
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

      final updatedLog = EntryLog(
        id: existing.id,
        scheduleId: existing.scheduleId,
        scheduleName: existing.scheduleName,
        medicationId: existing.medicationId,
        medicationName: existing.medicationName,
        scheduledTime: existing.scheduledTime,
        actionTime: _selectedActionTime,
        entryValue: existing.entryValue,
        entryUnit: existing.entryUnit,
        action: existing.action,
        actualEntryValue: newActualEntryValue,
        actualEntryUnit: newActualEntryUnit,
        notes: newNotes,
      );

      final repo = EntryLogRepository(Hive.box<EntryLog>('entry_logs'));
      await repo.upsert(updatedLog);

      if (mounted) {
        showAppSnackBar(context, 'Notes saved');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error saving notes: $e');
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      await _saveAdHocAmountAndNotesIfNeeded();

      final (actualEntryValue, actualEntryUnit) = _resolvedActualEntryOverride();

      // If status changed, call appropriate callback
      if (_selectedStatus != widget.entry.status) {
        // Persist an audit event when editing an existing logged entry.
        // This keeps a record of "status changed" even if the change reverts
        // back to pending/overdue (which deletes the original log).
        if (widget.entry.existingLog != null) {
          final auditBox = Hive.box<EntryStatusChangeLog>(
            'entry_status_change_logs',
          );
          final now = DateTime.now();
          final id = now.microsecondsSinceEpoch.toString();
          auditBox.put(
            id,
            EntryStatusChangeLog(
              id: id,
              scheduleId: widget.entry.scheduleId,
              scheduleName: widget.entry.scheduleName,
              medicationId: widget.entry.existingLog!.medicationId,
              medicationName: widget.entry.existingLog!.medicationName,
              scheduledTime: widget.entry.scheduledTime,
              changeTime: now,
              fromStatus: widget.entry.status.name,
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

        final request = EntryActionSheetSaveRequest(
          notes: notes,
          actionTime: _selectedStatus == EntryStatus.snoozed
              ? (_selectedSnoozeUntil ?? _defaultSnoozeUntil())
              : _selectedActionTime,
          actualEntryValue: actualEntryValue,
          actualEntryUnit: actualEntryUnit,
        );

        switch (_selectedStatus) {
          case EntryStatus.logged:
            await widget.onMarkLogged(request);
            break;
          case EntryStatus.skipped:
            await widget.onSkip(request);
            break;
          case EntryStatus.snoozed:
            await widget.onSnooze(request);
            break;
          case EntryStatus.pending:
          case EntryStatus.due:
          case EntryStatus.overdue:
            // Revert to original - delete existing log
            await widget.onDelete(request);
            break;
        }
      } else if (widget.entry.existingLog != null) {
        // Status didn't change but might need to save notes
        if (_isAdHoc) return;
        await _saveExistingLogEdits();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error saving entry changes: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget formContent(
      BuildContext context,
      ScrollController scrollController, {
      List<Widget> leading = const [],
    }) {
      return _wrapWithDownScrollHint(
        controller: scrollController,
        child: ListView(
          controller: scrollController,
          padding: kEntryActionSheetContentPadding,
          children: [
            ...leading,
            _buildEntryCardPreview(context),
            const SizedBox(height: kSpacingS),
            _buildStatusToggle(context),
            const SizedBox(height: kSpacingXS),
            _buildStatusHint(context),
            const SizedBox(height: kSpacingM),
            _buildNotesField(context),
            if (_selectedStatus == EntryStatus.logged) ...[
              const SizedBox(height: kSpacingM),
              _buildLoggedTimeField(context),
            ],
            if (_selectedStatus == EntryStatus.snoozed) ...[
              const SizedBox(height: kSpacingM),
              _buildSnoozeUntilField(context),
            ],
            const SizedBox(height: kSpacingM),
            CollapsibleSectionFormCard(
              title: 'Advanced',
              frameless: true,
              isExpanded: _editExpanded,
              onExpandedChanged: (v) => setState(() => _editExpanded = v),
              children: [
                EntryPartialEntrySection(
                  isAdHoc: _isAdHoc,
                  existingLog: widget.entry.existingLog,
                  scheduleId: widget.entry.scheduleId,
                  amountController: _amountController,
                  maxAdHocAmount: _maxAdHocAmount,
                  entryBaseUnit: widget.entry.entryUnit,
                  entryOverrideController: _entryOverrideController,
                  entryOverrideUnit: _entryOverrideUnit,
                  mdvMode: _mdvEntryChangeMode,
                  mdvSyringe: _mdvSyringeType,
                  mdvStrengthUnit: _mdvStrengthUnit,
                  onChanged: () => setState(() => _hasChanged = true),
                  onMdvModeChanged: (value) {
                    _convertMdvEntryValueOnModeChange(value);
                    setState(() {
                      _mdvEntryChangeMode = value;
                      _entryOverrideUnit =
                          mdvEntryChangeUnitLabel(value, _mdvStrengthUnit);
                      _hasChanged = true;
                    });
                  },
                  onMdvSyringeChanged: (value) => setState(() {
                    _mdvSyringeType = value;
                    _hasChanged = true;
                  }),
                  onUnitChanged: (value) => setState(() {
                    _entryOverrideUnit = value;
                    _hasChanged = true;
                  }),
                  onMdvStrengthUnitChanged: (value) {
                    // Convert the current controller text to the new unit
                    final controller = _entryOverrideController;
                    if (controller != null) {
                      final raw = double.tryParse(controller.text.trim());
                      if (raw != null && raw > 0) {
                        // Convert via mcg as intermediate
                        final mcg = mdvStrengthToMcg(raw, _mdvStrengthUnit);
                        final converted = switch (value) {
                          'mcg' => mcg,
                          'mg' => mcg / 1000,
                          'g' => mcg / 1000000,
                          _ => mcg / 1000,
                        };
                        controller.text = converted % 1 == 0
                            ? converted.toInt().toString()
                            : converted
                                .toStringAsFixed(4)
                                .replaceAll(RegExp(r'0+$'), '');
                      }
                    }
                    setState(() {
                      _mdvStrengthUnit = value;
                      if (_mdvEntryChangeMode == MdvEntryChangeMode.strength) {
                        _entryOverrideUnit = value;
                      }
                      _hasChanged = true;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (widget.presentation == EntryActionSheetPresentation.bottomSheet) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final mq = MediaQuery.of(context);
          final bottomInset = mq.padding.bottom + mq.viewInsets.bottom;
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(kBorderRadiusLarge),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: formContent(
                    context,
                    scrollController,
                    leading: [
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
                                    'Log entry',
                                    style: cardTitleStyle(
                                      context,
                                    )?.copyWith(color: colorScheme.primary),
                                  ),
                                  Text(
                                    'Confirm status, adjust timing if needed, add notes, and save.',
                                    style: helperTextStyle(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: kBottomSheetContentPadding.copyWith(
                    bottom: kBottomSheetContentPadding.bottom + bottomInset,
                  ),
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
      insetPadding: kEntryActionSheetDialogInsetPadding,
      titleTextStyle: cardTitleStyle(
        context,
      )?.copyWith(color: colorScheme.primary),
      contentTextStyle: bodyTextStyle(context),
      title: const Text('Log entry'),
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

  Widget _buildStatusHint(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        _hasChanged
            ? 'Tap Save & Close to apply changes.'
            : 'Tap to toggle the Entry status.',
        style: helperTextStyle(context)?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
