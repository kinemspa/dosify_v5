import 'package:hive_flutter/hive_flutter.dart';

import 'package:dosifi_v5/src/core/notifications/expiry_notification_settings.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

class ExpiryNotificationScheduler {
  const ExpiryNotificationScheduler._();

  static const String _typePrimary = 'primary';
  static const String _typeActiveVial = 'active_vial';
  static const String _typeSealedVials = 'sealed_vials';

  static int _idFor(String medicationId, String type) {
    return NotificationService.stableIdForKey('expiry|$type|$medicationId');
  }

  static Future<void> rescheduleAll() async {
    final box = Hive.box<Medication>('medications');
    for (final med in box.values) {
      await rescheduleForMedication(med);
    }
  }

  static Future<void> cancelForMedicationId(String medicationId) async {
    await _cancelByType(medicationId, _typePrimary);
    await _cancelByType(medicationId, _typeActiveVial);
    await _cancelByType(medicationId, _typeSealedVials);
  }

  static Future<void> rescheduleForMedication(Medication med) async {
    // Cancel first so edits (or disabling expiry) remove old reminders.
    await cancelForMedicationId(med.id);

    final leadDays = ExpiryNotificationSettings.value.value.leadDays;

    await _scheduleIfEligible(
      medicationId: med.id,
      type: _typePrimary,
      medicationName: med.name,
      label: 'Expiry',
      expiry: med.expiry,
      leadDays: leadDays,
    );

    await _scheduleIfEligible(
      medicationId: med.id,
      type: _typeActiveVial,
      medicationName: med.name,
      label: 'Active vial expiry',
      expiry: med.reconstitutedVialExpiry,
      leadDays: leadDays,
    );

    await _scheduleIfEligible(
      medicationId: med.id,
      type: _typeSealedVials,
      medicationName: med.name,
      label: 'Sealed vials expiry',
      expiry: med.backupVialsExpiry,
      leadDays: leadDays,
    );
  }

  static Future<void> _cancelByType(String medicationId, String type) async {
    final id = _idFor(medicationId, type);
    try {
      await NotificationService.cancel(id);
    } catch (_) {
      // Best-effort.
    }
  }

  static Future<void> _scheduleIfEligible({
    required String medicationId,
    required String type,
    required String medicationName,
    required String label,
    required DateTime? expiry,
    required int leadDays,
  }) async {
    if (expiry == null) return;

    final fireAt = expiry.subtract(Duration(days: leadDays));
    if (!fireAt.isAfter(DateTime.now())) return;

    final id = _idFor(medicationId, type);
    final title = 'Expiring soon';
    final body = '$medicationName | $label in $leadDays days';

    try {
      await NotificationService.scheduleAtAlarmClockUtc(
        id,
        fireAt.toUtc(),
        title: title,
        body: body,
        channelId: 'expiry',
      );
    } catch (_) {
      // Best-effort.
    }
  }
}
