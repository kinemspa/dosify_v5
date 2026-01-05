// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/schedule_wizard_base.dart';
import 'package:dosifi_v5/src/widgets/dose_input_field.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

enum ScheduleMode { everyDay, daysOfWeek, daysOnOff, daysOfMonth }

enum _StartFromMode { now, date }

enum _EndMode { none, date }

enum _MonthlyMissingDayMode { skip, lastDay }

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

  SyringeType _normalizeSyringeType(SyringeType type) {
    // The 10mL syringe is no longer offered; normalize legacy selections.
    if (type == SyringeType.ml_10_0) return SyringeType.ml_5_0;
    return type;
  }

  // Step 2: Schedule Pattern
  ScheduleMode _mode = ScheduleMode.everyDay;
  final Set<int> _days = {1, 2, 3, 4, 5, 6, 7};
  final Set<int> _daysOfMonth = {};
  final _daysOn = TextEditingController(text: '5');
  final _daysOff = TextEditingController(text: '2');
  DateTime _cycleAnchor = DateTime.now();
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 9, minute: 0)];

  _MonthlyMissingDayMode _monthlyMissingDayMode =
      _MonthlyMissingDayMode.lastDay;

  // Schedule bounds
  _StartFromMode _startFromMode = _StartFromMode.now;
  DateTime _startFromDate = DateTime.now();
  _EndMode _endMode = _EndMode.none;
  DateTime _endDate = DateTime.now();

  // Step 3: Review
  bool _active = true;
  final _name = TextEditingController();
  bool _nameAuto = true;

  int _readPositiveInt(
    TextEditingController controller, {
    required int fallback,
  }) {
    final parsed = int.tryParse(controller.text.trim());
    if (parsed == null || parsed < 1) return fallback;
    return parsed;
  }

  void _incIntController(TextEditingController controller) {
    final current = _readPositiveInt(controller, fallback: 1);
    setState(() => controller.text = '${current + 1}');
  }

  void _decIntController(TextEditingController controller) {
    final current = _readPositiveInt(controller, fallback: 1);
    if (current <= 1) return;
    setState(() => controller.text = '${current - 1}');
  }

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _loadInitialData(widget.initial!);
    }
  }

  @override
  void dispose() {
    _doseValue.dispose();
    _doseUnit.dispose();
    _daysOn.dispose();
    _daysOff.dispose();
    _name.dispose();
    super.dispose();
  }

  void _loadInitialData(Schedule s) {
    _nameAuto = false;
    _name.text = s.name;
    _active = s.active;

    _doseValue.text = s.doseValue.toString();
    _doseUnit.text = s.doseUnit;
    _medicationId = s.medicationId;

    final meds = Hive.box<Medication>('medications').values;
    Medication? match;
    if (s.medicationId != null) {
      for (final m in meds) {
        if (m.id == s.medicationId) {
          match = m;
          break;
        }
      }
    }
    if (match == null) {
      for (final m in meds) {
        if (m.name == s.medicationName) {
          match = m;
          break;
        }
      }
    }
    _selectedMed = match;

    final minutes = (s.timesOfDay ?? [s.minutesOfDay]).toList()..sort();
    _times
      ..clear()
      ..addAll(minutes.map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60)));

    if (s.hasDaysOfMonth) {
      _mode = ScheduleMode.daysOfMonth;
      _daysOfMonth
        ..clear()
        ..addAll(s.daysOfMonth!);
    } else if (s.hasCycle) {
      _mode = ScheduleMode.daysOnOff;
      final n = s.cycleEveryNDays ?? 2;
      final on = n ~/ 2;
      final off = n - on;
      _daysOn.text = '$on';
      _daysOff.text = '$off';
      _cycleAnchor = s.cycleAnchorDate ?? DateTime.now();
    } else {
      final days = s.daysOfWeek.toSet();
      if (days.length == 7) {
        _mode = ScheduleMode.everyDay;
        _days
          ..clear()
          ..addAll({1, 2, 3, 4, 5, 6, 7});
      } else {
        _mode = ScheduleMode.daysOfWeek;
        _days
          ..clear()
          ..addAll(days);
      }
    }

    final startAt = s.startAt;
    if (startAt == null) {
      _startFromMode = _StartFromMode.now;
      _startFromDate = DateTime.now();
    } else {
      final now = DateTime.now();
      final startDay = DateTime(startAt.year, startAt.month, startAt.day);
      final today = DateTime(now.year, now.month, now.day);
      if (startDay.isAtSameMomentAs(today)) {
        _startFromMode = _StartFromMode.now;
        _startFromDate = now;
      } else {
        _startFromMode = _StartFromMode.date;
        _startFromDate = startAt;
      }
    }

    final endAt = s.endAt;
    if (endAt == null) {
      _endMode = _EndMode.none;
      _endDate = DateTime.now();
    } else {
      _endMode = _EndMode.date;
      _endDate = endAt;
    }

    _monthlyMissingDayMode =
        s.monthlyMissingDayBehavior == MonthlyMissingDayBehavior.lastDay
        ? _MonthlyMissingDayMode.lastDay
        : _MonthlyMissingDayMode.skip;
  }

  @override
  String getStepLabel(int step) => widget.stepLabels[step];

  bool _hasPositiveDoseFromResult(DoseCalculationResult result) {
    final values = <double>[
      (result.doseTabletQuarters ?? 0) / 4.0,
      (result.doseCapsules ?? 0).toDouble(),
      (result.doseSyringes ?? 0).toDouble(),
      (result.doseVials ?? 0).toDouble(),
      (result.doseMassMcg ?? 0).toDouble(),
      (result.doseVolumeMicroliter ?? 0).toDouble(),
      (result.syringeUnits ?? 0).toDouble(),
    ];
    return values.any((v) => v > 0.000001);
  }

  @override
  bool get canProceed {
    switch (currentStep) {
      case 0:
        if (_selectedMed == null) return false;

        // Prefer typed dose result from DoseInputField (especially important for MDV).
        final result = _doseResult;
        if (result != null && result.success && !result.hasError) {
          return _hasPositiveDoseFromResult(result);
        }

        // Backward-compatible fallback for legacy dose fields.
        return _doseValue.text.trim().isNotEmpty &&
            _doseUnit.text.trim().isNotEmpty &&
            (double.tryParse(_doseValue.text.trim()) ?? 0) > 0;
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
    final med = _selectedMed;
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
                  if (med != null)
                    Text(
                      _medStrengthOrConcentrationSummaryLabel(med),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  if (med != null)
                    Text(
                      _remainingStockSummaryLabel(med),
                      style: helperTextStyle(
                        context,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (med != null && _doseValue.text.isNotEmpty)
                    Text(
                      'Dose: ${_doseMetricsSummaryLabel()}',
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

  String _medStrengthOrConcentrationSummaryLabel(Medication med) {
    final unit = MedicationDisplayHelpers.unitLabel(med.strengthUnit);

    final isPerMl = switch (med.strengthUnit) {
      Unit.mcgPerMl || Unit.mgPerMl || Unit.gPerMl || Unit.unitsPerMl => true,
      _ => false,
    };

    final term = isPerMl ? 'Concentration' : 'Strength';
    final value = fmt2(med.strengthValue);

    if (isPerMl) {
      return '$term: $value $unit';
    }

    final perUnit = switch (med.form) {
      MedicationForm.tablet => 'tablet',
      MedicationForm.capsule => 'capsule',
      MedicationForm.prefilledSyringe => 'syringe',
      MedicationForm.singleDoseVial => 'vial',
      MedicationForm.multiDoseVial => null,
    };

    if (perUnit == null) return '$term: $value $unit';
    return '$term: $value $unit per $perUnit';
  }

  String _remainingStockSummaryLabel(Medication med) {
    final v = med.stockValue;
    final formatted = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'\.0+$'), '')
              .replaceFirst(RegExp(r'(\.\d*[1-9])0+$'), r'$1');
    return 'Remaining: $formatted';
  }

  String _doseSummaryLabel() {
    final rawValue = double.tryParse(_doseValue.text.trim());
    final value = rawValue ?? 0;
    final unit = _doseUnit.text.trim();
    if (unit.isEmpty) return fmt2(value);

    String singularize(String plural) {
      final t = plural.trim();
      if (t.endsWith('s')) return t.substring(0, t.length - 1);
      return t;
    }

    String pluralize(String base) {
      final t = base.trim();
      if (t.endsWith('s')) return t;
      return '${t}s';
    }

    final prettyValue = fmt2(value);
    final isExactlyOne = (value - 1).abs() < 0.000001;
    final prettyUnit = isExactlyOne ? singularize(unit) : pluralize(unit);
    return '$prettyValue $prettyUnit';
  }

  String _doseMetricsSummaryLabel() {
    final med = _selectedMed;
    final r = _doseResult;
    if (med == null || r == null || r.hasError) {
      return _doseSummaryLabel();
    }

    final summary = MedicationDisplayHelpers.doseMetricsSummary(
      med,
      doseTabletQuarters: r.doseTabletQuarters,
      doseCapsules: r.doseCapsules,
      doseSyringes: r.doseSyringes,
      doseVials: r.doseVials,
      doseMassMcg: r.doseMassMcg,
      doseVolumeMicroliter: r.doseVolumeMicroliter,
      syringeUnits: r.syringeUnits,
    );
    if (summary.isEmpty) return _doseSummaryLabel();
    return summary;
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
          const SizedBox(height: kSpacingS),
          _helperBelowLeft(
            _selectedMed == null
                ? 'Tap a medication to select it. Only medications with stock are shown.'
                : 'Tap the selected medication to change it.',
          ),
        ]),
        if (_selectedMed != null) ...[
          const SizedBox(height: 16),
          _buildSection(context, 'Configure Dose', [_buildDoseConfiguration()]),
        ],
      ],
    );
  }

  Widget _helperBelowLeft(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: helperTextStyle(context)),
    );
  }

  Widget _buildMedicationSelector() {
    return ValueListenableBuilder<Box<Medication>>(
      valueListenable: Hive.box<Medication>('medications').listenable(),
      builder: (context, box, _) {
        final medications = box.values.where((m) => m.stockValue > 0).toList();

        if (_selectedMed != null) {
          return _MedicationListRow(
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
          final cs = Theme.of(context).colorScheme;
          return Container(
            padding: kInsetSectionPadding,
            decoration: buildInsetSectionDecoration(context: context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: kIconSizeLarge,
                  color: cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
                ),
                const SizedBox(height: kSpacingS),
                Text(
                  'No medications available',
                  style: cardTitleStyle(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kSpacingXS),
                Text(
                  'Add a medication first to create a schedule',
                  style: helperTextStyle(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Keep the selector usable with long medication lists.
        final maxHeight = MediaQuery.sizeOf(context).height * 0.45;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView.separated(
            itemCount: medications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final med = medications[index];
              return _MedicationListRow(
                medication: med,
                isSelected: false,
                onTap: () => _selectMedication(med),
              );
            },
          ),
        );
      },
    );
  }

  void _selectMedication(Medication med) {
    setState(() {
      _selectedMed = med;
      _medicationId = med.id;
      _selectedSyringeType = null;

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
          _doseUnit.text = u == Unit.unitsPerMl ? 'units' : 'mg';
          if (_doseValue.text.trim().isEmpty) {
            if (u == Unit.mcgPerMl) {
              _doseValue.text = fmt2(med.strengthValue);
              _doseUnit.text = 'mcg';
            } else if (u == Unit.mgPerMl) {
              _doseValue.text = fmt2(med.strengthValue);
              _doseUnit.text = 'mg';
            } else if (u == Unit.gPerMl) {
              _doseValue.text = fmt2(med.strengthValue);
              _doseUnit.text = 'g';
            } else if (u == Unit.unitsPerMl) {
              _doseValue.text = fmt2(med.strengthValue);
              _doseUnit.text = 'units';
            } else {
              _doseValue.text = '1';
            }
          }
      }
      _maybeAutoName();
    });
  }

  void _syncLegacyDoseFieldsFromResult(DoseCalculationResult result) {
    if (!result.success) return;

    // MDV needs explicit sync because DoseInputField doesn't use legacy controllers.
    if (_selectedMed?.form == MedicationForm.multiDoseVial) {
      if (result.syringeUnits != null) {
        _doseValue.text = fmt2(result.syringeUnits!);
        _doseUnit.text = 'units';
        return;
      }

      if (result.doseVolumeMicroliter != null) {
        _doseValue.text = fmt2(result.doseVolumeMicroliter! / 1000);
        _doseUnit.text = 'ml';
        return;
      }

      if (result.doseMassMcg != null) {
        final raw = result.doseMassMcg!;
        final strengthUnit = (_getStrengthUnit() ?? 'mg').toLowerCase();
        if (strengthUnit == 'units') {
          _doseValue.text = fmt2(raw);
          _doseUnit.text = 'units';
          return;
        }
        if (strengthUnit == 'mg') {
          _doseValue.text = fmt2(raw / 1000);
          _doseUnit.text = 'mg';
          return;
        }
        if (strengthUnit == 'g') {
          _doseValue.text = fmt2(raw / 1000000);
          _doseUnit.text = 'g';
          return;
        }
        _doseValue.text = fmt2(raw);
        _doseUnit.text = 'mcg';
        return;
      }
    }

    if (result.doseTabletQuarters != null) {
      final tabletCount = result.doseTabletQuarters! / 4;
      _doseValue.text = fmt2(tabletCount);
      _doseUnit.text = 'tablets';
      return;
    }

    if (result.doseCapsules != null) {
      _doseValue.text = result.doseCapsules!.toString();
      _doseUnit.text = 'capsules';
      return;
    }

    if (result.doseSyringes != null) {
      _doseValue.text = result.doseSyringes!.toString();
      _doseUnit.text = 'syringes';
      return;
    }

    if (result.doseVials != null) {
      _doseValue.text = result.doseVials!.toString();
      _doseUnit.text = 'vials';
      return;
    }

    if (result.doseVolumeMicroliter != null) {
      // Keep existing unit choice when possible.
      if (_doseUnit.text.trim().toLowerCase() == 'ml') {
        _doseValue.text = fmt2(result.doseVolumeMicroliter! / 1000);
        return;
      }
    }

    if (result.doseMassMcg != null) {
      final unit = _doseUnit.text.trim().toLowerCase();
      final mcg = result.doseMassMcg!;
      if (unit == 'mg') {
        _doseValue.text = fmt2(mcg / 1000);
        return;
      }
      if (unit == 'g') {
        _doseValue.text = fmt2(mcg / 1000000);
        return;
      }
      _doseValue.text = fmt2(mcg);
      if (_doseUnit.text.trim().isEmpty) {
        _doseUnit.text = 'mcg';
      }
    }
  }

  Widget _buildDoseConfiguration() {
    return Column(
      children: [
        if (_selectedMed!.form == MedicationForm.multiDoseVial) ...[
          LabelFieldRow(
            label: 'Syringe',
            field: SmallDropdown36<SyringeType>(
              value: _selectedSyringeType ?? _getSyringeType(),
              items: SyringeType.values
                  .where((t) => t != SyringeType.ml_10_0)
                  .map(
                    (t) => DropdownMenuItem<SyringeType>(
                      value: t,
                      child: Text(t.name, style: bodyTextStyle(context)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSyringeType = value;
                });
              },
            ),
          ),
          const SizedBox(height: kSpacingS),
          _helperBelowLeft(
            'Choose the syringe size so the unit markings match what you use.',
          ),
          const SizedBox(height: kSpacingS),
        ],
        DoseInputField(
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
          onStrengthUnitChanged: (unit) {
            setState(() {
              _doseUnit.text = unit;
            });
          },
          onDoseChanged: (result) {
            setState(() {
              _doseResult = result;
              _syncLegacyDoseFieldsFromResult(result);
              _maybeAutoName();
            });
          },
        ),
        const SizedBox(height: kSpacingS),
        _helperBelowLeft(
          _selectedMed!.form == MedicationForm.multiDoseVial
              ? 'Enter the dose by strength, volume (mL), or syringe units. The app will calculate the other values automatically based on the vial concentration and syringe size.'
              : 'Set the per-dose amount. You can fine-tune later if needed.',
        ),
      ],
    );
  }

  // ==================== STEP 2: SCHEDULE PATTERN ====================

  Widget _buildSchedulePatternStep() {
    return Column(
      children: [
        _buildSection(context, 'Schedule Dates', [
          LabelFieldRow(
            label: 'Start Date',
            field: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmallDropdown36<_StartFromMode>(
                  value: _startFromMode,
                  decoration: buildCompactFieldDecoration(context: context),
                  items: const [
                    DropdownMenuItem(
                      value: _StartFromMode.now,
                      child: Center(child: Text('Today')),
                    ),
                    DropdownMenuItem(
                      value: _StartFromMode.date,
                      child: Center(child: Text('Selected date')),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _startFromMode = v ?? _StartFromMode.now;
                  }),
                ),
                if (_startFromMode == _StartFromMode.date) ...[
                  const SizedBox(height: kSpacingS),
                  DateButton36(
                    label: MaterialLocalizations.of(
                      context,
                    ).formatCompactDate(_startFromDate),
                    selected: true,
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(
                          _startFromDate.year,
                          _startFromDate.month,
                          _startFromDate.day,
                        ),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (picked == null) return;
                      setState(() {
                        _startFromDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _startFromDate.hour,
                          _startFromDate.minute,
                        );

                        if (_endMode == _EndMode.date) {
                          final startDay = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
                          final endDay = DateTime(
                            _endDate.year,
                            _endDate.month,
                            _endDate.day,
                          );
                          if (endDay.isBefore(startDay)) {
                            _endDate = picked;
                          }
                        }
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: kSpacingS),
          _helperBelowLeft(
            'Start today by default. Choose a date to start later.',
          ),
          const SizedBox(height: kSpacingS),
          LabelFieldRow(
            label: 'End',
            field: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmallDropdown36<_EndMode>(
                  value: _endMode,
                  decoration: buildCompactFieldDecoration(context: context),
                  items: const [
                    DropdownMenuItem(
                      value: _EndMode.none,
                      child: Center(child: Text('No end')),
                    ),
                    DropdownMenuItem(
                      value: _EndMode.date,
                      child: Center(child: Text('End date')),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _endMode = v ?? _EndMode.none;
                    if (_endMode == _EndMode.none) return;

                    final startDay = _effectiveStartAt();
                    final endDay = DateTime(
                      _endDate.year,
                      _endDate.month,
                      _endDate.day,
                    );
                    if (endDay.isBefore(
                      DateTime(startDay.year, startDay.month, startDay.day),
                    )) {
                      _endDate = startDay;
                    }
                  }),
                ),
                if (_endMode == _EndMode.date) ...[
                  const SizedBox(height: kSpacingS),
                  DateButton36(
                    label: MaterialLocalizations.of(
                      context,
                    ).formatCompactDate(_endDate),
                    selected: true,
                    onPressed: () async {
                      final startAt = _effectiveStartAt();
                      final first = DateTime(
                        startAt.year,
                        startAt.month,
                        startAt.day,
                      );
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime(
                              _endDate.year,
                              _endDate.month,
                              _endDate.day,
                            ).isBefore(first)
                            ? first
                            : DateTime(
                                _endDate.year,
                                _endDate.month,
                                _endDate.day,
                              ),
                        firstDate: first,
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (picked == null) return;
                      setState(() => _endDate = picked);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: kSpacingS),
          _helperBelowLeft('Optional end date for this schedule.'),
        ]),
        _buildSection(context, 'Schedule Pattern', [
          LabelFieldRow(
            label: 'Type',
            field: SmallDropdown36<ScheduleMode>(
              value: _mode,
              decoration: buildCompactFieldDecoration(context: context),
              items: ScheduleMode.values
                  .map(
                    (mode) => DropdownMenuItem(
                      value: mode,
                      child: Center(
                        child: Text(
                          _modeLabel(mode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  final wasDaysOnOff = _mode == ScheduleMode.daysOnOff;
                  _mode = value ?? ScheduleMode.everyDay;
                  _days.clear();
                  _daysOfMonth.clear();

                  if (_mode == ScheduleMode.everyDay) {
                    _days.addAll([1, 2, 3, 4, 5, 6, 7]);
                  }

                  if (!wasDaysOnOff &&
                      _mode == ScheduleMode.daysOnOff &&
                      widget.initial?.cycleAnchorDate == null) {
                    final startAt = _effectiveStartAt();
                    _cycleAnchor = DateTime(
                      startAt.year,
                      startAt.month,
                      startAt.day,
                    );
                  }
                  _maybeAutoName();
                });
              },
            ),
          ),
          const SizedBox(height: kSpacingS),
          _helperBelowLeft('Choose how often this schedule repeats.'),
          _buildScheduleModeFields(),
        ]),
        const SizedBox(height: kSpacingL),
        _buildSection(context, 'Dosing Times', [
          _buildTimesList(),
          const SizedBox(height: kSpacingS),
          _helperBelowLeft('Tap a time to edit it.'),
        ]),
      ],
    );
  }

  DateTime _effectiveStartAt() {
    final now = DateTime.now();
    if (_startFromMode == _StartFromMode.now) return now;

    final selectedDay = DateTime(
      _startFromDate.year,
      _startFromDate.month,
      _startFromDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    if (selectedDay.isAtSameMomentAs(today)) return now;
    return selectedDay;
  }

  DateTime? _effectiveEndAt() {
    if (_endMode != _EndMode.date) return null;
    return DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      23,
      59,
      59,
      999,
    );
  }

  // ==================== DOSE HELPERS (DoseInputField) ====================

  double? _getStrengthPerUnitMcg() {
    final med = _selectedMed;
    if (med == null) return null;

    switch (med.form) {
      case MedicationForm.tablet:
      case MedicationForm.capsule:
      case MedicationForm.prefilledSyringe:
      case MedicationForm.singleDoseVial:
        final value = med.strengthValue;
        return switch (med.strengthUnit) {
          Unit.mcg || Unit.mcgPerMl => value,
          Unit.mg || Unit.mgPerMl => value * 1000,
          Unit.g || Unit.gPerMl => value * 1000000,
          Unit.units || Unit.unitsPerMl => value,
        };
      case MedicationForm.multiDoseVial:
        return 0;
    }
  }

  double? _getVolumePerUnitMicroliter() {
    final med = _selectedMed;
    if (med == null) return null;

    if (med.volumePerDose != null) {
      final volume = med.volumePerDose!;
      return switch (med.volumeUnit) {
        VolumeUnit.ml => volume * 1000,
        VolumeUnit.l => volume * 1000000,
        null => volume * 1000,
      };
    }

    return null;
  }

  String? _getStrengthUnit() {
    final med = _selectedMed;
    if (med == null) return null;

    return switch (med.strengthUnit) {
      Unit.mcg || Unit.mcgPerMl => 'mcg',
      Unit.mg || Unit.mgPerMl => 'mg',
      Unit.g || Unit.gPerMl => 'g',
      Unit.units || Unit.unitsPerMl => 'units',
    };
  }

  double? _getTotalVialStrengthMcg() {
    final med = _selectedMed;
    if (med == null || med.form != MedicationForm.multiDoseVial) {
      return null;
    }

    final volumeMl = med.containerVolumeMl ?? 1.0;

    // Preferred: derive concentration from the medication's stored strength + per-mL value.
    // This matches how other parts of the app treat `perMlValue` when strengthUnit is not a
    // per-mL unit.
    double? concentrationMcgPerMl;
    switch (med.strengthUnit) {
      case Unit.mcgPerMl:
        concentrationMcgPerMl = med.strengthValue;
      case Unit.mgPerMl:
        concentrationMcgPerMl = med.strengthValue * 1000;
      case Unit.gPerMl:
        concentrationMcgPerMl = med.strengthValue * 1000000;
      case Unit.mcg:
        concentrationMcgPerMl = med.perMlValue;
      case Unit.mg:
        concentrationMcgPerMl = med.perMlValue == null
            ? null
            : (med.perMlValue! * 1000);
      case Unit.g:
        concentrationMcgPerMl = med.perMlValue == null
            ? null
            : (med.perMlValue! * 1000000);
      case Unit.units:
      case Unit.unitsPerMl:
        concentrationMcgPerMl = null;
    }

    if (concentrationMcgPerMl != null) {
      // total mcg in vial = (mcg/mL) * (mL)
      return concentrationMcgPerMl * volumeMl;
    }

    // Fallback (IU-based MDV): treat stored values as units.
    final perMlUnits = (med.strengthUnit == Unit.unitsPerMl)
        ? med.strengthValue
        : (med.perMlValue ?? med.strengthValue);
    return perMlUnits * volumeMl;
  }

  double? _getTotalVialVolumeMicroliter() {
    final med = _selectedMed;
    if (med == null || med.form != MedicationForm.multiDoseVial) {
      return null;
    }

    final volumeMl = med.containerVolumeMl ?? 1.0;
    return volumeMl * 1000;
  }

  SyringeType? _getSyringeType() {
    final med = _selectedMed;
    if (med == null || med.form != MedicationForm.multiDoseVial) {
      return null;
    }

    if (_selectedSyringeType != null) {
      return _normalizeSyringeType(_selectedSyringeType!);
    }

    // Default behavior:
    // - Prefer a saved, user-appropriate dosing volume (from reconstitution)
    // - Otherwise default to a 1mL syringe
    final doseVolumeMl = med.volumePerDose;
    if (doseVolumeMl != null && doseVolumeMl > 0) {
      if (doseVolumeMl <= 0.3) return SyringeType.ml_0_3;
      if (doseVolumeMl <= 0.5) return SyringeType.ml_0_5;
      if (doseVolumeMl <= 1.0) return SyringeType.ml_1_0;
      if (doseVolumeMl <= 3.0) return SyringeType.ml_3_0;
      if (doseVolumeMl <= 5.0) return SyringeType.ml_5_0;
      return SyringeType.ml_5_0;
    }

    return SyringeType.ml_1_0;
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
          padding: const EdgeInsets.only(top: kSpacingS),
          child: Text(
            'Schedule will repeat every day',
            style: helperTextStyle(context),
          ),
        );

      case ScheduleMode.daysOfWeek:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: kSpacingS),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: kSpacingXS,
              runSpacing: kSpacingXS,
              children: List.generate(7, (i) {
                final day = i + 1;
                final isSelected = _days.contains(day);
                return PrimaryChoiceChip(
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
        final daysOnValue = _readPositiveInt(_daysOn, fallback: 5);
        final daysOffValue = _readPositiveInt(_daysOff, fallback: 2);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: kSpacingS),
            LabelFieldRow(
              label: 'Days On',
              field: StepperRow36(
                controller: _daysOn,
                onDec: () => _decIntController(_daysOn),
                onInc: () => _incIntController(_daysOn),
                decoration: buildFieldDecoration(context),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(height: kSpacingS),
            LabelFieldRow(
              label: 'Days Off',
              field: StepperRow36(
                controller: _daysOff,
                onDec: () => _decIntController(_daysOff),
                onInc: () => _incIntController(_daysOff),
                decoration: buildFieldDecoration(context),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(height: kSpacingS),
            Text(
              'Take medication for $daysOnValue days, then pause for $daysOffValue days',
              style: helperTextStyle(context),
            ),
          ],
        );

      case ScheduleMode.daysOfMonth:
        final showMissingDayOption = _daysOfMonth.any((d) => d >= 28);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: kSpacingS),
            _helperBelowLeft(
              'Select which days of the month to take this dose (1-31).',
            ),
            const SizedBox(height: kSpacingS),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: kSpacingXS,
              runSpacing: kSpacingXS,
              children: List.generate(31, (i) {
                final day = i + 1;
                final isSelected = _daysOfMonth.contains(day);
                return PrimaryChoiceChip(
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
            if (showMissingDayOption) ...[
              const SizedBox(height: kSpacingS),
              LabelFieldRow(
                label: "If day doesn't exist",
                field: SmallDropdown36<_MonthlyMissingDayMode>(
                  value: _monthlyMissingDayMode,
                  decoration: buildCompactFieldDecoration(context: context),
                  items: const [
                    DropdownMenuItem(
                      value: _MonthlyMissingDayMode.lastDay,
                      child: Center(child: Text('Use last day of month')),
                    ),
                    DropdownMenuItem(
                      value: _MonthlyMissingDayMode.skip,
                      child: Center(child: Text('Skip that month')),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _monthlyMissingDayMode =
                        v ?? _MonthlyMissingDayMode.lastDay;
                  }),
                ),
              ),
              const SizedBox(height: kSpacingS),
              _helperBelowLeft(
                'Example: selecting 31st in April can become Apr 30 (last day) instead of skipping.',
              ),
            ],
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
            padding: const EdgeInsets.only(bottom: kSpacingS),
            child: Container(
              decoration: buildInsetSectionDecoration(context: context),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: kSpacingS,
                ),
                dense: true,
                leading: Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.onSurfaceVariant
                      .withValues(alpha: kOpacityMedium),
                ),
                title: Text(
                  time.format(context),
                  style: bodyTextStyle(context),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _times.length > 1
                      ? () => setState(() => _times.removeAt(i))
                      : null,
                ),
                onTap: () => _pickTimeAt(i),
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
        sectionSpacing,
        _buildSection(context, 'Settings', [_buildSettingsFields()]),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelFieldRow(
          label: 'Schedule Name',
          field: Field36(
            child: TextFormField(
              controller: _name,
              style: bodyTextStyle(context),
              decoration: buildFieldDecoration(
                context,
                hint: 'e.g., 1 Tablet',
              ).copyWith(border: InputBorder.none),
            ),
          ),
        ),
        const SizedBox(height: kSpacingS),
        Text(
          'Auto-filled based on the dose. You can rename it.',
          style: helperTextStyle(context),
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

    final dose = _autoNameDoseSegment();

    _name.text = dose;
  }

  String _autoNameDoseSegment() {
    // Prefer typed dose result when available.
    final r = _doseResult;
    if (r != null && !r.hasError) {
      if (r.doseTabletQuarters != null) {
        final quarters = r.doseTabletQuarters!;
        final tablets = quarters / 4.0;
        String count;
        if (quarters == 1) {
          count = '1/4';
        } else if (quarters == 2) {
          count = '1/2';
        } else if (quarters == 3) {
          count = '3/4';
        } else {
          count = fmt2(tablets);
        }
        final label = (tablets - 1.0).abs() < 0.0001 || tablets < 1
            ? 'Tablet'
            : 'Tablets';
        return '$count $label';
      }

      if (r.doseCapsules != null) {
        final n = r.doseCapsules!;
        return '$n ${n == 1 ? 'Capsule' : 'Capsules'}';
      }

      if (r.doseSyringes != null) {
        final n = r.doseSyringes!;
        return '$n ${n == 1 ? 'Injection' : 'Injections'}';
      }

      if (r.doseVials != null) {
        final n = r.doseVials!;
        return '$n ${n == 1 ? 'Vial' : 'Vials'}';
      }

      if (_selectedMed?.form == MedicationForm.multiDoseVial &&
          r.syringeUnits != null) {
        final u = r.syringeUnits!;
        return '${fmt2(u)} ${u == 1 ? 'Unit' : 'Units'}';
      }

      if (r.doseMassMcg != null) {
        // Fall back to the user-facing dose label for strength-based entries.
        return _doseSummaryLabel();
      }
    }

    // Fall back to legacy fields.
    final value = _doseValue.text.trim();
    final unit = _doseUnit.text.trim();
    if (value.isEmpty) return '';
    if (unit.isEmpty) return value;
    return '$value $unit';
  }

  Widget _buildSettingsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelFieldRow(
          label: 'Status',
          field: Wrap(
            spacing: kSpacingS,
            runSpacing: kSpacingS,
            children: [
              PrimaryChoiceChip(
                label: const Text('Active'),
                selected: _active,
                onSelected: (_) => setState(() => _active = true),
              ),
              PrimaryChoiceChip(
                label: const Text('Disabled'),
                selected: !_active,
                onSelected: (_) => setState(() => _active = false),
              ),
            ],
          ),
        ),
        buildHelperText(
          context,
          _active ? 'Schedule is enabled' : 'Schedule is disabled',
        ),
        if (_mode == ScheduleMode.daysOnOff) ...[
          const SizedBox(height: kSpacingM),
          ListTile(
            title: Text('Cycle Anchor Date', style: bodyTextStyle(context)),
            subtitle: Text(
              MaterialLocalizations.of(context).formatCompactDate(_cycleAnchor),
              style: helperTextStyle(context),
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
          buildHelperText(
            context,
            'For days on/off schedules, this sets which day the cycle starts on. By default it matches your start date.',
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
      startAt: _effectiveStartAt(),
      endAt: _effectiveEndAt(),
      monthlyMissingDayBehaviorCode:
          _monthlyMissingDayMode == _MonthlyMissingDayMode.lastDay
          ? MonthlyMissingDayBehavior.lastDay.index
          : MonthlyMissingDayBehavior.skip.index,
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
      padding: const EdgeInsets.all(kSpacingL),
      decoration: buildInsetSectionDecoration(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: sectionTitleStyle(context)),
          const SizedBox(height: kSpacingM),
          ...children,
        ],
      ),
    );
  }
}

// ==================== MEDICATION LIST ROW ====================

class _MedicationListRow extends StatelessWidget {
  const _MedicationListRow({
    required this.medication,
    required this.isSelected,
    required this.onTap,
  });

  final Medication medication;
  final bool isSelected;
  final VoidCallback onTap;

  Color _stockColorFor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (medication.stockValue <= 0) return cs.error;
    final low = medication.lowStockThreshold?.toInt() ?? 5;
    if (medication.lowStockEnabled && medication.stockValue <= low) {
      return cs.tertiary;
    }
    return cs.onSurfaceVariant.withValues(alpha: kOpacityMedium);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final manufacturer = (medication.manufacturer ?? '').trim();
    final strengthLabel =
        '${fmt2(medication.strengthValue)} ${MedicationDisplayHelpers.unitLabel(medication.strengthUnit)} '
        '${MedicationDisplayHelpers.formLabel(medication.form, plural: true)}';
    final detailLabel = manufacturer.isEmpty
        ? strengthLabel
        : '$manufacturer · $strengthLabel';

    final stockInfo = MedicationDisplayHelpers.calculateStock(medication);
    final stockColor = _stockColorFor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingS,
            vertical: kSpacingXS,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      medication.name,
                      style: cardTitleStyle(context)?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kSpacingXS),
                    Text(
                      detailLabel,
                      style: helperTextStyle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kSpacingS),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stockInfo.label,
                    style: helperTextStyle(
                      context,
                      color: stockColor,
                    )?.copyWith(fontWeight: kFontWeightSemiBold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(width: kSpacingXS),
              Icon(
                isSelected ? Icons.close : Icons.chevron_right,
                size: kIconSizeMedium,
                color: cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
