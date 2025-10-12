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
          // Storage icons removed per user request
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

  /// Builds the schedule description with prominent styling
  /// Format: "Take 1 Panadol tablet\nEvery Day\nat 9:00 AM\nDose equals 20mg"
  Widget _buildStyledDescription(BuildContext context, String description, Color fg) {
    final theme = Theme.of(context);
    
    // Parse the description to extract parts
    // Original format: "Take {dose} {MedName} {MedType} {frequency} at {times}. Dose is {dose} {unit} is {strength}."
    
    // Extract parts using regex
    final takeMatch = RegExp(r'Take (\d+\.?\d*)\s+(\S+)\s+(tablet|tablets|capsule|capsules|syringe|syringes|vial|vials)', caseSensitive: false).firstMatch(description);
    final frequencyMatch = RegExp(r'(Every [^at]+)', caseSensitive: false).firstMatch(description);
    final timeMatch = RegExp(r'at ([\d:,\s]+(?:AM|PM|am|pm)[^.]*)', caseSensitive: false).firstMatch(description);
    final doseMatch = RegExp(r'is (\d+\.?\d*)(mg|mcg|g|IU|units|ml)', caseSensitive: false).firstMatch(description);
    
    // Build formatted text
    final lines = <TextSpan>[];
    
    // Line 1: "Take 1 Panadol tablet"
    if (takeMatch != null) {
      lines.add(TextSpan(
        text: 'Take ',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: fg.withValues(alpha: 0.95),
          fontWeight: FontWeight.w500,
        ),
      ));
      lines.add(TextSpan(
        text: '${takeMatch.group(1)}',
        style: theme.textTheme.titleLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ));
      lines.add(TextSpan(
        text: ' ${takeMatch.group(2)} ',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: fg.withValues(alpha: 0.95),
          fontWeight: FontWeight.w500,
        ),
      ));
      lines.add(TextSpan(
        text: takeMatch.group(3) ?? '',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ));
    }
    
    // Line 2: "Every Day"
    if (frequencyMatch != null) {
      lines.add(TextSpan(
        text: '\n${frequencyMatch.group(1)?.trim()}',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: fg.withValues(alpha: 0.95),
          fontWeight: FontWeight.w500,
        ),
      ));
    }
    
    // Line 3: "at 9:00 AM"
    if (timeMatch != null) {
      lines.add(TextSpan(
        text: '\nat ${timeMatch.group(1)?.trim()}',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: fg.withValues(alpha: 0.95),
          fontWeight: FontWeight.w500,
        ),
      ));
    }
    
    // Line 4: "Dose equals 20mg"
    if (doseMatch != null) {
      lines.add(TextSpan(
        text: '\nDose equals ',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: fg.withValues(alpha: 0.95),
          fontWeight: FontWeight.w500,
        ),
      ));
      lines.add(TextSpan(
        text: '${doseMatch.group(1)}',
        style: theme.textTheme.titleLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ));
      lines.add(TextSpan(
        text: doseMatch.group(2) ?? '',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: lines),
    );
  }
}
