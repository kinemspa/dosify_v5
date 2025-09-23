import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'select_medication_for_schedule_page.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

class AddEditSchedulePage extends StatefulWidget {
  const AddEditSchedulePage({super.key, this.initial});
  final Schedule? initial;

  @override
  State<AddEditSchedulePage> createState() => _AddEditSchedulePageState();
}

class _AddEditSchedulePageState extends State<AddEditSchedulePage> {
  // Days selector mode
  ScheduleMode _mode = ScheduleMode.daysOfWeek;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _medicationName;
  late final TextEditingController _doseValue;
  late final TextEditingController _doseUnit;
  String? _medicationId;
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 9, minute: 0)];
  final Set<int> _days = {1,2,3,4,5};
  bool _active = true;
  bool _useCycle = false;
  final TextEditingController _cycleN = TextEditingController(text: '2');
  DateTime _cycleAnchor = DateTime.now();
  bool _nameAuto = true;
  Medication? _selectedMed;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s?.name ?? '');
    _medicationName = TextEditingController(text: s?.medicationName ?? '');
    _medicationId = s?.medicationId;
    _doseValue = TextEditingController(text: s?.doseValue.toString() ?? '');
    _doseUnit = TextEditingController(text: s?.doseUnit ?? 'mg');
    if (s != null) {
      final times = s.timesOfDay ?? [s.minutesOfDay];
      _times
        ..clear()
        ..addAll(times.map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60)));
      _days
        ..clear()
        ..addAll(s.daysOfWeek);
      _active = s.active;
      _useCycle = s.cycleEveryNDays != null;
      if (_useCycle) {
        _cycleN.text = s.cycleEveryNDays!.toString();
        _cycleAnchor = s.cycleAnchorDate ?? DateTime.now();
      }
      _nameAuto = false; // existing schedule name considered manual
    }
    _name.addListener(() {
      // If user edits name manually, stop auto-updating
      if (_nameAuto && _name.text.isNotEmpty) {
        _nameAuto = false;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _medicationName.dispose();
    _doseValue.dispose();
    _doseUnit.dispose();
    super.dispose();
  }

  Future<void> _pickTimeAt(int index) async {
    final picked = await showTimePicker(context: context, initialTime: _times[index]);
    if (picked != null) setState(() => _times[index] = picked);
  }

  Future<void> _pickMedication() async {
    if (!mounted) return;
    final selected = await context.push<Medication>('/schedules/select-medication');
    if (selected != null) {
      setState(() {
        _selectedMed = selected;
        _medicationId = selected.id;
        _medicationName.text = selected.name;
        // Set sensible defaults based on form
        switch (selected.form) {
          case MedicationForm.tablet:
            _doseUnit.text = 'tablets';
            if ((_doseValue.text).trim().isEmpty) _doseValue.text = '1';
            break;
          case MedicationForm.capsule:
            _doseUnit.text = 'capsules';
            if ((_doseValue.text).trim().isEmpty) _doseValue.text = '1';
            break;
          case MedicationForm.injectionPreFilledSyringe:
            _doseUnit.text = 'syringes';
            if ((_doseValue.text).trim().isEmpty) _doseValue.text = '1';
            break;
          case MedicationForm.injectionSingleDoseVial:
            _doseUnit.text = 'vials';
            if ((_doseValue.text).trim().isEmpty) _doseValue.text = '1';
            break;
          case MedicationForm.injectionMultiDoseVial:
            // Default to mg if mg/mL, else units if units/mL, else mg
            final u = selected.strengthUnit;
            if (u == Unit.unitsPerMl) {
              _doseUnit.text = 'IU';
            } else {
              _doseUnit.text = 'mg';
            }
            if ((_doseValue.text).trim().isEmpty) _doseValue.text = '1';
            break;
        }
        _maybeAutoName();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // If name was auto-generated, ask user if they want to edit before saving
    if (_nameAuto) {
      final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Use this schedule name?'),
              content: Text(_name.text.isEmpty ? '(empty)' : _name.text),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Edit')),
                FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Looks good')),
              ],
            ),
          ) ??
          false;
      if (!proceed) {
        return; // Let user edit
      }
    }

    final id = widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final minutesList = _times.map((t) => t.hour * 60 + t.minute).toList();

    // Compute UTC fields from the first time and days as legacy, plus per-time UTC list
    final now = DateTime.now();
    int computeUtcMinutes(int localMinutes) {
      final localToday = DateTime(now.year, now.month, now.day, localMinutes ~/ 60, localMinutes % 60);
      final utc = localToday.toUtc();
      return utc.hour * 60 + utc.minute;
    }

    List<int> computeUtcDays(Set<int> localDays, int localMinutes) {
      final List<int> utcDays = [];
      for (final d in localDays) {
        final delta = (d - now.weekday) % 7;
        final candidate = DateTime(now.year, now.month, now.day + delta, localMinutes ~/ 60, localMinutes % 60);
        final utc = candidate.toUtc();
        utcDays.add(utc.weekday);
      }
      utcDays.sort();
      return utcDays;
    }

    final minutesUtc = computeUtcMinutes(minutesList.first);
    final timesUtc = minutesList.map(computeUtcMinutes).toList();
    final daysUtc = computeUtcDays(_days, minutesList.first);

    // Compute typed dose normalized fields
    int? doseUnitCode;
    int? doseMassMcg;
    int? doseVolumeMicroliter;
    int? doseTabletQuarters;
    int? doseCapsules;
    int? doseSyringes;
    int? doseVials;
    int? doseIU;
    int? displayUnitCode;
    int? inputModeCode;

    final med = _selectedMed;
    final doseVal = double.tryParse(_doseValue.text.trim()) ?? 0;
    final unitStr = _doseUnit.text.trim().toLowerCase();
    if (med != null && doseVal > 0 && unitStr.isNotEmpty) {
      switch (med.form) {
        case MedicationForm.tablet:
          if (unitStr == 'tablets') {
            doseTabletQuarters = (doseVal * 4).round();
            // convert to mass using med.strength
            final perTabMcg = switch (med.strengthUnit) {
              Unit.mcg => med.strengthValue,
              Unit.mg => med.strengthValue * 1000,
              Unit.g => med.strengthValue * 1e6,
              Unit.units => med.strengthValue,
              Unit.mcgPerMl => med.strengthValue,
              Unit.mgPerMl => med.strengthValue * 1000,
              Unit.gPerMl => med.strengthValue * 1e6,
              Unit.unitsPerMl => med.strengthValue,
            };
            doseMassMcg = (perTabMcg * doseTabletQuarters / 4.0).round();
            doseUnitCode = DoseUnit.tablets.index;
            displayUnitCode = DoseUnit.tablets.index;
            inputModeCode = DoseInputMode.tablets.index;
          } else {
            // mass → compute tablets equivalence
            final desiredMcg = switch (unitStr) { 'mcg' => doseVal, 'mg' => doseVal * 1000, 'g' => doseVal * 1e6, _ => doseVal };
            doseMassMcg = desiredMcg.round();
            final perTabMcg = switch (med.strengthUnit) {
              Unit.mcg => med.strengthValue,
              Unit.mg => med.strengthValue * 1000,
              Unit.g => med.strengthValue * 1e6,
              Unit.units => med.strengthValue,
              Unit.mcgPerMl => med.strengthValue,
              Unit.mgPerMl => med.strengthValue * 1000,
              Unit.gPerMl => med.strengthValue * 1e6,
              Unit.unitsPerMl => med.strengthValue,
            };
            doseTabletQuarters = ((desiredMcg / perTabMcg) * 4).round();
            doseUnitCode = switch (unitStr) { 'mcg' => DoseUnit.mcg.index, 'mg' => DoseUnit.mg.index, 'g' => DoseUnit.g.index, _ => DoseUnit.mg.index };
            displayUnitCode = doseUnitCode;
            inputModeCode = DoseInputMode.mass.index;
          }
          break;
        case MedicationForm.capsule:
          if (unitStr == 'capsules') {
            doseCapsules = doseVal.round();
            final perCapMcg = switch (med.strengthUnit) {
              Unit.mcg => med.strengthValue,
              Unit.mg => med.strengthValue * 1000,
              Unit.g => med.strengthValue * 1e6,
              Unit.units => med.strengthValue,
              _ => med.strengthValue,
            };
            doseMassMcg = (perCapMcg * doseCapsules).round();
            doseUnitCode = DoseUnit.capsules.index;
            displayUnitCode = DoseUnit.capsules.index;
            inputModeCode = DoseInputMode.capsules.index;
          } else {
            final desiredMcg = switch (unitStr) { 'mcg' => doseVal, 'mg' => doseVal * 1000, 'g' => doseVal * 1e6, _ => doseVal };
            doseMassMcg = desiredMcg.round();
            final perCapMcg = switch (med.strengthUnit) {
              Unit.mcg => med.strengthValue,
              Unit.mg => med.strengthValue * 1000,
              Unit.g => med.strengthValue * 1e6,
              Unit.units => med.strengthValue,
              _ => med.strengthValue,
            };
            doseCapsules = (desiredMcg / perCapMcg).round();
            doseUnitCode = switch (unitStr) { 'mcg' => DoseUnit.mcg.index, 'mg' => DoseUnit.mg.index, 'g' => DoseUnit.g.index, _ => DoseUnit.mg.index };
            displayUnitCode = doseUnitCode;
            inputModeCode = DoseInputMode.mass.index;
          }
          break;
        case MedicationForm.injectionPreFilledSyringe:
          doseSyringes = doseVal.round();
          doseUnitCode = DoseUnit.syringes.index;
          displayUnitCode = DoseUnit.syringes.index;
          inputModeCode = DoseInputMode.count.index;
          break;
        case MedicationForm.injectionSingleDoseVial:
          doseVials = doseVal.round();
          doseUnitCode = DoseUnit.vials.index;
          displayUnitCode = DoseUnit.vials.index;
          inputModeCode = DoseInputMode.count.index;
          break;
        case MedicationForm.injectionMultiDoseVial:
          // Allow mg/mcg/g, IU/units or mL
          double? mgPerMl;
          double? iuPerMl;
          switch (med.strengthUnit) {
            case Unit.mgPerMl:
              mgPerMl = med.perMlValue ?? med.strengthValue;
              break;
            case Unit.mcgPerMl:
              mgPerMl = (med.perMlValue ?? med.strengthValue) / 1000.0;
              break;
            case Unit.gPerMl:
              mgPerMl = (med.perMlValue ?? med.strengthValue) * 1000.0;
              break;
            case Unit.unitsPerMl:
              iuPerMl = med.perMlValue ?? med.strengthValue;
              break;
            default:
              break;
          }
          if (unitStr == 'ml') {
            final ml = doseVal;
            doseVolumeMicroliter = (ml * 1000).round();
            if (mgPerMl != null) doseMassMcg = (ml * mgPerMl * 1000).round();
            if (iuPerMl != null) doseIU = (ml * iuPerMl).round();
            doseUnitCode = DoseUnit.ml.index;
            displayUnitCode = DoseUnit.ml.index;
            inputModeCode = DoseInputMode.volume.index;
          } else if (unitStr == 'iu' || unitStr == 'units') {
            if (iuPerMl != null) {
              final ml = doseVal / iuPerMl;
              doseIU = doseVal.round();
              doseVolumeMicroliter = (ml * 1000).round();
              doseUnitCode = DoseUnit.iu.index;
              displayUnitCode = DoseUnit.iu.index;
              inputModeCode = DoseInputMode.iuUnits.index;
            }
          } else {
            // mg/mcg/g
            if (mgPerMl != null) {
              final desiredMg = switch (unitStr) { 'mg' => doseVal, 'mcg' => doseVal / 1000.0, 'g' => doseVal * 1000.0, _ => doseVal };
              final ml = desiredMg / mgPerMl;
              doseMassMcg = (desiredMg * 1000).round();
              doseVolumeMicroliter = (ml * 1000).round();
              doseUnitCode = switch (unitStr) { 'mcg' => DoseUnit.mcg.index, 'mg' => DoseUnit.mg.index, 'g' => DoseUnit.g.index, _ => DoseUnit.mg.index };
              displayUnitCode = doseUnitCode;
              inputModeCode = DoseInputMode.mass.index;
            }
          }
          break;
      }
    }

    final s = Schedule(
      id: id,
      name: _name.text.trim(),
      medicationName: _medicationName.text.trim(),
      doseValue: double.tryParse(_doseValue.text.trim()) ?? 0,
      doseUnit: _doseUnit.text.trim(),
      minutesOfDay: minutesList.first,
      daysOfWeek: _days.toList()..sort(),
      minutesOfDayUtc: minutesUtc,
      daysOfWeekUtc: daysUtc,
      medicationId: _medicationId,
      active: _active,
      timesOfDay: minutesList,
      timesOfDayUtc: timesUtc,
      cycleEveryNDays: _useCycle ? int.tryParse(_cycleN.text.trim()) : null,
      cycleAnchorDate: _useCycle ? DateTime(_cycleAnchor.year, _cycleAnchor.month, _cycleAnchor.day) : null,
      doseUnitCode: doseUnitCode,
      doseMassMcg: doseMassMcg,
      doseVolumeMicroliter: doseVolumeMicroliter,
      doseTabletQuarters: doseTabletQuarters,
      doseCapsules: doseCapsules,
      doseSyringes: doseSyringes,
      doseVials: doseVials,
      doseIU: doseIU,
      displayUnitCode: displayUnitCode,
      inputModeCode: inputModeCode,
    );
    final box = Hive.box<Schedule>('schedules');
    // Ensure notifications permission for Android 13+
    final granted = await NotificationService.ensurePermissionGranted();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable notifications to receive schedule alerts.')),
      );
    }
    // Cancel existing notifications for this schedule id (handles edits)
    await ScheduleScheduler.cancelFor(id);
    await box.put(id, s);
    // Schedule notifications if active
    try {
      await ScheduleScheduler.scheduleFor(s);
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exact alarms required'),
            content: const Text('To schedule exact reminders, enable Alarms & reminders permission for Dosifi.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await NotificationService.openExactAlarmsSettings();
                },
                child: const Text('Open settings'),
              ),
            ],
          ),
        );
      }
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule saved'),
        content: const Text('Your reminder has been saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
    if (mounted) {
      // Navigate back to the schedules list explicitly
      context.go('/schedules');
    }
  }

  Widget _pillBtn(BuildContext context, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(8);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          overlayColor: WidgetStatePropertyAll(theme.colorScheme.primary.withValues(alpha: 0.12)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children, {Widget? trailing}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4, right: 2),
              child: Row(children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 15, color: theme.colorScheme.primary)),
                ),
                if (trailing != null)
                  Flexible(
                    child: DefaultTextStyle(
                      style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.primary.withOpacity(0.50), fontWeight: FontWeight.w600),
                      child: Align(alignment: Alignment.centerRight, child: trailing),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }

  String _doseSummaryShort() {
    final med = _medicationName.text.trim();
    final val = double.tryParse(_doseValue.text.trim()) ?? 0;
    final unit = _doseUnit.text.trim();
    if (med.isEmpty || unit.isEmpty || val <= 0) return '';
    final v = val == val.roundToDouble() ? val.toStringAsFixed(0) : val.toStringAsFixed(2);
    return '$v $unit${med.isEmpty ? '' : ' · $med'}';
  }

  String _scheduleSummaryShort() {
    if (_times.isEmpty) return '';
    final times = _times.map((t) => t.format(context)).join(', ');
    switch (_mode) {
      case ScheduleMode.everyDay:
        return 'Every day · $times';
      case ScheduleMode.daysOfWeek:
        const labels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
        final ds = _days.toList()..sort();
        final dtext = ds.map((i) => labels[i-1]).join(', ');
        return '$dtext · $times';
      case ScheduleMode.daysOnOff:
        final n = int.tryParse(_cycleN.text.trim());
        return n == null ? times : 'Every $n days · $times';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null ? 'Add Schedule' : 'Edit Schedule',
        actions: [
          if (widget.initial != null)
            IconButton(
              tooltip: 'Delete',
              onPressed: () async {
                final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete schedule?'),
                        content: Text('Delete "${widget.initial!.name}"? This will cancel its notifications.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
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
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 96),
          children: [
            _section(context, 'General', [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Schedule name'),
                textInputAction: TextInputAction.next,
                onChanged: (_) => _nameAuto = false,
                // Name not required until save/confirm
                validator: (_) => null,
              ),
              const SizedBox(height: 12),
              // Medication dropdown (from saved meds)
              DropdownButtonFormField<Medication>(
                value: _selectedMed,
                isExpanded: true,
                alignment: AlignmentDirectional.center,
                decoration: const InputDecoration(labelText: 'Medication'),
                items: Hive.box<Medication>('medications')
                    .values
                    .map((m) => DropdownMenuItem<Medication>(value: m, alignment: AlignmentDirectional.center, child: Center(child: Text(m.name, textAlign: TextAlign.center))))
                    .toList(),
                onChanged: (m) {
                  setState(() {
                    _selectedMed = m;
                    _medicationId = m?.id;
                    _medicationName.text = m?.name ?? '';
                    // set sensible defaults based on form
                    if (m != null) {
                      switch (m.form) {
                        case MedicationForm.tablet:
                          _doseUnit.text = 'tablets';
                          if ((_doseValue.text).trim().isEmpty) _doseValue.text = '1';
                          break;
                        case MedicationForm.capsule:
                          _doseUnit.text = 'capsules';
                          if ((_doseValue.text).trim().isEmpty) _doseValue.text = '1';
                          break;
                        case MedicationForm.injectionPreFilledSyringe:
                          _doseUnit.text = 'syringes';
                          if ((_doseValue.text).trim().isEmpty) _doseValue.text = '1';
                          break;
                        case MedicationForm.injectionSingleDoseVial:
                          _doseUnit.text = 'vials';
                          if ((_doseValue.text).trim().isEmpty) _doseValue.text = '1';
                          break;
                        case MedicationForm.injectionMultiDoseVial:
                          final u = m.strengthUnit;
                          if (u == Unit.unitsPerMl) {
                            _doseUnit.text = 'IU';
                          } else {
                            _doseUnit.text = 'mg';
                          }
                          if ((_doseValue.text).trim().isEmpty) _doseValue.text = '1';
                          break;
                      }
                    }
                    _maybeAutoName();
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
            ]),
            const SizedBox(height: 10),
            // Dose controls (Typed) in a card with summary
            _section(context, 'Dose', [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(children: [
                  _pillBtn(context, '−', () {
                    final unit = _doseUnit.text.trim().toLowerCase();
                    final step = unit == 'tablets' ? 0.25 : 1.0;
                    final v = double.tryParse(_doseValue.text.trim()) ?? 0.0;
                    final nv = (v - step);
                    setState(() {
                      _doseValue.text = (unit == 'tablets') ? nv.clamp(0, 1e12).toStringAsFixed(2) : nv.clamp(0, 1e12).round().toString();
                      _coerceDoseValueForUnit();
                      _maybeAutoName();
                    });
                  }),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 96,
                    child: TextFormField(
                      controller: _doseValue,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: 'Dose value'),
                      keyboardType: (_doseUnit.text.trim().toLowerCase() == 'tablets')
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.number,
                      onChanged: (_) {
                        _coerceDoseValueForUnit();
                        _maybeAutoName();
                        setState(() {});
                      },
                      validator: (v) {
                        final d = double.tryParse(v?.trim() ?? '');
                        if (d == null || d <= 0) return 'Enter a positive number';
                        final unit = _doseUnit.text.trim().toLowerCase();
                        if (['capsules','syringes','vials'].contains(unit)) {
                          if (d % 1 != 0) return 'Whole numbers only';
                        }
                        if (unit == 'tablets') {
                          final q = (d * 4).roundToDouble();
                          if ((q - d * 4).abs() > 1e-6 && d % 0.25 != 0) {
                            return 'Use quarter-tablet steps (0.25)';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  _pillBtn(context, '+', () {
                    final unit = _doseUnit.text.trim().toLowerCase();
                    final step = unit == 'tablets' ? 0.25 : 1.0;
                    final v = double.tryParse(_doseValue.text.trim()) ?? 0.0;
                    final nv = (v + step);
                    setState(() {
                      _doseValue.text = (unit == 'tablets') ? nv.clamp(0, 1e12).toStringAsFixed(2) : nv.clamp(0, 1e12).round().toString();
                      _coerceDoseValueForUnit();
                      _maybeAutoName();
                    });
                  }),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _doseUnit.text.isEmpty ? null : _doseUnit.text,
                      isExpanded: true,
                      alignment: AlignmentDirectional.center,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: _doseUnitOptions().map((e) => DropdownMenuItem(value: e, alignment: AlignmentDirectional.center, child: Center(child: Text(e, textAlign: TextAlign.center)))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _doseUnit.text = v ?? '';
                          _coerceDoseValueForUnit();
                          _maybeAutoName();
                        });
                      },
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                _DoseFormulaStrip(selectedMed: _selectedMed, valueCtrl: _doseValue, unitCtrl: _doseUnit),
              ],
            ),
            ], trailing: Text(_doseSummaryShort(), overflow: TextOverflow.ellipsis)),
            const SizedBox(height: 10),
            _section(context, 'Schedule', [
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ScheduleMode>(
                          value: _mode,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Days mode'),
                          items: ScheduleMode.values
                              .map((m) => DropdownMenuItem(value: m, child: Text(_modeLabel(m))))
                              .toList(),
                          onChanged: (m) {
                            setState(() {
                              _mode = m ?? ScheduleMode.daysOfWeek;
                              if (_mode == ScheduleMode.everyDay) {
                                _days..clear()..addAll([1,2,3,4,5,6,7]);
                                _useCycle = false;
                              } else if (_mode == ScheduleMode.daysOnOff) {
                                _useCycle = true;
                              } else {
                                _useCycle = false;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _times.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Time of day'),
                              subtitle: Text(_times[i].format(context)),
                              trailing: TextButton(onPressed: () => _pickTimeAt(i), child: const Text('Pick')),
                            ),
                          ),
                          if (_times.length > 1)
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: () => setState(() => _times.removeAt(i)),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _times.add(_times.last)),
                      icon: const Icon(Icons.add),
                      label: const Text('Add time'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_mode == ScheduleMode.daysOfWeek)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (i) {
                    final dayIndex = i + 1; // 1..7
                    const labels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                    final selected = _days.contains(dayIndex);
                    return FilterChip(
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(labels[i]),
                      ),
                      selected: selected,
                      onSelected: (sel) {
                        setState(() {
                          if (sel) {
                            _days.add(dayIndex);
                          } else {
                            _days.remove(dayIndex);
                          }
                        });
                      },
                    );
                  }),
                ),
              if (_mode == ScheduleMode.daysOnOff)
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _cycleN,
                        decoration: const InputDecoration(labelText: 'Every N days'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n < 1) return '>= 1';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start date'),
                        subtitle: Text('${_cycleAnchor.toLocal()}'.split(' ').first),
                        trailing: TextButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 10),
                              initialDate: _cycleAnchor,
                            );
                            if (picked != null) setState(() => _cycleAnchor = picked);
                          },
                          child: const Text('Pick'),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ], trailing: Text(_scheduleSummaryShort(), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  List<String> _doseUnitOptions() {
    final med = _selectedMed;
    if (med == null) {
      return const ['mg','mcg','g','tablets','capsules','syringes','vials','IU'];
    }
    switch (med.form) {
      case MedicationForm.tablet:
        return const ['tablets','mg'];
      case MedicationForm.capsule:
        return const ['capsules','mg'];
      case MedicationForm.injectionPreFilledSyringe:
        return const ['syringes'];
      case MedicationForm.injectionSingleDoseVial:
        return const ['vials'];
      case MedicationForm.injectionMultiDoseVial:
        return const ['mg','mcg','g','IU'];
    }
  }

  void _coerceDoseValueForUnit() {
    final unit = _doseUnit.text.trim().toLowerCase();
    final val = double.tryParse(_doseValue.text.trim());
    if (val == null) return;
    if (unit == 'tablets') {
      // Round to nearest quarter tablet
      final q = (val * 4).round() / 4.0;
      _doseValue.text = q.toStringAsFixed(q % 1 == 0 ? 0 : (q * 4 % 1 == 0 ? 2 : 2));
    } else if (['capsules','syringes','vials'].contains(unit)) {
      _doseValue.text = val.round().toString();
    }
  }

  void _maybeAutoName() {
    if (!_nameAuto) return;
    final med = _medicationName.text.trim();
    final dose = _doseValue.text.trim();
    final unit = _doseUnit.text.trim();
    if (med.isEmpty || dose.isEmpty || unit.isEmpty) return;
    _name.text = '$med — $dose $unit';
  }
}

enum ScheduleMode { everyDay, daysOfWeek, daysOnOff }

String _modeLabel(ScheduleMode m) => switch (m) {
  ScheduleMode.everyDay => 'Every day',
  ScheduleMode.daysOfWeek => 'Days of the week',
  ScheduleMode.daysOnOff => 'Days on / days off',
};

class _DoseFormulaStrip extends StatelessWidget {
  const _DoseFormulaStrip({required this.selectedMed, required this.valueCtrl, required this.unitCtrl});
  final Medication? selectedMed;
  final TextEditingController valueCtrl;
  final TextEditingController unitCtrl;

  String _fmt(double v, {int decimals = 2}) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final med = selectedMed;
    final v = double.tryParse(valueCtrl.text.trim());
    final unit = unitCtrl.text.trim().toLowerCase();
    if (med == null || v == null || v <= 0 || unit.isEmpty) {
      return const SizedBox.shrink();
    }

    String line;
    switch (med.form) {
      case MedicationForm.tablet:
        if (unit == 'tablets') {
          final quarters = (v * 4).round();
          final perTabMcg = switch (med.strengthUnit) {
            Unit.mcg => med.strengthValue,
            Unit.mg => med.strengthValue * 1000,
            Unit.g => med.strengthValue * 1e6,
            Unit.units => med.strengthValue, // unusual but support
            Unit.mcgPerMl => med.strengthValue, // treat as mcg/tab if mis-entered
            Unit.mgPerMl => med.strengthValue * 1000,
            Unit.gPerMl => med.strengthValue * 1e6,
            Unit.unitsPerMl => med.strengthValue,
          };
          final totalMcg = perTabMcg * quarters / 4.0;
          final mg = totalMcg / 1000.0;
          line = '${_fmt(v)} tab × ${_fmt(med.strengthValue)} ${med.strengthUnit.name} = ${_fmt(totalMcg)} mcg (${_fmt(mg)} mg)';
        } else {
          // mass entry; compute tablets eq
          final desiredMcg = switch (unit) {
            'mcg' => v,
            'mg' => v * 1000,
            'g' => v * 1e6,
            _ => v,
          };
          final perTabMcg = switch (med.strengthUnit) {
            Unit.mcg => med.strengthValue,
            Unit.mg => med.strengthValue * 1000,
            Unit.g => med.strengthValue * 1e6,
            Unit.units => med.strengthValue,
            Unit.mcgPerMl => med.strengthValue,
            Unit.mgPerMl => med.strengthValue * 1000,
            Unit.gPerMl => med.strengthValue * 1e6,
            Unit.unitsPerMl => med.strengthValue,
          };
          final tabs = desiredMcg / perTabMcg;
          final quarters = (tabs * 4).round() / 4.0;
          line = '${_fmt(desiredMcg)} mcg = ~${_fmt(quarters)} tablets';
        }
        break;
      case MedicationForm.capsule:
        if (unit == 'capsules') {
          final perCapMcg = switch (med.strengthUnit) {
            Unit.mcg => med.strengthValue,
            Unit.mg => med.strengthValue * 1000,
            Unit.g => med.strengthValue * 1e6,
            Unit.units => med.strengthValue,
            _ => med.strengthValue,
          };
          final totalMcg = perCapMcg * v;
          final mg = totalMcg / 1000.0;
          line = '${_fmt(v)} cap × ${_fmt(med.strengthValue)} ${med.strengthUnit.name} = ${_fmt(totalMcg)} mcg (${_fmt(mg)} mg)';
        } else {
          final desiredMcg = switch (unit) {
            'mcg' => v,
            'mg' => v * 1000,
            'g' => v * 1e6,
            _ => v,
          };
          final perCapMcg = switch (med.strengthUnit) {
            Unit.mcg => med.strengthValue,
            Unit.mg => med.strengthValue * 1000,
            Unit.g => med.strengthValue * 1e6,
            Unit.units => med.strengthValue,
            _ => med.strengthValue,
          };
          final caps = desiredMcg / perCapMcg;
          line = '${_fmt(desiredMcg)} mcg = ~${_fmt(caps)} capsules';
        }
        break;
      case MedicationForm.injectionPreFilledSyringe:
        line = '${_fmt(v)} syringe';
        break;
      case MedicationForm.injectionSingleDoseVial:
        line = '${_fmt(v)} vial';
        break;
      case MedicationForm.injectionMultiDoseVial:
        double? mgPerMl;
        double? iuPerMl;
        switch (med.strengthUnit) {
          case Unit.mgPerMl:
            mgPerMl = med.perMlValue ?? med.strengthValue;
            break;
          case Unit.mcgPerMl:
            mgPerMl = (med.perMlValue ?? med.strengthValue) / 1000.0;
            break;
          case Unit.gPerMl:
            mgPerMl = (med.perMlValue ?? med.strengthValue) * 1000.0;
            break;
          case Unit.unitsPerMl:
            iuPerMl = med.perMlValue ?? med.strengthValue;
            break;
          default:
            break;
        }
        if (unit == 'ml') {
          final ml = v;
          String rhs;
          if (mgPerMl != null) {
            rhs = '${_fmt(ml * mgPerMl)} mg';
          } else if (iuPerMl != null) {
            rhs = '${_fmt(ml * iuPerMl)} IU';
          } else {
            rhs = '';
          }
          line = '${_fmt(ml)} mL ${rhs.isEmpty ? '' : '= $rhs'}';
        } else if (unit == 'iu' || unit == 'units') {
          if (iuPerMl == null) return const SizedBox.shrink();
          final ml = v / iuPerMl;
          line = '${_fmt(v)} IU ÷ ${_fmt(iuPerMl)} IU/mL = ${_fmt(ml, decimals: 3)} mL';
        } else {
          // mg/mcg/g
          if (mgPerMl == null) return const SizedBox.shrink();
          final desiredMg = switch (unit) { 'mg' => v, 'mcg' => v / 1000.0, 'g' => v * 1000.0, _ => v };
          final ml = desiredMg / mgPerMl;
          line = '${_fmt(desiredMg)} mg ÷ ${_fmt(mgPerMl)} mg/mL = ${_fmt(ml, decimals: 3)} mL';
        }
        break;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(line, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

