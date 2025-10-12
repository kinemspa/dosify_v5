import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'widgets/schedule_summary_card.dart';

class AddEditSchedulePage extends StatefulWidget {
  const AddEditSchedulePage({super.key, this.initial});
  final Schedule? initial;

  @override
  State<AddEditSchedulePage> createState() => _AddEditSchedulePageState();
}

class _AddEditSchedulePageState extends State<AddEditSchedulePage> {
  late ScheduleMode _mode;
  DateTime? _endDate;
  bool _noEnd = true;
  final _formKey = GlobalKey<FormState>();
  
  // For floating summary card
  final GlobalKey _summaryKey = GlobalKey();
  double _summaryHeight = 130; // Initial height estimate

  late final TextEditingController _name;
  late final TextEditingController _medicationName;
  late final TextEditingController _doseValue;
  late final TextEditingController _doseUnit;
  String? _medicationId;
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 9, minute: 0)];
  final Set<int> _days = {1, 2, 3, 4, 5, 6, 7};
  final Set<int> _daysOfMonth = {}; // 1-31 for monthly schedules
  bool _active = true;
  bool _useCycle = false;
  final TextEditingController _daysOn = TextEditingController(text: '5');
  final TextEditingController _daysOff = TextEditingController(text: '2');
  final TextEditingController _cycleN = TextEditingController(text: '2');
  DateTime _cycleAnchor = DateTime.now();
  bool _nameAuto = true;
  Medication? _selectedMed;
  DateTime _startDate = DateTime.now();

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
      if (s.daysOfMonth != null && s.daysOfMonth!.isNotEmpty) {
        _daysOfMonth
          ..clear()
          ..addAll(s.daysOfMonth!);
      }
      _active = s.active;
      _useCycle = s.cycleEveryNDays != null;
      if (_useCycle) {
        _cycleN.text = s.cycleEveryNDays!.toString();
        // Try to parse as days on/off if possible
        // For backward compatibility, assume equal days on and off
        final n = s.cycleEveryNDays ?? 2;
        _daysOn.text = '${n ~/ 2}';
        _daysOff.text = '${n - (n ~/ 2)}';
        _cycleAnchor = s.cycleAnchorDate ?? DateTime.now();
      }
      _nameAuto = false; // existing schedule name considered manual
    }
    // Initialize mode based on current fields
    _mode = _useCycle
        ? ScheduleMode.daysOnOff
        : (_daysOfMonth.isNotEmpty
              ? ScheduleMode.daysOfMonth
              : (_days.length == 7
                    ? ScheduleMode.everyDay
                    : ScheduleMode.daysOfWeek));

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
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) setState(() => _times[index] = picked);
  }

  bool _showMedSelector = false;

  void _pickMedication(Medication selected) {
    setState(() {
      _selectedMed = selected;
      _medicationId = selected.id;
      _medicationName.text = selected.name;
      _showMedSelector = false;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate medication selection
    if (_selectedMed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a medication first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If name was auto-generated, ask user if they want to edit before saving
    if (_nameAuto) {
      final proceed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Use this schedule name?'),
              content: Text(_name.text.isEmpty ? '(empty)' : _name.text),
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

    final id =
        widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final minutesList = _times.map((t) => t.hour * 60 + t.minute).toList();

    // Compute UTC fields from the first time and days as legacy, plus per-time UTC list
    final now = DateTime.now();
    int computeUtcMinutes(int localMinutes) {
      final localToday = DateTime(
        now.year,
        now.month,
        now.day,
        localMinutes ~/ 60,
        localMinutes % 60,
      );
      final utc = localToday.toUtc();
      return utc.hour * 60 + utc.minute;
    }

    List<int> computeUtcDays(Set<int> localDays, int localMinutes) {
      final List<int> utcDays = [];
      for (final d in localDays) {
        final delta = (d - now.weekday) % 7;
        final candidate = DateTime(
          now.year,
          now.month,
          now.day + delta,
          localMinutes ~/ 60,
          localMinutes % 60,
        );
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
            final desiredMcg = switch (unitStr) {
              'mcg' => doseVal,
              'mg' => doseVal * 1000,
              'g' => doseVal * 1e6,
              _ => doseVal,
            };
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
            doseUnitCode = switch (unitStr) {
              'mcg' => DoseUnit.mcg.index,
              'mg' => DoseUnit.mg.index,
              'g' => DoseUnit.g.index,
              _ => DoseUnit.mg.index,
            };
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
            final desiredMcg = switch (unitStr) {
              'mcg' => doseVal,
              'mg' => doseVal * 1000,
              'g' => doseVal * 1e6,
              _ => doseVal,
            };
            doseMassMcg = desiredMcg.round();
            final perCapMcg = switch (med.strengthUnit) {
              Unit.mcg => med.strengthValue,
              Unit.mg => med.strengthValue * 1000,
              Unit.g => med.strengthValue * 1e6,
              Unit.units => med.strengthValue,
              _ => med.strengthValue,
            };
            doseCapsules = (desiredMcg / perCapMcg).round();
            doseUnitCode = switch (unitStr) {
              'mcg' => DoseUnit.mcg.index,
              'mg' => DoseUnit.mg.index,
              'g' => DoseUnit.g.index,
              _ => DoseUnit.mg.index,
            };
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
              final desiredMg = switch (unitStr) {
                'mg' => doseVal,
                'mcg' => doseVal / 1000.0,
                'g' => doseVal * 1000.0,
                _ => doseVal,
              };
              final ml = desiredMg / mgPerMl;
              doseMassMcg = (desiredMg * 1000).round();
              doseVolumeMicroliter = (ml * 1000).round();
              doseUnitCode = switch (unitStr) {
                'mcg' => DoseUnit.mcg.index,
                'mg' => DoseUnit.mg.index,
                'g' => DoseUnit.g.index,
                _ => DoseUnit.mg.index,
              };
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
      cycleAnchorDate: _useCycle
          ? DateTime(_cycleAnchor.year, _cycleAnchor.month, _cycleAnchor.day)
          : null,
      daysOfMonth: _daysOfMonth.isNotEmpty
          ? (_daysOfMonth.toList()..sort())
          : null,
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
    // Also preflight-check exact alarm capability and general notification enablement
    // so users see actionable guidance instead of silent drops.
    final granted = await NotificationService.ensurePermissionGranted();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable notifications to receive schedule alerts.'),
        ),
      );
    }

    // Proactive checks: exact alarms and notifications enabled
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
            content: const Text(
              'To schedule exact reminders, enable Alarms & reminders permission for Dosifi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
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
          overlayColor: WidgetStatePropertyAll(
            theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
        ),
      ),
    );
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

  String _doseSummaryShort() {
    final med = _medicationName.text.trim();
    final val = double.tryParse(_doseValue.text.trim()) ?? 0;
    final unit = _doseUnit.text.trim();
    if (med.isEmpty || unit.isEmpty || val <= 0) return '';
    final v = val == val.roundToDouble()
        ? val.toStringAsFixed(0)
        : val.toStringAsFixed(2);
    return '$v $unit${med.isEmpty ? '' : ' · $med'}';
  }

  String _scheduleSummaryShort() {
    if (_times.isEmpty) return '';
    final times = _times.map((t) => t.format(context)).join(', ');
    final start = '${_startDate.toLocal()}'.split(' ').first;
    final end = _noEnd || _endDate == null
        ? 'No end'
        : 'Ends ${'${_endDate!.toLocal()}'.split(' ').first}';
    return 'Start $start · $times · $end';
  }

  String _doseFormulaLine() {
    final med = _selectedMed;
    final v = double.tryParse(_doseValue.text.trim());
    final unit = _doseUnit.text.trim().toLowerCase();
    if (med == null || v == null || v <= 0 || unit.isEmpty) return '';
    // Reuse logic from _DoseFormulaStrip
    switch (med.form) {
      case MedicationForm.tablet:
        if (unit == 'tablets') {
          final quarters = (v * 4).round();
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
          final totalMcg = perTabMcg * quarters / 4.0;
          final mg = totalMcg / 1000.0;
          return '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)} tab × ${med.strengthValue} ${_unitShort(med.strengthUnit)} = ${totalMcg.toStringAsFixed(0)} mcg (${mg.toStringAsFixed(2)} mg)';
        } else {
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
          return '${desiredMcg.toStringAsFixed(0)} mcg ≈ ${quarters.toStringAsFixed(2)} tablets';
        }
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
          return '${v.toStringAsFixed(0)} cap × ${med.strengthValue} ${_unitShort(med.strengthUnit)} = ${totalMcg.toStringAsFixed(0)} mcg (${mg.toStringAsFixed(2)} mg)';
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
          return '${desiredMcg.toStringAsFixed(0)} mcg ≈ ${caps.toStringAsFixed(2)} capsules';
        }
      case MedicationForm.injectionPreFilledSyringe:
        return '${v.toStringAsFixed(0)} syringe';
      case MedicationForm.injectionSingleDoseVial:
        return '${v.toStringAsFixed(0)} vial';
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
          if (mgPerMl != null)
            return '${ml.toStringAsFixed(2)} mL = ${(ml * mgPerMl).toStringAsFixed(2)} mg';
          if (iuPerMl != null)
            return '${ml.toStringAsFixed(2)} mL = ${(ml * iuPerMl).toStringAsFixed(0)} IU';
          return '${ml.toStringAsFixed(2)} mL';
        } else if (unit == 'iu' || unit == 'units') {
          if (iuPerMl == null) return '';
          final ml = v / iuPerMl;
          return '${v.toStringAsFixed(0)} IU = ${ml.toStringAsFixed(3)} mL';
        } else {
          if (mgPerMl == null) return '';
          final desiredMg = switch (unit) {
            'mg' => v,
            'mcg' => v / 1000.0,
            'g' => v * 1000.0,
            _ => v,
          };
          final ml = desiredMg / mgPerMl;
          return '${desiredMg.toStringAsFixed(2)} mg = ${ml.toStringAsFixed(3)} mL';
        }
    }
  }

  Widget _rowLabelField(
    BuildContext context, {
    required String label,
    required Widget field,
  }) {
    final width = MediaQuery.of(context).size.width;
    final labelWidth = width >= 400 ? 120.0 : 110.0;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.75),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget _helperBelowLeft(String text) {
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

  Widget _incBtn(String symbol, VoidCallback onTap) {
    return SizedBox(
      height: 30,
      width: 30,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(30, 30),
        ),
        onPressed: onTap,
        child: Text(symbol),
      ),
    );
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
        child: FilledButton(onPressed: _save, child: const Text('Save')),
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
              _rowLabelField(
                context,
                label: 'Medication',
                field: _selectedMed != null
                    ? _MedicationSummaryDisplay(
                        medication: _selectedMed!,
                        onClear: () => setState(() {
                          _selectedMed = null;
                          _medicationId = null;
                          _medicationName.clear();
                        }),
                        onExpand: () => setState(
                          () => _showMedSelector = !_showMedSelector,
                        ),
                        isExpanded: _showMedSelector,
                      )
                    : OutlinedButton(
                        onPressed: () =>
                            setState(() => _showMedSelector = true),
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
                _selectedMed == null
                    ? 'Select a medication to schedule'
                    : 'Tap to change medication',
              ),
              // Inline medication selector
              if (_showMedSelector) ...[
                const SizedBox(height: 8),
                _InlineMedicationSelector(
                  onSelect: _pickMedication,
                  onCancel: () => setState(() => _showMedSelector = false),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            // Dose controls (Typed) in a card with summary
            if (_selectedMed != null)
              _section(context, 'Dose', [
                _rowLabelField(
                  context,
                  label: 'Dose value',
                  field: SizedBox(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _incBtn('−', () {
                          final unit = _doseUnit.text.trim().toLowerCase();
                          // Smart step: 0.25 for tablets, 1.0 for everything else
                          final step = unit == 'tablets' ? 0.25 : 1.0;
                          final v =
                              double.tryParse(_doseValue.text.trim()) ?? 0.0;
                          final nv = (v - step).clamp(0, 1e12);
                          setState(() {
                            _doseValue.text = (unit == 'tablets')
                                ? nv.toStringAsFixed(nv % 1 == 0 ? 0 : 2)
                                : nv.round().toString();
                            _coerceDoseValueForUnit();
                            _maybeAutoName();
                          });
                        }),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 120,
                          child: Field36(
                            child: TextFormField(
                              controller: _doseValue,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(labelText: ''),
                              keyboardType:
                                  (_doseUnit.text.trim().toLowerCase() ==
                                      'tablets')
                                  ? const TextInputType.numberWithOptions(
                                      decimal: true,
                                    )
                                  : TextInputType.number,
                              onChanged: (_) {
                                _coerceDoseValueForUnit();
                                _maybeAutoName();
                                setState(() {});
                              },
                              validator: (v) {
                                final d = double.tryParse(v?.trim() ?? '');
                                if (d == null || d <= 0)
                                  return 'Enter a positive number';
                                final unit = _doseUnit.text
                                    .trim()
                                    .toLowerCase();
                                if ([
                                  'capsules',
                                  'syringes',
                                  'vials',
                                ].contains(unit)) {
                                  if (d % 1 != 0) return 'Whole numbers only';
                                }
                                if (unit == 'tablets') {
                                  final q = (d * 4).roundToDouble();
                                  if ((q - d * 4).abs() > 1e-6 &&
                                      d % 0.25 != 0) {
                                    return 'Use quarter-tablet steps (0.25)';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _incBtn('+', () {
                          final unit = _doseUnit.text.trim().toLowerCase();
                          // Smart step: 0.25 for tablets, 1.0 for everything else
                          final step = unit == 'tablets' ? 0.25 : 1.0;
                          final v =
                              double.tryParse(_doseValue.text.trim()) ?? 0.0;
                          final nv = (v + step).clamp(0, 1e12);
                          setState(() {
                            _doseValue.text = (unit == 'tablets')
                                ? nv.toStringAsFixed(nv % 1 == 0 ? 0 : 2)
                                : nv.round().toString();
                            _coerceDoseValueForUnit();
                            _maybeAutoName();
                          });
                        }),
                      ],
                    ),
                  ),
                ),
                _rowLabelField(
                  context,
                  label: 'Unit',
                  field: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: kFieldHeight,
                      width: 120,
                      child: DropdownButtonFormField<String>(
                        value: _doseUnit.text.isEmpty ? null : _doseUnit.text,
                        isExpanded: false,
                        alignment: AlignmentDirectional.center,
                        decoration: const InputDecoration(labelText: ''),
                        items: _doseUnitOptions()
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                alignment: AlignmentDirectional.center,
                                child: Center(
                                  child: Text(
                                    e,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _doseUnit.text = v ?? '';
                            _coerceDoseValueForUnit();
                            _maybeAutoName();
                          });
                        },
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ),
                ),
                _helperBelowLeft(
                  'Enter dose amount and unit (tablets allow 0.25 steps)',
                ),
              ]),
            const SizedBox(height: 10),
            if (_selectedMed != null)
              _section(context, 'Schedule', [
                Column(
                  children: [
                    // 1. Choose schedule type
                    _rowLabelField(
                      context,
                      label: 'Schedule type',
                      field: DropdownButtonFormField<ScheduleMode>(
                        value: _mode,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: ''),
                        items: ScheduleMode.values
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(_modeLabel(m)),
                              ),
                            )
                            .toList(),
                        onChanged: (m) {
                          if (m == null) return;
                          setState(() {
                            _mode = m;
                            if (_mode == ScheduleMode.everyDay) {
                              _days
                                ..clear()
                                ..addAll([1, 2, 3, 4, 5, 6, 7]);
                              _useCycle = false;
                              _daysOfMonth.clear();
                            } else if (_mode == ScheduleMode.daysOfWeek) {
                              _useCycle = false;
                              _daysOfMonth.clear();
                              if (_days.isEmpty) {
                                _days.addAll([1, 2, 3, 4, 5]);
                              }
                            } else if (_mode == ScheduleMode.daysOnOff) {
                              _useCycle = true;
                              _daysOfMonth.clear();
                            } else if (_mode == ScheduleMode.daysOfMonth) {
                              _useCycle = false;
                              if (_daysOfMonth.isEmpty) {
                                _daysOfMonth.addAll([
                                  1,
                                ]); // Default to 1st of month
                              }
                            }
                          });
                        },
                      ),
                    ),
                    _helperBelowLeft(_getScheduleModeDescription(_mode)),
                    // 2. Select start date
                    _rowLabelField(
                      context,
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
                              initialDate: _startDate,
                            );
                            if (picked != null)
                              setState(() => _startDate = picked);
                          },
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            '${_startDate.toLocal()}'.split(' ').first,
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(120, kFieldHeight),
                          ),
                        ),
                      ),
                    ),
                    _helperBelowLeft('Select when this schedule should start'),
                    // 3. Select days/months based on mode
                    // Days/months selection section
                    if (_mode == ScheduleMode.daysOfWeek) ...[
                      _helperBelowLeft('Select days of the week'),
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
                            final selected = _days.contains(dayIndex);
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
                      ),
                    ],
                    if (_mode == ScheduleMode.daysOnOff) ...[
                      _rowLabelField(
                        context,
                        label: 'Days on',
                        field: SizedBox(
                          width: 120,
                          height: kFieldHeight,
                          child: Field36(
                            child: TextFormField(
                              controller: _daysOn,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(labelText: ''),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              validator: (v) {
                                final n = int.tryParse(v?.trim() ?? '');
                                if (_mode == ScheduleMode.daysOnOff &&
                                    (n == null || n < 1))
                                  return '>= 1';
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                      ),
                      _rowLabelField(
                        context,
                        label: 'Days off',
                        field: SizedBox(
                          width: 120,
                          height: kFieldHeight,
                          child: Field36(
                            child: TextFormField(
                              controller: _daysOff,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(labelText: ''),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              validator: (v) {
                                final n = int.tryParse(v?.trim() ?? '');
                                if (_mode == ScheduleMode.daysOnOff &&
                                    (n == null || n < 1))
                                  return '>= 1';
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                      ),
                      _helperBelowLeft(
                        'Take doses for specified days on, then stop for days off. Cycle repeats continuously.',
                      ),
                    ],
                    if (_mode == ScheduleMode.daysOfMonth) ...[
                      _helperBelowLeft('Select days of the month (1-31)'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(31, (i) {
                            final day = i + 1;
                            final selected = _daysOfMonth.contains(day);
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
                              onSelected: (sel) {
                                setState(() {
                                  if (sel) {
                                    _daysOfMonth.add(day);
                                  } else {
                                    _daysOfMonth.remove(day);
                                  }
                                });
                              },
                            );
                          }),
                        ),
                      ),
                    ],
                    // 4. Add dosing times
                    const SizedBox(height: 8),
                    _rowLabelField(
                      context,
                      label: 'Time 1',
                      field: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_times.length, (i) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Field36(
                                    width: 120,
                                    child: FilledButton.icon(
                                      onPressed: () => _pickTimeAt(i),
                                      icon: const Icon(
                                        Icons.schedule,
                                        size: 18,
                                      ),
                                      label: Text(_times[i].format(context)),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size(
                                          120,
                                          kFieldHeight,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (_times.length > 1)
                                    IconButton(
                                      tooltip: 'Remove',
                                      onPressed: () =>
                                          setState(() => _times.removeAt(i)),
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
                                setState(() => _times.add(_times.last)),
                            icon: const Icon(Icons.add),
                            label: const Text('Add time'),
                          ),
                        ],
                      ),
                    ),
                    _helperBelowLeft('Add one or more dosing times'),
                    // 5. Select end date
                    _rowLabelField(
                      context,
                      label: 'End date',
                      field: Row(
                        children: [
                          Field36(
                            width: 120,
                            child: FilledButton.icon(
                              onPressed: _noEnd
                                  ? null
                                  : () async {
                                      final now = DateTime.now();
                                      final picked = await showDatePicker(
                                        context: context,
                                        firstDate: DateTime(now.year - 1),
                                        lastDate: DateTime(now.year + 10),
                                        initialDate: _endDate ?? _startDate,
                                      );
                                      if (picked != null)
                                        setState(() {
                                          _endDate = picked;
                                          _noEnd = false;
                                        });
                                    },
                              icon: const Icon(Icons.event, size: 18),
                              label: Text(
                                _noEnd || _endDate == null
                                    ? 'No end'
                                    : '${_endDate!.toLocal()}'.split(' ').first,
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(120, kFieldHeight),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: _noEnd,
                            onChanged: (v) => setState(() {
                              _noEnd = v ?? true;
                              if (_noEnd) _endDate = null;
                            }),
                          ),
                          const Text('No end'),
                        ],
                      ),
                    ),
                    _helperBelowLeft('Optional end date (or leave as No end)'),
                  ],
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
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
              child: IgnorePointer(child: _buildFloatingSummary()),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds the floating summary card that stays at top of screen
  Widget _buildFloatingSummary() {
    final card = ScheduleSummaryCard(
      key: _summaryKey,
      medication: _selectedMed,
      scheduleDescription: _buildScheduleDescription(),
      showInfoOnly: _selectedMed == null || _showMedSelector,
      startDate: _startDate,
      endDate: _noEnd ? null : _endDate,
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

  String _unitShort(Unit u) => switch (u) {
    Unit.mcg => 'mcg',
    Unit.mg => 'mg',
    Unit.g => 'g',
    Unit.units => 'units',
    Unit.mcgPerMl => 'mcg/mL',
    Unit.mgPerMl => 'mg/mL',
    Unit.gPerMl => 'g/mL',
    Unit.unitsPerMl => 'IU/mL',
  };

  String _medStrengthAndStock(Medication m) {
    final strength = _medStrengthLabel(m);
    final stock = m.stockValue;
    String trim(num n) {
      final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
      if (!s.contains('.')) return s;
      return s
          .replaceFirst(RegExp(r'\.0+$'), '')
          .replaceFirst(RegExp(r'(\.\d*?)0+$'), r'$1');
    }

    final s = trim(stock);
    // show "100 remaining" format per user request
    // (second number removed for now; can reintroduce pack/initial later)
    // final stockPart = stock > 0 ? ' • $s/$s' : '';
    return '$strength${stock > 0 ? ' • $s remaining' : ''}';
  }

  String _medStrengthLabel(Medication m) {
    final u = _unitShort(m.strengthUnit);
    String trim(num n) {
      final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
      if (!s.contains('.')) return s;
      return s
          .replaceFirst(RegExp(r'\.0+$'), '')
          .replaceFirst(RegExp(r'(\.\d*?)0+$'), r'$1');
    }

    final v = trim(m.strengthValue);
    return '$v $u';
  }

  List<String> _doseUnitOptions() {
    final med = _selectedMed;
    if (med == null) {
      return const [
        'mg',
        'mcg',
        'g',
        'tablets',
        'capsules',
        'syringes',
        'vials',
        'IU',
      ];
    }
    switch (med.form) {
      case MedicationForm.tablet:
        return const ['tablets', 'mg'];
      case MedicationForm.capsule:
        return const ['capsules', 'mg'];
      case MedicationForm.injectionPreFilledSyringe:
        return const ['syringes'];
      case MedicationForm.injectionSingleDoseVial:
        return const ['vials'];
      case MedicationForm.injectionMultiDoseVial:
        return const ['mg', 'mcg', 'g', 'IU'];
    }
  }

  void _coerceDoseValueForUnit() {
    final unit = _doseUnit.text.trim().toLowerCase();
    final val = double.tryParse(_doseValue.text.trim());
    if (val == null) return;
    if (unit == 'tablets') {
      // Round to nearest quarter tablet
      final q = (val * 4).round() / 4.0;
      _doseValue.text = q.toStringAsFixed(
        q % 1 == 0 ? 0 : (q * 4 % 1 == 0 ? 2 : 2),
      );
    } else if (['capsules', 'syringes', 'vials'].contains(unit)) {
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

  String _getUnitLabel(Unit u) => switch (u) {
    Unit.mcg || Unit.mcgPerMl => 'mcg',
    Unit.mg || Unit.mgPerMl => 'mg',
    Unit.g || Unit.gPerMl => 'g',
    Unit.units || Unit.unitsPerMl => 'units',
  };

  String _getStockUnitLabel(Medication m) => switch (m.form) {
    MedicationForm.tablet => 'tablets',
    MedicationForm.capsule => 'capsules',
    MedicationForm.injectionPreFilledSyringe => 'syringes',
    MedicationForm.injectionSingleDoseVial => 'vials',
    MedicationForm.injectionMultiDoseVial => 'vials',
  };

  IconData _getMedicationIcon(MedicationForm form) => switch (form) {
    MedicationForm.tablet => Icons.add_circle,
    MedicationForm.capsule => Icons.medication,
    MedicationForm.injectionPreFilledSyringe => Icons.colorize,
    MedicationForm.injectionSingleDoseVial => Icons.local_drink,
    MedicationForm.injectionMultiDoseVial => Icons.addchart,
  };

  /// Builds the schedule description for the summary card
  /// Format: "Take {dose} {MedName} {MedType} {frequency} at {times}. Dose is {dose} {unit} is {strength}."
  /// Example: "Take 1 Panadol Tablets Every Day at 22:00. Dose is 1 tablet is 20mg."
  String? _buildScheduleDescription() {
    final med = _selectedMed;
    if (med == null) return null;
    
    final doseVal = double.tryParse(_doseValue.text.trim());
    final doseUnitText = _doseUnit.text.trim();

    if (doseVal == null ||
        doseVal <= 0 ||
        doseUnitText.isEmpty ||
        _times.isEmpty) {
      return null;
    }

    // Format dose value (no trailing zeros)
    final doseStr = doseVal == doseVal.roundToDouble()
        ? doseVal.toStringAsFixed(0)
        : doseVal.toStringAsFixed(2);

    // Format times (chronological order)
    final sortedTimes = _times.toList()
      ..sort((a, b) {
        final aMin = a.hour * 60 + a.minute;
        final bMin = b.hour * 60 + b.minute;
        return aMin.compareTo(bMin);
      });
    
    final timesStr = sortedTimes.map((t) => t.format(context)).join(', ');

    // Format frequency pattern
    String frequencyText;
    if (_mode == ScheduleMode.everyDay) {
      frequencyText = 'Every Day';
    } else if (_mode == ScheduleMode.daysOfWeek) {
      // Check if all 7 days are selected (treat as "Every day")
      if (_days.length == 7) {
        frequencyText = 'Every Day';
      } else {
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final ds = _days.toList()..sort();
        final dtext = ds.map((i) => labels[i - 1]).join(', ');
        frequencyText = 'Every $dtext';
      }
    } else if (_mode == ScheduleMode.daysOfMonth) {
      final sorted = _daysOfMonth.toList()..sort();
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
        break;
      case MedicationForm.capsule:
        medType = 'Capsules';
        break;
      case MedicationForm.injectionPreFilledSyringe:
        medType = 'Pre-Filled Syringes';
        break;
      case MedicationForm.injectionSingleDoseVial:
        medType = 'Single Dose Vials';
        break;
      case MedicationForm.injectionMultiDoseVial:
        medType = 'Multi Dose Vials';
        break;
    }
    
    // Get strength info for dose calculation
    String strengthInfo = '';
    final strengthVal = med.strengthValue;
    final strengthUnit = _getUnitLabel(med.strengthUnit);
    
    // Calculate total strength based on dose
    if (doseUnitText.toLowerCase() == 'tablets' || 
        doseUnitText.toLowerCase() == 'tablet' ||
        doseUnitText.toLowerCase() == 'capsules' ||
        doseUnitText.toLowerCase() == 'capsule') {
      final totalStrength = strengthVal * doseVal;
      final totalStr = totalStrength == totalStrength.roundToDouble()
          ? totalStrength.toStringAsFixed(0)
          : totalStrength.toStringAsFixed(2);
      strengthInfo = ' is $totalStr$strengthUnit';
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
}

enum ScheduleMode { everyDay, daysOfWeek, daysOnOff, daysOfMonth }

String _modeLabel(ScheduleMode m) => switch (m) {
  ScheduleMode.everyDay => 'Every day',
  ScheduleMode.daysOfWeek => 'Days of the week',
  ScheduleMode.daysOnOff => 'Days on / days off',
  ScheduleMode.daysOfMonth => 'Days of the month',
};

class _DoseFormulaStrip extends StatelessWidget {
  const _DoseFormulaStrip({
    required this.selectedMed,
    required this.valueCtrl,
    required this.unitCtrl,
  });
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
            Unit.mcgPerMl =>
              med.strengthValue, // treat as mcg/tab if mis-entered
            Unit.mgPerMl => med.strengthValue * 1000,
            Unit.gPerMl => med.strengthValue * 1e6,
            Unit.unitsPerMl => med.strengthValue,
          };
          final totalMcg = perTabMcg * quarters / 4.0;
          final mg = totalMcg / 1000.0;
          line =
              '${_fmt(v)} tab × ${_fmt(med.strengthValue)} ${med.strengthUnit.name} = ${_fmt(totalMcg)} mcg (${_fmt(mg)} mg)';
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
          line =
              '${_fmt(v)} cap × ${_fmt(med.strengthValue)} ${med.strengthUnit.name} = ${_fmt(totalMcg)} mcg (${_fmt(mg)} mg)';
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
          line =
              '${_fmt(v)} IU ÷ ${_fmt(iuPerMl)} IU/mL = ${_fmt(ml, decimals: 3)} mL';
        } else {
          // mg/mcg/g
          if (mgPerMl == null) return const SizedBox.shrink();
          final desiredMg = switch (unit) {
            'mg' => v,
            'mcg' => v / 1000.0,
            'g' => v * 1000.0,
            _ => v,
          };
          final ml = desiredMg / mgPerMl;
          line =
              '${_fmt(desiredMg)} mg ÷ ${_fmt(mgPerMl)} mg/mL = ${_fmt(ml, decimals: 3)} mL';
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
      child: Text(
        line,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// Schedule summary card similar to medication summary cards
class _ScheduleSummaryCard extends StatelessWidget {
  const _ScheduleSummaryCard({
    required this.medication,
    required this.medicationName,
    required this.doseValue,
    required this.doseUnit,
    required this.times,
    required this.mode,
    required this.days,
    required this.daysOfMonth,
    required this.cycleN,
    required this.startDate,
    required this.endDate,
    required this.noEnd,
    required this.daysOnController,
    required this.daysOffController,
  });

  final Medication? medication;
  final String medicationName;
  final double doseValue;
  final String doseUnit;
  final List<TimeOfDay> times;
  final ScheduleMode mode;
  final Set<int> days;
  final Set<int> daysOfMonth;
  final int? cycleN;
  final DateTime startDate;
  final DateTime? endDate;
  final bool noEnd;
  final TextEditingController daysOnController;
  final TextEditingController daysOffController;

  String _medStrengthLabel(Medication m) {
    final unitLabel = switch (m.strengthUnit) {
      Unit.mcg || Unit.mcgPerMl => 'mcg',
      Unit.mg || Unit.mgPerMl => 'mg',
      Unit.g || Unit.gPerMl => 'g',
      Unit.units || Unit.unitsPerMl => 'units',
    };
    final v = m.strengthValue;
    final val = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'\.0+$'), '')
              .replaceFirst(RegExp(r'(\.\d*?)0+$'), r'$1');
    return '$val $unitLabel';
  }

  String _formatDoseWithUnit(double dose, String unit) {
    final doseStr = dose == dose.roundToDouble()
        ? dose.toStringAsFixed(0)
        : dose.toStringAsFixed(2);

    // Singularize unit if dose is 1
    if (dose == 1.0) {
      if (unit.endsWith('s') && unit.length > 1) {
        return '$doseStr ${unit.substring(0, unit.length - 1)}';
      }
    }

    return '$doseStr $unit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Check if we have enough info to show summary
    if (medication == null ||
        medicationName.isEmpty ||
        doseValue <= 0 ||
        doseUnit.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Select a medication to schedule',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Build the summary text
    final doseFixed = doseValue == doseValue.roundToDouble()
        ? doseValue.toStringAsFixed(0)
        : doseValue.toStringAsFixed(2);
    final unitTxt = doseUnit.toLowerCase();

    // Build time/frequency text
    String timesStr = times.map((t) => t.format(context)).join(', ');
    String frequencyText;
    if (mode == ScheduleMode.everyDay) {
      frequencyText = 'every day';
    } else if (mode == ScheduleMode.daysOfWeek) {
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final ds = days.toList()..sort();
      final dtext = ds.map((i) => labels[i - 1]).join(', ');
      frequencyText = 'on $dtext';
    } else if (mode == ScheduleMode.daysOfMonth) {
      final sorted = daysOfMonth.toList()..sort();
      final dayText = sorted.take(5).join(', ');
      frequencyText = sorted.length > 5
          ? 'on days $dayText... each month'
          : 'on day${sorted.length > 1 ? 's' : ''} $dayText each month';
    } else {
      final n = cycleN ?? 2;
      frequencyText = 'every $n days';
    }

    // Build dose calculation if applicable
    String? doseCalc;
    if (medication != null) {
      final unitTxt = doseUnit.toLowerCase();
      if ((medication!.form == MedicationForm.tablet && unitTxt == 'tablets') ||
          (medication!.form == MedicationForm.capsule &&
              unitTxt == 'capsules')) {
        final perUnitMcg = switch (medication!.strengthUnit) {
          Unit.mcg => medication!.strengthValue,
          Unit.mg => medication!.strengthValue * 1000,
          Unit.g => medication!.strengthValue * 1e6,
          _ => medication!.strengthValue,
        };
        final totalMcg = perUnitMcg * doseValue;
        final totalMg = totalMcg / 1000.0;
        final mgStr = totalMg == totalMg.roundToDouble()
            ? totalMg.toStringAsFixed(0)
            : totalMg.toStringAsFixed(2);
        doseCalc = '$mgStr mg per dose';
      }
    }
    final startStr = '${startDate.toLocal()}'.split(' ').first;
    final endStr = noEnd || endDate == null
        ? 'No end'
        : '${endDate!.toLocal()}'.split(' ').first;

    // Calculate stock depletion
    String stockDepletionText = '';
    if (medication!.stockValue > 0) {
      // Calculate daily usage based on schedule mode
      double dailyUsage = 0;
      final timesPerDay = times.length;

      if (mode == ScheduleMode.everyDay) {
        dailyUsage = doseValue * timesPerDay;
      } else if (mode == ScheduleMode.daysOfWeek) {
        // Average based on days per week
        dailyUsage = doseValue * timesPerDay * (days.length / 7.0);
      } else if (mode == ScheduleMode.daysOfMonth) {
        // Average based on days per month
        dailyUsage = doseValue * timesPerDay * (daysOfMonth.length / 30.0);
      } else if (mode == ScheduleMode.daysOnOff) {
        // Calculate average based on days on/off cycle
        final on = int.tryParse(daysOnController.text.trim()) ?? 5;
        final off = int.tryParse(daysOffController.text.trim()) ?? 2;
        final cycleLength = on + off;
        dailyUsage = doseValue * timesPerDay * (on / cycleLength);
      }

      if (dailyUsage > 0) {
        final daysRemaining = (medication!.stockValue / dailyUsage).floor();
        final depletionDate = DateTime.now().add(Duration(days: daysRemaining));
        final depletionStr = '${depletionDate.toLocal()}'.split(' ').first;
        stockDepletionText =
            'Estimated stock depletion by $depletionStr ($daysRemaining days)';
      }
    }

    // Get form label for dose
    final formLabel = switch (medication!.form) {
      MedicationForm.tablet => 'tablet',
      MedicationForm.capsule => 'capsule',
      MedicationForm.injectionPreFilledSyringe => 'syringe',
      MedicationForm.injectionSingleDoseVial => 'vial',
      MedicationForm.injectionMultiDoseVial => unitTxt,
    };

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line 1: MED NAME + Med Type | Manufacturer
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        medicationName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        medication!.form == MedicationForm.tablet
                            ? 'Tablet'
                            : medication!.form == MedicationForm.capsule
                            ? 'Capsule'
                            : medication!.form ==
                                  MedicationForm.injectionPreFilledSyringe
                            ? 'PFS'
                            : medication!.form ==
                                  MedicationForm.injectionSingleDoseVial
                            ? 'SDV'
                            : 'MDV',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                medication!.manufacturer ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Line 2: Med Strength in MedType | Remaining
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_medStrengthLabel(medication!)} per $formLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${medication!.stockValue.toStringAsFixed(medication!.stockValue == medication!.stockValue.roundToDouble() ? 0 : 1)} remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 12),
          // Line 3: Take X medtype of medname at Time1, Time2... | Schedule Type
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
              children: [
                const TextSpan(text: 'Take '),
                TextSpan(
                  text: _formatDoseWithUnit(doseValue, unitTxt),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' of $medicationName at '),
                TextSpan(
                  text: timesStr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            frequencyText[0].toUpperCase() + frequencyText.substring(1),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          // Line 4: Each Dose of X is Y strength/MedtypeUnit
          if (doseCalc != null) ...[
            const SizedBox(height: 8),
            Text(
              'Each dose is $doseCalc',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          // Line 5: Stock depletion estimate
          if (stockDepletionText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              stockDepletionText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          // Line 6: Starts X Ends Y
          const SizedBox(height: 8),
          Text(
            'Starts $startStr  •  ${endStr == 'No end' ? endStr : 'Ends $endStr'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget to display selected medication inline
class _MedicationSummaryDisplay extends StatelessWidget {
  const _MedicationSummaryDisplay({
    required this.medication,
    required this.onClear,
    required this.onExpand,
    required this.isExpanded,
  });

  final Medication medication;
  final VoidCallback onClear;
  final VoidCallback onExpand;
  final bool isExpanded;

  String _formatStock(Medication m) {
    final stock = m.stockValue;
    final s = stock == stock.roundToDouble()
        ? stock.toStringAsFixed(0)
        : stock
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'\.0+$'), '')
              .replaceFirst(RegExp(r'(\.\d*?)0+$'), r'$1');

    final unit = switch (m.form) {
      MedicationForm.tablet => 'tablets',
      MedicationForm.capsule => 'capsules',
      MedicationForm.injectionPreFilledSyringe => 'syringes',
      MedicationForm.injectionSingleDoseVial => 'vials',
      MedicationForm.injectionMultiDoseVial => 'vials',
    };

    return '$s $unit';
  }

  String _formatStrength(Medication m) {
    final v = m.strengthValue;
    final val = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'\.0+$'), '')
              .replaceFirst(RegExp(r'(\.\d*?)0+$'), r'$1');
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return OutlinedButton(
      onPressed: onExpand,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              medication.name,
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
    return '$s';
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

  String _formLabel(MedicationForm form) => switch (form) {
    MedicationForm.tablet => 'Tablet',
    MedicationForm.capsule => 'Capsule',
    MedicationForm.injectionPreFilledSyringe => 'PFS',
    MedicationForm.injectionSingleDoseVial => 'SDV',
    MedicationForm.injectionMultiDoseVial => 'MDV',
  };

  String _expiryLabel(Medication m) {
    if (m.expiry == null) return 'No expiry';
    final exp = m.expiry!;
    final now = DateTime.now();
    final diff = exp.difference(now).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Expires today';
    if (diff <= 30) return 'Expires in $diff days';
    final expStr = '${exp.toLocal()}'.split(' ').first;
    return 'Exp: $expStr';
  }
  
  String _formatDateDdMm(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }
  
  String _getUnitName(MedicationForm form) {
    return switch (form) {
      MedicationForm.tablet => 'tablets',
      MedicationForm.capsule => 'capsules',
      MedicationForm.injectionPreFilledSyringe => 'syringes',
      MedicationForm.injectionSingleDoseVial => 'vials',
      MedicationForm.injectionMultiDoseVial => 'vials',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final medBox = Hive.box<Medication>('medications');
    final medications = medBox.values.toList();

    if (medications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No medications saved yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add medications first before creating schedules',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Close'),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(4),
        itemCount: medications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final med = medications[index];
          final formLabel = _formLabel(med.form);

          // Determine stock color based on low stock status
          Color stockColor;
          final baseline = med.lowStockThreshold;
          if (baseline != null && baseline > 0) {
            final pct = (med.stockValue / baseline).clamp(0.0, 1.0);
            if (pct <= 0.2) {
              stockColor = cs.error;
            } else if (pct <= 0.5) {
              stockColor = Colors.orange;
            } else {
              stockColor = cs.primary;
            }
          } else if (med.lowStockEnabled &&
              med.stockValue <= (med.lowStockThreshold ?? 0)) {
            stockColor = cs.error;
          } else {
            stockColor = cs.onSurface;
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            title: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: med.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
                children: [
                  if (med.manufacturer != null && med.manufacturer!.isNotEmpty)
                    TextSpan(
                      text: '  •  ${med.manufacturer!}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_formatStrength(med)} $formLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          children: [
                            TextSpan(
                              text: '${_formatStock(med)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: stockColor,
                              ),
                            ),
                            TextSpan(
                              text: '/${_formatStock(med)} ${_getUnitName(med.form)}',
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (med.expiry != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          _formatDateDdMm(med.expiry!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: med.expiry!.isBefore(
                              DateTime.now().add(const Duration(days: 30)),
                            )
                                ? cs.error
                                : cs.onSurfaceVariant.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            onTap: () => onSelect(med),
          );
        },
      ),
    );
  }
}
