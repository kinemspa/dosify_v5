// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_form_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ScheduleFormState {
  ScheduleMode get mode => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  bool get noEnd => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get medicationName => throw _privateConstructorUsedError;
  String? get medicationId => throw _privateConstructorUsedError;
  double get doseValue => throw _privateConstructorUsedError;
  String get doseUnit => throw _privateConstructorUsedError;
  List<TimeOfDay> get times => throw _privateConstructorUsedError;
  Set<int> get days => throw _privateConstructorUsedError;
  Set<int> get daysOfMonth => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  bool get useCycle => throw _privateConstructorUsedError;
  int get daysOn => throw _privateConstructorUsedError;
  int get daysOff => throw _privateConstructorUsedError;
  int get cycleN => throw _privateConstructorUsedError;
  DateTime get cycleAnchor => throw _privateConstructorUsedError;
  bool get nameAuto => throw _privateConstructorUsedError;
  Medication? get selectedMed => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  SyringeType? get selectedSyringeType => throw _privateConstructorUsedError;
  bool get showMedSelector =>
      throw _privateConstructorUsedError; // Loading/Error state
  bool get isSaving => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ScheduleFormStateCopyWith<ScheduleFormState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleFormStateCopyWith<$Res> {
  factory $ScheduleFormStateCopyWith(
          ScheduleFormState value, $Res Function(ScheduleFormState) then) =
      _$ScheduleFormStateCopyWithImpl<$Res, ScheduleFormState>;
  @useResult
  $Res call(
      {ScheduleMode mode,
      DateTime? endDate,
      bool noEnd,
      String name,
      String medicationName,
      String? medicationId,
      double doseValue,
      String doseUnit,
      List<TimeOfDay> times,
      Set<int> days,
      Set<int> daysOfMonth,
      bool active,
      bool useCycle,
      int daysOn,
      int daysOff,
      int cycleN,
      DateTime cycleAnchor,
      bool nameAuto,
      Medication? selectedMed,
      DateTime startDate,
      SyringeType? selectedSyringeType,
      bool showMedSelector,
      bool isSaving,
      String? error});
}

/// @nodoc
class _$ScheduleFormStateCopyWithImpl<$Res, $Val extends ScheduleFormState>
    implements $ScheduleFormStateCopyWith<$Res> {
  _$ScheduleFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? endDate = freezed,
    Object? noEnd = null,
    Object? name = null,
    Object? medicationName = null,
    Object? medicationId = freezed,
    Object? doseValue = null,
    Object? doseUnit = null,
    Object? times = null,
    Object? days = null,
    Object? daysOfMonth = null,
    Object? active = null,
    Object? useCycle = null,
    Object? daysOn = null,
    Object? daysOff = null,
    Object? cycleN = null,
    Object? cycleAnchor = null,
    Object? nameAuto = null,
    Object? selectedMed = freezed,
    Object? startDate = null,
    Object? selectedSyringeType = freezed,
    Object? showMedSelector = null,
    Object? isSaving = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as ScheduleMode,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      noEnd: null == noEnd
          ? _value.noEnd
          : noEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      medicationName: null == medicationName
          ? _value.medicationName
          : medicationName // ignore: cast_nullable_to_non_nullable
              as String,
      medicationId: freezed == medicationId
          ? _value.medicationId
          : medicationId // ignore: cast_nullable_to_non_nullable
              as String?,
      doseValue: null == doseValue
          ? _value.doseValue
          : doseValue // ignore: cast_nullable_to_non_nullable
              as double,
      doseUnit: null == doseUnit
          ? _value.doseUnit
          : doseUnit // ignore: cast_nullable_to_non_nullable
              as String,
      times: null == times
          ? _value.times
          : times // ignore: cast_nullable_to_non_nullable
              as List<TimeOfDay>,
      days: null == days
          ? _value.days
          : days // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      daysOfMonth: null == daysOfMonth
          ? _value.daysOfMonth
          : daysOfMonth // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      useCycle: null == useCycle
          ? _value.useCycle
          : useCycle // ignore: cast_nullable_to_non_nullable
              as bool,
      daysOn: null == daysOn
          ? _value.daysOn
          : daysOn // ignore: cast_nullable_to_non_nullable
              as int,
      daysOff: null == daysOff
          ? _value.daysOff
          : daysOff // ignore: cast_nullable_to_non_nullable
              as int,
      cycleN: null == cycleN
          ? _value.cycleN
          : cycleN // ignore: cast_nullable_to_non_nullable
              as int,
      cycleAnchor: null == cycleAnchor
          ? _value.cycleAnchor
          : cycleAnchor // ignore: cast_nullable_to_non_nullable
              as DateTime,
      nameAuto: null == nameAuto
          ? _value.nameAuto
          : nameAuto // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedMed: freezed == selectedMed
          ? _value.selectedMed
          : selectedMed // ignore: cast_nullable_to_non_nullable
              as Medication?,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      selectedSyringeType: freezed == selectedSyringeType
          ? _value.selectedSyringeType
          : selectedSyringeType // ignore: cast_nullable_to_non_nullable
              as SyringeType?,
      showMedSelector: null == showMedSelector
          ? _value.showMedSelector
          : showMedSelector // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScheduleFormStateImplCopyWith<$Res>
    implements $ScheduleFormStateCopyWith<$Res> {
  factory _$$ScheduleFormStateImplCopyWith(_$ScheduleFormStateImpl value,
          $Res Function(_$ScheduleFormStateImpl) then) =
      __$$ScheduleFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ScheduleMode mode,
      DateTime? endDate,
      bool noEnd,
      String name,
      String medicationName,
      String? medicationId,
      double doseValue,
      String doseUnit,
      List<TimeOfDay> times,
      Set<int> days,
      Set<int> daysOfMonth,
      bool active,
      bool useCycle,
      int daysOn,
      int daysOff,
      int cycleN,
      DateTime cycleAnchor,
      bool nameAuto,
      Medication? selectedMed,
      DateTime startDate,
      SyringeType? selectedSyringeType,
      bool showMedSelector,
      bool isSaving,
      String? error});
}

