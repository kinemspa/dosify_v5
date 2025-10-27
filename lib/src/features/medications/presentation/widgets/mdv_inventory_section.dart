import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// Inventory section specifically for MDV medications with separate
/// active vial and backup stock vials inventory fields.
class MdvInventorySection extends StatelessWidget {
  final TextEditingController activeVialLowStockMlController;
  final bool activeVialLowStockEnabled;
  final ValueChanged<bool> onActiveVialLowStockEnabledChanged;
  final DateTime? activeVialExpiry;
  final VoidCallback onActiveVialExpiryPressed;
  final String? activeVialExpiryHelp;
  final Color? activeVialExpiryHelpColor;

  final TextEditingController backupVialsStockController;
  final bool backupVialsLowStockEnabled;
  final ValueChanged<bool> onBackupVialsLowStockEnabledChanged;
  final TextEditingController backupVialsLowStockThresholdController;
  final DateTime? backupVialsExpiry;
  final VoidCallback onBackupVialsExpiryPressed;
  final String? backupVialsExpiryHelp;
  final VoidCallback? onBackupVialsStockDec;
  final VoidCallback? onBackupVialsStockInc;
  final VoidCallback? onBackupVialsLowStockDec;
  final VoidCallback? onBackupVialsLowStockInc;

  const MdvInventorySection({
    super.key,
    required this.activeVialLowStockMlController,
    required this.activeVialLowStockEnabled,
    required this.onActiveVialLowStockEnabledChanged,
    required this.activeVialExpiry,
    required this.onActiveVialExpiryPressed,
    this.activeVialExpiryHelp,
    this.activeVialExpiryHelpColor,
    required this.backupVialsStockController,
    required this.backupVialsLowStockEnabled,
    required this.onBackupVialsLowStockEnabledChanged,
    required this.backupVialsLowStockThresholdController,
    required this.backupVialsExpiry,
    required this.onBackupVialsExpiryPressed,
    this.backupVialsExpiryHelp,
    this.onBackupVialsStockDec,
    this.onBackupVialsStockInc,
    this.onBackupVialsLowStockDec,
    this.onBackupVialsLowStockInc,
  });

  @override
  Widget build(BuildContext context) {
    return SectionFormCard(
      title: 'Inventory',
      neutral: true,
      children: [
        // Active/Reconstituted Vial Section
        Text('Active Vial', style: sectionTitleStyle(context)),
        const SizedBox(height: kSectionSpacing),

        // Low stock alert for active vial (in mL)
        LabelFieldRow(
          label: 'Low volume alert',
          field: Row(
            children: [
              Checkbox(
                value: activeVialLowStockEnabled,
                onChanged: (v) =>
                    onActiveVialLowStockEnabledChanged(v ?? false),
              ),
              Expanded(
                child: Text(
                  'Alert when volume is low',
                  style: kCheckboxLabelStyle(context),
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),

        if (activeVialLowStockEnabled) ...[
          const SizedBox(height: kFieldSpacing),
          LabelFieldRow(
            label: 'Threshold (mL)',
            field: StepperRow36(
              controller: activeVialLowStockMlController,
              onDec: () {
                final v =
                    double.tryParse(
                      activeVialLowStockMlController.text.trim(),
                    ) ??
                    0.0;
                activeVialLowStockMlController.text = (v - 0.1)
                    .clamp(0.0, 999.0)
                    .toStringAsFixed(1);
              },
              onInc: () {
                final v =
                    double.tryParse(
                      activeVialLowStockMlController.text.trim(),
                    ) ??
                    0.0;
                activeVialLowStockMlController.text = (v + 0.1)
                    .clamp(0.0, 999.0)
                    .toStringAsFixed(1);
              },
              decoration: buildCompactFieldDecoration(
                context: context,
                hint: '0.0',
              ),
              compact: true,
            ),
          ),
        ],

        const SizedBox(height: kFieldSpacing),

        // Active vial expiry
        LabelFieldRow(
          label: 'Expiry date',
          field: DateButton36(
            label: activeVialExpiry == null
                ? 'Select date'
                : MaterialLocalizations.of(
                    context,
                  ).formatCompactDate(activeVialExpiry!),
            onPressed: onActiveVialExpiryPressed,
            width: kSmallControlWidth,
            selected: activeVialExpiry != null,
          ),
        ),
        if (activeVialExpiryHelp != null && activeVialExpiryHelp!.isNotEmpty)
          _buildHelperText(
            context,
            activeVialExpiryHelp!,
            activeVialExpiryHelpColor,
          ),

        const SizedBox(height: kSectionSpacing * 1.5),

        // Backup Stock Vials Section
        Text('Backup Stock', style: sectionTitleStyle(context)),
        const SizedBox(height: kSectionSpacing),

        // Backup vials stock quantity
        LabelFieldRow(
          label: 'Stock quantity *',
          field: StepperRow36(
            controller: backupVialsStockController,
            onDec: onBackupVialsStockDec ?? () {},
            onInc: onBackupVialsStockInc ?? () {},
            decoration: buildCompactFieldDecoration(
              context: context,
              hint: '0',
            ),
          ),
        ),
        _buildHelperText(
          context,
          'Track the number of sealed unopened vials in storage',
          null,
        ),

        const SizedBox(height: kFieldSpacing),

        // Low stock alert for backup vials
        LabelFieldRow(
          label: 'Low stock alert',
          field: Row(
            children: [
              Checkbox(
                value: backupVialsLowStockEnabled,
                onChanged: (v) =>
                    onBackupVialsLowStockEnabledChanged(v ?? false),
              ),
              Expanded(
                child: Text(
                  'Enable alert when stock is low',
                  style: kCheckboxLabelStyle(context),
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),

        if (backupVialsLowStockEnabled) ...[
          const SizedBox(height: kFieldSpacing),
          LabelFieldRow(
            label: 'Threshold',
            field: StepperRow36(
              controller: backupVialsLowStockThresholdController,
              onDec: onBackupVialsLowStockDec ?? () {},
              onInc: onBackupVialsLowStockInc ?? () {},
              decoration: buildCompactFieldDecoration(
                context: context,
                hint: '0',
              ),
              compact: true,
            ),
          ),
        ],

        if (backupVialsExpiryHelp != null && backupVialsExpiryHelp!.isNotEmpty)
          _buildHelperText(context, backupVialsExpiryHelp!, null),

        const SizedBox(height: kFieldSpacing),

        // Backup vials expiry
        LabelFieldRow(
          label: 'Expiry date',
          field: DateButton36(
            label: backupVialsExpiry == null
                ? 'Select date'
                : MaterialLocalizations.of(
                    context,
                  ).formatCompactDate(backupVialsExpiry!),
            onPressed: onBackupVialsExpiryPressed,
            width: kSmallControlWidth,
            selected: backupVialsExpiry != null,
          ),
        ),
        _buildHelperText(context, 'Sealed vials expiry date', null),
      ],
    );
  }

  Widget _buildHelperText(BuildContext context, String text, Color? color) {
    return buildHelperText(context, text, color: color);
  }
}
