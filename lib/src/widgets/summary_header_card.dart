import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

class SummaryHeaderCard extends StatelessWidget {
  const SummaryHeaderCard({
    super.key,
    required this.title,
    this.manufacturer,
    this.strengthValue,
    this.strengthUnitLabel,
    this.perMlValue,
    this.stockCurrent,
    this.stockInitial,
    this.stockUnitLabel,
    this.expiryText,
    this.expiryDate,
    this.showRefrigerate = false,
    this.showFrozen = false,
    this.showDark = false,
    this.lowStockEnabled = false,
    this.lowStockThreshold,
    this.neutral = false,
    this.outlined = false,
    this.leadingIcon,
    this.includeNameInStrengthLine = false,
    this.formLabelPlural,
    this.perTabletLabel = true,
    this.perUnitLabel,
  });

  final String title;
  final String? manufacturer;
  final double? strengthValue;
  final String? strengthUnitLabel;
  final double? perMlValue;
  final double? stockCurrent;
  final double? stockInitial;
  final String? stockUnitLabel;
  final String? expiryText;
  final DateTime? expiryDate;
  final bool showRefrigerate;
  final bool showFrozen;
  final bool showDark;
  final bool lowStockEnabled;
  final double? lowStockThreshold;
  // When true, renders with soft surface background and onSurface text colors (for medication list cards).
  final bool neutral;
  final bool outlined;
  final IconData? leadingIcon;
  final bool includeNameInStrengthLine;
  final String? formLabelPlural;
  final bool perTabletLabel;
  // Optional: override the default "per tablet" with a custom unit (e.g., "Syringe")
  final String? perUnitLabel;

