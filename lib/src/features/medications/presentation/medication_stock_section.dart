// Backup/sealed-stock section extracted from medication_detail_page.dart (#166).
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_sealed_vials_editor_card.dart';
import 'package:dosifi_v5/src/widgets/status_pill.dart';

// ---------------------------------------------------------------------------
// Private helper functions
// ---------------------------------------------------------------------------

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

String _formatExpiry(DateTime date) {
  final now = DateTime.now();
  final diff = date.difference(now).inDays;
  final dateStr = DateFormat('d MMM y').format(date);
  if (diff < 0) return '$dateStr (Expired)';
  return '$dateStr ($diff days)';
}

bool _isExpiringSoon(DateTime expiry) =>
    expiry.isBefore(DateTime.now().add(const Duration(days: 30)));

Widget _buildMiniChip(BuildContext context, String label, {IconData? icon}) {
  final cs = Theme.of(context).colorScheme;
  return StatusPill(label: label, color: cs.primary, icon: icon, dense: true);
}

void _showBackupStockConditionsDialog(BuildContext context, Medication med) {
  bool fridge = med.backupVialsRequiresRefrigeration;
  bool freezer = med.backupVialsRequiresFreezer;
  bool light = med.backupVialsLightSensitive;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setState) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          titleTextStyle: cardTitleStyle(ctx)?.copyWith(color: cs.primary),
          contentTextStyle: bodyTextStyle(ctx),
          title: const Text('Sealed Vial Storage Conditions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('❄️ Requires Refrigeration'),
                value: fridge,
                onChanged: (v) => setState(() {
                  fridge = v ?? false;
                  if (fridge) freezer = false;
                }),
              ),
              CheckboxListTile(
                title: const Text('🧊 Requires Freezer'),
                value: freezer,
                onChanged: (v) => setState(() {
                  freezer = v ?? false;
                  if (freezer) fridge = false;
                }),
              ),
              CheckboxListTile(
                title: const Text('☀️ Light Sensitive'),
                value: light,
                onChanged: (v) => setState(() => light = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final box = Hive.box<Medication>('medications');
                box.put(
                  med.id,
                  med.copyWith(
                    backupVialsRequiresRefrigeration: fridge,
                    backupVialsRequiresFreezer: freezer,
                    backupVialsLightSensitive: light,
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildBackupStockConditionsRow(BuildContext context, Medication med) {
  final colorScheme = Theme.of(context).colorScheme;
  final conditions = <Widget>[];

  if (med.backupVialsRequiresRefrigeration) {
    conditions.add(_buildMiniChip(context, 'Fridge', icon: Icons.ac_unit));
  }
  if (med.backupVialsRequiresFreezer) {
    conditions.add(_buildMiniChip(context, 'Freeze', icon: Icons.severe_cold));
  }
  if (med.backupVialsLightSensitive) {
    conditions.add(
      _buildMiniChip(context, 'Light', icon: Icons.dark_mode_outlined),
    );
  }
  if (conditions.isEmpty) {
    conditions.add(
      _buildMiniChip(context, 'Room', icon: Icons.thermostat_outlined),
    );
  }

  return InkWell(
    onTap: () => _showBackupStockConditionsDialog(context, med),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingL,
        vertical: kSpacingS,
      ),
      child: Row(
        children: [
          SizedBox(
            width: kMedicationDetailInlineLabelWidth,
            child: Text(
              'Conditions',
              style: smallHelperTextStyle(
                context,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Wrap(spacing: kFieldSpacing, children: conditions),
          const Spacer(),
          Icon(
            Icons.chevron_right,
            size: kIconSizeSmall,
            color: colorScheme.onSurfaceVariant
                .withValues(alpha: kOpacityLow),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Sealed-vials / backup-stock section shown on the medication detail page.
///
/// Edit callbacks are forwarded from the parent state so that the parent can
/// use its own dialog helpers (which rely on `mounted`, `_showEditDialog`, etc).
class MedicationBackupStockSection extends StatelessWidget {
  const MedicationBackupStockSection({
    super.key,
    required this.med,
    required this.onEditBatch,
    required this.onEditLocation,
    required this.onEditExpiry,
  });

  final Medication med;
  final VoidCallback onEditBatch;
  final VoidCallback onEditLocation;
  final VoidCallback onEditExpiry;

  @override
  Widget build(BuildContext context) {
    return MedicationSealedVialsEditorCard(
      sealedVialsCountLabel:
          '${_formatNumber(med.stockValue).split('.')[0]} sealed vials',
      batchNumberValue: med.backupVialsBatchNumber ?? 'Not set',
      batchNumberIsPlaceholder: med.backupVialsBatchNumber == null,
      onEditBatchNumber: onEditBatch,
      expiryValue: med.backupVialsExpiry != null
          ? _formatExpiry(med.backupVialsExpiry!)
          : 'Not set',
      expiryIsPlaceholder: med.backupVialsExpiry == null,
      expiryIsWarning: med.backupVialsExpiry != null &&
          _isExpiringSoon(med.backupVialsExpiry!),
      onEditExpiry: onEditExpiry,
      locationValue: med.backupVialsStorageLocation ?? 'Not set',
      locationIsPlaceholder: med.backupVialsStorageLocation == null,
      onEditLocation: onEditLocation,
      conditionsRow: _buildBackupStockConditionsRow(context, med),
    );
  }
}
