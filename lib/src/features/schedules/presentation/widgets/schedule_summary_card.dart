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
                    '${_fmt2(med.stockValue)} $stockLabel remaining',
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
          // Dates row
          if (startDate != null) ..[
            const SizedBox(height: 8),
            _buildDatesRow(context, fg),
          ],
        ],
      ),
    );
  }

  /// Builds the schedule description with prominent styling
  /// Format: Two-column responsive layout with dates
  Widget _buildStyledDescription(BuildContext context, String description, Color fg) {
    final theme = Theme.of(context);
    
    // Parse the description to extract parts
    // Original format: "Take {dose} {MedName} {MedType} {frequency} at {times}. Dose is {dose} {unit} is {strength}."
    
    // Extract parts using improved regex
    final takeMatch = RegExp(
      r'Take (\d+\.?\d*)\s+(\S+)\s+(Tablets?|Capsules?|Pre-Filled Syringes?|Single Dose Vials?|Multi Dose Vials?)',
      caseSensitive: false,
    ).firstMatch(description);
    
    // Improved frequency match - capture everything between medType and " at "
    final frequencyMatch = RegExp(
      r'(?:Tablets?|Capsules?|Pre-Filled Syringes?|Single Dose Vials?|Multi Dose Vials?)\s+(Every[^.]+?)\s+at\s+',
      caseSensitive: false,
    ).firstMatch(description);
    
    final timeMatch = RegExp(
      r'at\s+([\d:,\s]+(?:AM|PM|am|pm)(?:,\s*[\d:,\s]+(?:AM|PM|am|pm))*)',
      caseSensitive: false,
    ).firstMatch(description);
    
    final doseMatch = RegExp(
      r'is\s+(\d+\.?\d*)(mg|mcg|g|IU|units|ml)(?!.*is)',
      caseSensitive: false,
    ).allMatches(description).lastOrNull;
    
    // Build two-column layout (responsive)
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth > 300;
        
        if (isTwoColumn) {
          // Two-column layout
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: Take instruction and frequency
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTakeLine(theme, takeMatch, fg),
                    if (frequencyMatch != null) ...[              const SizedBox(height: 2),
                      _buildTextLine(theme, frequencyMatch.group(1)?.trim() ?? '', fg),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right column: Time and dose
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (timeMatch != null) ..[
                      _buildTextLine(theme, timeMatch.group(1)?.trim() ?? '', fg, prefix: 'at '),
                      const SizedBox(height: 2),
                    ],
                    if (doseMatch != null)
                      _buildDoseLine(theme, doseMatch, fg),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Single column for narrow screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTakeLine(theme, takeMatch, fg),
              if (frequencyMatch != null) ..[
                const SizedBox(height: 2),
                _buildTextLine(theme, frequencyMatch.group(1)?.trim() ?? '', fg),
              ],
              if (timeMatch != null) ..[
                const SizedBox(height: 2),
                _buildTextLine(theme, timeMatch.group(1)?.trim() ?? '', fg, prefix: 'at '),
              ],
              if (doseMatch != null) ..[
                const SizedBox(height: 2),
                _buildDoseLine(theme, doseMatch, fg),
              ],
            ],
          );
        }
      },
    );
  }
  
  Widget _buildTakeLine(ThemeData theme, RegExpMatch? match, Color fg) {
    if (match == null) return const SizedBox.shrink();
    
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Take ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: fg.withValues(alpha: 0.95),
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: '${match.group(1)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          TextSpan(
            text: ' ${match.group(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: fg.withValues(alpha: 0.95),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextLine(ThemeData theme, String text, Color fg, {String prefix = ''}) {
    return Text(
      '$prefix$text',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: fg.withValues(alpha: 0.95),
        fontWeight: FontWeight.w500,
      ),
    );
  }
  
  Widget _buildDoseLine(ThemeData theme, RegExpMatch match, Color fg) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Dose: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: fg.withValues(alpha: 0.95),
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: '${match.group(1)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          TextSpan(
            text: match.group(2) ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDatesRow(BuildContext context, Color fg) {
    final theme = Theme.of(context);
    final startStr = MaterialLocalizations.of(context).formatCompactDate(startDate!);
    final endStr = endDate != null
        ? MaterialLocalizations.of(context).formatCompactDate(endDate!)
        : null;
    
    return Row(
      children: [
        Expanded(
          child: Text(
            'Start: $startStr',
            style: theme.textTheme.bodySmall?.copyWith(
              color: fg.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (endStr != null)
          Expanded(
            child: Text(
              'End: $endStr',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: fg.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
