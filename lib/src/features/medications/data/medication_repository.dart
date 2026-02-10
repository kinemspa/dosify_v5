// Package imports:
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/core/notifications/expiry_notification_scheduler.dart';

/// Repository for medication data access
/// Abstracts Hive database operations for better testability and maintainability
class MedicationRepository {
  MedicationRepository(this._box);

  final Box<Medication> _box;

  /// Get a medication by ID
  Medication? get(String id) => _box.get(id);

  /// Get all medications
  List<Medication> getAll() => _box.values.toList(growable: false);

  /// Save or update a medication
  Future<void> upsert(Medication med) async {
    if (kIsWeb) {
      await _box
          .put(med.id, med)
          .timeout(const Duration(seconds: 3));
    } else {
      await _box.put(med.id, med);
    }

    // Best-effort: keep expiry notifications in sync with edits.
    try {
      if (!kIsWeb) {
        await ExpiryNotificationScheduler.rescheduleForMedication(
          med,
        ).timeout(const Duration(seconds: 2));
      }
    } catch (_) {
      // Best-effort.
    }
  }

  /// Delete a medication
  Future<void> delete(String id) async {
    // IMPORTANT:
    // Deleting a medication must remove associated schedules and cancel their
    // notifications, while preserving historical data like dose logs.
    final scheduleBox = Hive.box<Schedule>('schedules');
    final linkedSchedules = scheduleBox.values
        .where((s) => s.medicationId == id)
        .toList(growable: false);

    for (final s in linkedSchedules) {
      // Best-effort cancellation; deletion should still proceed.
      try {
        await ScheduleScheduler.cancelFor(s.id, days: s.daysOfWeek);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to cancel notifications for schedule ${s.id}: $e');
        }
      }
      await scheduleBox.delete(s.id);
    }

    // Delete medication-owned saved reconstitutions.
    // Standalone saved recons are preserved (ownerMedicationId == null).
    try {
      await SavedReconstitutionRepository().deleteForMedication(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Failed to delete owned saved reconstitution for med $id: $e',
        );
      }
    }

    await _box.delete(id);

    // Best-effort: remove any scheduled expiry reminders for this medication.
    try {
      if (!kIsWeb) {
        await ExpiryNotificationScheduler.cancelForMedicationId(
          id,
        ).timeout(const Duration(seconds: 2));
      }
    } catch (_) {
      // Best-effort.
    }
  }

  /// Watch a medication for changes (returns Stream)
  Stream<Medication?> watch(String id) {
    return _box.watch(key: id).map((event) => event.value as Medication?);
  }

  /// Watch all medications for changes
  Stream<List<Medication>> watchAll() {
    return _box.watch().map((_) => _box.values.toList(growable: false));
  }

  /// Get linked schedules for a medication
  List<Schedule> getLinkedSchedules(String medicationId) {
    final scheduleBox = Hive.box<Schedule>('schedules');
    return scheduleBox.values
        .where((s) => s.medicationId == medicationId && s.active)
        .toList(growable: false);
  }

  /// Check if a medication exists
  bool exists(String id) => _box.containsKey(id);

  /// Get count of all medications
  int get count => _box.length;

  /// Get medications by form type
  List<Medication> getByForm(MedicationForm form) {
    return _box.values.where((m) => m.form == form).toList(growable: false);
  }

  /// Get medications that are low on stock (below 25%)
  List<Medication> getLowStock() {
    return _box.values
        .where((m) {
          final maxStock = m.initialStockValue ?? m.stockValue;
          if (maxStock <= 0) return false;
          return (m.stockValue / maxStock) < 0.25;
        })
        .toList(growable: false);
  }

  /// Get medications expiring soon (within 30 days)
  List<Medication> getExpiringSoon() {
    final now = DateTime.now();
    final threshold = now.add(const Duration(days: 30));

    return _box.values
        .where((m) {
          final expiry = m.expiry;
          return expiry != null &&
              expiry.isAfter(now) &&
              expiry.isBefore(threshold);
        })
        .toList(growable: false);
  }

  /// Get medications that are expired
  List<Medication> getExpired() {
    final now = DateTime.now();
    return _box.values
        .where((m) {
          final expiry = m.expiry;
          return expiry != null && expiry.isBefore(now);
        })
        .toList(growable: false);
  }

  /// Search medications by name
  List<Medication> searchByName(String query) {
    final lowerQuery = query.toLowerCase();
    return _box.values
        .where((m) => m.name.toLowerCase().contains(lowerQuery))
        .toList(growable: false);
  }

  /// Get medications stored in a specific location
  List<Medication> getByLocation(String location) {
    return _box.values
        .where(
          (m) => m.storageLocation?.toLowerCase() == location.toLowerCase(),
        )
        .toList(growable: false);
  }

  /// Update stock value for a medication
  Future<void> updateStock(String id, double newStockValue) async {
    final med = _box.get(id);
    if (med == null) return;
    await _box.put(id, med.copyWith(stockValue: newStockValue));
  }

  /// Update expiry date for a medication
  Future<void> updateExpiry(String id, DateTime? newExpiry) async {
    final med = _box.get(id);
    if (med == null) return;
    await _box.put(id, med.copyWith(expiry: newExpiry));
  }

  /// Update storage location
  Future<void> updateStorageLocation(String id, String? location) async {
    final med = _box.get(id);
    if (med == null) return;
    await _box.put(id, med.copyWith(storageLocation: location));
  }

  /// Increment stock by amount
  Future<void> incrementStock(String id, double amount) async {
    final med = _box.get(id);
    if (med == null) return;
    await updateStock(id, med.stockValue + amount);
  }

  /// Decrement stock by amount
  Future<void> decrementStock(String id, double amount) async {
    final med = _box.get(id);
    if (med == null) return;
    final newStock = (med.stockValue - amount).clamp(0.0, double.infinity);
    await updateStock(id, newStock);
  }

  /// Get listenable for reactive UI updates
  Listenable get listenable => _box.listenable();
}
