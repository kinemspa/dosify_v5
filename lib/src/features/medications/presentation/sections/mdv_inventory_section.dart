// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// MDV-specific inventory section split into Active Vial and Backup Stock
class MdvInventorySection extends StatelessWidget {
  const MdvInventorySection({
    required this.activeVialLowStockMlController,
    required this.activeVialLowStockEnabled,
    required this.onActiveVialLowStockChanged,
    required this.backupStockController,
    required this.backupLowStockEnabled,
    required this.onBackupLowStockChanged,
    required this.backupLowStockController,
    required this.activeVialExpiry,
    required this.onActiveVialExpiryPressed,
    required this.backupVialsExpiry,
    required this.onBackupVialsExpiryPressed,
    this.onActiveVialLowStockDec,
    this.onActiveVialLowStockInc,
    this.onBackupStockDec,
    this.onBackupStockInc,
    this.onBackupLowStockDec,
    this.onBackupLowStockInc,
    super.key,
  });

  final TextEditingController activeVialLowStockMlController;
  final bool activeVialLowStockEnabled;
  final ValueChanged<bool> onActiveVialLowStockChanged;
  final VoidCallback? onActiveVialLowStockDec;
  final VoidCallback? onActiveVialLowStockInc;
  
  final TextEditingController backupStockController;
  final bool backupLowStockEnabled;
  final ValueChanged<bool> onBackupLowStockChanged;
  final TextEditingController backupLowStockController;
  final VoidCallback? onBackupStockDec;
  final VoidCallback? onBackupStockInc;
  final VoidCallback? onBackupLowStockDec;
  final VoidCallback? onBackupLowStockInc;

  final DateTime? activeVialExpiry;
  final VoidCallback onActiveVialExpiryPressed;
  final DateTime? backupVialsExpiry;
  final VoidCallback onBackupVialsExpiryPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionFormCard(
      title: 'Inventory',
      neutral: true,
      children: [
        // Active Vial subsection header
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
          child: Text(
            'Active/Reconstituted Vial',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // Active vial low stock alert
        LabelFieldRow(
          label: 'Low stock alert (mL)',
          field: Row(
            children: [
              Checkbox(
                value: activeVialLowStockEnabled,
                onChanged: (v) => onActiveVialLowStockChanged(v ?? false),
              ),
              if (activeVialLowStockEnabled)
                Expanded(
                  child: StepperRow36(
                    controller: activeVialLowStockMlController,
                    onDec:
                        onActiveVialLowStockDec ??
                        () {
                          final v =
                              double.tryParse(
                                activeVialLowStockMlController.text.trim(),
                              ) ??
                              0.0;
                          activeVialLowStockMlController.text = (v - 0.5)
                              .clamp(0.0, 999.0)
                              .toStringAsFixed(1);
                        },
                    onInc:
                        onActiveVialLowStockInc ??
                        () {
                          final v =
                              double.tryParse(
                                activeVialLowStockMlController.text.trim(),
                              ) ??
                              0.0;
                          activeVialLowStockMlController.text = (v + 0.5)
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
          ),
        ),
        _support(
          context,
          'Alert when active vial volume drops below this threshold',
        ),

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
        _support(
          context,
          'Reconstituted vial expiry (typically 48 hours after mixing)',
        ),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        // Backup Stock subsection header
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
          child: Text(
            'Backup Stock Vials',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // Backup stock quantity
        LabelFieldRow(
          label: 'Stock quantity *',
          field: StepperRow36(
            controller: backupStockController,
            onDec:
                onBackupStockDec ??
                () {
                  final v =
                      int.tryParse(backupStockController.text.trim()) ?? 0;
                  backupStockController.text = (v - 1)
                      .clamp(0, 1000000)
                      .toString();
                },
            onInc:
                onBackupStockInc ??
                () {
                  final v =
                      int.tryParse(backupStockController.text.trim()) ?? 0;
                  backupStockController.text = (v + 1)
                      .clamp(0, 1000000)
                      .toString();
                },
            decoration: buildCompactFieldDecoration(
              context: context,
              hint: '0',
            ),
          ),
        ),
        _support(context, 'Number of unreconstituted sealed vials in storage'),

        // Backup stock low alert
        LabelFieldRow(
          label: 'Low stock alert',
          field: Row(
            children: [
              Checkbox(
                value: backupLowStockEnabled,
                onChanged: (v) => onBackupLowStockChanged(v ?? false),
              ),
              Expanded(
                child: Text(
                  'Enable alert when stock is low',
                  style: checkboxLabelStyle(context),
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        if (backupLowStockEnabled)
          LabelFieldRow(
            label: 'Threshold',
            field: StepperRow36(
              controller: backupLowStockController,
              onDec:
                  onBackupLowStockDec ??
                  () {
                    final v =
                        int.tryParse(backupLowStockController.text.trim()) ?? 0;
                    backupLowStockController.text = (v - 1)
                        .clamp(0, 1000000)
                        .toString();
                  },
              onInc:
                  onBackupLowStockInc ??
                  () {
                    final v =
                        int.tryParse(backupLowStockController.text.trim()) ?? 0;
                    backupLowStockController.text = (v + 1)
                        .clamp(0, 1000000)
                        .toString();
                  },
              decoration: buildCompactFieldDecoration(
                context: context,
                hint: '0',
              ),
              compact: true,
            ),
          ),
        if (backupLowStockEnabled)
          _support(context, 'Alert when backup stock drops below this count'),

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
        _support(
          context,
          'Sealed backup vials expiry (typically months/years)',
        ),
      ],
    );
  }

  Widget _support(BuildContext context, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(
        left: kLabelColWidth + 8,
        top: 2,
        bottom: 6,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
