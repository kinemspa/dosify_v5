// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/controllers/schedule_form_controller.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/schedule_summary_card.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/dose_input_field.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class AddEditSchedulePage extends ConsumerStatefulWidget {
  const AddEditSchedulePage({super.key, this.initial});
  final Schedule? initial;

  @override
  ConsumerState<AddEditSchedulePage> createState() =>
      _AddEditSchedulePageState();
}

class _AddEditSchedulePageState extends ConsumerState<AddEditSchedulePage> {
  final _formKey = GlobalKey<FormState>();

  // For floating summary card
  final GlobalKey _summaryKey = GlobalKey();
  double _summaryHeight = 130; // Initial height estimate

  late final TextEditingController _name;
  late final TextEditingController _medicationName;
  late final TextEditingController _doseValue;
  late final TextEditingController _doseUnit;
  late final TextEditingController _daysOn;
  late final TextEditingController _daysOff;
  late final TextEditingController _cycleN;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s?.name ?? '');
    _medicationName = TextEditingController(text: s?.medicationName ?? '');
    _doseValue = TextEditingController(text: s?.doseValue.toString() ?? '');
    _doseUnit = TextEditingController(text: s?.doseUnit ?? 'mg');

    // Cycle defaults
    final n = s?.cycleEveryNDays ?? 2;
    _cycleN = TextEditingController(text: n.toString());
    _daysOn = TextEditingController(text: '${n ~/ 2}');
    _daysOff = TextEditingController(text: '${n - (n ~/ 2)}');

    // Listeners to update controller state
    _name.addListener(_onNameChanged);
    _doseValue.addListener(_onDoseChanged);
    _doseUnit.addListener(_onDoseChanged);
    _daysOn.addListener(_onCycleChanged);
    _daysOff.addListener(_onCycleChanged);
    _cycleN.addListener(_onCycleChanged);
  }

  @override
  void dispose() {
    _name.removeListener(_onNameChanged);
    _doseValue.removeListener(_onDoseChanged);
    _doseUnit.removeListener(_onDoseChanged);
    _daysOn.removeListener(_onCycleChanged);
    _daysOff.removeListener(_onCycleChanged);
    _cycleN.removeListener(_onCycleChanged);

    _name.dispose();
    _medicationName.dispose();
    _doseValue.dispose();
    _doseUnit.dispose();
    _daysOn.dispose();
    _daysOff.dispose();
    _cycleN.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    ref.read(scheduleFormProvider(widget.initial).notifier).setName(_name.text);
  }

  void _onDoseChanged() {
    final val = double.tryParse(_doseValue.text.trim()) ?? 0;
    ref
        .read(scheduleFormProvider(widget.initial).notifier)
        .updateDose(val, _doseUnit.text);
  }

  void _onCycleChanged() {
    final on = int.tryParse(_daysOn.text.trim()) ?? 5;
    final off = int.tryParse(_daysOff.text.trim()) ?? 2;

    final notifier = ref.read(scheduleFormProvider(widget.initial).notifier);
    notifier.setDaysOn(on);
    notifier.setDaysOff(off);
    // Note: cycleN is updated via setCycleN if we had it, but logic uses daysOn/Off or cycleN depending on mode.
    // The controller uses cycleN for 'Every N days' logic if we added that mode, but currently it seems to use daysOn/Off for daysOnOff mode.
    // We should probably add setCycleN to controller if needed.
  }

  Future<void> _pickTimeAt(int index, TimeOfDay current) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      ref
          .read(scheduleFormProvider(widget.initial).notifier)
          .updateTime(index, picked);
    }
  }

  void _pickMedication(Medication selected) {
    ref
        .read(scheduleFormProvider(widget.initial).notifier)
        .setMedication(selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final state = ref.read(scheduleFormProvider(widget.initial));
    final notifier = ref.read(scheduleFormProvider(widget.initial).notifier);

    // Validate medication selection
    if (state.selectedMed == null && state.medicationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a medication first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If name was auto-generated, ask user if they want to edit before saving
    if (state.nameAuto) {
      final proceed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Use this schedule name?'),
              content: Text(state.name.isEmpty ? '(empty)' : state.name),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Edit'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Looks good'),
                ),
              ],
            ),
          ) ??
          false;
      if (!proceed) {
        return; // Let user edit
      }
    }

    // Ensure notifications permission
    final granted = await NotificationService.ensurePermissionGranted();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable notifications to receive schedule alerts.'),
        ),
      );
    }

    // Proactive checks
    final canExact = await NotificationService.canScheduleExactAlarms();
    final enabled = await NotificationService.areNotificationsEnabled();
    if (mounted && (!enabled || !canExact)) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Allow reminders'),
          content: Text(
            !enabled
                ? 'Notifications are disabled for Dosifi. Enable notifications to receive reminders.'
                : 'Android restricts exact alarms. Enable "Alarms & reminders" for Dosifi to deliver reminders at the exact time.',
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (!enabled) {
                  await NotificationService.openChannelSettings(
                    'upcoming_dose',
                  );
                }
                if (!canExact) {
                  await NotificationService.openExactAlarmsSettings();
                }
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
    }

    try {
      await notifier.save(widget.initial);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Schedule saved'),
          content: const Text('Your reminder has been saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) {
        context.go('/schedules');
      }
    } catch (e) {
      if (mounted) {
        // Check if it's the exact alarm error (though we try to catch it proactively)
        // The controller rethrows, so we catch it here.
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error saving schedule'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleFormProvider(widget.initial));
    final notifier = ref.read(scheduleFormProvider(widget.initial).notifier);
    final theme = Theme.of(context);

    // Listen for state changes that should update text fields
    ref.listen(scheduleFormProvider(widget.initial), (previous, next) {
      if (previous?.doseUnit != next.doseUnit &&
          _doseUnit.text != next.doseUnit) {
        _doseUnit.text = next.doseUnit;
      }
      if (previous?.doseValue != next.doseValue) {
        final currentVal = double.tryParse(_doseValue.text) ?? 0;
        if ((currentVal - next.doseValue).abs() > 0.001) {
          _doseValue.text = next.doseValue == next.doseValue.roundToDouble()
              ? next.doseValue.toStringAsFixed(0)
              : next.doseValue.toString();
        }
      }
      if (previous?.name != next.name && next.nameAuto) {
        // Only update name if it's auto-generated
        if (_name.text != next.name) {
          _name.text = next.name;
        }
      }
      if (previous?.medicationName != next.medicationName &&
          _medicationName.text != next.medicationName) {
        _medicationName.text = next.medicationName;
      }
    });

    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null ? 'Add Schedule' : 'Edit Schedule',
        actions: [
          if (widget.initial != null)
            IconButton(
              tooltip: 'Delete',
              onPressed: () async {
                final ok =
                    await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete schedule?'),
                        content: Text(
                          'Delete "${widget.initial!.name}"? This will cancel its notifications.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (!ok) return;
                await ScheduleScheduler.cancelFor(widget.initial!.id);
                final box = Hive.box<Schedule>('schedules');
                await box.delete(widget.initial!.id);
                if (!mounted) return;
                context.go('/schedules');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${widget.initial!.name}"')),
                );
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 120,
        child: FilledButton(
          onPressed: state.isSaving ? null : _save,
          child: state.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ),
      body: Stack(
        children: [
          // Main scrollable content
          Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(10, _summaryHeight + 18, 10, 96),
              children: [
                _section(context, 'Medication', [
                  // Medication row with label
                  LabelFieldRow(
                    label: 'Medication',
                    field:
                        state.selectedMed != null || state.medicationId != null
                        ? _MedicationSummaryDisplay(
                            medicationName: state.medicationName,
                            onClear: () {
                              // We need a clear method in controller or just setMedication to null?
                              // Controller doesn't have clear method yet, but we can implement it or just ignore for now as the original code allowed clearing.
                              // Actually, original code: _selectedMed = null; _medicationId = null; _medicationName.clear();
                              // We should probably add clearMedication to controller.
                              // For now, let's just toggle selector.
                              notifier.toggleMedSelector();
                            },
                            onExpand: notifier.toggleMedSelector,
                            isExpanded: state.showMedSelector,
                          )
                        : OutlinedButton(
                            onPressed: notifier.toggleMedSelector,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              'Select Medication',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                  ),
                  // Helper text
                  _helperBelowLeft(
                    context,
                    state.selectedMed == null && state.medicationId == null
                        ? 'Select a medication to schedule'
                        : 'Tap to change medication',
                  ),
                  // Inline medication selector
                  if (state.showMedSelector) ...[
                    const SizedBox(height: 8),
                    _InlineMedicationSelector(
                      onSelect: _pickMedication,
                      onCancel: notifier.toggleMedSelector,
                    ),
                  ],
                ]),
                const SizedBox(height: 10),
                // Week 2: Dose controls using DoseInputField widget
                if (state.selectedMed != null)
                  _section(context, 'Dose', [
                    DoseInputField(
                      medicationForm: state.selectedMed!.form,
                      strengthPerUnitMcg: _getStrengthPerUnitMcg(
                        state.selectedMed,
                      ),
                      volumePerUnitMicroliter: _getVolumePerUnitMicroliter(
                        state.selectedMed,
                      ),
                      strengthUnit: _getStrengthUnit(state.selectedMed),
                      // MDV-specific parameters
                      totalVialStrengthMcg: _getTotalVialStrengthMcg(
                        state.selectedMed,
                      ),
                      totalVialVolumeMicroliter: _getTotalVialVolumeMicroliter(
                        state.selectedMed,
                      ),
                      syringeType: _getSyringeType(
                        state.selectedMed,
                        state.selectedSyringeType,
                      ),
                      // Initial values from existing schedule or defaults
                      initialStrengthMcg: _getInitialStrengthMcg(),
                      initialTabletCount: _getInitialTabletCount(),
                      initialCapsuleCount: _getInitialCapsuleCount(),
                      initialInjectionCount: _getInitialInjectionCount(),
                      initialVialCount: _getInitialVialCount(),
                      onDoseChanged: (result) {
                        // Update legacy fields for backward compatibility
                        if (result.doseMassMcg != null) {
                          // This updates the text controller, which updates the state via listener
                          // But we should probably update state directly?
                          // The DoseInputField might not update the text controllers we passed to it?
                          // Actually DoseInputField doesn't take controllers, it takes initial values and calls onDoseChanged.
                          // So we need to update our controllers/state.
                          _doseValue.text = result.doseMassMcg.toString();
                          _doseUnit.text = 'mcg';
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Helper for dose input - moved below
                    _helperBelowLeft(
                      context,
                      _getDoseHelperText(state.selectedMed),
                    ),
                    const SizedBox(height: 8),
                    // Syringe size selector for MDV
                    if (state.selectedMed!.form == MedicationForm.multiDoseVial)
                      LabelFieldRow(
                        label: 'Syringe Size',
                        field: DropdownButtonFormField<SyringeType>(
                          value: _getSyringeType(
                            state.selectedMed,
                            state.selectedSyringeType,
                          ),
                          decoration: buildFieldDecoration(
                            context,
                            hint: 'Select syringe size',
                          ),
                          items: SyringeType.values
                              .where((t) => t != SyringeType.ml_10_0)
                              .map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name),
                                );
                              })
                              .toList(),
                          onChanged: notifier.setSyringeType,
                        ),
                      ),
                    if (state.selectedMed!.form == MedicationForm.multiDoseVial)
                      _helperBelowLeft(
                        context,
                        'Choose the syringe size for drawing from the vial',
                      ),
                    if (state.selectedMed!.form == MedicationForm.multiDoseVial)
                      const SizedBox(height: 8),
                    // Week 5: Show reconstitution info if available
                    if (_getReconstitutionHelper(state.selectedMed).isNotEmpty)
                      _helperBelowLeft(
                        context,
                        _getReconstitutionHelper(state.selectedMed),
                      ),
                  ]),
                const SizedBox(height: 10),
                if (state.selectedMed != null || state.medicationId != null)
                  _section(context, 'Schedule', [
                    Column(
                      children: [
                        // 1. Choose schedule type
                        LabelFieldRow(
                          label: 'Schedule type',
                          field: DropdownButtonFormField<ScheduleMode>(
                            value: state.mode,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: ''),
                            items: ScheduleMode.values
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      _modeLabel(m),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (m) {
                              if (m != null) notifier.setMode(m);
                            },
                          ),
                        ),
                        _helperBelowLeft(
                          context,
                          _getScheduleModeDescription(state.mode),
                        ),
                        // 2. Select start date
                        LabelFieldRow(
                          label: 'Start date',
                          field: Field36(
                            width: 120,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(now.year - 1),
                                  lastDate: DateTime(now.year + 10),
                                  initialDate: state.startDate,
                                );
                                if (picked != null)
                                  notifier.setStartDate(picked);
                              },
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                '${state.startDate.toLocal()}'.split(' ').first,
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(120, kFieldHeight),
                              ),
                            ),
                          ),
                        ),
                        _helperBelowLeft(
                          context,
                          'Select when this schedule should start',
                        ),
                        // 3. Select days/months based on mode
                        // Days/months selection section
                        if (state.mode == ScheduleMode.daysOfWeek) ...[
                          _helperBelowLeft(context, 'Select days of the week'),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(7, (i) {
                                final dayIndex = i + 1; // 1..7
                                const labels = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun',
                                ];
                                final selected = state.days.contains(dayIndex);
                                return FilterChip(
                                  label: Text(
                                    labels[i],
                                    style: TextStyle(
                                      color: selected
                                          ? theme.colorScheme.onPrimary
                                          : null,
                                    ),
                                  ),
                                  showCheckmark: false,
                                  selectedColor: theme.colorScheme.primary,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  selected: selected,
                                  onSelected: (_) =>
                                      notifier.toggleDay(dayIndex),
                                );
                              }),
                            ),
                          ),
                        ],
                        if (state.mode == ScheduleMode.daysOnOff) ...[
                          LabelFieldRow(
                            label: 'Days on',
                            field: StepperRow36(
                              controller: _daysOn,
                              onDec: () {
                                final v =
                                    int.tryParse(_daysOn.text.trim()) ?? 1;
                                final next = (v - 1).clamp(1, 1000000);
                                _daysOn.text = next.toString();
                              },
                              onInc: () {
                                final v =
                                    int.tryParse(_daysOn.text.trim()) ?? 1;
                                final next = (v + 1).clamp(1, 1000000);
                                _daysOn.text = next.toString();
                              },
                              decoration: buildCompactFieldDecoration(
                                context: context,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
                              validator: (v) {
                                final n = int.tryParse(v?.trim() ?? '');
                                if (state.mode == ScheduleMode.daysOnOff &&
                                    (n == null || n < 1)) {
                                  return '>= 1';
                                }
                                return null;
                              },
                            ),
                          ),
                          LabelFieldRow(
                            label: 'Days off',
                            field: StepperRow36(
                              controller: _daysOff,
                              onDec: () {
                                final v =
                                    int.tryParse(_daysOff.text.trim()) ?? 1;
                                final next = (v - 1).clamp(1, 1000000);
                                _daysOff.text = next.toString();
                              },
                              onInc: () {
                                final v =
                                    int.tryParse(_daysOff.text.trim()) ?? 1;
                                final next = (v + 1).clamp(1, 1000000);
                                _daysOff.text = next.toString();
                              },
                              decoration: buildCompactFieldDecoration(
                                context: context,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
                              validator: (v) {
                                final n = int.tryParse(v?.trim() ?? '');
                                if (state.mode == ScheduleMode.daysOnOff &&
                                    (n == null || n < 1)) {
                                  return '>= 1';
                                }
                                return null;
                              },
                            ),
                          ),
                          _helperBelowLeft(
                            context,
                            'Take doses for specified days on, then stop for days off. Cycle repeats continuously.',
                          ),
                        ],
                        if (state.mode == ScheduleMode.daysOfMonth) ...[
                          _helperBelowLeft(
                            context,
                            'Select which days of the month to take this dose (1-31).',
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: List.generate(31, (i) {
                                final day = i + 1;
                                final selected = state.daysOfMonth.contains(
                                  day,
                                );
                                return FilterChip(
                                  label: Text(
                                    '$day',
                                    style: TextStyle(
                                      color: selected
                                          ? theme.colorScheme.onPrimary
                                          : null,
                                      fontSize: 12,
                                    ),
                                  ),
                                  showCheckmark: false,
                                  selectedColor: theme.colorScheme.primary,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  selected: selected,
                                  onSelected: (_) =>
                                      notifier.toggleDayOfMonth(day),
                                );
                              }),
                            ),
                          ),
                        ],
                        // 4. Add dosing times
                        const SizedBox(height: 8),
                        LabelFieldRow(
                          label: 'Time 1',
                          field: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(state.times.length, (
                                  i,
                                ) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Field36(
                                        width: 120,
                                        child: FilledButton.icon(
                                          onPressed: () =>
                                              _pickTimeAt(i, state.times[i]),
                                          icon: const Icon(
                                            Icons.schedule,
                                            size: 18,
                                          ),
                                          label: Text(
                                            state.times[i].format(context),
                                          ),
                                          style: FilledButton.styleFrom(
                                            minimumSize: const Size(
                                              120,
                                              kFieldHeight,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (state.times.length > 1)
                                        IconButton(
                                          tooltip: 'Remove',
                                          onPressed: () =>
                                              notifier.removeTime(i),
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 18,
                                          ),
                                        ),
                                    ],
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    notifier.addTime(state.times.last),
                                icon: const Icon(Icons.add),
                                label: const Text('Add time'),
                              ),
                            ],
                          ),
                        ),
                        _helperBelowLeft(
                          context,
                          'Add one or more dosing times',
                        ),
                        // 5. Select end date
                        LabelFieldRow(
                          label: 'End date',
                          field: Row(
                            children: [
                              Field36(
                                width: 120,
                                child: FilledButton.icon(
                                  onPressed: state.noEnd
                                      ? null
                                      : () async {
                                          final now = DateTime.now();
                                          final picked = await showDatePicker(
                                            context: context,
                                            firstDate: DateTime(now.year - 1),
                                            lastDate: DateTime(now.year + 10),
                                            initialDate:
                                                state.endDate ??
                                                state.startDate,
                                          );
                                          if (picked != null) {
                                            notifier.setEndDate(picked);
                                          }
                                        },
                                  icon: const Icon(Icons.event, size: 18),
                                  label: Text(
                                    state.noEnd || state.endDate == null
                                        ? 'No end'
                                        : '${state.endDate!.toLocal()}'
                                              .split(' ')
                                              .first,
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(120, kFieldHeight),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Checkbox(
                                value: state.noEnd,
                                onChanged: (v) => notifier.setNoEnd(v ?? true),
                              ),
                              const Text('No end'),
                            ],
                          ),
                        ),
                        _helperBelowLeft(
                          context,
                          'Optional end date (or leave as No end)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: state.active,
                      onChanged: notifier.setActive,
                    ),
                  ]),
              ],
            ),
          ),
          // Floating summary card pinned beneath app bar (always show, even during med selection)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: IgnorePointer(
                child: _buildFloatingSummary(context, state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the floating summary card that stays at top of screen
  Widget _buildFloatingSummary(BuildContext context, ScheduleFormState state) {
    final card = ScheduleSummaryCard(
      key: _summaryKey,
      medication: state.selectedMed,
      scheduleDescription: _buildScheduleDescription(context, state),
      showInfoOnly: state.selectedMed == null || state.showMedSelector,
      startDate: state.startDate,
      endDate: state.noEnd ? null : state.endDate,
    );
    // Update height after render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _summaryKey.currentContext;
      if (ctx != null) {
        final rb = ctx.findRenderObject();
        if (rb is RenderBox) {
          final h = rb.size.height;
          if (h != _summaryHeight && h > 0) {
            setState(() => _summaryHeight = h);
          }
        }
      }
    });
    return card;
  }

  String _formatDoseValue(double value, String unit) {
    // Convert mcg to mg if >= 1000
    if (unit.toLowerCase() == 'mcg' && value >= 1000) {
      final mgValue = value / 1000;
      final formatted = mgValue == mgValue.roundToDouble()
          ? mgValue.toStringAsFixed(0)
          : mgValue.toStringAsFixed(2);
      return '$formatted mg';
    }

    // Otherwise return as-is
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$formatted$unit';
  }

  String _getUnitLabel(Unit u) => switch (u) {
    Unit.mcg || Unit.mcgPerMl => 'mcg',
    Unit.mg || Unit.mgPerMl => 'mg',
    Unit.g || Unit.gPerMl => 'g',
    Unit.units || Unit.unitsPerMl => 'units',
  };

  /// Builds the schedule description for the summary card
  String? _buildScheduleDescription(
    BuildContext context,
    ScheduleFormState state,
  ) {
    final med = state.selectedMed;
    if (med == null) return null;

    final doseVal = double.tryParse(_doseValue.text.trim());
    final doseUnitText = _doseUnit.text.trim();

    if (doseVal == null ||
        doseVal <= 0 ||
        doseUnitText.isEmpty ||
        state.times.isEmpty) {
      return null;
    }

    // Format dose value (no trailing zeros)
    final doseStr = doseVal == doseVal.roundToDouble()
        ? doseVal.toStringAsFixed(0)
        : doseVal.toStringAsFixed(2);

    // Format times (chronological order)
    final sortedTimes = state.times.toList()
      ..sort((a, b) {
        final aMin = a.hour * 60 + a.minute;
        final bMin = b.hour * 60 + b.minute;
        return aMin.compareTo(bMin);
      });

    final timesStr = sortedTimes.map((t) => t.format(context)).join(', ');

    // Format frequency pattern
    String frequencyText;
    if (state.mode == ScheduleMode.everyDay) {
      frequencyText = 'Every Day';
    } else if (state.mode == ScheduleMode.daysOfWeek) {
      // Check if all 7 days are selected (treat as "Every day")
      if (state.days.length == 7) {
        frequencyText = 'Every Day';
      } else {
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final ds = state.days.toList()..sort();
        final dtext = ds.map((i) => labels[i - 1]).join(', ');
        frequencyText = 'Every $dtext';
      }
    } else if (state.mode == ScheduleMode.daysOfMonth) {
      final sorted = state.daysOfMonth.toList()..sort();
      final dayText = sorted.take(3).join(', ');
      frequencyText = sorted.length > 3
          ? 'Days $dayText...'
          : 'Day${sorted.length > 1 ? 's' : ''} $dayText';
    } else {
      // Days on/off cycle
      final cycle = int.tryParse(_cycleN.text.trim()) ?? 2;
      frequencyText = 'Every $cycle days';
    }

    // Get medication form label
    String medType;
    switch (med.form) {
      case MedicationForm.tablet:
        medType = 'Tablets';
      case MedicationForm.capsule:
        medType = 'Capsules';
      case MedicationForm.prefilledSyringe:
        medType = 'Pre-Filled Syringes';
      case MedicationForm.singleDoseVial:
        medType = 'Single Dose Vials';
      case MedicationForm.multiDoseVial:
        medType = 'Multi Dose Vials';
    }

    // Get strength info for dose calculation
    var strengthInfo = '';
    final strengthVal = med.strengthValue;
    final strengthUnit = _getUnitLabel(med.strengthUnit);

    // Calculate total strength based on dose
    if (doseUnitText.toLowerCase() == 'tablets' ||
        doseUnitText.toLowerCase() == 'tablet' ||
        doseUnitText.toLowerCase() == 'capsules' ||
        doseUnitText.toLowerCase() == 'capsule') {
      final totalStrength = strengthVal * doseVal;
      strengthInfo = ' is ${_formatDoseValue(totalStrength, strengthUnit)}';
    } else {
      // For mg/mcg/g doses, strength is the dose itself
      strengthInfo = ' is $doseStr$doseUnitText';
    }

    // Format: Take {dose} {MedName} {MedType} {frequency} at {times}. Dose is {dose} {unit}{strengthInfo}.
    return 'Take $doseStr ${med.name} $medType $frequencyText at $timesStr. Dose is $doseStr $doseUnitText$strengthInfo.';
  }

  String _getScheduleModeDescription(ScheduleMode mode) {
    switch (mode) {
      case ScheduleMode.everyDay:
        return 'Medication will be taken every single day';
      case ScheduleMode.daysOfWeek:
        return 'Choose specific days of the week (e.g., Mon, Wed, Fri)';
      case ScheduleMode.daysOnOff:
        final on = int.tryParse(_daysOn.text.trim()) ?? 5;
        final off = int.tryParse(_daysOff.text.trim()) ?? 2;
        return 'Take doses for $on days, then stop for $off days, repeating continuously';
      case ScheduleMode.daysOfMonth:
        return 'Take on specific calendar dates each month (e.g., 1st, 15th)';
    }
  }

  Widget _section(
    BuildContext context,
    String title,
    List<Widget> children, {
    Widget? trailing,
  }) {
    return SectionFormCard(
      title: title,
      trailing: trailing,
      children: children,
    );
  }

  Widget _helperBelowLeft(BuildContext context, String text) {
    final width = MediaQuery.of(context).size.width;
    final labelWidth = width >= 400 ? 120.0 : 110.0;
    return Padding(
      padding: EdgeInsets.only(left: labelWidth + 8, top: 4, bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  String _getReconstitutionHelper(Medication? med) {
    if (med == null) return '';
    if (med.form != MedicationForm.multiDoseVial) return '';
    if (med.reconstitutedAt == null) return '';

    // Show reconstitution date and expiry
    final recon = med.reconstitutedAt!;
    final expiry = med.reconstitutedVialExpiry;
    final reconDate = '${recon.month}/${recon.day}/${recon.year}';

    if (expiry != null) {
      final now = DateTime.now();
      final daysLeft = expiry.difference(now).inDays;
      if (daysLeft < 0) {
        return '⚠️ Vial expired ${-daysLeft} days ago (reconstituted $reconDate)';
      } else if (daysLeft == 0) {
        return '⚠️ Vial expires today (reconstituted $reconDate)';
      } else if (daysLeft == 1) {
        return 'ℹ️ Vial expires tomorrow (reconstituted $reconDate)';
      } else if (daysLeft <= 3) {
        return 'ℹ️ Vial expires in $daysLeft days (reconstituted $reconDate)';
      } else {
        return 'ℹ️ Vial reconstituted on $reconDate';
      }
    }

    return 'ℹ️ Vial reconstituted on $reconDate';
  }

  String _getDoseHelperText(Medication? med) {
    if (med == null) return '';

    switch (med.form) {
      case MedicationForm.tablet:
        return 'Choose your input method: Tap quick buttons (¼, ½, 1, 2) for common doses, or toggle between "Tablets" and "Strength" modes. In Tablets mode, enter the number of tablets. In Strength mode, enter the total mg/mcg dose.';
      case MedicationForm.capsule:
        return 'Enter the number of capsules to take per dose. Use the +/- buttons or type directly.';
      case MedicationForm.prefilledSyringe:
        return 'Enter the number of pre-filled syringes to inject per dose.';
      case MedicationForm.singleDoseVial:
        return 'Enter the number of single-dose vials to use per dose.';
      case MedicationForm.multiDoseVial:
        return 'Choose your input method: Toggle between "Strength" (mcg/mg), "Volume" (ml), and "Units" modes. Or drag the syringe plunger to your desired dose. All three values update automatically based on vial concentration.';
    }
  }

  // Week 2: Helper methods for DoseInputField integration
  double _getStrengthPerUnitMcg(Medication? med) {
    if (med == null) return 0;

    switch (med.form) {
      case MedicationForm.tablet:
      case MedicationForm.capsule:
      case MedicationForm.prefilledSyringe:
      case MedicationForm.singleDoseVial:
        // Convert strength to mcg
        final value = med.strengthValue;
        return switch (med.strengthUnit) {
          Unit.mcg || Unit.mcgPerMl => value,
          Unit.mg || Unit.mgPerMl => value * 1000,
          Unit.g || Unit.gPerMl => value * 1000000,
          Unit.units || Unit.unitsPerMl => value, // Treat as mcg equivalent
        };
      case MedicationForm.multiDoseVial:
        return 0; // MDV uses different parameters
    }
  }

  double? _getVolumePerUnitMicroliter(Medication? med) {
    if (med == null) return null;

    if (med.volumePerDose != null) {
      // Convert to microliters based on volumeUnit
      final volume = med.volumePerDose!;
      return switch (med.volumeUnit) {
        VolumeUnit.ml => volume * 1000,
        VolumeUnit.l => volume * 1000000,
        null => volume * 1000, // Default to ml
      };
    }

    return null;
  }

  String _getStrengthUnit(Medication? med) {
    if (med == null) return 'mg';

    return switch (med.strengthUnit) {
      Unit.mcg || Unit.mcgPerMl => 'mcg',
      Unit.mg || Unit.mgPerMl => 'mg',
      Unit.g || Unit.gPerMl => 'g',
      Unit.units || Unit.unitsPerMl => 'units',
    };
  }

  double? _getTotalVialStrengthMcg(Medication? med) {
    if (med == null || med.form != MedicationForm.multiDoseVial) {
      return null;
    }

    final volumeMl = med.containerVolumeMl ?? 1.0;
    final strength = med.strengthValue;

    return switch (med.strengthUnit) {
      // Total amount in vial.
      Unit.mcg => strength,
      Unit.mg => strength * 1000,
      Unit.g => strength * 1000000,
      Unit.units => strength,

      // Per-mL concentration.
      Unit.mcgPerMl => strength * volumeMl,
      Unit.mgPerMl => (strength * 1000) * volumeMl,
      Unit.gPerMl => (strength * 1000000) * volumeMl,
      Unit.unitsPerMl => strength * volumeMl,
    };
  }

  double? _getTotalVialVolumeMicroliter(Medication? med) {
    if (med == null || med.form != MedicationForm.multiDoseVial) {
      return null;
    }

    final volumeMl = med.containerVolumeMl ?? 1.0;
    return volumeMl * 1000; // Convert ml to microliters
  }

  SyringeType? _getSyringeType(Medication? med, SyringeType? selected) {
    if (med == null || med.form != MedicationForm.multiDoseVial) {
      return null;
    }

    // The 10mL syringe is no longer offered; normalize legacy selections.
    if (selected == SyringeType.ml_10_0) {
      selected = SyringeType.ml_5_0;
    }

    // If user selected a syringe type, use it
    if (selected != null) {
      return selected;
    }

    // Otherwise auto-select based on vial volume
    final volumeMl = med.containerVolumeMl ?? 1.0;
    if (volumeMl <= 0.3) return SyringeType.ml_0_3;
    if (volumeMl <= 0.5) return SyringeType.ml_0_5;
    if (volumeMl <= 1.0) return SyringeType.ml_1_0;
    if (volumeMl <= 3.0) return SyringeType.ml_3_0;
    if (volumeMl <= 5.0) return SyringeType.ml_5_0;
    return SyringeType.ml_5_0;
  }

  double? _getInitialStrengthMcg() {
    if (widget.initial == null) return null;
    return widget.initial!.doseMassMcg?.toDouble();
  }

  double? _getInitialTabletCount() {
    if (widget.initial == null) return null;
    if (widget.initial!.doseTabletQuarters != null) {
      return widget.initial!.doseTabletQuarters! / 4.0;
    }
    return null;
  }

  int? _getInitialCapsuleCount() {
    if (widget.initial == null) return null;
    return widget.initial!.doseCapsules;
  }

  int? _getInitialInjectionCount() {
    if (widget.initial == null) return null;
    return widget.initial!.doseSyringes;
  }

  int? _getInitialVialCount() {
    if (widget.initial == null) return null;
    return widget.initial!.doseVials;
  }
}

enum ScheduleMode { everyDay, daysOfWeek, daysOnOff, daysOfMonth }

String _modeLabel(ScheduleMode m) => switch (m) {
  ScheduleMode.everyDay => 'Every day',
  ScheduleMode.daysOfWeek => 'Days of the week',
  ScheduleMode.daysOnOff => 'Days on / days off',
  ScheduleMode.daysOfMonth => 'Days of the month',
};

// Widget to display selected medication inline
class _MedicationSummaryDisplay extends StatelessWidget {
  const _MedicationSummaryDisplay({
    required this.medicationName,
    required this.onClear,
    required this.onExpand,
    required this.isExpanded,
  });

  final String medicationName;
  final VoidCallback onClear;
  final VoidCallback onExpand;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return OutlinedButton(
      onPressed: onExpand,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              medicationName,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.75),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 18,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

// Inline medication selector showing all medications in a scrollable list
class _InlineMedicationSelector extends StatelessWidget {
  const _InlineMedicationSelector({
    required this.onSelect,
    required this.onCancel,
  });

  final void Function(Medication) onSelect;
  final VoidCallback onCancel;

  String _formatStock(Medication m) {
    final stock = m.stockValue;
    final s = stock == stock.roundToDouble()
        ? stock.toStringAsFixed(0)
        : stock
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'\.0+$'), '')
              .replaceFirst(RegExp(r'(\.\ d*?)0+$'), r'$1');
    return s;
  }

  String _formatStrength(Medication m) {
    final v = m.strengthValue;
    final val = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'\.0+$'), '')
              .replaceFirst(RegExp(r'(\.\ d*?)0+$'), r'$1');
    final unitLabel = switch (m.strengthUnit) {
      Unit.mcg || Unit.mcgPerMl => 'mcg',
      Unit.mg || Unit.mgPerMl => 'mg',
      Unit.g || Unit.gPerMl => 'g',
      Unit.units || Unit.unitsPerMl => 'units',
    };
    return '$val $unitLabel';
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Medication>('medications');
    final meds = box.values.toList();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Medication',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onCancel,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: meds.isEmpty
                ? const Center(child: Text('No medications found'))
                : ListView.builder(
                    itemCount: meds.length,
                    itemBuilder: (context, index) {
                      final m = meds[index];
                      return ListTile(
                        title: Text(m.name),
                        subtitle: Text(
                          '${_formatStrength(m)} • Stock: ${_formatStock(m)}',
                        ),
                        onTap: () => onSelect(m),
                        dense: true,
                        trailing: const Icon(Icons.chevron_right),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
