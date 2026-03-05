// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/notifications/notification_service.dart';
import 'package:skedux/src/core/utils/format.dart';
import 'package:skedux/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:skedux/src/features/schedules/data/schedule_scheduler.dart';
import 'package:skedux/src/features/schedules/domain/entry_calculator.dart';
import 'package:skedux/src/features/schedules/domain/schedule.dart';
import 'package:skedux/src/features/schedules/presentation/schedule_mode.dart';
import 'package:skedux/src/features/schedules/presentation/widgets/schedule_wizard_base.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';
import 'package:skedux/src/widgets/entry_input_field.dart';
import 'package:skedux/src/widgets/field36.dart';
import 'package:skedux/src/widgets/unified_form.dart';

enum _StartFromMode { now, date }

enum _EndMode { none, date }

enum _MonthlyMissingDayMode { skip, lastDay }

class AddScheduleWizardPage extends ScheduleWizardBase {
  const AddScheduleWizardPage({
    super.key,
    this.initial,
    this.initialScheduleId,
  });

  final Schedule? initial;
  final String? initialScheduleId;

  bool get isEditing => initial != null || initialScheduleId != null;

  @override
  String get wizardTitle => isEditing ? 'Edit Schedule' : 'Add Schedule';

  @override
  int get stepCount => 3;

  @override
  List<String> get stepLabels => [
    'MEDICATION & AMOUNT',
    'SCHEDULE PATTERN',
    'REVIEW & CONFIRM',
  ];

  @override
  State<AddScheduleWizardPage> createState() => _AddScheduleWizardPageState();
}

