// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

/// Manages Hive database schema migrations to ensure backward compatibility
/// when adding new fields to existing models.
class HiveMigrationManager {
  static const String _versionKey = 'hive_schema_version';
  static const int _currentVersion = 2; // Increment when adding new fields

  /// Performs any necessary migrations when the app starts
  static Future<void> migrate() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_versionKey) ?? 1;

    if (storedVersion < _currentVersion) {
      debugPrint('Migrating Hive schema from v$storedVersion to v$_currentVersion');
      
      // Run migrations in sequence
      if (storedVersion < 2) {
        await _migrateV1ToV2();
      }
      
      // Add future migrations here
      // if (storedVersion < 3) {
      //   await _migrateV2ToV3();
      // }

      // Update stored version
      await prefs.setInt(_versionKey, _currentVersion);
      debugPrint('Migration completed successfully');
    }
  }

  /// Migration from v1 to v2: Add MDV active vial and backup stock fields
  static Future<void> _migrateV1ToV2() async {
    debugPrint('Running migration v1 → v2: Adding MDV tracking fields');
    
    try {
      // Box is already open from HiveBootstrap — use the sync accessor.
      final box = Hive.box<Medication>('medications');
      final medications = box.values.toList();
      
      debugPrint('Migrating ${medications.length} medications');
      
      // Iterate through all medications and update them
      // Since the new fields have default values (false for bools, null for others),
      // Hive will automatically apply these when reading old data
      for (var i = 0; i < medications.length; i++) {
        final med = medications[i];
        
        // Create a new Medication object with all fields, ensuring defaults are set
        final updatedMed = med.copyWith(
          // Explicitly set defaults for new fields to ensure they're persisted
          activeVialRequiresRefrigeration: false,
          activeVialRequiresFreezer: false,
          activeVialLightSensitive: false,
          backupVialsRequiresRefrigeration: false,
          backupVialsRequiresFreezer: false,
          backupVialsLightSensitive: false,
        );
        
        // Update in place using the same key
        await box.putAt(i, updatedMed);
      }
      
      debugPrint('Successfully migrated ${medications.length} medications');
    } catch (e) {
      debugPrint('Error during v1→v2 migration: $e');
      // Log error but don't throw - allow app to continue
      // The new TypeAdapter should handle missing fields gracefully
    }
  }

  /// Validates that the migration was successful
  static Future<bool> validateMigration() async {
    try {
      final box = Hive.box<Medication>('medications');
      final count = box.length;
      debugPrint('Validation: Found $count medications in database');
      
      // Try to read first medication to ensure deserialization works
      if (count > 0) {
        final firstMed = box.getAt(0);
        debugPrint('Validation: Successfully read first medication: ${firstMed?.name}');
      }
      
      return true;
    } catch (e) {
      debugPrint('Validation failed: $e');
      return false;
    }
  }
}