/// @nodoc
class __$$ScheduleFormStateImplCopyWithImpl<$Res>
    extends _$ScheduleFormStateCopyWithImpl<$Res, _$ScheduleFormStateImpl>
    implements _$$ScheduleFormStateImplCopyWith<$Res> {
  __$$ScheduleFormStateImplCopyWithImpl(_$ScheduleFormStateImpl _value,
      $Res Function(_$ScheduleFormStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? endDate = freezed,
    Object? noEnd = null,
    Object? name = null,
    Object? medicationName = null,
    Object? medicationId = freezed,
    Object? doseValue = null,
    Object? doseUnit = null,
    Object? times = null,
    Object? days = null,
    Object? daysOfMonth = null,
    Object? active = null,
    Object? useCycle = null,
    Object? daysOn = null,
    Object? daysOff = null,
    Object? cycleN = null,
    Object? cycleAnchor = null,
    Object? nameAuto = null,
    Object? selectedMed = freezed,
    Object? startDate = null,
    Object? selectedSyringeType = freezed,
    Object? showMedSelector = null,
    Object? isSaving = null,
    Object? error = freezed,
  }) {
    return _then(_$ScheduleFormStateImpl(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as ScheduleMode,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      noEnd: null == noEnd
          ? _value.noEnd
          : noEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      medicationName: null == medicationName
          ? _value.medicationName
          : medicationName // ignore: cast_nullable_to_non_nullable
              as String,
      medicationId: freezed == medicationId
          ? _value.medicationId
          : medicationId // ignore: cast_nullable_to_non_nullable
              as String?,
      doseValue: null == doseValue
          ? _value.doseValue
          : doseValue // ignore: cast_nullable_to_non_nullable
              as double,
      doseUnit: null == doseUnit
          ? _value.doseUnit
          : doseUnit // ignore: cast_nullable_to_non_nullable
              as String,
      times: null == times
          ? _value._times
          : times // ignore: cast_nullable_to_non_nullable
              as List<TimeOfDay>,
      days: null == days
          ? _value._days
          : days // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      daysOfMonth: null == daysOfMonth
          ? _value._daysOfMonth
          : daysOfMonth // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      useCycle: null == useCycle
          ? _value.useCycle
          : useCycle // ignore: cast_nullable_to_non_nullable
              as bool,
      daysOn: null == daysOn
          ? _value.daysOn
          : daysOn // ignore: cast_nullable_to_non_nullable
              as int,
      daysOff: null == daysOff
          ? _value.daysOff
          : daysOff // ignore: cast_nullable_to_non_nullable
              as int,
      cycleN: null == cycleN
          ? _value.cycleN
          : cycleN // ignore: cast_nullable_to_non_nullable
              as int,
      cycleAnchor: null == cycleAnchor
          ? _value.cycleAnchor
          : cycleAnchor // ignore: cast_nullable_to_non_nullable
              as DateTime,
      nameAuto: null == nameAuto
          ? _value.nameAuto
          : nameAuto // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedMed: freezed == selectedMed
          ? _value.selectedMed
          : selectedMed // ignore: cast_nullable_to_non_nullable
              as Medication?,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      selectedSyringeType: freezed == selectedSyringeType
          ? _value.selectedSyringeType
          : selectedSyringeType // ignore: cast_nullable_to_non_nullable
              as SyringeType?,
      showMedSelector: null == showMedSelector
          ? _value.showMedSelector
          : showMedSelector // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ScheduleFormStateImpl implements _ScheduleFormState {
  const _$ScheduleFormStateImpl(
      {required this.mode,
      this.endDate,
      this.noEnd = true,
      this.name = '',
      this.medicationName = '',
      this.medicationId,
      this.doseValue = 0,
      this.doseUnit = 'mg',
      final List<TimeOfDay> times = const [TimeOfDay(hour: 9, minute: 0)],
      final Set<int> days = const {1, 2, 3, 4, 5, 6, 7},
      final Set<int> daysOfMonth = const {},
      this.active = true,
      this.useCycle = false,
      this.daysOn = 5,
      this.daysOff = 2,
      this.cycleN = 2,
      required this.cycleAnchor,
      this.nameAuto = true,
      this.selectedMed,
      required this.startDate,
      this.selectedSyringeType,
      this.showMedSelector = false,
      this.isSaving = false,
      this.error})
      : _times = times,
        _days = days,
        _daysOfMonth = daysOfMonth;

  @override
  final ScheduleMode mode;
  @override
  final DateTime? endDate;
  @override
  @JsonKey()
  final bool noEnd;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String medicationName;
  @override
  final String? medicationId;
  @override
  @JsonKey()
  final double doseValue;
  @override
  @JsonKey()
  final String doseUnit;
  final List<TimeOfDay> _times;
  @override
  @JsonKey()
  List<TimeOfDay> get times {
    if (_times is EqualUnmodifiableListView) return _times;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_times);
  }

  final Set<int> _days;
  @override
  @JsonKey()
  Set<int> get days {
    if (_days is EqualUnmodifiableSetView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_days);
  }

  final Set<int> _daysOfMonth;
  @override
  @JsonKey()
  Set<int> get daysOfMonth {
    if (_daysOfMonth is EqualUnmodifiableSetView) return _daysOfMonth;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_daysOfMonth);
  }

  @override
  @JsonKey()
  final bool active;
  @override
  @JsonKey()
  final bool useCycle;
  @override
  @JsonKey()
  final int daysOn;
  @override
  @JsonKey()
  final int daysOff;
  @override
  @JsonKey()
  final int cycleN;
  @override
  final DateTime cycleAnchor;
  @override
  @JsonKey()
  final bool nameAuto;
  @override
  final Medication? selectedMed;
  @override
  final DateTime startDate;
  @override
  final SyringeType? selectedSyringeType;
  @override
  @JsonKey()
  final bool showMedSelector;
// Loading/Error state
  @override
  @JsonKey()
  final bool isSaving;
  @override
  final String? error;

  @override
  String toString() {
    return 'ScheduleFormState(mode: $mode, endDate: $endDate, noEnd: $noEnd, name: $name, medicationName: $medicationName, medicationId: $medicationId, doseValue: $doseValue, doseUnit: $doseUnit, times: $times, days: $days, daysOfMonth: $daysOfMonth, active: $active, useCycle: $useCycle, daysOn: $daysOn, daysOff: $daysOff, cycleN: $cycleN, cycleAnchor: $cycleAnchor, nameAuto: $nameAuto, selectedMed: $selectedMed, startDate: $startDate, selectedSyringeType: $selectedSyringeType, showMedSelector: $showMedSelector, isSaving: $isSaving, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleFormStateImpl &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.noEnd, noEnd) || other.noEnd == noEnd) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.medicationName, medicationName) ||
                other.medicationName == medicationName) &&
            (identical(other.medicationId, medicationId) ||
                other.medicationId == medicationId) &&
            (identical(other.doseValue, doseValue) ||
                other.doseValue == doseValue) &&
            (identical(other.doseUnit, doseUnit) ||
                other.doseUnit == doseUnit) &&
            const DeepCollectionEquality().equals(other._times, _times) &&
            const DeepCollectionEquality().equals(other._days, _days) &&
            const DeepCollectionEquality()
                .equals(other._daysOfMonth, _daysOfMonth) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.useCycle, useCycle) ||
                other.useCycle == useCycle) &&
            (identical(other.daysOn, daysOn) || other.daysOn == daysOn) &&
            (identical(other.daysOff, daysOff) || other.daysOff == daysOff) &&
            (identical(other.cycleN, cycleN) || other.cycleN == cycleN) &&
            (identical(other.cycleAnchor, cycleAnchor) ||
                other.cycleAnchor == cycleAnchor) &&
            (identical(other.nameAuto, nameAuto) ||
                other.nameAuto == nameAuto) &&
            (identical(other.selectedMed, selectedMed) ||
                other.selectedMed == selectedMed) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.selectedSyringeType, selectedSyringeType) ||
                other.selectedSyringeType == selectedSyringeType) &&
            (identical(other.showMedSelector, showMedSelector) ||
                other.showMedSelector == showMedSelector) &&
            (identical(other.isSaving, isSaving) ||
                other.isSaving == isSaving) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        mode,
        endDate,
        noEnd,
        name,
        medicationName,
        medicationId,
        doseValue,
        doseUnit,
        const DeepCollectionEquality().hash(_times),
        const DeepCollectionEquality().hash(_days),
        const DeepCollectionEquality().hash(_daysOfMonth),
        active,
        useCycle,
        daysOn,
        daysOff,
        cycleN,
        cycleAnchor,
        nameAuto,
        selectedMed,
        startDate,
        selectedSyringeType,
        showMedSelector,
        isSaving,
        error
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleFormStateImplCopyWith<_$ScheduleFormStateImpl> get copyWith =>
      __$$ScheduleFormStateImplCopyWithImpl<_$ScheduleFormStateImpl>(
          this, _$identity);
}

