// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/schedule_wizard_base.dart';
import 'package:dosifi_v5/src/widgets/dose_input_field.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

enum ScheduleMode { everyDay, daysOfWeek, daysOnOff, daysOfMonth }

class AddScheduleWizardPage extends ScheduleWizardBase {
  const AddScheduleWizardPage({super.key, this.initial});

  final Schedule? initial;

  @override
  int get stepCount => 3;

  @override
  List<String> get stepLabels => [
    'MEDICATION & DOSE',
    'SCHEDULE PATTERN',
    'REVIEW & CONFIRM',
  ];

  @override
  State<AddScheduleWizardPage> createState() => _AddScheduleWizardPageState();
}

class _AddScheduleWizardPageState
    extends ScheduleWizardState<AddScheduleWizardPage> {
  // Step 1: Medication & Dose
  Medication? _selectedMed;
  String? _medicationId;
  final _doseValue = TextEditingController();
  final _doseUnit = TextEditingController();
  SyringeType? _selectedSyringeType;
  DoseCalculationResult? _doseResult;

  // Step 2: Schedule Pattern
  ScheduleMode _mode = ScheduleMode.everyDay;
  final Set<int> _days = {1, 2, 3, 4, 5, 6, 7};
  final Set<int> _daysOfMonth = {};
  bool _useCycle = false;
  final _daysOn = TextEditingController(text: '5');
  final _daysOff = TextEditingController(text: '2');
  final _cycleN = TextEditingController(text: '2');
  DateTime _cycleAnchor = DateTime.now();
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 9, minute: 0)];

  // Step 3: Review
  bool _active = true;
  final _name = TextEditingController();
  bool _nameAuto = true;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _loadInitialData(widget.initial!);
    }
    _name.addListener(() {
      if (_nameAuto && _name.text.isNotEmpty) {
        _nameAuto = false;
      }
    });
  }

  void _loadInitialData(Schedule s) {
    final medBox = Hive.box<Medication>('medications');
    _selectedMed = medBox.get(s.medicationId);
    _medicationId = s.medicationId;
    _doseValue.text = s.doseValue.toString();
    _doseUnit.text = s.doseUnit;

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
      final n = s.cycleEveryNDays ?? 2;
      _daysOn.text = '${n ~/ 2}';
      _daysOff.text = '${n - (n ~/ 2)}';
      _cycleAnchor = s.cycleAnchorDate ?? DateTime.now();
    }

    _name.text = s.name;
    _nameAuto = false;

    _mode = _useCycle
        ? ScheduleMode.daysOnOff
        : (_daysOfMonth.isNotEmpty
              ? ScheduleMode.daysOfMonth
              : (_days.length == 7
                    ? ScheduleMode.everyDay
                    : ScheduleMode.daysOfWeek));
  }

  @override
  void dispose() {
    _doseValue.dispose();
    _doseUnit.dispose();
    _daysOn.dispose();
    _daysOff.dispose();
    _cycleN.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  String getStepLabel(int step) => widget.stepLabels[step];

  @override
  bool get canProceed {
    switch (currentStep) {
      case 0:
        return _selectedMed != null &&
            _doseValue.text.isNotEmpty &&
            _doseUnit.text.isNotEmpty &&
            (double.tryParse(_doseValue.text) ?? 0) > 0;
      case 1:
        if (_times.isEmpty) return false;
        if (_mode == ScheduleMode.daysOfWeek && _days.isEmpty) return false;
        if (_mode == ScheduleMode.daysOfMonth && _daysOfMonth.isEmpty)
          return false;
        if (_mode == ScheduleMode.daysOnOff) {
          final on = int.tryParse(_daysOn.text) ?? 0;
          final off = int.tryParse(_daysOff.text) ?? 0;
          if (on <= 0 || off <= 0) return false;
        }
        return true;
      case 2:
        return _name.text.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildMedicationDoseStep();
      case 1:
        return _buildSchedulePatternStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget buildSummaryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(kBorderRadiusSmall),
              ),
              child: Icon(
                _getMedicationIcon(),
                size: 20,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedMed?.name ?? 'Select Medication',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_selectedMed != null && _doseValue.text.isNotEmpty)
                    Text(
                      'Dose: ${_doseValue.text} ${_doseUnit.text}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_times.isNotEmpty && currentStep >= 1) ...[
          const SizedBox(height: 8),
          Text(
            _getPatternSummary(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ],
    );
  }

  String _getPatternSummary() {
    final buffer = StringBuffer();
    switch (_mode) {
      case ScheduleMode.everyDay:
        buffer.write('Every day');
      case ScheduleMode.daysOfWeek:
        if (_days.isEmpty) {
          buffer.write('Days of week');
        } else {
          final days = _days.toList()..sort();
          buffer.write(days.map(_getDayName).join(', '));
        }
      case ScheduleMode.daysOnOff:
        final on = int.tryParse(_daysOn.text) ?? 5;
        final off = int.tryParse(_daysOff.text) ?? 2;
        buffer.write('$on days on, $off days off');
      case ScheduleMode.daysOfMonth:
        if (_daysOfMonth.isEmpty) {
          buffer.write('Days of month');
        } else {
          final days = _daysOfMonth.toList()..sort();
          buffer.write(days.join(', '));
        }
    }
    buffer.write(' • ');
    buffer.write(_times.map((t) => t.format(context)).join(', '));
    return buffer.toString();
  }

  String _getDayName(int day) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
  }

  IconData _getMedicationIcon() {
    if (_selectedMed == null) return Icons.medication_outlined;
    switch (_selectedMed!.form) {
      case MedicationForm.tablet:
        return Icons.medication;
      case MedicationForm.capsule:
        return Icons.medication;
      case MedicationForm.prefilledSyringe:
        return Icons.vaccines;
      case MedicationForm.singleDoseVial:
        return Icons.science;
      case MedicationForm.multiDoseVial:
        return Icons.science;
    }
  }

  // ==================== STEP 1: MEDICATION & DOSE ====================

  Widget _buildMedicationDoseStep() {
    return Column(
      children: [
        _buildSection(context, 'Select Medication', [
          _buildMedicationSelector(),
        ]),
        if (_selectedMed != null) ...[
          const SizedBox(height: 16),
          _buildSection(context, 'Configure Dose', [_buildDoseConfiguration()]),
        ],
      ],
    );
  }

  Widget _buildMedicationSelector() {
    return ValueListenableBuilder<Box<Medication>>(
      valueListenable: Hive.box<Medication>('medications').listenable(),
      builder: (context, box, _) {
        final medications = box.values.where((m) => m.stockValue > 0).toList();

        if (_selectedMed != null) {
          return _MedicationCard(
            medication: _selectedMed!,
            isSelected: true,
            onTap: () => setState(() {
              _selectedMed = null;
              _medicationId = null;
              _doseValue.clear();
              _doseUnit.clear();
              _doseResult = null;
              _maybeAutoName();
            }),
          );
        }

        if (medications.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(kBorderRadiusMedium),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'No medications available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a medication first to create a schedule',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: medications.map((med) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MedicationCard(
                medication: med,
                isSelected: false,
                onTap: () => _selectMedication(med),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _selectMedication(Medication med) {
    setState(() {
      _selectedMed = med;
      _medicationId = med.id;

      // Set defaults based on form
      switch (med.form) {
        case MedicationForm.tablet:
          _doseUnit.text = 'tablets';
          if (_doseValue.text.trim().isEmpty) _doseValue.text = '1';
        case MedicationForm.capsule:
          _doseUnit.text = 'capsules';
          if (_doseValue.text.trim().isEmpty) _doseValue.text = '1';
        case MedicationForm.prefilledSyringe:
          _doseUnit.text = 'syringes';
          if (_doseValue.text.trim().isEmpty) _doseValue.text = '1';
        case MedicationForm.singleDoseVial:
          _doseUnit.text = 'vials';
          if (_doseValue.text.trim().isEmpty) _doseValue.text = '1';
        case MedicationForm.multiDoseVial:
          final u = med.strengthUnit;
          if (u == Unit.unitsPerMl) {
            _doseUnit.text = 'IU';
          } else {
            _doseUnit.text = 'mg';
          }
          if (_doseValue.text.trim().isEmpty) {
            if (u == Unit.mcgPerMl) {
              _doseValue.text = med.strengthValue.toString();
              _doseUnit.text = 'mcg';
            } else if (u == Unit.mgPerMl) {
              _doseValue.text = med.strengthValue.toString();
              _doseUnit.text = 'mg';
            } else if (u == Unit.gPerMl) {
              _doseValue.text = med.strengthValue.toString();
              _doseUnit.text = 'g';
            } else if (u == Unit.unitsPerMl) {
              _doseValue.text = med.strengthValue.toString();
              _doseUnit.text = 'IU';
            } else {
              _doseValue.text = '1';
            }
          }
      }
      _maybeAutoName();
    });
  }

  Widget _buildDoseConfiguration() {
    return DoseInputField(
      medicationForm: _selectedMed!.form,
      strengthPerUnitMcg: _getStrengthPerUnitMcg() ?? 0,
      volumePerUnitMicroliter: _getVolumePerUnitMicroliter(),
      strengthUnit: _getStrengthUnit() ?? '',
      totalVialStrengthMcg: _getTotalVialStrengthMcg(),
      totalVialVolumeMicroliter: _getTotalVialVolumeMicroliter(),
      syringeType: _getSyringeType(),
      initialStrengthMcg: _getInitialStrengthMcg(),
      initialTabletCount: _getInitialTabletCount(),
      initialCapsuleCount: _getInitialCapsuleCount(),
      initialInjectionCount: _getInitialInjectionCount(),
      initialVialCount: _getInitialVialCount(),
      onDoseChanged: (result) {
        setState(() {
          _doseResult = result;
          _doseValue.text = result.displayText.split(' ').first;
          _doseUnit.text = result.displayText.split(' ').skip(1).join(' ');
          _maybeAutoName();
        });
      },
    );
  }

  // Dose calculation helpers
  double? _getStrengthPerUnitMcg() {
    if (_selectedMed == null) return null;
    final med = _selectedMed!;

    if (med.form == MedicationForm.tablet ||
        med.form == MedicationForm.capsule) {
      return switch (med.strengthUnit) {
        Unit.mcg => med.strengthValue,
        Unit.mg => med.strengthValue * 1000,
        Unit.g => med.strengthValue * 1e6,
        Unit.units => med.strengthValue,
        _ => null,
      };
    }
    return null;
  }

  double? _getVolumePerUnitMicroliter() {
    if (_selectedMed == null) return null;
    final med = _selectedMed!;

    if (med.form == MedicationForm.prefilledSyringe ||
        med.form == MedicationForm.singleDoseVial) {
      final volumeMl = med.containerVolumeMl ?? 1.0;
      return volumeMl * 1000;
    }
    return null;
  }

  String? _getStrengthUnit() {
    if (_selectedMed == null) return null;
    return _unitDisplayName(_selectedMed!.strengthUnit);
  }

  String _unitDisplayName(Unit unit) {
    switch (unit) {
      case Unit.mcg:
        return 'mcg';
      case Unit.mg:
        return 'mg';
      case Unit.g:
        return 'g';
      case Unit.units:
        return 'IU';
      case Unit.mcgPerMl:
        return 'mcg/mL';
      case Unit.mgPerMl:
        return 'mg/mL';
      case Unit.gPerMl:
        return 'g/mL';
      case Unit.unitsPerMl:
        return 'IU/mL';
    }
  }

  double? _getTotalVialStrengthMcg() {
    if (_selectedMed == null ||
        _selectedMed!.form != MedicationForm.multiDoseVial) {
      return null;
    }

    final strength = _selectedMed!.strengthValue;
    final perMl = _selectedMed!.perMlValue ?? strength;
    final volume = _selectedMed!.containerVolumeMl ?? 1.0;

    final mcgPerMl = switch (_selectedMed!.strengthUnit) {
      Unit.mcgPerMl => perMl,
      Unit.mgPerMl => perMl * 1000,
      Unit.gPerMl => perMl * 1000000,
      Unit.unitsPerMl => perMl,
      _ => perMl,
    };

    return mcgPerMl * volume * 1000;
  }

  double? _getTotalVialVolumeMicroliter() {
    if (_selectedMed == null ||
        _selectedMed!.form != MedicationForm.multiDoseVial) {
      return null;
    }
    final volumeMl = _selectedMed!.containerVolumeMl ?? 1.0;
    return volumeMl * 1000;
  }

  SyringeType? _getSyringeType() {
    if (_selectedMed == null ||
        _selectedMed!.form != MedicationForm.multiDoseVial) {
      return null;
    }

    if (_selectedSyringeType != null) return _selectedSyringeType;

    final volumeMl = _selectedMed!.containerVolumeMl ?? 1.0;
    if (volumeMl <= 0.3) return SyringeType.ml_0_3;
    if (volumeMl <= 0.5) return SyringeType.ml_0_5;
    if (volumeMl <= 1.0) return SyringeType.ml_1_0;
    if (volumeMl <= 3.0) return SyringeType.ml_3_0;
    if (volumeMl <= 5.0) return SyringeType.ml_5_0;
    return SyringeType.ml_10_0;
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

  // ==================== STEP 2: SCHEDULE PATTERN ====================

  Widget _buildSchedulePatternStep() {
    return Column(
      children: [
        _buildSection(context, 'Schedule Pattern', [
          _buildScheduleModeSelector(),
          _buildScheduleModeFields(),
        ]),
        const SizedBox(height: 16),
        _buildSection(context, 'Dosing Times', [_buildTimesList()]),
      ],
    );
  }

  Widget _buildScheduleModeSelector() {
    return DropdownButtonFormField<ScheduleMode>(
      value: _mode,
      decoration: const InputDecoration(
        labelText: 'Schedule Type',
        border: OutlineInputBorder(),
      ),
      items: ScheduleMode.values.map((mode) {
        return DropdownMenuItem(value: mode, child: Text(_modeLabel(mode)));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _mode = value ?? ScheduleMode.everyDay;
          _days.clear();
          _daysOfMonth.clear();
          _useCycle = false;

          if (_mode == ScheduleMode.everyDay) {
            _days.addAll([1, 2, 3, 4, 5, 6, 7]);
          }
        });
      },
    );
  }

  String _modeLabel(ScheduleMode m) => switch (m) {
    ScheduleMode.everyDay => 'Every day',
    ScheduleMode.daysOfWeek => 'Days of the week',
    ScheduleMode.daysOnOff => 'Days on / days off',
    ScheduleMode.daysOfMonth => 'Days of the month',
  };

  Widget _buildScheduleModeFields() {
    switch (_mode) {
      case ScheduleMode.everyDay:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Schedule will repeat every day',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );

      case ScheduleMode.daysOfWeek:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final day = i + 1;
                final isSelected = _days.contains(day);
                return FilterChip(
                  label: Text(_getDayName(day)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _days.add(day);
                      } else {
                        _days.remove(day);
                      }
                    });
                  },
                );
              }),
            ),
          ],
        );

      case ScheduleMode.daysOnOff:
        return Column(
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LabelFieldRow(
                    label: 'Days On',
                    field: Field36(
                      child: TextFormField(
                        controller: _daysOn,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        style: bodyTextStyle(context),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LabelFieldRow(
                    label: 'Days Off',
                    field: Field36(
                      child: TextFormField(
                        controller: _daysOff,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        style: bodyTextStyle(context),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Take medication for ${_daysOn.text} days, then pause for ${_daysOff.text} days',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );

      case ScheduleMode.daysOfMonth:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(31, (i) {
                final day = i + 1;
                final isSelected = _daysOfMonth.contains(day);
                return FilterChip(
                  label: Text('$day'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _daysOfMonth.add(day);
                      } else {
                        _daysOfMonth.remove(day);
                      }
                    });
                  },
                );
              }),
            ),
          ],
        );
    }
  }

  Widget _buildTimesList() {
    return Column(
      children: [
        ..._times.asMap().entries.map((entry) {
          final i = entry.key;
          final time = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              dense: true,
              leading: const Icon(Icons.access_time),
              title: Text(time.format(context)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _times.length > 1
                    ? () => setState(() => _times.removeAt(i))
                    : null,
              ),
              onTap: () => _pickTimeAt(i),
              tileColor: Theme.of(context).colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kBorderRadiusSmall),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: _addTime,
          icon: const Icon(Icons.add),
          label: const Text('Add Time'),
        ),
      ],
    );
  }

  Future<void> _pickTimeAt(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) {
      setState(() => _times[index] = picked);
    }
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _times.add(picked);
        _times.sort(
          (a, b) => a.hour * 60 + a.minute - (b.hour * 60 + b.minute),
        );
      });
    }
  }

  // ==================== STEP 3: REVIEW ====================

  Widget _buildReviewStep() {
    return Column(
      children: [
        _buildSection(context, 'Schedule Name', [_buildNameField()]),
        const SizedBox(height: 16),
        _buildSection(context, 'Summary', [_buildSummaryDisplay()]),
        const SizedBox(height: 16),
        _buildSection(context, 'Settings', [_buildSettingsFields()]),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Schedule Name',
            border: OutlineInputBorder(),
            hintText: 'e.g., Morning Dose',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _nameAuto,
              onChanged: (value) {
                setState(() {
                  _nameAuto = value ?? false;
                  if (_nameAuto) _maybeAutoName();
                });
              },
            ),
            Expanded(
              child: Text(
                'Auto-generate name',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _maybeAutoName() {
    if (!_nameAuto) return;
    if (_selectedMed == null) {
      _name.text = '';
      return;
    }

    final medName = _selectedMed!.name;
    final dose = _doseValue.text.isNotEmpty
        ? '${_doseValue.text} ${_doseUnit.text}'
        : '';
    final pattern = _mode == ScheduleMode.everyDay
        ? 'Daily'
        : _mode == ScheduleMode.daysOfWeek
        ? 'Weekly'
        : _mode == ScheduleMode.daysOnOff
        ? 'Cycled'
        : 'Monthly';

    final times = _times.isEmpty ? '' : _times.first.format(context);

    _name.text =
        '$medName ${dose.isNotEmpty ? '($dose) ' : ''}$pattern${times.isNotEmpty ? ' at $times' : ''}';
  }

  Widget _buildSummaryDisplay() {
    return Column(
      children: [
        _buildReviewRow('Medication', _selectedMed?.name ?? ''),
        _buildReviewRow('Dose', '${_doseValue.text} ${_doseUnit.text}'),
        _buildReviewRow('Pattern', _getPatternSummary()),
        if (_mode == ScheduleMode.daysOnOff)
          _buildReviewRow(
            'Cycle Start',
            '${_cycleAnchor.year}-${_cycleAnchor.month}-${_cycleAnchor.day}',
          ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsFields() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Active'),
          subtitle: const Text('Schedule is enabled'),
          value: _active,
          onChanged: (value) => setState(() => _active = value),
        ),
        if (_mode == ScheduleMode.daysOnOff) ...[
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Cycle Start Date'),
            subtitle: Text(
              '${_cycleAnchor.year}-${_cycleAnchor.month}-${_cycleAnchor.day}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _cycleAnchor,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _cycleAnchor = date);
              }
            },
          ),
        ],
      ],
    );
  }

  // ==================== SAVE ====================

  @override
  Future<void> saveSchedule() async {
    if (!canProceed) return;

    final id =
        widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final minutesList = _times.map((t) => t.hour * 60 + t.minute).toList();

    // Compute UTC times and days
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
      final utcDays = <int>[];
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

    final effectiveDays = _mode == ScheduleMode.everyDay
        ? {1, 2, 3, 4, 5, 6, 7}
        : _mode == ScheduleMode.daysOfWeek
        ? _days
        : {1, 2, 3, 4, 5, 6, 7}; // Cycle mode uses all days

    final minutesUtc = computeUtcMinutes(minutesList.first);
    final timesUtc = minutesList.map(computeUtcMinutes).toList();
    final daysUtc = computeUtcDays(effectiveDays, minutesList.first);

    // Compute typed dose fields
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

    if (_doseResult != null) {
      final result = _doseResult!;
      doseMassMcg = result.doseMassMcg?.round();
      doseVolumeMicroliter = result.doseVolumeMicroliter?.round();
      doseTabletQuarters = result.doseTabletQuarters;
      doseCapsules = result.doseCapsules;
      doseSyringes = result.doseSyringes;
      doseVials = result.doseVials;

      // Parse display text to determine unit
      final displayText = result.displayText;
      if (displayText.contains('tablets')) {
        doseUnitCode = DoseUnit.tablets.index;
        displayUnitCode = DoseUnit.tablets.index;
        inputModeCode = DoseInputMode.tablets.index;
      } else if (displayText.contains('capsules')) {
        doseUnitCode = DoseUnit.capsules.index;
        displayUnitCode = DoseUnit.capsules.index;
        inputModeCode = DoseInputMode.capsules.index;
      } else if (displayText.contains('syringes')) {
        doseUnitCode = DoseUnit.syringes.index;
        displayUnitCode = DoseUnit.syringes.index;
      } else if (displayText.contains('vials')) {
        doseUnitCode = DoseUnit.vials.index;
        displayUnitCode = DoseUnit.vials.index;
      } else if (displayText.contains('mcg')) {
        doseUnitCode = DoseUnit.mcg.index;
        displayUnitCode = DoseUnit.mcg.index;
        inputModeCode = DoseInputMode.mass.index;
      } else if (displayText.contains('mg')) {
        doseUnitCode = DoseUnit.mg.index;
        displayUnitCode = DoseUnit.mg.index;
        inputModeCode = DoseInputMode.mass.index;
      } else if (displayText.contains('ml')) {
        doseUnitCode = DoseUnit.ml.index;
        displayUnitCode = DoseUnit.ml.index;
        inputModeCode = DoseInputMode.volume.index;
      } else if (displayText.contains('IU') || displayText.contains('units')) {
        doseUnitCode = DoseUnit.iu.index;
        displayUnitCode = DoseUnit.iu.index;
        inputModeCode = DoseInputMode.iuUnits.index;
      }
    }

    final schedule = Schedule(
      id: id,
      name: _name.text,
      medicationName: _selectedMed!.name,
      doseValue: double.tryParse(_doseValue.text) ?? 0,
      doseUnit: _doseUnit.text,
      minutesOfDay: minutesList.first,
      daysOfWeek: effectiveDays.toList()..sort(),
      minutesOfDayUtc: minutesUtc,
      daysOfWeekUtc: daysUtc,
      medicationId: _medicationId,
      active: _active,
      timesOfDay: minutesList,
      timesOfDayUtc: timesUtc,
      cycleEveryNDays: _mode == ScheduleMode.daysOnOff
          ? (int.tryParse(_daysOn.text) ?? 0) +
                (int.tryParse(_daysOff.text) ?? 0)
          : null,
      cycleAnchorDate: _mode == ScheduleMode.daysOnOff ? _cycleAnchor : null,
      daysOfMonth: _mode == ScheduleMode.daysOfMonth
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
    await box.put(id, schedule);

    if (schedule.active) {
      await ScheduleScheduler.scheduleFor(schedule);
    } else {
      await ScheduleScheduler.cancelFor(schedule.id);
    }

    if (mounted) {
      context.go('/schedules');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schedule "${schedule.name}" saved')),
      );
    }
  }

  // ==================== HELPERS ====================

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ==================== MEDICATION CARD ====================

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.isSelected,
    required this.onTap,
  });

  final Medication medication;
  final bool isSelected;
  final VoidCallback onTap;

  String _formatStrength() {
    final value = medication.strengthValue;
    final formattedValue = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '$formattedValue ${_unitDisplayName(medication.strengthUnit)}';
  }

  String _unitDisplayName(Unit unit) {
    switch (unit) {
      case Unit.mcg:
        return 'mcg';
      case Unit.mg:
        return 'mg';
      case Unit.g:
        return 'g';
      case Unit.units:
        return 'IU';
      case Unit.mcgPerMl:
        return 'mcg/mL';
      case Unit.mgPerMl:
        return 'mg/mL';
      case Unit.gPerMl:
        return 'g/mL';
      case Unit.unitsPerMl:
        return 'IU/mL';
    }
  }

  String _formatStock() {
    switch (medication.form) {
      case MedicationForm.tablet:
        final qty = medication.stockValue.toInt();
        return '$qty tablet${qty == 1 ? '' : 's'}';
      case MedicationForm.capsule:
        final qty = medication.stockValue.toInt();
        return '$qty capsule${qty == 1 ? '' : 's'}';
      case MedicationForm.prefilledSyringe:
        final qty = medication.stockValue.toInt();
        return '$qty syringe${qty == 1 ? '' : 's'}';
      case MedicationForm.singleDoseVial:
        final qty = medication.stockValue.toInt();
        return '$qty vial${qty == 1 ? '' : 's'}';
      case MedicationForm.multiDoseVial:
        final qty = medication.stockValue.toInt();
        return '$qty vial${qty == 1 ? '' : 's'}';
    }
  }

  IconData _getFormIcon(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return Icons.medication;
      case MedicationForm.capsule:
        return Icons.medication;
      case MedicationForm.prefilledSyringe:
        return Icons.vaccines;
      case MedicationForm.singleDoseVial:
        return Icons.science;
      case MedicationForm.multiDoseVial:
        return Icons.science;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusMedium),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(kBorderRadiusMedium),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(kBorderRadiusSmall),
              ),
              child: Icon(
                _getFormIcon(medication.form),
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(_formatStrength(), style: theme.textTheme.bodySmall),
                  Text(
                    _formatStock(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: theme.colorScheme.outlineVariant,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
