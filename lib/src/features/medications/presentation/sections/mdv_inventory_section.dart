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
    super.key,
  });

  final TextEditingController activeVialLowStockMlController;
  final bool activeVialLowStockEnabled;
  final Function(bool) onActiveVialLowStockChanged;
  
  final TextEditingController backupStockController;
  final bool backupLowStockEnabled;
  final Function(bool) onBackupLowStockChanged;
  final TextEditingController backupLowStockController;
  
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
                : MaterialLocalizations.of(context).formatCompactDate(activeVialExpiry!),
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
            decoration: buildCompactFieldDecoration(context: context, hint: '0'),
          ),
        ),
        _support(
          context,
          'Number of unreconstituted sealed vials in storage',
        ),
        
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
                  style: kCheckboxLabelStyle(context),
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
              decoration: buildCompactFieldDecoration(
                context: context,
                hint: '0',
              ),
              compact: true,
            ),
          ),
        if (backupLowStockEnabled)
          _support(
            context,
            'Alert when backup stock drops below this count',
          ),
        
        // Backup vials expiry
        LabelFieldRow(
          label: 'Expiry date',
          field: DateButton36(
            label: backupVialsExpiry == null
                ? 'Select date'
                : MaterialLocalizations.of(context).formatCompactDate(backupVialsExpiry!),
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
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