  String _fmt2(double? v) {
    if (v == null) return '-';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  // Convenience: build a header card directly from a Medication model
  factory SummaryHeaderCard.fromMedication(Medication m, {bool neutral = false, bool outlined = false}) {
    String unitLabel;
    switch (m.strengthUnit) {
      case Unit.mcg:
        unitLabel = 'mcg';
        break;
      case Unit.mg:
        unitLabel = 'mg';
        break;
      case Unit.g:
        unitLabel = 'g';
        break;
      default:
        unitLabel = m.strengthUnit.name;
    }
    String stockUnitLabel;
    switch (m.stockUnit) {
      case StockUnit.tablets:
        stockUnitLabel = 'tablets';
        break;
      default:
        stockUnitLabel = m.stockUnit.name;
    }
    final showDark = (m.storageInstructions?.toLowerCase().contains('light') ?? false);
    final icon = () {
      switch (m.form) {
        case MedicationForm.tablet:
          return Icons.medication;
        case MedicationForm.capsule:
          return MdiIcons.pill;
        case MedicationForm.injectionPreFilledSyringe:
        case MedicationForm.injectionSingleDoseVial:
        case MedicationForm.injectionMultiDoseVial:
          return Icons.vaccines;
      }
    }();
    return SummaryHeaderCard(
      title: m.name,
      manufacturer: m.manufacturer,
      strengthValue: m.strengthValue,
      strengthUnitLabel: unitLabel,
      stockCurrent: m.stockValue,
      stockInitial: m.initialStockValue ?? m.stockValue,
      stockUnitLabel: stockUnitLabel,
      expiryDate: m.expiry,
      showRefrigerate: m.requiresRefrigeration,
      showFrozen: false, // not persisted in model currently
      showDark: showDark,
      lowStockEnabled: m.lowStockEnabled,
      lowStockThreshold: m.lowStockThreshold,
      neutral: neutral,
      outlined: outlined,
      leadingIcon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool lowStockActive = lowStockEnabled && stockCurrent != null && lowStockThreshold != null && stockCurrent! <= lowStockThreshold!;

    final Color bg = neutral ? cs.surfaceContainerLowest : cs.primary;
    final Color fg = neutral ? cs.onSurface : cs.onPrimary;

    // Resolve localized expiry text if a DateTime was provided
    String? expDisplay;
    if (expiryDate != null) {
      expDisplay = MaterialLocalizations.of(context).formatCompactDate(expiryDate!);
    } else {
      expDisplay = expiryText;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: (neutral && outlined)
            ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.5), width: 0.75)
            : null,
        boxShadow: neutral
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (neutral ? cs.primary : cs.onPrimary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(leadingIcon ?? Icons.medication, color: neutral ? cs.primary : fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: neutral ? cs.primary : fg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Top-right cluster: Expiry text only
                    if (expDisplay != null && expDisplay.isNotEmpty)
                      Text(
                        'Exp: $expDisplay',
                        style: theme.textTheme.bodySmall?.copyWith(color: fg),
                      ),
                  ],
                ),
                if ((manufacturer ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    manufacturer!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fg.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                // Bottom area: left side (multi-line details), right side (storage icons)
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left cluster: each item on its own line for clarity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((strengthUnitLabel ?? '').isNotEmpty && (
                                includeNameInStrengthLine || (strengthValue != null)
                              ))
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: neutral ? cs.onSurfaceVariant : fg,
                                ),
                                children: includeNameInStrengthLine
                                    ? [
                                        TextSpan(
                                          text: _fmt2(strengthValue ?? 0),
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                        TextSpan(text: ' $strengthUnitLabel '),
                                        if (perMlValue != null) TextSpan(text: 'in ${_fmt2(perMlValue)} mL, '),
                                        TextSpan(text: '$title '),
                                        TextSpan(text: formLabelPlural ?? ''),
                                      ]
                                    : (
                                        perUnitLabel != null
                                            ? [
                                                TextSpan(
                                                  text: _fmt2(strengthValue ?? 0),
                                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                                ),
                                                TextSpan(text: ' $strengthUnitLabel'),
                                                if (perMlValue != null) TextSpan(text: ' in ${_fmt2(perMlValue)} mL'),
                                                const TextSpan(text: ' per '),
                                                TextSpan(text: perUnitLabel!),
                                              ]
                                            : (perTabletLabel
                                                ? [
                                                    TextSpan(
                                                      text: _fmt2(strengthValue ?? 0),
                                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                                    ),
                                                    TextSpan(text: ' $strengthUnitLabel'),
                                                    if (perMlValue != null) TextSpan(text: ' in ${_fmt2(perMlValue)} mL'),
                                                    const TextSpan(text: ' per tablet'),
                                                  ]
                                                : [
                                                    TextSpan(
                                                      text: _fmt2(strengthValue ?? 0),
                                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                                    ),
                                                    TextSpan(text: ' $strengthUnitLabel'),
                                                    if (perMlValue != null) TextSpan(text: ' in ${_fmt2(perMlValue)} mL'),
                                                    TextSpan(text: formLabelPlural != null && formLabelPlural!.isNotEmpty ? ' $formLabelPlural' : ''),
                                                  ]
                                              )
                                      ),
                              ),
                            ),
                          if (stockCurrent != null && (stockUnitLabel ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: neutral ? cs.onSurface : cs.onPrimary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _fmt2(stockCurrent),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: () {
                                          final total = stockInitial ?? 0;
                                          if (total <= 0) {
                                            // When no initial stock is set, ensure contrast on primary background
                                            return neutral ? cs.primary : cs.onPrimary;
                                          }
                                          final pct = (stockCurrent! / total).clamp(0.0, 1.0);
                                          if (!neutral) return cs.onPrimary;
                                          if (pct <= 0.2) return cs.error;
                                          if (pct <= 0.5) return Colors.orange;
                                          return cs.primary;
                                        }(),
                                      ),
                                    ),
                                    if (stockInitial != null) ...[
                                      const TextSpan(text: '/'),
                                      TextSpan(
                                        text: _fmt2(stockInitial),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: neutral ? cs.primary : cs.onPrimary,
                                        ),
                                      ),
                                    ],
                                    TextSpan(text: ' $stockUnitLabel remain'),
                                  ],
                                ),
                              ),
                            ),
                          if (lowStockEnabled && lowStockThreshold != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (lowStockActive) ...[
                                    Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade300),
                                    const SizedBox(width: 4),
                                  ],
                                  RichText(
                                    text: TextSpan(
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: lowStockActive
                                            ? Colors.amber.shade200
                                            : (neutral
                                                ? cs.onSurfaceVariant.withValues(alpha: 0.75)
                                                : fg.withValues(alpha: 0.85)),
                                        fontWeight: lowStockActive ? FontWeight.w700 : FontWeight.w600,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Alert at '),
                                        TextSpan(
                                          text: _fmt2(lowStockThreshold),
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                        TextSpan(text: ' ${stockUnitLabel ?? 'left'} remaining'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Right cluster: storage icons inline on the same bottom row, aligned bottom-right
                    if (showRefrigerate || showFrozen || showDark) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showRefrigerate)
                            Icon(Icons.kitchen, size: 18, color: neutral ? cs.onSurfaceVariant : fg),
                          if (showFrozen) ...[
                            if (showRefrigerate) const SizedBox(width: 6),
                            Icon(Icons.ac_unit, size: 18, color: neutral ? cs.onSurfaceVariant : fg),
                          ],
                          if (showDark) ...[
                            if (showRefrigerate || showFrozen) const SizedBox(width: 6),
                            Icon(Icons.dark_mode, size: 18, color: neutral ? cs.onSurfaceVariant : fg),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}