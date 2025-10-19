// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

/// Custom summary card for schedule screen with prominent dose display
class ScheduleSummaryCard extends StatelessWidget {
  const ScheduleSummaryCard({
    super.key,
    this.medication,
    this.scheduleDescription,
    this.showInfoOnly = false,
    this.startDate,
    this.endDate,
  });

  final Medication? medication;
  final String? scheduleDescription;
  final bool showInfoOnly;
  final DateTime? startDate;
  final DateTime? endDate;

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
        decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
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
      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(12)),
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
                child: Icon(_getMedicationIcon(med.form), color: fg),
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
                    Text('Exp: $expDisplay', style: theme.textTheme.bodySmall?.copyWith(color: fg)),
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
                    '${_fmt2(med.stockValue)} $stockLabel remaining',
                    style: theme.textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ],
          ),
          // Divider between med info and instructions
          if (scheduleDescription != null && scheduleDescription!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(height: 1, thickness: 0.5, color: fg.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            _buildCompactInstructions(context, scheduleDescription!, fg),
          ],
        ],
      ),
    );
  }

  /// Builds 4-line instruction layout
  /// Line 1: Take X form
  /// Line 2: Frequency
  /// Line 3: At times
  /// Line 4: Dates with Total per Dose on right
  Widget _buildCompactInstructions(BuildContext context, String description, Color fg) {
    final theme = Theme.of(context);

    // Parse description to extract components
    // Format: "Take {dose} {MedName} {MedType} {frequency} at {times}. Dose is {dose} {unit} is {strength}."

    // Extract dose and form (tablet/capsule/etc)
    final doseFormMatch = RegExp(
      r'Take\s+(\d+\.?\d*)\s+\S+\s+(Tablets?|Capsules?|Pre-Filled Syringes?|Single Dose Vials?|Multi Dose Vials?)',
      caseSensitive: false,
    ).firstMatch(description);

    // Extract frequency (Everything between form and "at")
    final frequencyMatch = RegExp(
      r'(?:Tablets?|Capsules?|Pre-Filled Syringes?|Single Dose Vials?|Multi Dose Vials?)\s+(.+?)\s+at\s+',
      caseSensitive: false,
    ).firstMatch(description);

    // Extract times
    final timeMatch = RegExp(
      r'at\s+([\d:,\s]+(?:AM|PM|am|pm)(?:,\s*[\d:,\s]+(?:AM|PM|am|pm))*)',
      caseSensitive: false,
    ).firstMatch(description);

    // Extract total dose/strength (last occurrence of "is {number}{unit}")
    final strengthMatch = RegExp(
      r'is\s+(\d+\.?\d*)(mg|mcg|g|IU|units|ml)',
      caseSensitive: false,
    ).allMatches(description).lastOrNull;

    // Build line 1: "Take X form"
    String? line1;
    if (doseFormMatch != null) {
      final doseStr = doseFormMatch.group(1);
      final dose = double.tryParse(doseStr ?? '0') ?? 0;
      final form = doseFormMatch.group(2)?.toLowerCase() ?? '';

      // Convert decimal to fraction for common values
      final displayDose = _toFractional(dose);

      // Simplify and make singular/plural aware
      final simpleForm = _simplifyForm(form, dose);

      line1 = 'Take $displayDose $simpleForm';
    }

    // Build line 2: Frequency
    String? line2;
    if (frequencyMatch != null) {
      line2 = frequencyMatch.group(1)?.trim() ?? '';
    }

    // Build line 3: Times with "At" prefix
    String? line3;
    if (timeMatch != null) {
      final times = timeMatch.group(1)?.trim() ?? '';
      if (times.isNotEmpty) {
        // Format times with commas and "and" for last time
        final timeList = times.split(RegExp(r',\s*'));
        if (timeList.length > 1) {
          final lastTime = timeList.removeLast();
          line3 = 'At ${timeList.join(', ')} and $lastTime';
        } else {
          line3 = 'At $times';
        }
      }
    }

    // Build total dose text for line 4 right side
    String? totalDose;
    if (strengthMatch != null) {
      final amount = strengthMatch.group(1);
      final unit = strengthMatch.group(2);
      totalDose = 'Total per Dose: $amount$unit';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line 1: Take X form
        if (line1 != null)
          Text(
            line1,
            style: theme.textTheme.bodySmall?.copyWith(
              color: fg.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        // Line 2: Frequency
        if (line2 != null) ...[
          const SizedBox(height: 2),
          Text(
            line2,
            style: theme.textTheme.bodySmall?.copyWith(
              color: fg.withValues(alpha: 0.95),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
        // Line 3: At times
        if (line3 != null) ...[
          const SizedBox(height: 2),
          Text(
            line3,
            style: theme.textTheme.bodySmall?.copyWith(
              color: fg.withValues(alpha: 0.95),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
        // Line 4: Dates with total dose on right
        if (startDate != null || totalDose != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(child: _buildDatesLine(context, fg)),
              if (totalDose != null) ...[
                const SizedBox(width: 8),
                Text(
                  totalDose,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fg.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// Convert decimal dose to fractional display (0.25 -> 1/4, 0.5 -> 1/2, 0.75 -> 3/4)
  String _toFractional(double dose) {
    if (dose == dose.roundToDouble()) {
      return dose.toStringAsFixed(0);
    }

    // Check for common fractions
    if ((dose - 0.25).abs() < 0.01) return '¼'; // ¼
    if ((dose - 0.5).abs() < 0.01) return '½'; // ½
    if ((dose - 0.75).abs() < 0.01) return '¾'; // ¾
    if ((dose - 1.25).abs() < 0.01) return '1¼';
    if ((dose - 1.5).abs() < 0.01) return '1½';
    if ((dose - 1.75).abs() < 0.01) return '1¾';
    if ((dose - 2.25).abs() < 0.01) return '2¼';
    if ((dose - 2.5).abs() < 0.01) return '2½';
    if ((dose - 2.75).abs() < 0.01) return '2¾';

    // For other decimals, show as-is
    return dose.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// Simplify form name and make it singular/plural aware
  String _simplifyForm(String form, double dose) {
    final isPlural = dose > 1;

    // Normalize form string
    final lower = form.toLowerCase();

    if (lower.contains('tablet')) {
      return isPlural ? 'tablets' : 'tablet';
    } else if (lower.contains('capsule')) {
      return isPlural ? 'capsules' : 'capsule';
    } else if (lower.contains('syringe')) {
      return isPlural ? 'syringes' : 'syringe';
    } else if (lower.contains('vial')) {
      return isPlural ? 'vials' : 'vial';
    }

    // Fallback
    return form;
  }

  /// Builds the dates line for line 4
  Widget _buildDatesLine(BuildContext context, Color fg) {
    final theme = Theme.of(context);

    if (startDate == null) {
      return const SizedBox.shrink();
    }

    final startStr = MaterialLocalizations.of(context).formatCompactDate(startDate!);
    final endStr = endDate != null
        ? MaterialLocalizations.of(context).formatCompactDate(endDate!)
        : null;

    return Text(
      endStr != null ? 'Start Date $startStr End $endStr' : 'Start Date $startStr No End',
      style: theme.textTheme.bodySmall?.copyWith(
        color: fg.withValues(alpha: 0.95),
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }
}
