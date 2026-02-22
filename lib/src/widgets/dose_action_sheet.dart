import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/core/notifications/low_stock_notifier.dart';
import 'package:dosifi_v5/src/core/notifications/snooze_settings.dart';
import 'package:dosifi_v5/src/features/medications/data/saved_reconstitution_repository.dart';
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
import 'package:dosifi_v5/src/widgets/dose_card_meta_lines.dart';
import 'package:dosifi_v5/src/widgets/dose_dialog_dose_preview.dart';
import 'package:dosifi_v5/src/widgets/dose_status_ui.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';

enum _MdvDoseChangeMode { strength, volume, units }

enum _DoseStatusOption { scheduled, taken, snoozed, skipped, delete }

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
      isDismissible: true,
      enableDrag: true,
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
  bool _editExpanded = false;
  DoseLog? _lastTakenLog;
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
                padding: kDoseActionSheetScrollHintPadding,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: kDoseActionSheetScrollHintIconSize,
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

  DateTime _clampDate(
    DateTime value, {
    required DateTime first,
    required DateTime last,
  }) {
    if (value.isBefore(first)) return first;
    if (value.isAfter(last)) return last;
    return value;
  }

  bool get _isAdHoc => widget.dose.existingLog?.scheduleId == 'ad_hoc';

  Color _statusAccentColor(BuildContext context) {
    final schedule = Hive.box<Schedule>(
      'schedules',
    ).get(widget.dose.scheduleId);
    final disabled = schedule != null && !schedule.isActive;
    return doseStatusVisual(context, _selectedStatus, disabled: disabled).color;
  }

  _DoseStatusOption _currentStatusOption() {
    if (_isAdHoc) {
      return _selectedStatus == DoseStatus.taken
          ? _DoseStatusOption.taken
          : _DoseStatusOption.delete;
    }

    if (_selectedStatus == DoseStatus.taken) return _DoseStatusOption.taken;
    if (_selectedStatus == DoseStatus.snoozed) return _DoseStatusOption.snoozed;
    if (_selectedStatus == DoseStatus.skipped) return _DoseStatusOption.skipped;
    return _DoseStatusOption.scheduled;
  }

  void _applyStatusOption(_DoseStatusOption option) {
    setState(() {
      switch (option) {
        case _DoseStatusOption.scheduled:
          _selectedStatus = DoseStatus.pending;
          _hasChanged = true;
          break;
        case _DoseStatusOption.taken:
          _selectedStatus = DoseStatus.taken;
          _hasChanged = true;
          break;
        case _DoseStatusOption.snoozed:
          _selectedStatus = DoseStatus.snoozed;
          final until = _selectedSnoozeUntil ?? _defaultSnoozeUntil();
          final max = _maxSnoozeUntil();
          final clamped = max != null && until.isAfter(max) ? max : until;
          _selectedSnoozeUntil = clamped;
          _selectedActionTime = clamped;
          _hasChanged = true;
          break;
        case _DoseStatusOption.skipped:
          _selectedStatus = DoseStatus.skipped;
          _hasChanged = true;
          break;
        case _DoseStatusOption.delete:
          _selectedStatus = DoseStatus.pending;
          _hasChanged = true;
          break;
      }
    });
  }

  Widget _buildStatusToggle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final option = _currentStatusOption();

    String labelFor(_DoseStatusOption o) {
      return switch (o) {
        _DoseStatusOption.scheduled => 'Scheduled',
        _DoseStatusOption.taken => 'Taken',
        _DoseStatusOption.snoozed => 'Snoozed',
        _DoseStatusOption.skipped => 'Skipped',
        _DoseStatusOption.delete => 'Delete',
      };
    }

    IconData iconFor(_DoseStatusOption o) {
      return switch (o) {
        _DoseStatusOption.scheduled => Icons.event_available_rounded,
        _DoseStatusOption.taken => Icons.check_circle_rounded,
        _DoseStatusOption.snoozed => Icons.snooze_rounded,
        _DoseStatusOption.skipped => Icons.do_not_disturb_on_rounded,
        _DoseStatusOption.delete => Icons.delete_outline_rounded,
      };
    }

    _DoseStatusOption nextOption(_DoseStatusOption current) {
      if (_isAdHoc) {
        return current == _DoseStatusOption.taken
            ? _DoseStatusOption.delete
            : _DoseStatusOption.taken;
      }

      return switch (current) {
        _DoseStatusOption.scheduled => _DoseStatusOption.taken,
        _DoseStatusOption.taken => _DoseStatusOption.snoozed,
        _DoseStatusOption.snoozed => _DoseStatusOption.skipped,
        _DoseStatusOption.skipped => _DoseStatusOption.scheduled,
        _DoseStatusOption.delete => _DoseStatusOption.taken,
      };
    }

    final accent = _statusAccentColor(context);

    return Center(
      child: SizedBox(
        width: kDoseActionSheetStatusButtonWidth,
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
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEditSectionChildren(BuildContext context) {
    return [
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
        const SizedBox(height: kSpacingXS),
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
              const strengthUnits = <String>['mcg', 'mg', 'g'];
              final normalizedUnit = (_doseOverrideUnit ?? widget.dose.doseUnit)
                  .toLowerCase();
              final selectedStrengthUnit =
                  strengthUnits.contains(normalizedUnit)
                  ? normalizedUnit
                  : 'mg';

              return Row(
                children: [
                  Expanded(
                    child: StepperRow36(
                      controller: _doseOverrideController!,
                      onDec: () {
                        final unit = _doseOverrideUnit ?? '';
                        final step = _doseOverrideStepSize(unit);
                        final v =
                            double.tryParse(_doseOverrideController!.text) ?? 0;
                        _doseOverrideController!.text = _formatAmount(
                          (v - step).clamp(0.0, double.infinity),
                        );
                        setState(() => _hasChanged = true);
                      },
                      onInc: () {
                        final unit = _doseOverrideUnit ?? '';
                        final step = _doseOverrideStepSize(unit);
                        final v =
                            double.tryParse(_doseOverrideController!.text) ?? 0;
                        _doseOverrideController!.text = _formatAmount(
                          (v + step).clamp(0.0, double.infinity),
                        );
                        setState(() => _hasChanged = true);
                      },
                      decoration: buildCompactFieldDecoration(context: context),
                    ),
                  ),
                  const SizedBox(width: kSpacingS),
                  SizedBox(
                    width: kCompactControlWidth,
                    child: SmallDropdown36<String>(
                      value: selectedStrengthUnit,
                      items: strengthUnits
                          .map(
                            (unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null || value == _doseOverrideUnit) return;
                        setState(() {
                          _doseOverrideUnit = value;
                          _hasChanged = true;
                        });
                      },
                    ),
                  ),
                ],
              );
            }

            final mode = _mdvDoseChangeMode ?? _MdvDoseChangeMode.strength;
            final syringe = _mdvSyringeType ?? SyringeType.ml_1_0;
            final unitLabel = _mdvDoseChangeUnitLabel(mode, _mdvStrengthUnit);

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
                const SizedBox(height: kSpacingXS),
                LabelFieldRow(
                  label: 'Syringe',
                  field: SmallDropdown36<SyringeType>(
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
                ),
                const SizedBox(height: kSpacingXS),
                Row(
                  children: [
                    Expanded(
                      child: StepperRow36(
                        controller: _doseOverrideController!,
                        onDec: () {
                          final step = _doseOverrideStepSize(unitLabel);
                          final v =
                              double.tryParse(_doseOverrideController!.text) ??
                              0;
                          _doseOverrideController!.text = _formatAmount(
                            (v - step).clamp(0.0, double.infinity),
                          );
                          setState(() => _hasChanged = true);
                        },
                        onInc: () {
                          final step = _doseOverrideStepSize(unitLabel);
                          final v =
                              double.tryParse(_doseOverrideController!.text) ??
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
                const SizedBox(height: kSpacingXS),
                // Gauge is embedded in the dose card preview.
              ],
            );
          },
        ),
        const SizedBox(height: kSpacingM),
      ],
    ];
  }

  Widget _buildTakenTimeField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time taken', style: sectionTitleStyle(context)),
        const SizedBox(height: kSpacingXS),
        SizedBox(
          width: double.infinity,
          height: kStandardFieldHeight,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                final firstDate = DateUtils.dateOnly(DateTime(2000));
                final lastDate = DateUtils.dateOnly(DateTime(2100));
                final initialDate = _clampDate(
                  DateUtils.dateOnly(_selectedActionTime),
                  first: firstDate,
                  last: lastDate,
                );
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
                if (pickedDate == null) return;
                if (!context.mounted) return;

                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_selectedActionTime),
                );
                if (pickedTime == null) return;
                if (!context.mounted) return;

                setState(() {
                  _selectedActionTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  _hasChanged = true;
                });
              } catch (e) {
                if (context.mounted) {
                  showAppSnackBar(context, 'Unable to open time picker: $e');
                }
              }
            },
            icon: Icon(
              Icons.check_circle_rounded,
              size: kIconSizeSmall,
              color: _statusAccentColor(context),
            ),
            label: Text(() {
              final date = MaterialLocalizations.of(
                context,
              ).formatMediumDate(_selectedActionTime);
              final time = DateTimeFormatter.formatTime(
                context,
                _selectedActionTime,
              );
              return '$date • $time';
            }()),
          ),
        ),
      ],
    );
  }

  Widget _buildSnoozeUntilField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Snooze until', style: sectionTitleStyle(context)),
        const SizedBox(height: kSpacingS),
        if (_maxSnoozeUntil() != null) ...[
          Text(() {
            final max = _maxSnoozeUntil()!;
            final date = MaterialLocalizations.of(
              context,
            ).formatMediumDate(max);
            final time = DateTimeFormatter.formatTime(context, max);
            return 'Next dose is at $date • $time.';
          }(), style: helperTextStyle(context)),
          const SizedBox(height: kSpacingS),
        ],
        SizedBox(
          width: double.infinity,
          height: kStandardFieldHeight,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                final now = DateTime.now();
                final initial = _selectedSnoozeUntil ?? _defaultSnoozeUntil();
                final max = _maxSnoozeUntil();

                final firstDate = DateUtils.dateOnly(now);
                final lastDate = DateUtils.dateOnly(DateTime(2100));
                final initialDate = _clampDate(
                  DateUtils.dateOnly(initial),
                  first: firstDate,
                  last: lastDate,
                );

                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
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
              } catch (e) {
                if (context.mounted) {
                  showAppSnackBar(context, 'Unable to open snooze picker: $e');
                }
              }
            },
            icon: const Icon(Icons.snooze_rounded, size: kIconSizeSmall),
            label: Text(() {
              final dt = _selectedSnoozeUntil ?? _defaultSnoozeUntil();
              final date = MaterialLocalizations.of(
                context,
              ).formatMediumDate(dt);
              final time = DateTimeFormatter.formatTime(context, dt);
              return '$date • $time';
            }()),
          ),
        ),
      ],
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
            hint: 'Add any notes about this dose…',
          ),
          maxLines: 3,
          textCapitalization: kTextCapitalizationDefault,
        ),
      ],
    );
  }

  Widget _buildDoseCardPreview(BuildContext context) {
    final schedule = Hive.box<Schedule>(
      'schedules',
    ).get(widget.dose.scheduleId);
    final medId =
        schedule?.medicationId ?? widget.dose.existingLog?.medicationId;
    final med = medId == null
        ? null
        : Hive.box<Medication>('medications').get(medId);
    if (med == null) {
      return SizedBox(
        width: double.infinity,
        child: DoseDialogDoseFallbackSummary(dose: widget.dose),
      );
    }

    final strengthLabel = MedicationDisplayHelpers.strengthOrConcentrationLabel(
      med,
    );
    final metrics = schedule == null
        ? '${DoseValueFormatter.format(widget.dose.doseValue, widget.dose.doseUnit)} ${widget.dose.doseUnit}'
        : MedicationDisplayHelpers.doseMetricsSummary(
            med,
            doseTabletQuarters: schedule.doseTabletQuarters,
            doseCapsules: schedule.doseCapsules,
            doseSyringes: schedule.doseSyringes,
            doseVials: schedule.doseVials,
            doseMassMcg: schedule.doseMassMcg?.toDouble(),
            doseVolumeMicroliter: schedule.doseVolumeMicroliter?.toDouble(),
            syringeUnits: schedule.doseIU?.toDouble(),
          );

    String? lastDoseLine() {
      final log = _lastTakenLog;
      final at = log?.actionTime;
      if (log == null || at == null) return null;

      final value = log.actualDoseValue ?? log.doseValue;
      final unit = log.actualDoseUnit ?? log.doseUnit;
      final amount = '${DoseValueFormatter.format(value, unit)} $unit';

      final now = DateTime.now();
      final sameDay =
          at.year == now.year && at.month == now.month && at.day == now.day;
      final time = DateTimeFormatter.formatTime(context, at);
      if (sameDay) return 'Last Dose: $amount • $time';

      final date = MaterialLocalizations.of(context).formatShortDate(at);
      return 'Last Dose: $amount • $date';
    }

    final metaLines = buildDoseCardInventoryMetaLines(
      context,
      medication: med,
      lastDoseLine: lastDoseLine(),
    );

    final mdvGaugeInCard = med.form == MedicationForm.multiDoseVial
        ? _buildMdvGaugeInCard(context, med: med)
        : null;

    return SizedBox(
      width: double.infinity,
      child: DoseCard(
        dose: widget.dose,
        medicationName: med.name,
        strengthOrConcentrationLabel: strengthLabel,
        doseMetrics: metrics,
        isActive: schedule?.isActive ?? true,
        medicationFormIcon: MedicationDisplayHelpers.medicationFormIcon(
          med.form,
        ),
        doseNumber: schedule == null
            ? null
            : ScheduleOccurrenceService.occurrenceNumber(
                schedule,
                widget.dose.scheduledTime,
              ),
        statusOverride: _selectedStatus,
        detailLines: metaLines,
        footer: mdvGaugeInCard,
        onTap: () {},
      ),
    );
  }

  Widget _buildMdvGaugeInCard(BuildContext context, {required Medication med}) {
    final syringe = _mdvSyringeType ?? SyringeType.ml_1_0;
    final result = _doseOverrideController == null
        ? null
        : _mdvDoseChangeResult(
            med: med,
            rawText: _doseOverrideController!.text,
          );

    final fallbackVolumeMl = med.volumePerDose;
    final fallbackUnits = fallbackVolumeMl == null
        ? 0.0
        : (fallbackVolumeMl * SyringeType.ml_1_0.unitsPerMl);

    final fillUnits = (result?.syringeUnits ?? fallbackUnits).clamp(
      0.0,
      syringe.maxUnits.toDouble(),
    );

    final cs = Theme.of(context).colorScheme;
    final captionStyle = microHelperTextStyle(context)?.copyWith(
      color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
    );
    final syringeLabel = syringe.name.replaceAll('ml', 'mL');
    final unitsLabel = fillUnits.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WhiteSyringeGauge(
          totalUnits: syringe.maxUnits.toDouble(),
          fillUnits: fillUnits,
          interactive: false,
          showValueLabel: false,
        ),
        const SizedBox(height: kSpacingXS),
        Text('$unitsLabel units on $syringeLabel syringe', style: captionStyle),
      ],
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

        // For existing ad-hoc logs, stock has already been deducted, so allow
        // increasing up to (currentStock + loggedAmount). For brand-new ad-hoc
        // entries (not yet persisted), cap at currentStock.
        final alreadyLogged = Hive.box<DoseLog>(
          'dose_logs',
        ).containsKey(log.id);
        final max = alreadyLogged
            ? (currentStock + log.doseValue)
            : currentStock;
        _maxAdHocAmount = max.clamp(0.0, double.infinity);

        final clampedInitial = log.doseValue.clamp(0.0, _maxAdHocAmount!);
        if ((clampedInitial - log.doseValue).abs() > 0.000001) {
          _amountController!.text = _formatAmount(clampedInitial);
        }
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

        final recon = SavedReconstitutionRepository().ownedForMedication(
          med.id,
        );
        final savedSyringeSizeMl = recon?.syringeSizeMl;

        _mdvSyringeType = savedSyringeSizeMl != null && savedSyringeSizeMl > 0
            ? SyringeTypeLookup.forVolumeMl(savedSyringeSizeMl)
            : _defaultMdvSyringeType(
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

    // Cache most recent taken log for the medication (used for "Last dose").
    final schedule = Hive.box<Schedule>(
      'schedules',
    ).get(widget.dose.scheduleId);
    final medId =
        schedule?.medicationId ?? widget.dose.existingLog?.medicationId;
    if (medId != null) {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      final logs = repo.getByMedicationId(medId);
      final currentId = widget.dose.existingLog?.id;

      DoseLog? best;
      for (final l in logs) {
        if (l.action != DoseAction.taken) continue;
        final at = l.actionTime;
        if (currentId != null && l.id == currentId) continue;
        if (best == null || at.isAfter(best.actionTime)) {
          best = l;
        }
      }

      _lastTakenLog = best;
    }

    // Always expand Advanced section so users can see it immediately
    _editExpanded = true;
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
    final time = DateTimeFormatter.formatTime(context, max);
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

    final doseLogBox = Hive.box<DoseLog>('dose_logs');
    final isNew = !doseLogBox.containsKey(existingLog.id);
    if (!isNew && !amountChanged && !notesChanged) return;

    final doseLogRepo = DoseLogRepository(doseLogBox);
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
            changeType: InventoryChangeType.adHocDose,
            previousStock: previousStock,
            newStock: updatedStock,
            changeAmount: changeAmount,
            notes: newNotes ?? 'Ad-hoc dose',
            timestamp: _selectedActionTime,
          ),
        );
      } else if (inv.changeType == InventoryChangeType.adHocDose) {
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
      doseValue: (isNew || amountChanged) ? newAmount : existingLog.doseValue,
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
        showAppSnackBar(context, 'Error saving dose changes: $e');
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
          padding: kDoseActionSheetContentPadding,
          children: [
            ...leading,
            _buildDoseCardPreview(context),
            const SizedBox(height: kSpacingS),
            _buildStatusToggle(context),
            const SizedBox(height: kSpacingXS),
            _buildStatusHint(context),
            const SizedBox(height: kSpacingM),
            _buildNotesField(context),
            if (_selectedStatus == DoseStatus.taken) ...[
              const SizedBox(height: kSpacingM),
              _buildTakenTimeField(context),
            ],
            if (_selectedStatus == DoseStatus.snoozed) ...[
              const SizedBox(height: kSpacingM),
              _buildSnoozeUntilField(context),
            ],
            const SizedBox(height: kSpacingM),
            CollapsibleSectionFormCard(
              title: 'Advanced',
              neutral: true,
              isExpanded: _editExpanded,
              onExpandedChanged: (v) => setState(() => _editExpanded = v),
              children: _buildEditSectionChildren(context),
            ),
          ],
        ),
      );
    }

    if (widget.presentation == DoseActionSheetPresentation.bottomSheet) {
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
                                    'Take dose',
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
                : 'Tap to toggle the Dose status.',
            style: helperTextStyle(context),
          ),
        ),
      ],
    );
  }
}
