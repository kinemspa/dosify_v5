// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication_detail_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MedicationDetailState {
  Medication get medication => throw _privateConstructorUsedError;
  List<Schedule> get linkedSchedules => throw _privateConstructorUsedError;
  StockLevel get stockLevel => throw _privateConstructorUsedError;
  ExpiryWarningLevel get expiryWarning => throw _privateConstructorUsedError;
  double? get daysRemaining => throw _privateConstructorUsedError;
  DateTime? get stockoutDate => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MedicationDetailStateCopyWith<MedicationDetailState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MedicationDetailStateCopyWith<$Res> {
  factory $MedicationDetailStateCopyWith(MedicationDetailState value,
          $Res Function(MedicationDetailState) then) =
      _$MedicationDetailStateCopyWithImpl<$Res, MedicationDetailState>;
  @useResult
  $Res call(
      {Medication medication,
      List<Schedule> linkedSchedules,
      StockLevel stockLevel,
      ExpiryWarningLevel expiryWarning,
      double? daysRemaining,
      DateTime? stockoutDate,
      bool isLoading,
      String? error});
}

/// @nodoc
class _$MedicationDetailStateCopyWithImpl<$Res,
        $Val extends MedicationDetailState>
    implements $MedicationDetailStateCopyWith<$Res> {
  _$MedicationDetailStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? medication = null,
    Object? linkedSchedules = null,
    Object? stockLevel = null,
    Object? expiryWarning = null,
    Object? daysRemaining = freezed,
    Object? stockoutDate = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      medication: null == medication
          ? _value.medication
          : medication // ignore: cast_nullable_to_non_nullable
              as Medication,
      linkedSchedules: null == linkedSchedules
          ? _value.linkedSchedules
          : linkedSchedules // ignore: cast_nullable_to_non_nullable
              as List<Schedule>,
      stockLevel: null == stockLevel
          ? _value.stockLevel
          : stockLevel // ignore: cast_nullable_to_non_nullable
              as StockLevel,
      expiryWarning: null == expiryWarning
          ? _value.expiryWarning
          : expiryWarning // ignore: cast_nullable_to_non_nullable
              as ExpiryWarningLevel,
      daysRemaining: freezed == daysRemaining
          ? _value.daysRemaining
          : daysRemaining // ignore: cast_nullable_to_non_nullable
              as double?,
      stockoutDate: freezed == stockoutDate
          ? _value.stockoutDate
          : stockoutDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MedicationDetailStateImplCopyWith<$Res>
    implements $MedicationDetailStateCopyWith<$Res> {
  factory _$$MedicationDetailStateImplCopyWith(
          _$MedicationDetailStateImpl value,
          $Res Function(_$MedicationDetailStateImpl) then) =
      __$$MedicationDetailStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Medication medication,
      List<Schedule> linkedSchedules,
      StockLevel stockLevel,
      ExpiryWarningLevel expiryWarning,
      double? daysRemaining,
      DateTime? stockoutDate,
      bool isLoading,
      String? error});
}

/// @nodoc
class __$$MedicationDetailStateImplCopyWithImpl<$Res>
    extends _$MedicationDetailStateCopyWithImpl<$Res,
        _$MedicationDetailStateImpl>
    implements _$$MedicationDetailStateImplCopyWith<$Res> {
  __$$MedicationDetailStateImplCopyWithImpl(_$MedicationDetailStateImpl _value,
      $Res Function(_$MedicationDetailStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? medication = null,
    Object? linkedSchedules = null,
    Object? stockLevel = null,
    Object? expiryWarning = null,
    Object? daysRemaining = freezed,
    Object? stockoutDate = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$MedicationDetailStateImpl(
      medication: null == medication
          ? _value.medication
          : medication // ignore: cast_nullable_to_non_nullable
              as Medication,
      linkedSchedules: null == linkedSchedules
          ? _value._linkedSchedules
          : linkedSchedules // ignore: cast_nullable_to_non_nullable
              as List<Schedule>,
      stockLevel: null == stockLevel
          ? _value.stockLevel
          : stockLevel // ignore: cast_nullable_to_non_nullable
              as StockLevel,
      expiryWarning: null == expiryWarning
          ? _value.expiryWarning
          : expiryWarning // ignore: cast_nullable_to_non_nullable
              as ExpiryWarningLevel,
      daysRemaining: freezed == daysRemaining
          ? _value.daysRemaining
          : daysRemaining // ignore: cast_nullable_to_non_nullable
              as double?,
      stockoutDate: freezed == stockoutDate
          ? _value.stockoutDate
          : stockoutDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MedicationDetailStateImpl implements _MedicationDetailState {
  const _$MedicationDetailStateImpl(
      {required this.medication,
      required final List<Schedule> linkedSchedules,
      required this.stockLevel,
      required this.expiryWarning,
      this.daysRemaining,
      this.stockoutDate,
      this.isLoading = false,
      this.error})
      : _linkedSchedules = linkedSchedules;

  @override
  final Medication medication;
  final List<Schedule> _linkedSchedules;
  @override
  List<Schedule> get linkedSchedules {
    if (_linkedSchedules is EqualUnmodifiableListView) return _linkedSchedules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_linkedSchedules);
  }

  @override
  final StockLevel stockLevel;
  @override
  final ExpiryWarningLevel expiryWarning;
  @override
  final double? daysRemaining;
  @override
  final DateTime? stockoutDate;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'MedicationDetailState(medication: $medication, linkedSchedules: $linkedSchedules, stockLevel: $stockLevel, expiryWarning: $expiryWarning, daysRemaining: $daysRemaining, stockoutDate: $stockoutDate, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MedicationDetailStateImpl &&
            (identical(other.medication, medication) ||
                other.medication == medication) &&
            const DeepCollectionEquality()
                .equals(other._linkedSchedules, _linkedSchedules) &&
            (identical(other.stockLevel, stockLevel) ||
                other.stockLevel == stockLevel) &&
            (identical(other.expiryWarning, expiryWarning) ||
                other.expiryWarning == expiryWarning) &&
            (identical(other.daysRemaining, daysRemaining) ||
                other.daysRemaining == daysRemaining) &&
            (identical(other.stockoutDate, stockoutDate) ||
                other.stockoutDate == stockoutDate) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      medication,
      const DeepCollectionEquality().hash(_linkedSchedules),
      stockLevel,
      expiryWarning,
      daysRemaining,
      stockoutDate,
      isLoading,
      error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MedicationDetailStateImplCopyWith<_$MedicationDetailStateImpl>
      get copyWith => __$$MedicationDetailStateImplCopyWithImpl<
          _$MedicationDetailStateImpl>(this, _$identity);
}

abstract class _MedicationDetailState implements MedicationDetailState {
  const factory _MedicationDetailState(
      {required final Medication medication,
      required final List<Schedule> linkedSchedules,
      required final StockLevel stockLevel,
      required final ExpiryWarningLevel expiryWarning,
      final double? daysRemaining,
      final DateTime? stockoutDate,
      final bool isLoading,
      final String? error}) = _$MedicationDetailStateImpl;

  @override
  Medication get medication;
  @override
  List<Schedule> get linkedSchedules;
  @override
  StockLevel get stockLevel;
  @override
  ExpiryWarningLevel get expiryWarning;
  @override
  double? get daysRemaining;
  @override
  DateTime? get stockoutDate;
  @override
  bool get isLoading;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$MedicationDetailStateImplCopyWith<_$MedicationDetailStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