class _AddScheduleWizardPageState
    extends ScheduleWizardState<AddScheduleWizardPage> {
  Schedule? _resolvedInitial;

  Schedule? get _initial => widget.initial ?? _resolvedInitial;

  // Step 1: Medication & Entry
  Medication? _selectedMed;
  String? _medicationId;
  final _entryValue = TextEditingController();
  final _entryUnit = TextEditingController();
  SyringeType? _selectedSyringeType;
  EntryCalculationResult? _entryResult;

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

  void _onNameChanged() {
    // Keep the wizard navigation bar in sync with validation state.
    // Without this, the Save button can remain enabled/disabled after edits,
    // and pressing Save can appear to do nothing.
    if (!mounted) return;
    if (currentStep == 2) {
      setState(() {});
    }
  }

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
    _name.addListener(_onNameChanged);
    final schedule =
        widget.initial ??
        (widget.initialScheduleId == null
            ? null
            : Hive.box<Schedule>('schedules').get(widget.initialScheduleId));
    if (schedule != null) {
      _resolvedInitial = schedule;
      _loadInitialData(schedule);
    }
  }

  @override
  void dispose() {
    _name.removeListener(_onNameChanged);
    _entryValue.dispose();
    _entryUnit.dispose();
    _daysOn.dispose();
    _daysOff.dispose();
    _name.dispose();
    super.dispose();
  }

  void _loadInitialData(Schedule s) {
    _nameAuto = false;
    _name.text = s.name;
    _active = s.active;

    _entryValue.text = s.entryValue.toString();
    _entryUnit.text = s.entryUnit;
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

  bool _hasPositiveEntryFromResult(EntryCalculationResult result) {
    final values = <double>[
      (result.entryTabletQuarters ?? 0) / 4.0,
      (result.entryCapsules ?? 0).toDouble(),
      (result.entrySyringes ?? 0).toDouble(),
      (result.entryVials ?? 0).toDouble(),
      (result.entryMassMcg ?? 0).toDouble(),
      (result.entryVolumeMicroliter ?? 0).toDouble(),
      (result.syringeUnits ?? 0).toDouble(),
    ];
    return values.any((v) => v > 0.000001);
  }

  @override
  bool get canProceed {
    switch (currentStep) {
      case 0:
        if (_selectedMed == null) return false;

        // Prefer typed entry result from EntryInputField (especially important for MDV).
        final result = _entryResult;
        if (result != null && result.success && !result.hasError) {
          return _hasPositiveEntryFromResult(result);
        }

        // Backward-compatible fallback for legacy entry fields.
        return _entryValue.text.trim().isNotEmpty &&
            _entryUnit.text.trim().isNotEmpty &&
            (double.tryParse(_entryValue.text.trim()) ?? 0) > 0;
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
        return _buildMedicationEntryStep();
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
    final headerFg = medicationDetailHeaderForegroundColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: kScheduleWizardSummaryIconSize,
              height: kScheduleWizardSummaryIconSize,
              decoration: BoxDecoration(
                color: headerFg.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(kBorderRadiusSmall),
              ),
              child: Icon(_getMedicationIcon(), size: 20, color: headerFg),
            ),
            const SizedBox(width: kScheduleWizardSummaryIconGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedMed?.name ?? 'Select Medication',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: headerFg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (med != null)
                    Text(
                      _medStrengthOrConcentrationSummaryLabel(med),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: headerFg.withValues(alpha: 0.85),
                      ),
                    ),
                  if (med != null)
                    Text(
                      _remainingStockSummaryLabel(med),
                      style: helperTextStyle(
                        context,
                        color: headerFg.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (med != null &&
                      med.form != MedicationForm.multiDoseVial &&
                      _entryValue.text.isNotEmpty)
                    Text(
                      'Amount: ${_entryMetricsSummaryLabel(separator: ' = ')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: headerFg.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_times.isNotEmpty && currentStep >= 1) ...[
          const SizedBox(height: 8),
          Padding(
            padding: kScheduleWizardSummaryPatternPadding,
            child: Text(
              _getPatternSummary(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: headerFg.withValues(alpha: 0.85),
              ),
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
    return formatted;
  }

  String _entrySummaryLabel() {
    final rawValue = double.tryParse(_entryValue.text.trim());
    final value = rawValue ?? 0;
    final unit = _entryUnit.text.trim();
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

  String _entryMetricsSummaryLabel({String separator = ' | '}) {
    final med = _selectedMed;
    final r = _entryResult;
    if (med == null || r == null || r.hasError) {
      return _entrySummaryLabel();
    }

    final summary = MedicationDisplayHelpers.entryMetricsSummary(
      med,
      entryTabletQuarters: r.entryTabletQuarters,
      entryCapsules: r.entryCapsules,
      entrySyringes: r.entrySyringes,
      entryVials: r.entryVials,
      entryMassMcg: r.entryMassMcg,
      entryVolumeMicroliter: r.entryVolumeMicroliter,
      syringeUnits: r.syringeUnits,
      separator: separator,
    );
    if (summary.isEmpty) return _entrySummaryLabel();
    return summary;
  }

  String _getPatternSummary() {
    final buffer = StringBuffer();
    switch (_mode) {
      case ScheduleMode.everyDay:
        buffer.write(_modeLabel(_mode));
      case ScheduleMode.daysOfWeek:
        buffer.write('${_modeLabel(_mode)}: ');
        if (_days.isEmpty) {
          buffer.write('Days of week');
        } else {
          final days = _days.toList()..sort();
          buffer.write(days.map(_getDayName).join(', '));
        }
      case ScheduleMode.daysOnOff:
        final on = int.tryParse(_daysOn.text) ?? 5;
        final off = int.tryParse(_daysOff.text) ?? 2;
        buffer.write('${_modeLabel(_mode)}: $on days on, $off days off');
      case ScheduleMode.daysOfMonth:
        buffer.write('${_modeLabel(_mode)}: ');
        if (_daysOfMonth.isEmpty) {
          buffer.write('Days of month');
        } else {
          final days = _daysOfMonth.toList()..sort();
          buffer.write(days.join(', '));
        }
    }
    buffer.write(' | ');
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

  Widget _buildMedicationEntryStep() {
    return Column(
      children: [
        _buildSection(context, 'Select Medication', [
          _buildMedicationSelector(),
          const SizedBox(height: kSpacingS),
          _helperBelowLeft(
            _selectedMed == null
                ? 'Tap a medication to select it.'
                : 'Tap the selected medication to change it.',
          ),
        ], titleSpacing: kSpacingS),
        if (_selectedMed != null) ...[
          const SizedBox(height: 16),
          _buildSection(context, 'Configure Amount', [_buildEntryConfiguration()]),
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
        final medications = box.values.toList()
          ..sort((a, b) {
            final aHasStock = a.stockValue > 0;
            final bHasStock = b.stockValue > 0;
            if (aHasStock != bHasStock) {
              return aHasStock ? -1 : 1;
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

        if (_selectedMed != null) {
          return _MedicationListRow(
            medication: _selectedMed!,
            isSelected: true,
            onTap: () => setState(() {
              _selectedMed = null;
              _medicationId = null;
              _entryValue.clear();
              _entryUnit.clear();
              _entryResult = null;
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
          _entryUnit.text = 'tablets';
          if (_entryValue.text.trim().isEmpty) _entryValue.text = '1';
        case MedicationForm.capsule:
          _entryUnit.text = 'capsules';
          if (_entryValue.text.trim().isEmpty) _entryValue.text = '1';
        case MedicationForm.prefilledSyringe:
          _entryUnit.text = 'syringes';
          if (_entryValue.text.trim().isEmpty) _entryValue.text = '1';
        case MedicationForm.singleDoseVial:
          _entryUnit.text = 'vials';
          if (_entryValue.text.trim().isEmpty) _entryValue.text = '1';
        case MedicationForm.multiDoseVial:
          final savedRecon = SavedReconstitutionRepository().ownedForMedication(
            med.id,
          );

          if (_entryValue.text.trim().isEmpty) {
            final entry = savedRecon?.calculatedEntry;
            final unit = savedRecon?.entryUnit;
            if (entry != null &&
                entry > 0 &&
                unit != null &&
                unit.trim().isNotEmpty) {
              _entryValue.text = fmt2(entry);
              _entryUnit.text = unit.trim();
              break;
            }

            // Fallback: infer entry amount from saved concentration + entry volume.
            final perMl = med.perMlValue;
            final volumeMl = med.volumePerEntry;
            if (perMl != null &&
                volumeMl != null &&
                perMl > 0 &&
                volumeMl > 0) {
              _entryValue.text = fmt2(perMl * volumeMl);
              final u = med.strengthUnit;
              if (u == Unit.mcg) {
                _entryUnit.text = 'mcg';
              } else if (u == Unit.mg) {
                _entryUnit.text = 'mg';
              } else if (u == Unit.g) {
                _entryUnit.text = 'g';
              } else if (u == Unit.units) {
                _entryUnit.text = 'units';
              } else {
                _entryUnit.text = 'mg';
              }
              break;
            }
          }

          if (_entryUnit.text.trim().isEmpty) {
            final u = med.strengthUnit;
            if (u == Unit.units) {
              _entryUnit.text = 'units';
            } else if (u == Unit.mcg) {
              _entryUnit.text = 'mcg';
            } else if (u == Unit.g) {
              _entryUnit.text = 'g';
            } else {
              _entryUnit.text = 'mg';
            }
          }

          if (_entryValue.text.trim().isEmpty) _entryValue.text = '1';
      }
      _maybeAutoName();
    });
  }

  void _syncLegacyEntryFieldsFromResult(EntryCalculationResult result) {
    if (!result.success) return;

    // MDV needs explicit sync because EntryInputField doesn't use legacy controllers.
    if (_selectedMed?.form == MedicationForm.multiDoseVial) {
      if (result.syringeUnits != null) {
        _entryValue.text = fmt2(result.syringeUnits!);
        _entryUnit.text = 'units';
        return;
      }

      if (result.entryVolumeMicroliter != null) {
        _entryValue.text = fmt2(result.entryVolumeMicroliter! / 1000);
        _entryUnit.text = 'ml';
        return;
      }

      if (result.entryMassMcg != null) {
        final raw = result.entryMassMcg!;
        final strengthUnit = (_getStrengthUnit() ?? 'mg').toLowerCase();
        if (strengthUnit == 'units') {
          _entryValue.text = fmt2(raw);
          _entryUnit.text = 'units';
          return;
        }
        if (strengthUnit == 'mg') {
          _entryValue.text = fmt2(raw / 1000);
          _entryUnit.text = 'mg';
          return;
        }
        if (strengthUnit == 'g') {
          _entryValue.text = fmt2(raw / 1000000);
          _entryUnit.text = 'g';
          return;
        }
        _entryValue.text = fmt2(raw);
        _entryUnit.text = 'mcg';
        return;
      }
    }

    if (result.entryTabletQuarters != null) {
      final tabletCount = result.entryTabletQuarters! / 4;
      _entryValue.text = fmt2(tabletCount);
      _entryUnit.text = 'tablets';
      return;
    }

    if (result.entryCapsules != null) {
      _entryValue.text = result.entryCapsules!.toString();
      _entryUnit.text = 'capsules';
      return;
    }

    if (result.entrySyringes != null) {
      _entryValue.text = result.entrySyringes!.toString();
      _entryUnit.text = 'syringes';
      return;
    }

    if (result.entryVials != null) {
      _entryValue.text = result.entryVials!.toString();
      _entryUnit.text = 'vials';
      return;
    }

    if (result.entryVolumeMicroliter != null) {
      // Keep existing unit choice when possible.
      if (_entryUnit.text.trim().toLowerCase() == 'ml') {
        _entryValue.text = fmt2(result.entryVolumeMicroliter! / 1000);
        return;
      }
    }

    if (result.entryMassMcg != null) {
      final unit = _entryUnit.text.trim().toLowerCase();
      final mcg = result.entryMassMcg!;
      if (unit == 'mg') {
        _entryValue.text = fmt2(mcg / 1000);
        return;
      }
      if (unit == 'g') {
        _entryValue.text = fmt2(mcg / 1000000);
        return;
      }
      _entryValue.text = fmt2(mcg);
      if (_entryUnit.text.trim().isEmpty) {
        _entryUnit.text = 'mcg';
      }
    }
  }

  Widget _buildEntryConfiguration() {
    return Column(
      children: [
        if (_selectedMed!.form == MedicationForm.multiDoseVial) ...[
          LabelFieldRow(
            label: 'Syringe Size',
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
          _helperBelowLeft('Select the syringe size used for administration.'),
          const SizedBox(height: kSpacingS),
        ],
        EntryInputField(
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
              _entryUnit.text = unit;
            });
          },
          onEntryChanged: (result) {
            setState(() {
              _entryResult = result;
              _syncLegacyEntryFieldsFromResult(result);
              _maybeAutoName();
            });
          },
        ),
        const SizedBox(height: kSpacingS),
        if (_selectedMed!.form == MedicationForm.multiDoseVial)
          _helperBelowLeft(
            'Enter the amount by strength, volume (mL), or syringe units. The app will calculate the other values automatically based on the vial concentration and syringe size.',
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
        ], titlePrimary: true),
        const SizedBox(height: kSpacingL),
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
                      _initial?.cycleAnchorDate == null) {
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
        ], titlePrimary: true),
        const SizedBox(height: kSpacingL),
        _buildSection(context, 'Dosing Times', [
          _buildTimesList(),
          const SizedBox(height: kSpacingS),
          _helperBelowLeft('Tap a time to edit it.'),
        ], titlePrimary: true),
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

  // ==================== DOSE HELPERS (EntryInputField) ====================

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

    if (med.volumePerEntry != null) {
      final volume = med.volumePerEntry!;
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
    final entryVolumeMl = med.volumePerEntry;
    if (entryVolumeMl != null && entryVolumeMl > 0) {
      if (entryVolumeMl <= 0.3) return SyringeType.ml_0_3;
      if (entryVolumeMl <= 0.5) return SyringeType.ml_0_5;
      if (entryVolumeMl <= 1.0) return SyringeType.ml_1_0;
      if (entryVolumeMl <= 3.0) return SyringeType.ml_3_0;
      if (entryVolumeMl <= 5.0) return SyringeType.ml_5_0;
      return SyringeType.ml_5_0;
    }

    return SyringeType.ml_1_0;
  }

  double? _getInitialStrengthMcg() {
    if (_initial == null) return null;
    return _initial!.entryMassMcg?.toDouble();
  }

  double? _getInitialTabletCount() {
    if (_initial == null) return null;
    if (_initial!.entryTabletQuarters != null) {
      return _initial!.entryTabletQuarters! / 4.0;
    }
    return null;
  }

  int? _getInitialCapsuleCount() {
    if (_initial == null) return null;
    return _initial!.entryCapsules;
  }

  int? _getInitialInjectionCount() {
    if (_initial == null) return null;
    return _initial!.entrySyringes;
  }

  String _modeLabel(ScheduleMode m) => switch (m) {
    ScheduleMode.everyDay => 'Daily',
    ScheduleMode.daysOfWeek => 'Weekly',
    ScheduleMode.daysOnOff => 'Cycle',
    ScheduleMode.daysOfMonth => 'Monthly',
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
            const SizedBox(height: kSpacingS),
            _helperBelowLeft('Choose the days of the week for scheduled entries.'),
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
              'Active for $daysOnValue days, then pause for $daysOffValue days. This cycle repeats.',
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
            const SizedBox(height: kSpacingS),
            _helperBelowLeft('Select the day numbers (1–31) for scheduled entries.'),
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
              textCapitalization: kTextCapitalizationDefault,
              decoration: buildFieldDecoration(
                context,
                hint: 'e.g., 1 Tablet',
              ).copyWith(border: InputBorder.none),
            ),
          ),
        ),
        const SizedBox(height: kSpacingS),
        Text(
          'Auto-filled based on the entry. You can rename it.',
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

    final entry = _autoNameEntrySegment();

    _name.text = entry;
  }

  String _autoNameEntrySegment() {
    // Prefer typed entry result when available.
    final r = _entryResult;
    if (r != null && !r.hasError) {
      if (r.entryTabletQuarters != null) {
        final quarters = r.entryTabletQuarters!;
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

      if (r.entryCapsules != null) {
        final n = r.entryCapsules!;
        return '$n ${n == 1 ? 'Capsule' : 'Capsules'}';
      }

      if (r.entrySyringes != null) {
        final n = r.entrySyringes!;
        return '$n ${n == 1 ? 'Injection' : 'Injections'}';
      }

      if (r.entryVials != null) {
        final n = r.entryVials!;
        return '$n ${n == 1 ? 'Vial' : 'Vials'}';
      }

      if (_selectedMed?.form == MedicationForm.multiDoseVial &&
          r.syringeUnits != null) {
        final u = r.syringeUnits!;
        return '${fmt2(u)} ${u == 1 ? 'Unit' : 'Units'}';
      }

      if (r.entryMassMcg != null) {
        // Fall back to the user-facing entry label for strength-based entries.
        return _entrySummaryLabel();
      }
    }

    // Fall back to legacy fields.
    final value = _entryValue.text.trim();
    final unit = _entryUnit.text.trim();
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

    // Ensure notifications permission (same safety checks as legacy schedule editor)
    final granted = await NotificationService.ensurePermissionGranted();
    if (!granted && mounted) {
      showAppSnackBar(
        context,
        'Enable notifications to receive schedule alerts.',
      );
    }

    final canExact = await NotificationService.canScheduleExactAlarms();
    final enabled = await NotificationService.areNotificationsEnabled();
    if (mounted && (!enabled || !canExact)) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Allow reminders'),
          content: Text(
            !enabled
                ? 'Notifications are disabled for Skedux. Enable notifications to receive reminders.'
                : 'Android restricts exact alarms. Enable "Alarms & reminders" for Skedux to deliver reminders at the exact time.',
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
                    'upcoming_entry',
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

    final id = _initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
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

    // Compute typed entry fields
    int? entryUnitCode;
    int? entryMassMcg;
    int? entryVolumeMicroliter;
    int? entryTabletQuarters;
    int? entryCapsules;
    int? entrySyringes;
    int? entryVials;
    int? entryIU;
    int? displayUnitCode;
    int? inputModeCode;

    if (_entryResult != null) {
      final result = _entryResult!;
      entryMassMcg = result.entryMassMcg?.round();
      entryVolumeMicroliter = result.entryVolumeMicroliter?.round();
      entryTabletQuarters = result.entryTabletQuarters;
      entryCapsules = result.entryCapsules;
      entrySyringes = result.entrySyringes;
      entryVials = result.entryVials;

      // Parse display text to determine unit
      final displayText = result.displayText;
      if (displayText.contains('tablets')) {
        entryUnitCode = EntryUnit.tablets.index;
        displayUnitCode = EntryUnit.tablets.index;
        inputModeCode = EntryInputMode.tablets.index;
      } else if (displayText.contains('capsules')) {
        entryUnitCode = EntryUnit.capsules.index;
        displayUnitCode = EntryUnit.capsules.index;
        inputModeCode = EntryInputMode.capsules.index;
      } else if (displayText.contains('syringes')) {
        entryUnitCode = EntryUnit.syringes.index;
        displayUnitCode = EntryUnit.syringes.index;
      } else if (displayText.contains('vials')) {
        entryUnitCode = EntryUnit.vials.index;
        displayUnitCode = EntryUnit.vials.index;
      } else if (displayText.contains('mcg')) {
        entryUnitCode = EntryUnit.mcg.index;
        displayUnitCode = EntryUnit.mcg.index;
        inputModeCode = EntryInputMode.mass.index;
      } else if (displayText.contains('mg')) {
        entryUnitCode = EntryUnit.mg.index;
        displayUnitCode = EntryUnit.mg.index;
        inputModeCode = EntryInputMode.mass.index;
      } else if (displayText.contains('ml')) {
        entryUnitCode = EntryUnit.ml.index;
        displayUnitCode = EntryUnit.ml.index;
        inputModeCode = EntryInputMode.volume.index;
      } else if (displayText.contains('IU') || displayText.contains('units')) {
        entryUnitCode = EntryUnit.iu.index;
        displayUnitCode = EntryUnit.iu.index;
        inputModeCode = EntryInputMode.iuUnits.index;
      }
    }

    final schedule = Schedule(
      id: id,
      name: _name.text,
      medicationName: _selectedMed!.name,
      entryValue: double.tryParse(_entryValue.text) ?? 0,
      entryUnit: _entryUnit.text,
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
      entryUnitCode: entryUnitCode,
      entryMassMcg: entryMassMcg,
      entryVolumeMicroliter: entryVolumeMicroliter,
      entryTabletQuarters: entryTabletQuarters,
      entryCapsules: entryCapsules,
      entrySyringes: entrySyringes,
      entryVials: entryVials,
      entryIU: entryIU,
      displayUnitCode: displayUnitCode,
      inputModeCode: inputModeCode,
      startAt: _effectiveStartAt(),
      endAt: _effectiveEndAt(),
      monthlyMissingDayBehaviorCode:
          _monthlyMissingDayMode == _MonthlyMissingDayMode.lastDay
          ? MonthlyMissingDayBehavior.lastDay.index
          : MonthlyMissingDayBehavior.skip.index,
    );

    try {
      final box = Hive.box<Schedule>('schedules');
      await box.put(id, schedule);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to save schedule');
      }
      return;
    }

    // Scheduling notifications is best-effort; a failure should not block saving.
    try {
      if (schedule.active) {
        await ScheduleScheduler.scheduleFor(schedule);
      } else {
        await ScheduleScheduler.cancelFor(schedule.id);
      }
    } catch (_) {
      // Intentionally ignore; user may have disabled exact alarms/notifications.
    }

    if (!mounted) return;
    showAppSnackBar(context, 'Schedule "${schedule.name}" saved');
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/schedules');
  }

  // ==================== HELPERS ====================

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children, {
    bool titlePrimary = true,
    double titleSpacing = kSpacingM,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(kSpacingL),
      decoration: buildInsetSectionDecoration(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: sectionTitleStyle(context)?.copyWith(color: cs.primary),
          ),
          SizedBox(height: titleSpacing),
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
        : '$manufacturer | $strengthLabel';

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
