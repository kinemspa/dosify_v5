// Package imports:
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/core/hive/hive_encryption_key_service.dart';
import 'package:dosifi_v5/src/core/hive/hive_migration_manager.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/saved_reconstitution_calculation.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_status_change_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/supplies/domain/stock_movement.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';

class HiveBootstrap {
  // All box names in dependency order.
  static const _allBoxNames = [
    'medications',
    'schedules',
    'dose_logs',
    'dose_status_change_logs',
    'supplies',
    'stock_movements',
    'inventory_logs',
    'saved_reconstitutions',
  ];

  static Future<void> init() async {
    print('HiveBootstrap: initFlutter...');
    await Hive.initFlutter();

    // Register every adapter upfront so the encryption migration can read
    // typed objects from unencrypted boxes before rewriting them encrypted.
    _registerAdapters();

    // Obtain (or generate) the AES-256 key from Android Keystore.
    print('HiveBootstrap: Loading encryption key...');
    final cipher = await HiveEncryptionKeyService.initialize();

    // One-time migration: convert pre-existing unencrypted boxes → encrypted.
    await _migrateToEncryptedIfNeeded(cipher);

    // Open medications first so HiveMigrationManager can use the open box.
    await _openBoxWithRetry<Medication>('medications', cipher: cipher);

    // Run schema migrations if needed.
    print('HiveBootstrap: Running migrations...');
    await HiveMigrationManager.migrate();

    // Validate migration was successful.
    final isValid = await HiveMigrationManager.validateMigration();
    if (!isValid) {
      print('WARNING: Hive migration validation failed');
    }

    await _openBoxWithRetry<Schedule>('schedules', cipher: cipher);
    await _openBoxWithRetry<DoseLog>('dose_logs', cipher: cipher);
    await _openBoxWithRetry<DoseStatusChangeLog>(
      'dose_status_change_logs',
      cipher: cipher,
    );
    await _openBoxWithRetry<Supply>('supplies', cipher: cipher);
    await _openBoxWithRetry<StockMovement>('stock_movements', cipher: cipher);
    await _openBoxWithRetry<InventoryLog>('inventory_logs', cipher: cipher);
    await _openBoxWithRetry<SavedReconstitutionCalculation>(
      'saved_reconstitutions',
      cipher: cipher,
    );

    print('HiveBootstrap: Initialization complete');
  }

  /// One-time migration: reads every box unencrypted, deletes it from disk,
  /// then rewrites it encrypted. Guarded by a SharedPreferences flag so it
  /// only runs on the first launch after this update.
  static Future<void> _migrateToEncryptedIfNeeded(
    HiveAesCipher cipher,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('hive_encryption_migrated_v1') == true) return;

    print('HiveBootstrap: Migrating boxes to encrypted storage...');

    for (final boxName in _allBoxNames) {
      try {
        // Open unencrypted to read existing data.
        final plain = await Hive.openBox<dynamic>(boxName);
        final data = plain.toMap();
        await plain.close();
        await Hive.deleteBoxFromDisk(boxName);

        // Rewrite encrypted.
        final encrypted = await Hive.openBox<dynamic>(
          boxName,
          encryptionCipher: cipher,
        );
        if (data.isNotEmpty) {
          await encrypted.putAll(data);
        }
        await encrypted.close();

        print('HiveBootstrap: Encrypted "$boxName" (${data.length} entries)');
      } catch (e) {
        print(
          'HiveBootstrap: WARN: Could not encrypt box "$boxName": $e. Skipping.',
        );
      }
    }

    await prefs.setBool('hive_encryption_migrated_v1', true);
    print('HiveBootstrap: Encryption migration complete');
  }

  static Future<Box<T>> _openBoxWithRetry<T>(
    String name, {
    required HiveAesCipher cipher,
  }) async {
    try {
      print('HiveBootstrap: Opening box "$name"...');
      return await Hive.openBox<T>(name, encryptionCipher: cipher).timeout(
        const Duration(seconds: 15),
      );
    } catch (e) {
      print('HiveBootstrap: Failed to open box "$name" (Error: $e).');

      // Only delete and recreate on actual corruption errors (HiveError).
      // Do NOT delete on timeouts or other transient errors — that causes data loss!
      if (e is HiveError) {
        print(
          'HiveBootstrap: Detected HiveError (corruption). Attempting recovery by deleting box...',
        );
        try {
          await Hive.deleteBoxFromDisk(name);
          print(
            'HiveBootstrap: Deleted corrupted box "$name". Retrying open...',
          );
          return await Hive.openBox<T>(name, encryptionCipher: cipher);
        } catch (e2) {
          print(
            'HiveBootstrap: CRITICAL ERROR: Could not recover box "$name": $e2',
          );
          rethrow;
        }
      } else {
        // For timeouts and other errors, retry without deleting.
        print('HiveBootstrap: Retrying open without deletion...');
        try {
          return await Hive.openBox<T>(name, encryptionCipher: cipher);
        } catch (e2) {
          print(
            'HiveBootstrap: CRITICAL ERROR: Could not open box "$name": $e2',
          );
          rethrow;
        }
      }
    }
  }

  static void _registerAdapters() {
    // Core medication enums + model
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UnitAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(StockUnitAdapter());
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(MedicationFormAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(VolumeUnitAdapter());
    if (!Hive.isAdapterRegistered(10))
      Hive.registerAdapter(MedicationAdapter());

    // Schedules + dose logging
    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(ScheduleAdapter());
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(DoseLogAdapter());
    if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(DoseActionAdapter());
    if (!Hive.isAdapterRegistered(45))
      Hive.registerAdapter(DoseStatusChangeLogAdapter());

    // Supplies + stock
    if (!Hive.isAdapterRegistered(50)) Hive.registerAdapter(SupplyAdapter());
    if (!Hive.isAdapterRegistered(51))
      Hive.registerAdapter(StockMovementAdapter());
    if (!Hive.isAdapterRegistered(52))
      Hive.registerAdapter(SupplyTypeAdapter());
    if (!Hive.isAdapterRegistered(53))
      Hive.registerAdapter(SupplyUnitAdapter());
    if (!Hive.isAdapterRegistered(54))
      Hive.registerAdapter(MovementReasonAdapter());

    // Inventory logs
    if (!Hive.isAdapterRegistered(43))
      Hive.registerAdapter(InventoryLogAdapter());
    if (!Hive.isAdapterRegistered(44))
      Hive.registerAdapter(InventoryChangeTypeAdapter());

    // Saved reconstitution calculations
    if (!Hive.isAdapterRegistered(60))
      Hive.registerAdapter(SavedReconstitutionCalculationAdapter());
  }
}
