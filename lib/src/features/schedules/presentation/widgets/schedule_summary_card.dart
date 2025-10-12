import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// Custom summary card for schedule screen with prominent dose display
class ScheduleSummaryCard extends StatelessWidget {
  const ScheduleSummaryCard({
    super.key,
    this.medication,
    this.scheduleDescription,
    this.showInfoOnly = false,
  });

  final Medication? medication;
  final String? scheduleDescription;
  final bool showInfoOnly;

  String _fmt2(double? v) {
    if (v == null) return '-';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  IconData _getMedicationIcon(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return Icons.medication;
      case MedicationForm.capsule:
        return MdiIcons.pill;
      case MedicationForm.injectionPreFilledSyringe:
        return Icons.colorize;
      case MedicationForm.injectionSingleDoseVial:
        return Icons.local_drink;
      case MedicationForm.injectionMultiDoseVial:
        return Icons.addchart;
    }
  }

  String _getUnitLabel(Unit u) {
    switch (u) {
      case Unit.mcg:
      case Unit.mcgPerMl:
        return 'mcg';
      case Unit.mg:
      case Unit.mgPerMl:
        return 'mg';
      case Unit.g:
      case Unit.gPerMl:
        return 'g';
      case Unit.units:
      case Unit.unitsPerMl:
        return 'units';
    }
  }

  String _getStockUnitLabel(Medication m) {
    switch (m.form) {
      case MedicationForm.tablet:
        return 'tablets';
      case MedicationForm.capsule:
        return 'capsules';
      case MedicationForm.injectionPreFilledSyringe:
        return 'syringes';
      case MedicationForm.injectionSingleDoseVial:
      case MedicationForm.injectionMultiDoseVial:
        return 'vials';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fg = cs.onPrimary;

    // Info-only mode (when no medication selected)
    if (showInfoOnly || medication == null) {
      return Container(
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.calendar_today, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Select a medication to schedule',
                    style: theme.textTheme.bodySmall?.copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final med = medication!;
    final unitLabel = _getUnitLabel(med.strengthUnit);
    final stockLabel = _getStockUnitLabel(med);

    // Resolve expiry text
    String? expDisplay;
    if (med.expiry != null) {
      expDisplay = MaterialLocalizations.of(context).formatCompactDate(med.expiry!);
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Icon + Med Name + Expiry
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getMedicationIcon(med.form),
                  color: fg,
                ),
              ),
              const SizedBox(width: 12),
              // Med Name + Manufacturer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    if (med.manufacturer != null && med.manufacturer!.isNotEmpty) ...{
                      const SizedBox(height: 2),
                      Text(
                        med.manufacturer!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: fg.withValues(alpha: 0.9),
                        ),
                      ),
                    },
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right side: Expiry, Strength, Stock
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Expiry
                  if (expDisplay != null && expDisplay.isNotEmpty)
                    Text(
                      'Exp: $expDisplay',
                      style: theme.textTheme.bodySmall?.copyWith(color: fg),
                    ),
                  const SizedBox(height: 4),
                  // Strength
                  Text(
                    '${_fmt2(med.strengthValue)} $unitLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fg.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Remaining tablets/stock
                  Text(
                    '${_fmt2(med.stockValue)} $stockLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fg.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Bottom row: Storage icons
          if (med.requiresRefrigeration ||
              (med.storageInstructions?.toLowerCase().contains('light') ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 48),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (med.requiresRefrigeration) ...[
                    Icon(Icons.kitchen, size: 18, color: fg),
                    const SizedBox(width: 6),
                  ],
                  if (med.storageInstructions?.toLowerCase().contains('light') ?? false)
                    Icon(Icons.dark_mode, size: 18, color: fg),
                ],
              ),
            ),
          // Dose description with prominent styling
          if (scheduleDescription != null && scheduleDescription!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildStyledDescription(context, scheduleDescription!, fg),
            ),
        ],
      ),
    );
  }

  /// Builds the schedule description with prominent styling for dose keywords
  Widget _buildStyledDescription(BuildContext context, String description, Color fg) {
    final theme = Theme.of(context);
    
    // Parse the description to style specific parts
    // Format: "Take {dose} {MedName} {MedType} {frequency} at {times}. Dose is {dose} {unit} is {strength}."
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\d+\.?\d*)\s*(tablet|tablets|capsule|capsules|syringe|syringes|vial|vials|mg|mcg|g|IU|units|ml)', caseSensitive: false);
    
    int lastMatchEnd = 0;
    for (final match in regex.allMatches(description)) {
      // Add text before match (normal style)
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: description.substring(lastMatchEnd, match.start),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: fg.withValues(alpha: 0.9),
          ),
        ));
      }
      
      // Add the number (prominent style)
      spans.add(TextSpan(
        text: match.group(1),
        style: theme.textTheme.titleMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ));
      
      // Add the unit (semi-prominent style)
      if (match.group(2) != null) {
        spans.add(TextSpan(
          text: ' ${match.group(2)}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
          ),
        ));
      }
      
      lastMatchEnd = match.end;
    }
    
    // Add remaining text
    if (lastMatchEnd < description.length) {
      spans.add(TextSpan(
        text: description.substring(lastMatchEnd),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: fg.withValues(alpha: 0.9),
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
