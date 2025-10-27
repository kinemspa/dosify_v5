import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// Storage section specifically for MDV medications with separate
/// active vial and backup stock vial storage fields.
class MdvStorageSection extends StatelessWidget {
  final TextEditingController activeLocationController;
  final String? activeStorageCondition;
  final ValueChanged<String?> onActiveStorageConditionChanged;

  final TextEditingController backupLocationController;
  final String? backupStorageCondition;
  final ValueChanged<String?> onBackupStorageConditionChanged;

  const MdvStorageSection({
    super.key,
    required this.activeLocationController,
    required this.activeStorageCondition,
    required this.onActiveStorageConditionChanged,
    required this.backupLocationController,
    required this.backupStorageCondition,
    required this.onBackupStorageConditionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active/Reconstituted Vial Storage
        Text(
          'Active Vial Storage',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: kSectionSpacing),

        // Active Location
        LabelFieldRow(
          label: 'Location',
          field: Field36(
            child: TextField(
              controller: activeLocationController,
              decoration: buildFieldDecoration(
                context,
                hint: 'e.g., Fridge shelf 2',
              ),
            ),
          ),
        ),
        const SizedBox(height: kFieldSpacing),

        // Active Storage Condition
        LabelFieldRow(
          label: 'Storage',
          field: Field36(
            child: DropdownButtonFormField<String>(
              value: activeStorageCondition,
              decoration: buildFieldDecoration(
                context,
                hint: 'Select condition',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'room_temp',
                  child: Text('Room Temperature'),
                ),
                DropdownMenuItem(
                  value: 'refrigerated',
                  child: Text('Refrigerated (2-8°C)'),
                ),
                DropdownMenuItem(value: 'frozen', child: Text('Frozen')),
                DropdownMenuItem(
                  value: 'protect_light',
                  child: Text('Protect from Light'),
                ),
              ],
              onChanged: onActiveStorageConditionChanged,
            ),
          ),
        ),

        const SizedBox(height: kSectionSpacing * 1.5),

        // Backup Stock Vials Storage
        Text(
          'Backup Stock Storage',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: kSectionSpacing),

        // Backup Location
        LabelFieldRow(
          label: 'Location',
          field: Field36(
            child: TextField(
              controller: backupLocationController,
              decoration: buildFieldDecoration(
                context,
                hint: 'e.g., Medicine cabinet',
              ),
            ),
          ),
        ),
        const SizedBox(height: kFieldSpacing),

        // Backup Storage Condition
        LabelFieldRow(
          label: 'Storage',
          field: Field36(
            child: DropdownButtonFormField<String>(
              value: backupStorageCondition,
              decoration: buildFieldDecoration(
                context,
                hint: 'Select condition',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'room_temp',
                  child: Text('Room Temperature'),
                ),
                DropdownMenuItem(
                  value: 'refrigerated',
                  child: Text('Refrigerated (2-8°C)'),
                ),
                DropdownMenuItem(value: 'frozen', child: Text('Frozen')),
                DropdownMenuItem(
                  value: 'protect_light',
                  child: Text('Protect from Light'),
                ),
              ],
              onChanged: onBackupStorageConditionChanged,
            ),
          ),
        ),
      ],
    );
  }
}
