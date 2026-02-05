import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/medication_stock_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/expiry_tracking_service.dart';
import 'package:dosifi_v5/src/features/medications/data/medication_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

part 'medication_detail_controller.freezed.dart';

@freezed
class MedicationDetailState with _$MedicationDetailState {
  const factory MedicationDetailState({
    required Medication medication,
    required List<Schedule> linkedSchedules,
    required StockLevel stockLevel,
    required ExpiryWarningLevel expiryWarning,
    double? daysRemaining,
    DateTime? stockoutDate,
    @Default(false) bool isLoading,
    String? error,
  }) = _MedicationDetailState;
}

/// Controller for medication detail page
/// Manages medication state and coordinates business logic
class MedicationDetailController
    extends AutoDisposeFamilyNotifier<MedicationDetailState?, String> {
  late MedicationRepository _repository;

  @override
  MedicationDetailState? build(String medicationId) {
    // Initialize repository
    final box = Hive.box<Medication>('medications');
    _repository = MedicationRepository(box);

    // Get initial medication
    final med = _repository.get(medicationId);
    if (med == null) return null;

    // Calculate initial state
    return _calculateState(med);
  }

  /// Calculate state from medication
  MedicationDetailState _calculateState(Medication med) {
    final linkedSchedules = _repository.getLinkedSchedules(med.id);
    final stockLevel = MedicationStockService.getStockLevel(med);
    final expiryWarning = ExpiryTrackingService.getWarningLevel(med.expiry);
    final daysRemaining =
        MedicationStockService.calculateDaysRemaining(med, linkedSchedules);
    final stockoutDate =
        MedicationStockService.calculateStockoutDate(med, linkedSchedules);

    return MedicationDetailState(
      medication: med,
      linkedSchedules: linkedSchedules,
      stockLevel: stockLevel,
      expiryWarning: expiryWarning,
      daysRemaining: daysRemaining,
      stockoutDate: stockoutDate,
    );
  }

  /// Refresh state (e.g., after external changes)
  void refresh() {
    final med = _repository.get(arg);
    if (med == null) {
      state = null;
      return;
    }
    state = _calculateState(med);
  }

  /// Update stock value
  Future<void> updateStock(double newValue) async {
    if (state == null) return;

    state = state!.copyWith(isLoading: true, error: null);

    try {
      await _repository.updateStock(arg, newValue);
      refresh();
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: 'Failed to update stock: $e',
      );
    }
  }

  /// Increment stock
  Future<void> incrementStock(double amount) async {
    if (state == null) return;

    state = state!.copyWith(isLoading: true, error: null);

    try {
      await _repository.incrementStock(arg, amount);
      refresh();
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: 'Failed to increment stock: $e',
      );
    }
  }

  /// Decrement stock
  Future<void> decrementStock(double amount) async {
    if (state == null) return;

    state = state!.copyWith(isLoading: true, error: null);

    try {
      await _repository.decrementStock(arg, amount);
      refresh();
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: 'Failed to decrement stock: $e',
      );
    }
  }

  /// Update expiry date
  Future<void> updateExpiry(DateTime? newExpiry) async {
    if (state == null) return;

    state = state!.copyWith(isLoading: true, error: null);

    try {
      await _repository.updateExpiry(arg, newExpiry);
      refresh();
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: 'Failed to update expiry: $e',
      );
    }
  }

  /// Update storage location
  Future<void> updateStorageLocation(String? location) async {
    if (state == null) return;

    state = state!.copyWith(isLoading: true, error: null);

    try {
      await _repository.updateStorageLocation(arg, location);
      refresh();
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: 'Failed to update storage location: $e',
      );
    }
  }

  /// Update medication (full update)
  Future<void> updateMedication(Medication updated) async {
    if (state == null) return;

    state = state!.copyWith(isLoading: true, error: null);

    try {
      await _repository.upsert(updated);
      state = _calculateState(updated);
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: 'Failed to update medication: $e',
      );
    }
  }

  /// Delete medication
  Future<bool> deleteMedication() async {
    if (state == null) return false;

    state = state!.copyWith(isLoading: true, error: null);

    try {
      await _repository.delete(arg);
      state = null;
      return true;
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: 'Failed to delete medication: $e',
      );
      return false;
    }
  }
}

/// Provider for medication detail controller
final medicationDetailControllerProvider = AutoDisposeNotifierProviderFamily<
    MedicationDetailController,
    MedicationDetailState?,
    String>(MedicationDetailController.new);
