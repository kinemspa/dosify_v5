import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

/// Service for calculating medication stock levels and projections
class MedicationStockService {
  /// Calculate the stock fill ratio (0.0 to 1.0)
  static double calculateStockRatio(Medication med) {
    if (med.stockValue <= 0) return 0.0;
    final maxStock = med.initialStockValue ?? med.stockValue;
    if (maxStock <= 0) return 1.0;
    return (med.stockValue / maxStock).clamp(0.0, 1.0);
  }

  /// Check if medication is low on stock (below 25%)
  static bool isLowStock(Medication med) {
    return calculateStockRatio(med) < 0.25;
  }

  /// Check if medication is critically low (below 10%)
  static bool isCriticallyLow(Medication med) {
    return calculateStockRatio(med) < 0.10;
  }

  /// Calculate days remaining until stockout based on linked schedules
  /// Returns null if no schedules or unable to calculate
  static double? calculateDaysRemaining(
    Medication med,
    List<Schedule> linkedSchedules,
  ) {
    if (med.stockValue <= 0) return 0.0;
    if (linkedSchedules.isEmpty) return null;

    // Calculate total daily consumption from all active schedules
    double totalDailyConsumption = 0.0;

    for (final schedule in linkedSchedules) {
      if (!schedule.active) continue;

      // Get number of times per day
      final timesPerDay = schedule.timesOfDay?.length ?? 1;

      // Get dose value
      final doseValue = schedule.doseValue;

      // Calculate daily consumption for this schedule
      // For weekly schedules, divide by 7
      if (schedule.hasCycle && schedule.cycleEveryNDays != null) {
        // Cyclic schedule: every N days
        final cycleLength = schedule.cycleEveryNDays!;
        totalDailyConsumption += (doseValue * timesPerDay) / cycleLength;
      } else if (schedule.hasDaysOfMonth) {
        // Monthly schedule: specific days of month
        final daysPerMonth = schedule.daysOfMonth!.length;
        totalDailyConsumption += (doseValue * timesPerDay * daysPerMonth) / 30;
      } else {
        // Weekly schedule: specific days of week
        final daysPerWeek = schedule.daysOfWeek.length;
        totalDailyConsumption += (doseValue * timesPerDay * daysPerWeek) / 7;
      }
    }

    if (totalDailyConsumption <= 0) return null;

    return med.stockValue / totalDailyConsumption;
  }

  /// Calculate the projected stockout date
  /// Returns null if unable to calculate
  static DateTime? calculateStockoutDate(
    Medication med,
    List<Schedule> linkedSchedules,
  ) {
    final daysRemaining = calculateDaysRemaining(med, linkedSchedules);
    if (daysRemaining == null) return null;

    return DateTime.now().add(Duration(days: daysRemaining.ceil()));
  }

  /// Get stock status as a human-readable string
  static String getStockStatus(Medication med) {
    final ratio = calculateStockRatio(med);
    
    if (ratio <= 0) return 'Out of stock';
    if (ratio < 0.10) return 'Critically low';
    if (ratio < 0.25) return 'Low stock';
    if (ratio < 0.50) return 'Moderate';
    return 'Good';
  }

  /// Get stock color indicator based on level
  static StockLevel getStockLevel(Medication med) {
    final ratio = calculateStockRatio(med);
    
    if (ratio <= 0) return StockLevel.empty;
    if (ratio < 0.10) return StockLevel.critical;
    if (ratio < 0.25) return StockLevel.low;
    if (ratio < 0.50) return StockLevel.moderate;
    return StockLevel.good;
  }
}

/// Stock level enum for color coding
enum StockLevel {
  empty,
  critical,
  low,
  moderate,
  good,
}