abstract class _ScheduleFormState implements ScheduleFormState {
  const factory _ScheduleFormState(
      {required final ScheduleMode mode,
      final DateTime? endDate,
      final bool noEnd,
      final String name,
      final String medicationName,
      final String? medicationId,
      final double doseValue,
      final String doseUnit,
      final List<TimeOfDay> times,
      final Set<int> days,
      final Set<int> daysOfMonth,
      final bool active,
      final bool useCycle,
      final int daysOn,
      final int daysOff,
      final int cycleN,
      required final DateTime cycleAnchor,
      final bool nameAuto,
      final Medication? selectedMed,
      required final DateTime startDate,
      final SyringeType? selectedSyringeType,
      final bool showMedSelector,
      final bool isSaving,
      final String? error}) = _$ScheduleFormStateImpl;

  @override
  ScheduleMode get mode;
  @override
  DateTime? get endDate;
  @override
  bool get noEnd;
  @override
  String get name;
  @override
  String get medicationName;
  @override
  String? get medicationId;
  @override
  double get doseValue;
  @override
  String get doseUnit;
  @override
  List<TimeOfDay> get times;
  @override
  Set<int> get days;
  @override
  Set<int> get daysOfMonth;
  @override
  bool get active;
  @override
  bool get useCycle;
  @override
  int get daysOn;
  @override
  int get daysOff;
  @override
  int get cycleN;
  @override
  DateTime get cycleAnchor;
  @override
  bool get nameAuto;
  @override
  Medication? get selectedMed;
  @override
  DateTime get startDate;
  @override
  SyringeType? get selectedSyringeType;
  @override
  bool get showMedSelector;
  @override // Loading/Error state
  bool get isSaving;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$ScheduleFormStateImplCopyWith<_$ScheduleFormStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
